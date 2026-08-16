import json
import os
import urllib.request

import boto3

_secrets = boto3.client("secretsmanager")

GITHUB_API = "https://api.github.com"


def _github_token():
    secret = _secrets.get_secret_value(SecretId=os.environ["GITHUB_TOKEN_SECRET_ARN"])["SecretString"]
    try:
        return json.loads(secret)["token"]
    except (json.JSONDecodeError, KeyError):
        return secret


def _github_request(method, path, token):
    req = urllib.request.Request(
        f"{GITHUB_API}{path}",
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
        },
    )
    with urllib.request.urlopen(req) as resp:
        body = resp.read()
        return json.loads(body) if body else {}


def handler(event, context):
    token = _github_token()
    owner = os.environ["GITHUB_REPO_OWNER"]
    repo = os.environ["GITHUB_REPO_NAME"]
    prefix = os.environ.get("RUNNER_NAME_PREFIX", "codebuild-")

    runners = _github_request("GET", f"/repos/{owner}/{repo}/actions/runners?per_page=100", token)
    removed = []
    for runner in runners.get("runners", []):
        if runner["status"] == "offline" and runner["name"].startswith(prefix):
            _github_request("DELETE", f"/repos/{owner}/{repo}/actions/runners/{runner['id']}", token)
            removed.append(runner["name"])

    return {"removed": removed, "checked": len(runners.get("runners", []))}
