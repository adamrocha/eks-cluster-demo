#!/usr/bin/env python3
import json
import urllib.request
from urllib.parse import urlparse


def get_public_ip(timeout=5):
    url_string = "https://4.ident.me"
    # 1. Audit URL for permitted schemes (Fixes B310 / SSRF)
    parsed = urlparse(url_string)
    if parsed.scheme not in ("http", "https"):
        return {"error": f"Disallowed scheme: {parsed.scheme}"}
    headers = {"User-Agent": "Mozilla/5.0"}

    try:
        req = urllib.request.Request(url_string, headers=headers)
        # 2. Add '# nosec' if the linter persists.
        # This tells Trunk: "I have audited the scheme above."
        with urllib.request.urlopen(req, timeout=timeout) as response:  # nosec
            return response.read().decode().strip()
    except Exception as e:
        return {"error": str(e)}


def main():
    result = get_public_ip()
    print(
        json.dumps(
            {"ip": result, "status": "success"} if isinstance(result, str) else result
        )
    )


if __name__ == "__main__":
    main()
