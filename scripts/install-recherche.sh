#!/usr/bin/env bash
# Installiert die sechs Claude-Code-Erweiterungen der Rubrik "Recherche",
# eine nach der anderen, und prüft nach jeder, ob sie läuft.
#
#   ./scripts/install-recherche.sh          # alle sechs nacheinander
#   ./scripts/install-recherche.sh 3        # nur Nummer 3 (Harvey)
#   ./scripts/install-recherche.sh 4 5 6    # nur diese
#
# Läuft auf macOS und Linux (unter Windows: in WSL).
# API-Schlüssel werden hier NICHT abgefragt -- dafür gibt es scripts/set-key.sh.

set -u

BASE="${RECHERCHE_DIR:-$HOME/claude-erweiterungen}"
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$BASE"

B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; N=$'\033[0m'
say()  { printf '%s\n' "$*"; }
head1(){ printf '\n%s== %s ==%s\n' "$B" "$*" "$N"; }
ok()   { printf '%s✓ %s%s\n' "$G" "$*" "$N"; }
warn() { printf '%s! %s%s\n' "$Y" "$*" "$N"; }
bad()  { printf '%s✗ %s%s\n' "$R" "$*" "$N"; }
have() { command -v "$1" >/dev/null 2>&1; }
yes_no() { local a; read -r -p "$1 [j/N] " a; [[ "$a" =~ ^[jJyY] ]]; }

RESULT=()   # normales Array statt "declare -A": läuft auch mit dem alten bash 3.2 von macOS

# ---------------------------------------------------------------------------
# Voraussetzungen: erklären, dann (nach Rückfrage) installieren
# ---------------------------------------------------------------------------
need_claude() {
  if have claude; then return 0; fi
  bad "Claude Code (der Befehl 'claude') fehlt."
  say "  Ohne Claude Code lässt sich keine dieser Erweiterungen nutzen."
  say "  Anleitung: https://code.claude.com/docs/en/setup"
  return 1
}

need_git() {
  have git && return 0
  bad "git fehlt. git lädt Programme aus GitHub herunter."
  say "  macOS: xcode-select --install    Linux: sudo apt install git"
  return 1
}

need_uv() {
  have uv && return 0
  warn "uv fehlt."
  say "  uv ist ein kleines Werkzeug, das Python-Programme mit allem, was sie"
  say "  brauchen, in einen eigenen Ordner installiert. Es bringt bei Bedarf"
  say "  sogar die passende Python-Version selbst mit. Kostenlos."
  if yes_no "  uv jetzt mit dem offiziellen Installer installieren?"; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi
  have uv
}

need_node() {
  if have node; then
    local major; major=$(node -p 'process.versions.node.split(".")[0]')
    [ "$major" -ge 18 ] && return 0
    warn "Node.js ist zu alt (Version $major, gebraucht: 18 oder neuer)."
  else
    warn "Node.js fehlt."
  fi
  say "  Node.js führt JavaScript-Programme aus, hier die Weboberfläche."
  say "  macOS: brew install node     Linux: https://nodejs.org (LTS-Version)"
  return 1
}

need_bun() {
  have bun && return 0
  [ -x "$HOME/.bun/bin/bun" ] && export PATH="$HOME/.bun/bin:$PATH" && return 0
  warn "Bun fehlt."
  say "  Bun ist wie Node.js ein Programm, das JavaScript ausführt, nur"
  say "  schneller. AI Job Search nutzt es für die Suche auf Jobportalen. Kostenlos."
  if yes_no "  Bun jetzt mit dem offiziellen Installer installieren?"; then
    curl -fsSL https://bun.sh/install | bash
    export PATH="$HOME/.bun/bin:$PATH"
  fi
  have bun
}

check_latex() {
  if have lualatex && have xelatex; then return 0; fi
  warn "LaTeX (lualatex/xelatex) fehlt."
  say "  LaTeX ist ein Satzprogramm. AI Job Search baut damit Lebenslauf und"
  say "  Anschreiben als schön gesetzte PDF. Suchen und Bewerten von Stellen"
  say "  geht auch ohne. Kostenlos, aber groß (einige GB)."
  say "  macOS: brew install --cask mactex-no-gui"
  say "  Linux: sudo apt install texlive-luatex texlive-xetex texlive-fonts-extra texlive-latex-extra"
  return 1
}

clone_or_update() {  # $1 = URL, $2 = Zielordner
  if [ -d "$2/.git" ]; then
    git -C "$2" pull --ff-only -q || warn "Konnte $2 nicht aktualisieren, nutze vorhandene Version."
  else
    git clone -q "$1" "$2"
  fi
}

