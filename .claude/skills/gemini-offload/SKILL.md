---
name: gemini-offload
description: Hand simple, low-risk text tasks to Google Gemini's free API instead of spending Claude usage - summarizing, translating, rephrasing, drafting short texts, extracting lists, or explaining a short snippet. Use when the user says "mit Gemini", "lagere aus", "offload", or when a task is clearly simple and self-contained. Do not use for tasks that need repository context, judgement, editing files, or confidential/personal data.
---

# Gemini offload

Run the bundled script; it calls Gemini's OpenAI-compatible endpoint
(`https://generativelanguage.googleapis.com/v1beta/openai/`) with the key from
`GEMINI_API_KEY` or `~/.config/gemini/api_key`.

```bash
python3 .claude/skills/gemini-offload/scripts/gemini.py "Fasse in 3 Stichpunkten zusammen:" < datei.txt
python3 .claude/skills/gemini-offload/scripts/gemini.py "Übersetze ins Englische: ..."
python3 .claude/skills/gemini-offload/scripts/gemini.py --check      # key test
```

- Default model `gemini-3.5-flash-lite` (cheapest quota); pass `--model gemini-3.8-flash` for harder text.
- Free tier: Google publishes no fixed limits; error 429 means the daily quota is used up - then do the task yourself.
- Review Gemini's answer before passing it on; say that the answer came from Gemini.
- Never send secrets, passwords or personal data to Gemini.
