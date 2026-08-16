import base64
import hashlib
import hmac
import json
import os

import boto3

_secrets = boto3.client("secretsmanager")
_codebuild = boto3.client("codebuild")
_hmac_secret_cache = None


def _hmac_secret():
    global _hmac_secret_cache
    if _hmac_secret_cache is None:
        _hmac_secret_cache = _secrets.get_secret_value(
            SecretId=os.environ["WEBHOOK_SECRET_ARN"]
        )["SecretString"]
    return _hmac_secret_cache


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

    _codebuild.start_build(
        projectName=os.environ["CODEBUILD_PROJECT_NAME"],
        environmentVariablesOverride=[
            {"name": "RUNNER_LABELS", "value": ",".join(job["labels"])},
            {"name": "GH_JOB_ID", "value": str(job["id"])},
            {"name": "GH_RUN_ID", "value": str(job["run_id"])},
        ],
    )
    return {"statusCode": 201, "body": "build started"}
