import base64
import hashlib
import hmac
import json
import os
import urllib.error
import urllib.request

import boto3

_secrets = boto3.client("secretsmanager")
_codebuild = boto3.client("codebuild")
_hmac_secret_cache = None
_github_token_cache = None


def _hmac_secret():
    global _hmac_secret_cache
    if _hmac_secret_cache is None:
        _hmac_secret_cache = _secrets.get_secret_value(
            SecretId=os.environ["WEBHOOK_SECRET_ARN"]
        )["SecretString"]
    return _hmac_secret_cache


def _github_token():
    global _github_token_cache
    if _github_token_cache is None:
        secret = _secrets.get_secret_value(
            SecretId=os.environ["GITHUB_TOKEN_SECRET_ARN"]
        )["SecretString"]
        try:
            _github_token_cache = json.loads(secret)["token"]
        except (json.JSONDecodeError, KeyError):
            _github_token_cache = secret
    return _github_token_cache


def _job_still_queued(job_id):
    # Re-check the job's live status right before starting a build. GitHub delivers
    # webhooks at-least-once, so a duplicate `queued` delivery for a job another
    # build already claimed would otherwise spin up a second CodeBuild runner that
    # just idles until build_timeout with nothing to do.
    owner = os.environ["GITHUB_REPO_OWNER"]
    repo = os.environ["GITHUB_REPO_NAME"]
    req = urllib.request.Request(
        f"https://api.github.com/repos/{owner}/{repo}/actions/jobs/{job_id}",
        headers={
            "Authorization": f"Bearer {_github_token()}",
            "Accept": "application/vnd.github+json",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read())
    except urllib.error.HTTPError:
        # If the status check itself fails, err on the side of starting the build -
        # a spurious extra runner that idles out is cheaper than never running the job.
        return True
    return data.get("status") == "queued"


def handler(event, context):
    raw = base64.b64decode(event["body"]) if event.get("isBase64Encoded") else event["body"].encode()
    headers = {k.lower(): v for k, v in event.get("headers", {}).items()}

    expected = "sha256=" + hmac.new(_hmac_secret().encode(), raw, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, headers.get("x-hub-signature-256", "")):
        return {"statusCode": 401, "body": "bad signature"}

    if headers.get("x-github-event") != "workflow_job":
        return {"statusCode": 202, "body": "ignored: not workflow_job"}

    payload = json.loads(raw)
    if payload.get("action") != "queued":
        return {"statusCode": 202, "body": "ignored: not queued"}

    job = payload["workflow_job"]
    if os.environ["RUNNER_LABEL"] not in job.get("labels", []):
        return {"statusCode": 202, "body": "ignored: label mismatch"}

    if not _job_still_queued(job["id"]):
        return {"statusCode": 202, "body": "ignored: job no longer queued (already claimed)"}

    _codebuild.start_build(
        projectName=os.environ["CODEBUILD_PROJECT_NAME"],
        environmentVariablesOverride=[
            {"name": "RUNNER_LABELS", "value": ",".join(job["labels"])},
            {"name": "GH_JOB_ID", "value": str(job["id"])},
            {"name": "GH_RUN_ID", "value": str(job["run_id"])},
        ],
    )
    return {"statusCode": 201, "body": "build started"}
