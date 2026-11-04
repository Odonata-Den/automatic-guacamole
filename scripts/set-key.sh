#!/usr/bin/env bash
# Fragt einen API-Schlüssel oder ein Passwort UNSICHTBAR im Terminal ab
# und trägt es direkt dort ein, wo die Erweiterung es erwartet.
# Der Schlüssel erscheint weder auf dem Bildschirm noch im Verlauf der Shell
# noch in einer Befehlszeile; er geht nur über eine Pipe an python3.
#
#   ./scripts/set-key.sh scrapegraph            -> ~/.claude.json (MCP-Server "scrapegraph")
#   ./scripts/set-key.sh mirofish               -> ~/claude-erweiterungen/MiroFish/.env
#   ./scripts/set-key.sh harvey VARIABLE        -> ~/claude-erweiterungen/harvey/.env
#        z. B. GMAIL_CLIENT_SECRET, SMTP_PASSWORD, IMAP_PASSWORD, REOON_API_KEY
#   ./scripts/set-key.sh env DATEI VARIABLE     -> beliebige .env-Datei

set -eu
BASE="${RECHERCHE_DIR:-$HOME/claude-erweiterungen}"

ask_secret() {  # $1 = Beschriftung; Ergebnis in SECRET
  SECRET=""
  IFS= read -r -s -p "$1 (Eingabe bleibt unsichtbar): " SECRET; echo
  [ -n "$SECRET" ] || { echo "Nichts eingegeben, abgebrochen."; exit 1; }
}

# Schreibt VAR=Wert in eine .env-Datei (ersetzt eine vorhandene Zeile), Rechte 600.
put_env() {  # $1 = Datei, $2 = Variable; Wert kommt über stdin
  python3 -I -c '
import os, sys, re
path, var = sys.argv[1], sys.argv[2]
val = sys.stdin.read()
if not re.fullmatch(r"[A-Za-z0-9_.:/+=@-]*", val):
    # Sonderzeichen (Leerzeichen, #, Anführungszeichen): in einfache
    # Anführungszeichen setzen, wie python-dotenv es erwartet.
    q, bs = chr(39), chr(92)
    val = q + val.replace(bs, bs + bs).replace(q, bs + q) + q
lines = open(path).read().splitlines() if os.path.exists(path) else []
pat = re.compile(r"^\s*#?\s*" + re.escape(var) + r"\s*=")
out, done = [], False
for l in lines:
    if pat.match(l) and not done:
        out.append(f"{var}={val}"); done = True
    elif pat.match(l):
        continue
    else:
        out.append(l)
if not done:
    out.append(f"{var}={val}")
fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
with os.fdopen(fd, "w") as f:
    f.write("\n".join(out) + "\n")
os.chmod(path, 0o600)
' "$1" "$2"
}

case "${1:-}" in
  scrapegraph)
    ask_secret "ScrapeGraph-API-Schlüssel (von dashboard.scrapegraphai.com)"
    printf '%s' "$SECRET" | python3 -I -c '
import json, os, sys
p = os.path.expanduser("~/.claude.json")
cfg = json.load(open(p))
srv = cfg.get("mcpServers", {}).get("scrapegraph")
if not srv:
    sys.exit("MCP-Server \"scrapegraph\" nicht gefunden. Erst ./scripts/install-recherche.sh 1 ausführen.")
srv.setdefault("env", {})["SGAI_API_KEY"] = sys.stdin.read()
tmp = p + ".tmp"
fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
with os.fdopen(fd, "w") as f:
    json.dump(cfg, f, indent=2)
os.replace(tmp, p)
'
    echo "Gespeichert in: ~/.claude.json -> mcpServers -> scrapegraph -> env -> SGAI_API_KEY"
    echo "Claude Code neu starten, damit der Schlüssel benutzt wird."
    ;;
  mirofish)
    F="$BASE/MiroFish/.env"
    [ -f "$F" ] || { echo "$F fehlt. Erst ./scripts/install-recherche.sh 2 ausführen."; exit 1; }
    ask_secret "LLM-API-Schlüssel (OpenAI-kompatibler Anbieter)"
    printf '%s' "$SECRET" | put_env "$F" LLM_API_KEY
    ask_secret "Zep-API-Schlüssel (von app.getzep.com)"
    printf '%s' "$SECRET" | put_env "$F" ZEP_API_KEY
    echo "Gespeichert in: $F  (LLM_API_KEY, ZEP_API_KEY; nur für dich lesbar)"
    echo "Anbieter/Modell ändern: LLM_BASE_URL und LLM_MODEL_NAME in derselben Datei."
    ;;
  harvey)
    VAR="${2:?Welche Variable? z. B. ./scripts/set-key.sh harvey SMTP_PASSWORD}"
    F="$BASE/harvey/.env"
    [ -f "$F" ] || { echo "$F fehlt. Erst ./scripts/install-recherche.sh 3 ausführen."; exit 1; }
    ask_secret "$VAR für Harvey"
    printf '%s' "$SECRET" | put_env "$F" "$VAR"
    echo "Gespeichert in: $F  ($VAR; nur für dich lesbar)"
    ;;
  env)
    F="${2:?Datei fehlt}"; VAR="${3:?Variable fehlt}"
    ask_secret "$VAR"
    printf '%s' "$SECRET" | put_env "$F" "$VAR"
    echo "Gespeichert in: $F  ($VAR; nur für dich lesbar)"
    ;;
  *)
    sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
unset SECRET
