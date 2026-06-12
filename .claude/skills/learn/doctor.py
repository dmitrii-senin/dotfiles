#!/usr/bin/env python3
"""learn engine validator — `/learn doctor`.

Walks the whole engine and reports problems that static review misses:
  - invalid JSON (decks, weak-areas, progress, flashcard banks)
  - missing required files per domain (domain.md / mission.md / resources.md)
  - the universal mode->file map points at files that don't exist
  - dead path references in domain.md / modes/*.md (knowledge/, cheatsheets/, modes/,
    methodology/, flashcards/, data/, records/, notes/)
  - flashcard bank cards missing id/front/back

Run:  python3 .claude/skills/learn/doctor.py
Exit code is non-zero if any ERROR is found (WARN does not fail).
"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent  # .../.claude/skills/learn
DOMAINS = ROOT / "domains"
METH = ROOT / "methodology"

errors, warns = [], []


def err(m):
    errors.append(m)


def warn(m):
    warns.append(m)


# universal mode -> methodology file (must match SKILL.md dispatch map)
UNIVERSAL = {
    "mm": "mm.md",
    "flash": "srs.md",
    "drill": "drill.md",
    "challenge": "challenge.md",
    "cheatsheet": "cheatsheet.md",
    "update": "update.md",
}
EXPECTED_METH = set(UNIVERSAL.values()) | {"pedagogy.md", "state.md"}

# path-ref prefixes we check for existence
REF_DIRS = (
    "knowledge/",
    "cheatsheets/",
    "modes/",
    "flashcards/",
    "data/",
    "records/",
    "notes/",
    "methodology/",
)
# tokens with these are templates/examples, not real paths -> skip
PLACEHOLDER = re.compile(r"[<>*{}]|NNNN|YYYY")
TOKEN = re.compile(r"`([^`]+)`")


def check_json(p):
    try:
        return json.loads(p.read_text())
    except Exception as e:
        err(f"{p.relative_to(ROOT)}: invalid JSON — {e}")
        return None


def check_refs(md_file, base):
    """base = dir that domain-relative refs resolve against; methodology/ resolves at ROOT."""
    text = md_file.read_text()
    for tok in TOKEN.findall(text):
        tok = tok.strip()
        if PLACEHOLDER.search(tok):
            continue
        if not tok.startswith(REF_DIRS):
            continue
        # strip trailing punctuation
        tok = tok.rstrip(").,;:")
        # skip non-file refs: bare directory mentions, and data/ (runtime state,
        # created on demand — not pre-existing content)
        if tok.endswith("/") or tok.startswith("data/"):
            continue
        target = (ROOT / tok) if tok.startswith("methodology/") else (base / tok)
        if not target.exists():
            warn(f"{md_file.relative_to(ROOT)}: ref to missing path `{tok}`")


# --- engine ---
if not (ROOT / "SKILL.md").is_file():
    err("SKILL.md missing")
for f in sorted(EXPECTED_METH):
    if not (METH / f).is_file():
        err(f"methodology/{f} missing (referenced by the mode map / engine)")
for f in METH.glob("*.md"):
    if f.name not in EXPECTED_METH:
        warn(f"methodology/{f.name} is not in the expected set")

# --- domains ---
domains = sorted(d for d in DOMAINS.iterdir() if d.is_dir()) if DOMAINS.is_dir() else []
if not domains:
    err("no domains/ found")

for d in domains:
    name = d.name
    for req in ("domain.md", "mission.md", "resources.md"):
        if not (d / req).is_file():
            err(f"{name}: missing {req}")
    # JSON: data + flashcard banks
    for jp in list((d / "data").glob("*.json")) + list(
        (d / "flashcards").glob("*.json")
    ):
        obj = check_json(jp)
        if obj is None:
            continue
        # bank card sanity (a bank is {cards:[...]} or a flat list of cards)
        if jp.parent.name == "flashcards":
            cards = obj.get("cards") if isinstance(obj, dict) else obj
            if isinstance(cards, list):
                for i, c in enumerate(cards):
                    if not isinstance(c, dict) or not all(
                        k in c for k in ("id", "front", "back")
                    ):
                        warn(
                            f"{name}/flashcards/{jp.name}: card #{i} missing id/front/back"
                        )
                        break
    # active deck shape
    deck = d / "data" / "flashcards.json"
    if deck.is_file():
        o = check_json(deck)
        if isinstance(o, dict) and "deck" not in o:
            warn(f"{name}/data/flashcards.json: no top-level 'deck' array")
    # mode files non-empty
    for m in (d / "modes").glob("*.md") if (d / "modes").is_dir() else []:
        if m.stat().st_size == 0:
            err(f"{name}/modes/{m.name} is empty")
    # dead refs in domain.md + modes/*.md
    if (d / "domain.md").is_file():
        check_refs(d / "domain.md", d)
    for m in (d / "modes").glob("*.md") if (d / "modes").is_dir() else []:
        check_refs(m, d)

# --- report ---
print(f"learn doctor — {len(domains)} domains: {', '.join(x.name for x in domains)}")
for w in warns:
    print(f"  WARN  {w}")
for e in errors:
    print(f"  ERROR {e}")
if not errors and not warns:
    print("  OK — no problems found")
print(f"\n{len(errors)} error(s), {len(warns)} warning(s)")
sys.exit(1 if errors else 0)