backup() {  # sichert eine Datei mit Zeitstempel, falls sie existiert
  [ -e "$1" ] || return 0
  local b; b="$1.vor-$2-$(date +%Y%m%d-%H%M%S)"
  cp -a "$1" "$b" && ok "Sicherung: $b"
}

# ---------------------------------------------------------------------------
# 1. ScrapeGraph AI -- MCP-Server (empfohlener Weg laut scrapegraph-mcp README)
# ---------------------------------------------------------------------------
install_1() {
  head1 "1/6 ScrapeGraph AI"
  say "ScrapeGraph AI liest Webseiten für Claude aus und zieht gezielt Daten heraus."
  warn "KOSTEN: Der Dienst ist kostenpflichtig (Credits). Es gibt ein kleines"
  warn "Gratis-Kontingent; bezahlte Pakete ab ca. 20 US-\$ im Monat."
  warn "Du brauchst einen API-Schlüssel von https://dashboard.scrapegraphai.com"
  yes_no "Trotzdem einrichten?" || { RESULT[1]="übersprungen (kostenpflichtig, abgelehnt)"; return; }
  need_claude && need_uv || { RESULT[1]="fehlgeschlagen: Voraussetzung fehlt"; return; }

  claude mcp remove -s user scrapegraph >/dev/null 2>&1
  # Der Schlüssel wird NICHT hier eingegeben; ein Platzhalter wird später
  # von scripts/set-key.sh scrapegraph unsichtbar ersetzt.
  if claude mcp add -s user scrapegraph -e SGAI_API_KEY=NOCH_NICHT_GESETZT \
       -- uvx --from git+https://github.com/ScrapeGraphAI/scrapegraph-mcp scrapegraph-mcp; then
    say "Prüfe die Verbindung (beim ersten Mal lädt uv den Server, ca. 1 Min.) ..."
    if claude mcp list 2>/dev/null | grep -E '^scrapegraph:.*Connected' ; then
      ok "ScrapeGraph AI ist in Claude Code eingetragen und startet."
      RESULT[1]="installiert -- Schlüssel noch setzen: ./scripts/set-key.sh scrapegraph"
    else
      bad "Server startet nicht. Details: claude mcp get scrapegraph"
      RESULT[1]="fehlgeschlagen: MCP-Server startet nicht"
    fi
  else
    RESULT[1]="fehlgeschlagen: 'claude mcp add' ging nicht"
  fi
}

# ---------------------------------------------------------------------------
# 2. MiroFish -- eigenständige Web-App (kein Claude-Code-Weg dokumentiert)
# ---------------------------------------------------------------------------
install_2() {
  head1 "2/6 MiroFish"
  say "MiroFish ist KEINE Claude-Code-Erweiterung, sondern ein eigenes Programm"
  say "mit Weboberfläche (http://localhost:3000). Es simuliert viele KI-Figuren,"
  say "um Entwicklungen vorherzusagen. Claude Code nutzt es nicht direkt."
  warn "KOSTEN: Braucht einen kostenpflichtigen LLM-API-Schlüssel (die Anleitung"
  warn "warnt vor hohem Verbrauch) und einen Zep-Schlüssel (Gratis-Kontingent)."
  warn "GRÖSSE: Unter Linux lädt es ca. 3 GB (PyTorch mit Grafikkarten-Bibliotheken)."
  yes_no "Trotzdem installieren?" || { RESULT[2]="übersprungen (abgelehnt)"; return; }
  need_git && need_node && need_uv || { RESULT[2]="fehlgeschlagen: Voraussetzung fehlt"; return; }

  local D="$BASE/MiroFish"
  clone_or_update https://github.com/666ghj/MiroFish "$D" || { RESULT[2]="fehlgeschlagen: Download"; return; }
  [ -f "$D/.env" ] || { cp "$D/.env.example" "$D/.env"; chmod 600 "$D/.env"; }
  if (cd "$D" && npm run setup:all); then
    if (cd "$D/backend" && uv run python -c "import flask, openai, zep_cloud" 2>/dev/null); then
      ok "MiroFish ist installiert in $D"
      RESULT[2]="installiert (eigenes Programm) -- Schlüssel: ./scripts/set-key.sh mirofish"
    else
      RESULT[2]="fehlgeschlagen: Python-Teil unvollständig"
    fi
  else
    RESULT[2]="fehlgeschlagen: 'npm run setup:all' brach ab"
  fi
}

