#!/usr/bin/env python3
"""AI code review zmiany w Gerricie (Claude API).

Uruchamiany przez Jenkinsa na osobnej maszynie (agent "ai-review") dla każdego
nowego patchsetu. Wysyła diff do Claude, a wynik publikuje w Gerricie jako
komentarze przy liniach i głos Code-Review:
  -1  gdy jest choć jedna uwaga o wadze "error",
  +1  gdy uwag "error" nie ma,
   0  gdy AI review nie zadziałało (brak klucza, błąd API) - awaria narzędzia
      nie może blokować zmian.
Zatwierdzenie (+2) zawsze należy do człowieka.

Zmienne środowiskowe:
  GERRIT_URL, GERRIT_USER, GERRIT_PASSWORD      REST API Gerrita (konto ai-reviewer)
  GERRIT_CHANGE_NUMBER, GERRIT_PATCHSET_REVISION, GERRIT_CHANGE_SUBJECT  (Gerrit Trigger)
  ANTHROPIC_API_KEY        klucz Claude API; pusty = tryb dry-run
  AI_REVIEW_MODEL          model (domyślnie claude-opus-5-5)
  AI_REVIEW_EFFORT         low | medium | high (domyślnie medium)
  AI_REVIEW_DRY_RUN_FINDING  w dry-run: "" przykładowa uwaga info (głos 0),
                           "error" uwaga error (-1), "none" brak uwag (+1)
"""

from __future__ import annotations

import base64
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path

import anthropic

MODEL = os.environ.get("AI_REVIEW_MODEL", "claude-opus-5-5")
EFFORT = os.environ.get("AI_REVIEW_EFFORT", "medium")
MAX_DIFF_CHARS = int(os.environ.get("AI_REVIEW_MAX_DIFF_CHARS", "60000"))
PROMPT_FILE = Path(__file__).with_name("ai-review-prompt.md")
# Pliki generowane - nie recenzujemy ich
SKIP_FILES = re.compile(r"^i18n/.*\.ts$")

REVIEW_SCHEMA = {
    "type": "object",
    "properties": {
        "summary": {"type": "string"},
        "findings": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "file": {"type": "string"},
                    "line": {"type": "integer"},
                    "severity": {"type": "string", "enum": ["error", "warning", "info"]},
                    "message": {"type": "string"},
                },
                "required": ["file", "line", "severity", "message"],
                "additionalProperties": False,
            },
        },
    },
    "required": ["summary", "findings"],
    "additionalProperties": False,
}

SEVERITY_LABEL = {"error": "BŁĄD", "warning": "Ostrzeżenie", "info": "Sugestia"}


# --- diff z numerami linii --------------------------------------------------------

@dataclass
class FileDiff:
    path: str
    lines: list[str] = field(default_factory=list)      # diff z numerami linii
    commentable: set[int] = field(default_factory=set)  # linie nowej wersji w hunkach
    added: list[int] = field(default_factory=list)      # linie dodane


def read_diff() -> list[FileDiff]:
    """Diff ostatniego commita (patchsetu) z numerami linii nowej wersji plików."""
    raw = subprocess.run(
        ["git", "diff", "--unified=5", "--no-color", "--no-ext-diff", "HEAD~1", "HEAD"],
        check=True, capture_output=True, text=True,
    ).stdout
    files: list[FileDiff] = []
    current: FileDiff | None = None
    new_line = 0
    for line in raw.splitlines():
        if line.startswith("diff --git "):
            current = None
        elif line.startswith("+++ "):
            path = line[4:]
            if path == "/dev/null" or SKIP_FILES.match(path[2:]):
                current = None
            else:
                current = FileDiff(path=path[2:])
                files.append(current)
        elif current is None or line.startswith("--- "):
            continue
        elif line.startswith("@@"):
            m = re.match(r"@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@(.*)", line)
            new_line = int(m.group(1)) if m else 0
            current.lines.append(line)
        elif line.startswith("+"):
            current.lines.append(f"{new_line:5d} + {line[1:]}")
            current.commentable.add(new_line)
            current.added.append(new_line)
            new_line += 1
        elif line.startswith("-"):
            current.lines.append(f"      - {line[1:]}")
        elif line.startswith("\\"):
            continue  # "\ No newline at end of file"
        else:
            current.lines.append(f"{new_line:5d}   {line[1:]}")
            current.commentable.add(new_line)
            new_line += 1
    return [f for f in files if f.added]


def render_diff(files: list[FileDiff]) -> str:
    parts = [f"=== {f.path} ===\n" + "\n".join(f.lines) for f in files]
    text = "\n\n".join(parts)
    if len(text) > MAX_DIFF_CHARS:
        raise ValueError(f"diff ma {len(text)} znaków (limit {MAX_DIFF_CHARS})")
    return text


# --- Claude API ---------------------------------------------------------------------

def commit_message() -> str:
    return subprocess.run(["git", "log", "-1", "--format=%B"], check=True,
                          capture_output=True, text=True).stdout.strip()


