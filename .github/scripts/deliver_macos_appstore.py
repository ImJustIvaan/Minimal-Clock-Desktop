#!/usr/bin/env python3
"""Wait for the most recently uploaded Mac App Store build to finish Apple's
processing, and report its final state.

Invoked by .github/workflows/deliver-macos-appstore.yml. Deliberately does
not attach the build to a version or submit for review — those actions need
an App Store Connect API key with the App Manager role, which this project's
key doesn't have. Once this reports the build as VALID, attach it to a
version and submit for review manually in App Store Connect.
"""
import base64
import os
import sys
import time

import jwt
import requests

API_BASE = "https://api.appstoreconnect.apple.com"
POLL_INTERVAL_SECONDS = 60
POLL_TIMEOUT_SECONDS = 2 * 60 * 60  # Apple's processing can take a while.


def env(name):
    value = os.environ.get(name)
    if not value:
        print(f"Missing required environment variable: {name}", file=sys.stderr)
        sys.exit(1)
    return value


def make_token(key_id, issuer_id, private_key_pem):
    now = int(time.time())
    return jwt.encode(
        {
            "iss": issuer_id,
            "iat": now,
            "exp": now + 19 * 60,
            "aud": "appstoreconnect-v1",
        },
        private_key_pem,
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )


class ConnectError(RuntimeError):
    pass


class Client:
    def __init__(self, key_id, issuer_id, private_key_pem):
        self._key_id = key_id
        self._issuer_id = issuer_id
        self._private_key_pem = private_key_pem
        self._token = make_token(key_id, issuer_id, private_key_pem)
        self._token_issued_at = time.time()

    def _headers(self):
        # Tokens are valid ~20 min; refresh if we're close to expiry (the
        # processing-wait loop can run for a long time).
        if time.time() - self._token_issued_at > 15 * 60:
            self._token = make_token(self._key_id, self._issuer_id, self._private_key_pem)
            self._token_issued_at = time.time()
        return {
            "Authorization": f"Bearer {self._token}",
            "Content-Type": "application/json",
        }

    def request(self, method, path, **kwargs):
        url = path if path.startswith("http") else f"{API_BASE}{path}"
        resp = requests.request(method, url, headers=self._headers(), timeout=30, **kwargs)
        if resp.status_code >= 300:
            print(f"{method} {url} -> {resp.status_code}", file=sys.stderr)
            print(resp.text, file=sys.stderr)
            raise ConnectError(f"{method} {path} failed with {resp.status_code}")
        return resp.json() if resp.text else {}


def find_latest_macos_build(client, app_id):
    # filter[platform] isn't a valid filter on /v1/builds, and this App Store
    # Connect app record covers more than one platform (iOS/macOS/tvOS share
    # one app id) — so fetch recent builds across all platforms and pick the
    # newest one whose preReleaseVersion is actually MAC_OS.
    data = client.request(
        "GET",
        "/v1/builds",
        params={
            "filter[app]": app_id,
            "sort": "-uploadedDate",
            "limit": 20,
            "include": "preReleaseVersion",
            "fields[builds]": "version,processingState,uploadedDate,preReleaseVersion",
            "fields[preReleaseVersions]": "platform,version",
        },
    )
    included = {item["id"]: item for item in data.get("included", [])}
    for build in data.get("data", []):
        prerelease_ref = build["relationships"].get("preReleaseVersion", {}).get("data")
        prerelease = included.get(prerelease_ref["id"]) if prerelease_ref else None
        if prerelease and prerelease["attributes"].get("platform") == "MAC_OS":
            return build, prerelease["attributes"].get("version")
    return None, None


def wait_for_latest_build(client, app_id):
    print("Waiting for the latest uploaded macOS build to finish processing...")
    deadline = time.time() + POLL_TIMEOUT_SECONDS
    last_state = None
    while time.time() < deadline:
        build, marketing_version = find_latest_macos_build(client, app_id)
        if build is None:
            raise ConnectError("No macOS builds found for this app yet — has the upload finished?")
        state = build["attributes"]["processingState"]
        if state != last_state:
            print(f"  build {build['id']} (marketing version {marketing_version}, "
                  f"build {build['attributes'].get('version')}): {state}")
            last_state = state
        if state == "VALID":
            return build
        if state in ("FAILED", "INVALID"):
            raise ConnectError(f"Build processing ended in state {state} — check App Store Connect.")
        time.sleep(POLL_INTERVAL_SECONDS)
    raise ConnectError("Timed out waiting for build processing to finish.")


def main():
    key_id = env("APPLE_API_KEY_ID")
    issuer_id = env("APPLE_API_ISSUER_ID")
    key_b64 = env("APPLE_API_KEY_BASE64")
    app_id = env("APP_STORE_CONNECT_APP_ID")

    private_key_pem = base64.b64decode(key_b64)
    client = Client(key_id, issuer_id, private_key_pem)

    try:
        build = wait_for_latest_build(client, app_id)
    except ConnectError as e:
        print(f"\nFailed: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"\nBuild {build['id']} (version {build['attributes'].get('version')}) has finished "
          f"processing and is ready. Attach it to a version and submit for review manually "
          f"in App Store Connect.")


if __name__ == "__main__":
    main()