# ---------------------------------------------------------------------------
# 3. Harvey -- Vertriebs-Agent, nutzt dein Claude-Abo über Claude Code
# ---------------------------------------------------------------------------
install_3() {
  head1 "3/6 Harvey"
  say "Harvey sucht Firmen, schreibt Kaltakquise-E-Mails, verschickt sie und"
  say "beantwortet Antworten. Es nutzt dein Claude-Pro/Max-Abo über Claude Code."
  warn "KOSTEN: Claude Pro/Max (hast du vermutlich), ein eigenes Postfach auf einer"
  warn "Zweit-Domain (ca. 7 \$/Monat Google Workspace) und laut Anleitung ein"
  warn "kostenpflichtiger Aufwärmdienst für das Postfach (z. B. TrulyInbox)."
  warn "RECHT: Laut Harveys eigener Anleitung verlangt Deutschland schon für"
  warn "Geschäfts-E-Mails eine vorherige Einwilligung. Kein Versand ohne Prüfung!"
  yes_no "Trotzdem installieren?" || { RESULT[3]="übersprungen (abgelehnt)"; return; }
  need_claude && need_git && need_uv || { RESULT[3]="fehlgeschlagen: Voraussetzung fehlt"; return; }

  local D="$BASE/harvey"
  clone_or_update https://github.com/ethanplusai/harvey.git "$D" || { RESULT[3]="fehlgeschlagen: Download"; return; }
  [ -f "$D/.env" ] || { cp "$D/.env.example" "$D/.env"; chmod 600 "$D/.env"; }
  if (cd "$D" && uv venv -q --allow-existing -p 3.13 .venv && uv pip install -q -p .venv/bin/python -e .); then
    if (cd "$D" && .venv/bin/harvey status >/dev/null 2>&1); then
      ok "Harvey ist installiert in $D"
      RESULT[3]="installiert -- Einrichtung in Claude Code: cd $D && claude"
    else
      RESULT[3]="fehlgeschlagen: 'harvey status' läuft nicht"
    fi
  else
    RESULT[3]="fehlgeschlagen: Python-Installation"
  fi
}

# ---------------------------------------------------------------------------
# 4. AI Job Search -- Claude-Code-Projekt mit /setup, /apply, /rank ...
# ---------------------------------------------------------------------------
install_4() {
  head1 "4/6 AI Job Search"
  say "AI Job Search sucht passende Stellen und schreibt mit Claude Code"
  say "Lebenslauf und Anschreiben. Kein zusätzlicher Dienst nötig."
  need_claude && need_git && need_bun || { RESULT[4]="fehlgeschlagen: Voraussetzung fehlt"; return; }
  have python3 || { bad "python3 fehlt (gebraucht: 3.10+)"; RESULT[4]="fehlgeschlagen: python3 fehlt"; return; }
  check_latex || true

  local D="$BASE/ai-job-search"
  # Die Anleitung rät: für die eigene Jobsuche KEIN öffentlicher Fork,
  # weil /setup persönliche Daten in die Dateien schreibt. Deshalb nur klonen.
  clone_or_update https://github.com/ai-job-search-dev/ai-job-search "$D" || { RESULT[4]="fehlgeschlagen: Download"; return; }
  if (cd "$D" && python3 tools/install_portal_clis.py); then
    # "--help" endet mit Code 1, daher auf die Ausgabe prüfen
    if (cd "$D" && bun run .agents/skills/freehire-search/cli/src/cli.ts --help 2>&1 | grep -q USAGE); then
      ok "AI Job Search ist installiert in $D"
      if have lualatex && have xelatex; then
        RESULT[4]="installiert -- starten: cd $D && claude"
      else
        RESULT[4]="installiert, aber ohne LaTeX (keine PDF-Ausgabe) -- starten: cd $D && claude"
      fi
    else
      RESULT[4]="fehlgeschlagen: Jobportal-Werkzeug startet nicht"
    fi
  else
    RESULT[4]="fehlgeschlagen: install_portal_clis.py"
  fi
}

