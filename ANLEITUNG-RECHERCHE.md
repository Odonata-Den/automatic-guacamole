# Recherche-Erweiterungen für Claude Code

Diese Anleitung installiert sechs Erweiterungen auf **deinem eigenen Rechner** (macOS oder Linux; Windows nur über WSL). Grundlage sind die Installationsanleitungen der Projekte, Stand 4. November 2026.

## So geht's

```bash
git clone -b claude/confident-babbage-sf2orr https://github.com/odonata-den/automatic-guacamole.git
cd automatic-guacamole
./scripts/install-recherche.sh        # alle sechs nacheinander
./scripts/install-recherche.sh 4 6    # oder nur einzelne Nummern
```

Das Skript arbeitet die Erweiterungen der Reihe nach ab, prüft nach jeder, ob sie läuft, und gibt am Ende eine Übersicht aus. Fehlt eine Voraussetzung, erklärt es zuerst, was sie ist, und fragt, bevor es etwas installiert. Bei kostenpflichtigen Diensten fragt es ebenfalls nach. Die Programme landen in `~/claude-erweiterungen/`.

**API-Schlüssel und Passwörter** fragt das Installationsskript nie ab. Dafür gibt es `./scripts/set-key.sh`: Es fragt unsichtbar ab, und der Wert erscheint weder auf dem Bildschirm noch im Shell-Verlauf.

| Befehl | Speicherort |
|---|---|
| `./scripts/set-key.sh scrapegraph` | `~/.claude.json` → `mcpServers` → `scrapegraph` → `env` → `SGAI_API_KEY` |
| `./scripts/set-key.sh mirofish` | `~/claude-erweiterungen/MiroFish/.env` (`LLM_API_KEY`, `ZEP_API_KEY`) |
| `./scripts/set-key.sh harvey SMTP_PASSWORD` | `~/claude-erweiterungen/harvey/.env` (beliebige Variable, z. B. `GMAIL_CLIENT_SECRET`, `REOON_API_KEY`) |

Die `.env`-Dateien sind nur für dich lesbar (Rechte 600).

**Danach Claude Code neu starten**, also alle `claude`-Fenster schließen und neu öffnen.

## Die sechs Erweiterungen

| # | Erweiterung | Was sie ist | Kosten | Schlüssel |
|---|---|---|---|---|
| 1 | ScrapeGraph AI | MCP-Server: Claude liest Webseiten aus und zieht Daten heraus | **kostenpflichtig**: kleines Gratis-Kontingent, danach ab ca. 20 $/Monat | `SGAI_API_KEY` |
| 2 | MiroFish | **eigenes Programm** mit Weboberfläche (localhost:3000), **keine** Claude-Code-Erweiterung | **LLM-API kostenpflichtig**, hoher Verbrauch; Zep hat ein Gratis-Kontingent | `LLM_API_KEY`, `ZEP_API_KEY` |
| 3 | Harvey | autonomer Vertriebs-Agent über dein Claude-Abo | Claude Pro/Max; Postfach ca. 7 $/Monat; Aufwärmdienst kostenpflichtig | Postfach-Zugang |
| 4 | AI Job Search | Claude-Code-Projekt für Stellensuche und Bewerbungen | nur Claude-Abo | keiner |
| 5 | Chief of Staff | Befehle `/gm`, `/triage`, `/my-tasks`, `/enrich` in `~/.claude` | kostenlos | keiner (Gmail/Kalender per Anmeldung) |
| 6 | Agency Agents | ca. 280 Fach-Agenten in `~/.claude/agents` | kostenlos | keiner |

### Wichtige Hinweise

- **ScrapeGraph AI:** Die Anleitung nennt für Claude Code keinen eigenen Weg. Das Skript trägt den offiziellen MCP-Server direkt aus GitHub ein, weil die Version auf PyPI veraltet ist (1.0.1 statt 3.0.0).
- **MiroFish:** Die Anleitung kennt keinen Weg für Claude Code. Das Skript installiert MiroFish nur auf Nachfrage als eigenständiges Programm. Unter Linux lädt es ca. 3 GB (PyTorch). Starten: `cd ~/claude-erweiterungen/MiroFish && npm run dev`.
- **Harvey:** Harvey verschickt selbstständig Kaltakquise-E-Mails. Laut seiner eigenen Anleitung verlangt Deutschland schon für Geschäfts-E-Mails eine vorherige Einwilligung. Schick nichts los, bevor das rechtlich geklärt ist. Ein Versand passiert ohnehin erst, wenn du ein Postfach einrichtest und die Mails freigibst.
- **AI Job Search:** Für PDF-Lebensläufe brauchst du LaTeX. Die Anleitung rät von einem öffentlichen Fork ab, weil `/setup` persönliche Daten in die Dateien schreibt. Das Skript klont das Projekt deshalb nur lokal.
- **Chief of Staff:** Das Installationsprogramm **ersetzt `~/.claude/CLAUDE.md`**. Das Skript legt vorher eine Sicherung an: `~/.claude/CLAUDE.md.vor-chief-of-staff-<Datum>`. Der Befehl `claude mcp add gmail` aus der Projektanleitung ist veraltet und funktioniert nicht. Verbinde Gmail und Google Kalender stattdessen auf claude.ai unter *Einstellungen → Connectors*. Wenn du in Claude Code mit demselben Konto angemeldet bist, stehen sie dort ebenfalls zur Verfügung (prüfen mit `/mcp`).
- **Agency Agents:** Standardmäßig wird alles installiert. Nur einzelne Bereiche: `AGENCY_ARGS="--division research,product" ./scripts/install-recherche.sh 6`.
- **Chief of Staff ohne Rückfragen:** `COS_NAME="…" COS_FIRST="…" COS_ROLE="…" COS_COMPANY="…" COS_WORK_EMAIL="…" COS_PRIVATE_EMAIL="…" COS_URL="…" ./scripts/install-recherche.sh 5`

## Zum Ausprobieren

1. **ScrapeGraph AI** (in einem beliebigen Ordner `claude`): „Lies https://www.tagesschau.de aus und gib mir die fünf wichtigsten Schlagzeilen als Liste.“
2. **MiroFish** (im Browser auf http://localhost:3000): einen Nachrichtenartikel hochladen und fragen: „Wie wird die Öffentlichkeit in den nächsten zwei Wochen darauf reagieren?“
3. **Harvey** (`cd ~/claude-erweiterungen/harvey && claude`): „set up Harvey for me“
4. **AI Job Search** (`cd ~/claude-erweiterungen/ai-job-search && claude`): `/setup`
5. **Chief of Staff** (`claude`): `/gm`
6. **Agency Agents** (`claude`): „Nutze den Research Synthesist und fasse zusammen, was die Forschung über die Vier-Tage-Woche sagt.“
