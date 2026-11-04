#!/usr/bin/env python3
"""Send one simple task to Google Gemini (free tier) via its OpenAI-compatible API.

Usage:  echo "text" | python3 gemini.py "Fasse zusammen:"      (stdin is appended to the prompt)
        python3 gemini.py "Übersetze ins Englische: Guten Morgen"
Options: --model MODEL   (default: env GEMINI_MODEL or gemini-3.5-flash-lite)
         --check         only test that the key works (lists models)

The API key is read from the environment variable GEMINI_API_KEY (Google's
recommended name), or else from the file ~/.config/gemini/api_key.
Only Python's standard library is used.
"""
import json
import os
import stat
import sys
import urllib.error
import urllib.request
from pathlib import Path

BASE = "https://generativelanguage.googleapis.com/v1beta/openai/"
KEY_FILE = Path.home() / ".config" / "gemini" / "api_key"


def api_key():
    key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not key and KEY_FILE.is_file():
        key = KEY_FILE.read_text(encoding="utf-8").strip()
    if not key:
        sys.exit("Kein Gemini-Schlüssel gefunden: weder GEMINI_API_KEY noch %s." % KEY_FILE)
    return key


def call(path, payload=None):
    req = urllib.request.Request(
        BASE + path,
        data=json.dumps(payload).encode() if payload is not None else None,
        headers={"Authorization": "Bearer " + api_key(), "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")[:500]
        hint = {400: "Anfrage oder Schlüssel ungültig", 401: "Schlüssel ungültig",
                403: "Schlüssel ungültig oder gesperrt", 429: "Kostenloses Limit erreicht, später erneut versuchen"}
        sys.exit("Gemini-Fehler %s (%s): %s" % (e.code, hint.get(e.code, "siehe Text"), body))


def main(argv):
    model = os.environ.get("GEMINI_MODEL", "gemini-3.5-flash-lite")
    if "--model" in argv:
        i = argv.index("--model")
        model = argv[i + 1]
        del argv[i:i + 2]
    if "--check" in argv:
        ids = [m["id"] for m in call("models").get("data", [])]
        print("Schlüssel OK, %d Modelle verfügbar, z.B.: %s" % (len(ids), ", ".join(i for i in ids if "flash" in i)[:300]))
        return
    prompt = " ".join(argv).strip()
    mode = os.fstat(0).st_mode if not sys.stdin.closed else 0
    if stat.S_ISFIFO(mode) or stat.S_ISREG(mode):  # piped or redirected input only
        extra = sys.stdin.read()
        if extra.strip():
            prompt = (prompt + "\n\n" + extra).strip()
    if not prompt:
        sys.exit(__doc__)
    out = call("chat/completions", {"model": model, "messages": [{"role": "user", "content": prompt}]})
    print(out["choices"][0]["message"]["content"])


if __name__ == "__main__":
    main(sys.argv[1:])