# ---------------------------------------------------------------------------
# 5. Chief of Staff -- Vorlagen + Befehle in ~/.claude
# ---------------------------------------------------------------------------
install_5() {
  head1 "5/6 Chief of Staff"
  say "Chief of Staff macht Claude Code zu deinem persönlichen Assistenten:"
  say "Morgen-Briefing, Posteingang sortieren, Aufgaben, Kontakte."
  say "Kostenlos; braucht Gmail und Google Kalender als Verbindung (siehe unten)."
  need_claude && need_git || { RESULT[5]="fehlgeschlagen: Voraussetzung fehlt"; return; }

  local D="$BASE/claude-chief-of-staff"
  clone_or_update https://github.com/mimurchison/claude-chief-of-staff.git "$D" || { RESULT[5]="fehlgeschlagen: Download"; return; }

  # Das Installationsprogramm ERSETZT ~/.claude/CLAUDE.md ohne Rückfrage.
  mkdir -p "$CLAUDE_DIR"
  backup "$CLAUDE_DIR/CLAUDE.md" chief-of-staff

  # Das Programm hat keine Optionen gegen Rückfragen; wir geben die Antworten
  # vorab per Umgebungsvariable oder einmal gesammelt hier ein.
  local q v
  local -a keys=(COS_NAME COS_FIRST COS_ROLE COS_COMPANY COS_WORK_EMAIL COS_PRIVATE_EMAIL COS_URL COS_HOME_BY COS_EARLIEST COS_CURRENCY COS_TZ)
  local -a qs=("Vollständiger Name" "Vorname (für E-Mail-Grüße)" "Rolle/Titel" "Firma" "Geschäftliche E-Mail" "Private E-Mail" "Firmen-Website (z. B. beispiel.de)" "Zu Hause bis (z. B. 18:00, leer = egal)" "Frühester Termin (z. B. 9:00, leer = egal)" "Währung" "Zeitzone")
  local -a defs=("" "" "" "" "" "" "" "" "" "EUR" "Europe/Berlin")
  local -a answers=()
  for i in "${!keys[@]}"; do
    v="${!keys[$i]:-}"
    if [ -z "$v" ]; then
      q="${qs[$i]}"; [ -n "${defs[$i]}" ] && q="$q [${defs[$i]}]"
      read -r -p "  $q: " v
      v="${v:-${defs[$i]}}"
    fi
    # Das Installationsprogramm nutzt sed; diese Zeichen würden es stören.
    v="${v//\//-}"; v="${v//&/und}"; v="${v//|/-}"
    answers+=("$v")
  done
  if printf '%s\n' "${answers[@]}" | bash "$D/install.sh" >/dev/null; then
    if [ -f "$CLAUDE_DIR/commands/gm.md" ] && grep -q "Chief of Staff" "$CLAUDE_DIR/CLAUDE.md"; then
      ok "Chief of Staff ist in $CLAUDE_DIR installiert (/gm, /triage, /my-tasks, /enrich)"
      RESULT[5]="installiert -- Gmail + Kalender noch verbinden (siehe Anleitung)"
    else
      RESULT[5]="fehlgeschlagen: Dateien fehlen nach der Installation"
    fi
  else
    RESULT[5]="fehlgeschlagen: install.sh brach ab"
  fi
}

# ---------------------------------------------------------------------------
# 6. Agency Agents -- Agenten nach ~/.claude/agents
# ---------------------------------------------------------------------------
install_6() {
  head1 "6/6 Agency Agents"
  say "Agency Agents bringt rund 280 Fach-Agenten (z. B. 'Research Synthesist',"
  say "'Trend Researcher') in Claude Code. Kostenlos."
  need_claude && need_git || { RESULT[6]="fehlgeschlagen: Voraussetzung fehlt"; return; }

  local D="$BASE/agency-agents"
  clone_or_update https://github.com/msitarzewski/agency-agents "$D" || { RESULT[6]="fehlgeschlagen: Download"; return; }
  # Nur einzelne Bereiche? z. B.  AGENCY_ARGS="--division research,product"
  if (cd "$D" && ./scripts/install.sh --tool claude-code --no-interactive ${AGENCY_ARGS:-}); then
    local n; n=$(ls "$CLAUDE_DIR/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
    if [ "$n" -gt 0 ]; then
      ok "$n Agenten liegen in $CLAUDE_DIR/agents"
      RESULT[6]="installiert ($n Agenten)"
    else
      RESULT[6]="fehlgeschlagen: keine Agenten in $CLAUDE_DIR/agents"
    fi
  else
    RESULT[6]="fehlgeschlagen: install.sh brach ab"
  fi
}

# ---------------------------------------------------------------------------
NAMES=([1]="ScrapeGraph AI" [2]="MiroFish" [3]="Harvey" [4]="AI Job Search" [5]="Chief of Staff" [6]="Agency Agents")
STEPS=("$@"); [ ${#STEPS[@]} -eq 0 ] && STEPS=(1 2 3 4 5 6)

say "${B}Recherche-Erweiterungen für Claude Code${N}  (Ordner: $BASE)"
for s in "${STEPS[@]}"; do
  case "$s" in [1-6]) "install_$s" ;; *) bad "Unbekannte Nummer: $s";; esac
done

head1 "Übersicht"
for s in "${STEPS[@]}"; do
  [ -n "${NAMES[$s]:-}" ] && printf '  %d. %-16s %s\n' "$s" "${NAMES[$s]}" "${RESULT[$s]:-nicht ausgeführt}"
done
say ""
say "Bitte Claude Code jetzt neu starten (alle offenen 'claude'-Fenster schließen"
say "und neu öffnen), damit neue MCP-Server, Befehle und Agenten geladen werden."