def ask_claude(files: list[FileDiff]) -> tuple[dict, str]:
    client = anthropic.Anthropic()
    user = (
        f"Opis zmiany:\n{commit_message()}\n\n"
        f"Diff (numery linii nowej wersji plików):\n\n{render_diff(files)}"
    )
    response = client.beta.messages.create(
        model=MODEL,
        max_tokens=16000,
        system=PROMPT_FILE.read_text(encoding="utf-8"),
        messages=[{"role": "user", "content": user}],
        output_config={
            "effort": EFFORT,
            "format": {"type": "json_schema", "schema": REVIEW_SCHEMA},
        },
        # Przy odmowie modelu (klasyfikatory bezpieczeństwa) serwer sam ponawia
        # zapytanie na modelu zapasowym
        betas=["server-side-fallback-2026-07-01"],
        fallbacks="default",
    )
    if response.stop_reason == "refusal":
        category = response.stop_details.category if response.stop_details else None
        raise RuntimeError(f"model odmówił recenzji (kategoria: {category})")
    if response.stop_reason == "max_tokens":
        raise RuntimeError("odpowiedź ucięta (max_tokens)")
    text = next(b.text for b in response.content if b.type == "text")
    usage = response.usage
    usage_note = (f"{response.model}, tokeny: {usage.input_tokens} wejście / "
                  f"{usage.output_tokens} wyjście, request-id {response._request_id}")
    return json.loads(text), usage_note


def dry_run_review(files: list[FileDiff]) -> tuple[dict, str]:
    mode = os.environ.get("AI_REVIEW_DRY_RUN_FINDING", "")
    first = files[0]
    findings = []
    if mode in ("", "error"):
        severity = "error" if mode == "error" else "info"
        findings.append({
            "file": first.path, "line": first.added[0], "severity": severity,
            "message": "Przykładowa uwaga z trybu dry-run (brak klucza Claude API).",
        })
    return ({"summary": "Tryb dry-run: recenzja bez wywołania Claude API.", "findings": findings},
            "dry-run, bez wywołania API")


# --- Gerrit ---------------------------------------------------------------------------

def post_review(message: str, vote: int, comments: dict[str, list[dict]]) -> None:
    url = (f"{os.environ['GERRIT_URL'].rstrip('/')}/a/changes/"
           f"{os.environ['GERRIT_CHANGE_NUMBER']}/revisions/"
           f"{os.environ['GERRIT_PATCHSET_REVISION']}/review")
    body: dict = {"message": message, "comments": comments, "tag": "autogenerated:ai-review"}
    if vote:
        body["labels"] = {"Code-Review": vote}
    auth = base64.b64encode(
        f"{os.environ['GERRIT_USER']}:{os.environ['GERRIT_PASSWORD']}".encode()).decode()
    req = urllib.request.Request(
        url, data=json.dumps(body).encode(), method="POST",
        headers={"Content-Type": "application/json; charset=UTF-8",
                 "Authorization": f"Basic {auth}"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        print(f"Gerrit: recenzja opublikowana (HTTP {resp.status})")


def build_review(result: dict, files: list[FileDiff], note: str, dry_run: bool):
    by_path = {f.path: f for f in files}
    comments: dict[str, list[dict]] = {}
    unplaced: list[str] = []
    counts = {"error": 0, "warning": 0, "info": 0}

    for f in result.get("findings", []):
        sev = f["severity"]
        counts[sev] += 1
        text = f"[AI: {SEVERITY_LABEL[sev]}] {f['message']}"
        target = by_path.get(f["file"])
        if target and f["line"] in target.commentable:
            comments.setdefault(f["file"], []).append(
                {"line": f["line"], "message": text, "unresolved": sev == "error"})
        else:  # model wskazał linię spoza diffu - uwaga trafia do komentarza ogólnego
            unplaced.append(f"- {f['file']}:{f['line']}: {text}")

    if dry_run and not os.environ.get("AI_REVIEW_DRY_RUN_FINDING"):
        vote = 0
    else:
        vote = -1 if counts["error"] else 1

    lines = [
        f"AI code review: {counts['error']} błędów, {counts['warning']} ostrzeżeń, "
        f"{counts['info']} sugestii -> Code-Review {vote:+d}" if vote else
        f"AI code review: {counts['error']} błędów, {counts['warning']} ostrzeżeń, "
        f"{counts['info']} sugestii -> bez głosu (dry-run)",
        "",
        result.get("summary", ""),
    ]
    if unplaced:
        lines += ["", "Uwagi poza diffem:", *unplaced]
    lines += ["", f"({note}. Zatwierdzenie +2 należy do człowieka.)"]
    return "\n".join(lines), vote, comments


def main() -> int:
    files = read_diff()
    if not files:
        print("Brak zmian w plikach źródłowych - pomijam AI review.")
        return 0

    dry_run = not os.environ.get("ANTHROPIC_API_KEY")
    try:
        result, note = dry_run_review(files) if dry_run else ask_claude(files)
        message, vote, comments = build_review(result, files, note, dry_run)
    except (anthropic.APIError, RuntimeError, ValueError, json.JSONDecodeError, KeyError) as e:
        # Awaria narzędzia: informacja w Gerricie, bez głosu
        print(f"AI review niedostępne: {e}", file=sys.stderr)
        message, vote, comments = (
            f"AI code review niedostępne ({type(e).__name__}: {e}). Zmiana wymaga zwykłego review.",
            0, {})

    print(message)
    try:
        post_review(message, vote, comments)
    except urllib.error.HTTPError as e:
        print(f"Gerrit odrzucił recenzję: HTTP {e.code} {e.read().decode(errors='replace')}",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
