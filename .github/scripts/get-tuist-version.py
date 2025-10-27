#!/usr/bin/env python3
import json
import os
import sys
import urllib.error
import urllib.request

headers = {
    "Accept": "application/vnd.github+json",
    "User-Agent": "isoinspector-ci",
    "X-GitHub-Api-Version": "2022-11-28",
}
auth_header = os.environ.get("AUTH_HEADER")
if auth_header:
    # Explicitly handle 'Authorization: Bearer ...' and 'Authorization:Bearer ...'
    if auth_header.startswith("Authorization:"):
        value = auth_header[len("Authorization:"):].strip()
        if value.startswith("Bearer "):
            headers["Authorization"] = value
        else:
            sys.stderr.write("Authorization header does not start with 'Bearer '\n")
            sys.exit(1)

per_page = 30
max_pages = 10
version = None
page = 1
last_payload = None
while page <= max_pages and not version:
    url = f"https://api.github.com/repos/tuist/tuist/releases?per_page={per_page}&page={page}"
    request = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(request) as response:
            payload = json.load(response)
            last_payload = payload
    except urllib.error.HTTPError as exc:  # pragma: no cover - network failure guard
        sys.stderr.write("Failed to determine Tuist CLI release\n")
        sys.stderr.write(f"HTTP error: {exc.code}\n")
        try:
            details = exc.read().decode("utf-8")
            data = json.loads(details)
            error_data = data if isinstance(data, dict) else None
            message = error_data.get("message") if error_data else None
            if message:
                sys.stderr.write(message + "\n")
        except Exception:  # pragma: no cover - best effort diagnostics
            pass
        sys.exit(1)

    if not payload:
        break

    for release in payload:
        tag = release.get("tag_name")
        if not tag:
            continue
        for asset in release.get("assets", []):
            if asset.get("name") == "tuist.zip":
                version = tag
                break
        if version:
            break

    page += 1

if not version:
    sys.stderr.write("Failed to determine Tuist CLI release\n")
    error_data = last_payload if isinstance(last_payload, dict) else None
    if error_data and "message" in error_data:
        sys.stderr.write(str(error_data["message"]) + "\n")
    sys.exit(1)

with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as fh:
    fh.write(f"tuist_version={version}\n")
