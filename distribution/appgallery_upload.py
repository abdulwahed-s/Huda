import argparse
import glob
import json
import os
import sys
import time

import requests

TOKEN_URL = "https://connect-api.cloud.huawei.com/api/oauth2/v1/token"
BASE = "https://connect-api.cloud.huawei.com/api/publish/v2"

LOCALE_MAP = {
    "whatsnew-en-US": "en_US",
    "whatsnew-ar":    "ar",
    "whatsnew-de-DE": "de_DE",
    "whatsnew-es-ES": "es_ES",
    "whatsnew-fr-FR": "fr_FR",
    "whatsnew-bn-BD": "bn_BD",
    "whatsnew-ms":    "ms_MY",
    "whatsnew-ru-RU": "ru_RU",
    "whatsnew-tr-TR": "tr_TR",
    "whatsnew-ur":    "ur",
}


def die(msg):
    print(f"\n❌ {msg}")
    sys.exit(1)


def get_access_token(client_id, client_secret):
    resp = requests.post(TOKEN_URL, json={
        "grant_type": "client_credentials",
        "client_id": client_id,
        "client_secret": client_secret,
    })
    if not resp.ok:
        die(f"Token request failed: HTTP {resp.status_code} — {resp.text}")
    token = resp.json().get("access_token")
    if not token:
        die(f"No access_token in response: {resp.text}")
    print("✓ Obtained access token")
    return token


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--client-id", default=os.environ.get("HUAWEI_CLIENT_ID"),
                    help="Team-level API Client ID (or env HUAWEI_CLIENT_ID)")
    ap.add_argument("--client-secret", default=os.environ.get("HUAWEI_CLIENT_SECRET"),
                    help="API Client Secret (or env HUAWEI_CLIENT_SECRET)")
    ap.add_argument("--aab", required=True, help="Path to the .aab file")
    ap.add_argument("--app-id", default=os.environ.get("HUAWEI_APP_ID"),
                    help="Numeric AppGallery app ID (or env HUAWEI_APP_ID)")
    ap.add_argument("--whatsnew", default="distribution/whatsnew",
                    help="Folder with whatsnew-* release-note files")
    ap.add_argument("--no-submit", action="store_true",
                    help="Upload only; do not submit for review")
    args = ap.parse_args()

    if not args.client_id or not args.client_secret:
        die("client-id and client-secret are required (flags or env vars)")
    if not args.app_id:
        die("app-id is required (--app-id or env HUAWEI_APP_ID)")
    if not os.path.isfile(args.aab):
        die(f"AAB not found: {args.aab}")

    app_id = args.app_id

    access_token = get_access_token(args.client_id, args.client_secret)
    auth_headers = {
        "Authorization": f"Bearer {access_token}",
        "client_id": args.client_id,
        "Content-Type": "application/json",
    }

    # 1. Get upload URL
    meta = requests.get(
        f"{BASE}/upload-url?appId={app_id}&suffix=aab&releaseType=1",
        headers=auth_headers,
    ).json()
    if "uploadUrl" not in meta:
        die(f"upload-url response: {json.dumps(meta, indent=2)}")
    upload_url = meta["uploadUrl"]
    auth_code = meta["authCode"]
    print("✓ Got upload URL")

    # 2. Upload AAB (no JSON content-type on the multipart POST)
    file_size = os.path.getsize(args.aab)
    with open(args.aab, "rb") as f:
        up = requests.post(upload_url, data={
            "authCode": auth_code,
            "fileCount": "1",
        }, files={"file": (os.path.basename(args.aab), f, "application/octet-stream")})
    up_json = up.json()
    try:
        dest_url = up_json["result"]["UploadFileRsp"]["fileInfoList"][0]["fileDestUlr"]
    except (KeyError, IndexError):
        die(f"Upload response unexpected: {json.dumps(up_json, indent=2)}")
    print("✓ AAB uploaded")

    # 3. Update app file info
    resp = requests.put(f"{BASE}/app-file-info?appId={app_id}", headers=auth_headers, json={
        "fileType": 5,
        "files": [{"fileName": os.path.basename(args.aab),
                   "fileDestUrl": dest_url, "size": file_size}],
    })
    if not resp.ok or resp.json().get("ret", {}).get("code", 0) != 0:
        die(f"app-file-info failed: {resp.status_code} — {resp.text}")
    print("✓ App file info updated")

    # 4. Give Huawei time to compile the AAB server-side before submitting.
    #    (Huawei queues compilation; a short wait avoids submitting too early.)
    if not args.no_submit:
        print("… waiting 90s for AAB server-side compilation")
        time.sleep(90)

    # 5. Release notes — PUT app-language-info with lang + newFeatures in body
    for filepath in sorted(glob.glob(os.path.join(args.whatsnew, "whatsnew-*"))):
        lang = LOCALE_MAP.get(os.path.basename(filepath))
        if not lang:
            continue
        text = open(filepath, encoding="utf-8").read().strip()
        r = requests.put(f"{BASE}/app-language-info?appId={app_id}",
                         headers=auth_headers,
                         json={"lang": lang, "newFeatures": text})
        ok = r.ok and r.json().get("ret", {}).get("code", 0) == 0
        print(f"{'✓' if ok else '⚠'} Release notes [{lang}]"
              + ("" if ok else f": {r.status_code} {r.text[:200]}"))

    # 6. Submit
    if args.no_submit:
        print("\n✓ Upload complete (submit skipped)")
        return
    resp = requests.post(f"{BASE}/app-submit?appId={app_id}", headers=auth_headers)
    if not resp.ok or resp.json().get("ret", {}).get("code", 0) != 0:
        die(f"app-submit failed: {resp.status_code} — {resp.text}")
    print("\n✓ Submitted to AppGallery for review")


if __name__ == "__main__":
    main()
