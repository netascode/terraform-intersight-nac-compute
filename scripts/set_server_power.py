#!/usr/bin/env python3
"""Set the admin power state of an Intersight server (compute.ServerSetting).

The CiscoDevNet/intersight provider has no resource for compute.ServerSetting, so the module calls this script
from a terraform_data local-exec provisioner. It sends PATCH /api/v1/compute/ServerSettings/<moid> with
{"AdminPowerState": <state>}; Intersight starts a power workflow and returns immediately.

Credentials come from the same environment variables as the provider, so no secret is passed on the command line:
  INTERSIGHT_API_KEY       API key id
  INTERSIGHT_SECRET_KEY    secret key, either a path to the PEM file or the PEM contents
  INTERSIGHT_ENDPOINT_URL  endpoint (default https://intersight.com)

Requires the Python packages requests and cryptography.
"""
import argparse
import base64
import hashlib
import os
import sys
from datetime import datetime, timezone
from urllib.parse import urlparse

import requests
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, padding

STATES = ["PowerOn", "PowerOff", "Shutdown", "PowerCycle", "HardReset", "Reboot"]


class IntersightAuth(requests.auth.AuthBase):
    """HTTP signature auth (draft-cavage) as used by the Intersight API."""

    def __init__(self, key_id, key):
        self.key_id = key_id
        self.key = key

    def __call__(self, r):
        body = r.body or b""
        if isinstance(body, str):
            body = body.encode()
        digest = base64.b64encode(hashlib.sha256(body).digest()).decode()
        date = datetime.now(timezone.utc).strftime("%a, %d %b %Y %H:%M:%S GMT")
        parsed = urlparse(r.url)
        path = f"{parsed.path}?{parsed.query}" if parsed.query else parsed.path
        signing_string = (
            f"(request-target): {r.method.lower()} {path}\n"
            f"date: {date}\n"
            f"host: {parsed.netloc}\n"
            f"digest: SHA-256={digest}"
        )
        if isinstance(self.key, ec.EllipticCurvePrivateKey):
            signature = self.key.sign(signing_string.encode(), ec.ECDSA(hashes.SHA256()))
        else:
            signature = self.key.sign(signing_string.encode(), padding.PKCS1v15(), hashes.SHA256())
        r.headers.update(
            {
                "Date": date,
                "Host": parsed.netloc,
                "Digest": f"SHA-256={digest}",
                "Authorization": (
                    f'Signature keyId="{self.key_id}",algorithm="hs2019",'
                    f'headers="(request-target) date host digest",'
                    f'signature="{base64.b64encode(signature).decode()}"'
                ),
            }
        )
        return r


def load_auth():
    key_id = os.environ.get("INTERSIGHT_API_KEY")
    secret = os.environ.get("INTERSIGHT_SECRET_KEY")
    if not key_id or not secret:
        sys.exit("INTERSIGHT_API_KEY and INTERSIGHT_SECRET_KEY must be set")
    if os.path.isfile(secret):
        with open(secret, "rb") as f:
            pem = f.read().decode()
    else:
        pem = secret.replace("\\n", "\n")
    # Strip the PEM armor and decode, which also handles mismatched PKCS#1/PKCS#8 labels
    der = base64.b64decode("".join(line for line in pem.splitlines() if not line.startswith("-----")))
    return IntersightAuth(key_id, serialization.load_der_private_key(der, password=None))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--moid", required=True, help="Moid of the compute.ServerSetting")
    parser.add_argument("--state", required=True, choices=STATES, help="AdminPowerState to set")
    args = parser.parse_args()

    base = os.environ.get("INTERSIGHT_ENDPOINT_URL", "https://intersight.com").rstrip("/")
    url = f"{base}/api/v1/compute/ServerSettings/{args.moid}"
    response = requests.patch(url, auth=load_auth(), json={"AdminPowerState": args.state}, timeout=60)
    if not response.ok:
        sys.exit(f"PATCH {url} failed: HTTP {response.status_code} {response.text}")
    print(f"Sent {args.state} to compute.ServerSetting {args.moid}")


if __name__ == "__main__":
    main()
