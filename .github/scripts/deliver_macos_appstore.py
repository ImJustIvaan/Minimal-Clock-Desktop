#!/usr/bin/env python3
"""Drive a Mac App Store build the rest of the way through App Store Connect:
wait for Apple to finish processing the latest upload, attach it to an App
Store version, set that version's "What's New" text, and submit it for App
Review.

Invoked by .github/workflows/deliver-macos-appstore.yml — see that file for
the required secrets/inputs and the manual prerequisites (app record must
already exist in App Store Connect, export compliance, API key role).
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


def wait_for_latest_build(client, app_id):
    print("Waiting for the latest uploaded build to finish processing...")
    deadline = time.time() + POLL_TIMEOUT_SECONDS
    last_state = None
    while time.time() < deadline:
        # The builds endpoint doesn't support filter[platform] — this app
        # only ships on macOS, so filtering by app is sufficient.
        data = client.request(
            "GET",
            "/v1/builds",
            params={
                "filter[app]": app_id,
                "sort": "-uploadedDate",
                "limit": 1,
                "fields[builds]": "version,processingState,uploadedDate",
            },
        )
        builds = data.get("data", [])
        if not builds:
            raise ConnectError("No builds found for this app yet — has the upload finished?")
        build = builds[0]
        state = build["attributes"]["processingState"]
        if state != last_state:
            print(f"  build {build['id']} (version {build['attributes'].get('version')}): {state}")
            last_state = state
        if state == "VALID":
            return build
        if state in ("FAILED", "INVALID"):
            raise ConnectError(f"Build processing ended in state {state} — check App Store Connect.")
        time.sleep(POLL_INTERVAL_SECONDS)
    raise ConnectError("Timed out waiting for build processing to finish.")


def find_or_create_version(client, app_id, version_string):
    data = client.request(
        "GET",
        f"/v1/apps/{app_id}/appStoreVersions",
        params={"filter[versionString]": version_string, "filter[platform]": "MAC_OS"},
    )
    versions = data.get("data", [])
    if versions:
        version = versions[0]
        print(f"Using existing App Store version {version['id']} ({version_string}), "
              f"state={version['attributes'].get('appStoreState')}")
        return version

    print(f"Creating new App Store version {version_string}...")
    created = client.request(
        "POST",
        "/v1/appStoreVersions",
        json={
            "data": {
                "type": "appStoreVersions",
                "attributes": {
                    "platform": "MAC_OS",
                    "versionString": version_string,
                    "releaseType": "MANUAL",
                },
                "relationships": {
                    "app": {"data": {"type": "apps", "id": app_id}},
                },
            }
        },
    )
    return created["data"]


def attach_build(client, version_id, build_id):
    print(f"Attaching build {build_id} to version {version_id}...")
    client.request(
        "PATCH",
        f"/v1/appStoreVersions/{version_id}/relationships/build",
        json={"data": {"type": "builds", "id": build_id}},
    )


def set_whats_new(client, version_id, whats_new):
    if not whats_new:
        return
    data = client.request(
        "GET",
        f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations",
    )
    localizations = data.get("data", [])
    if not localizations:
        print("No localizations found on this version — skipping What's New update.")
        return
    localization_id = localizations[0]["id"]
    print(f"Setting What's New on localization {localization_id}...")
    client.request(
        "PATCH",
        f"/v1/appStoreVersionLocalizations/{localization_id}",
        json={
            "data": {
                "type": "appStoreVersionLocalizations",
                "id": localization_id,
                "attributes": {"whatsNew": whats_new},
            }
        },
    )


def submit_for_review(client, app_id, version_id):
    print("Creating review submission...")
    submission = client.request(
        "POST",
        "/v1/reviewSubmissions",
        json={
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "MAC_OS"},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            }
        },
    )
    submission_id = submission["data"]["id"]

    print("Adding the App Store version to the review submission...")
    client.request(
        "POST",
        "/v1/reviewSubmissionItems",
        json={
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
                },
            }
        },
    )

    print("Submitting for App Review...")
    client.request(
        "PATCH",
        f"/v1/reviewSubmissions/{submission_id}",
        json={
            "data": {
                "type": "reviewSubmissions",
                "id": submission_id,
                "attributes": {"submitted": True},
            }
        },
    )
    print(f"Submitted review submission {submission_id} for App Review.")


def main():
    key_id = env("APPLE_API_KEY_ID")
    issuer_id = env("APPLE_API_ISSUER_ID")
    key_b64 = env("APPLE_API_KEY_BASE64")
    app_id = env("APP_STORE_CONNECT_APP_ID")
    version_string = env("VERSION_STRING")
    whats_new = os.environ.get("WHATS_NEW", "")

    private_key_pem = base64.b64decode(key_b64)
    client = Client(key_id, issuer_id, private_key_pem)

    try:
        build = wait_for_latest_build(client, app_id)
        version = find_or_create_version(client, app_id, version_string)
        attach_build(client, version["id"], build["id"])
        set_whats_new(client, version["id"], whats_new)
        submit_for_review(client, app_id, version["id"])
    except ConnectError as e:
        print(f"\nFailed: {e}", file=sys.stderr)
        print("Finish this submission manually in App Store Connect.", file=sys.stderr)
        sys.exit(1)

    print("\nDone. The build has been submitted for App Review.")


if __name__ == "__main__":
    main()
