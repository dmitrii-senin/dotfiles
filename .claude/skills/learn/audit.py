#!/usr/bin/env python3
"""learn engine flashcard auditor — `/learn <domain> flash audit`.

Surfaces near-duplicate cards in a domain's active deck by Jaccard similarity
on tokenized fronts. Read-only: prints pairs above threshold, never mutates.

Use to plan cleanup passes (merge near-duplicates, remove redundant cards).
Pair with the rule from `domains/ccna/records/0002-flashcards-vs-practice-modes.md`:
flashcards hold knowledge; practice modes hold skill.

Run:
  python3 .claude/skills/learn/audit.py <domain> [--threshold 0.5] [--chapter X] [--area X]

Exit code 0 always (advisory tool).
"""
import argparse, json, re, sys
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parent

# common English + question-word stopwords — drop so two "What is …?" cards
# don't appear similar just because they share the question framing.
STOPWORDS = {
    "a",
    "an",
    "the",
    "of",
    "in",
    "on",
    "at",
    "to",
    "for",
    "from",
    "by",
    "with",
    "and",
    "or",
    "but",
    "if",
    "then",
    "as",
    "is",
    "are",
    "was",
    "were",
    "be",
    "been",
    "being",
    "do",
    "does",
    "did",
    "has",
    "have",
    "had",
    "can",
    "could",
    "may",
    "might",
    "will",
    "would",
    "should",
    "this",
    "that",
    "these",
    "those",
    "it",
    "its",
    "you",
    "your",
    "we",
    "our",
    "they",
    "their",
    # question framing words
    "what",
    "how",
    "why",
    "when",
    "where",
    "which",
    "who",
    "whom",
    # very generic glue
    "vs",
    "versus",
    "given",
    "between",
    "into",
    "within",
    "about",
    "out",
    "use",
    "used",
    "uses",
    "using",
}

TOKEN_RE = re.compile(r"[a-z0-9]+")


def tokenize(text: str) -> set[str]:
    """Lowercase, split on non-alphanumeric, drop stopwords + 1-char tokens."""
    return {
        t for t in TOKEN_RE.findall(text.lower()) if t not in STOPWORDS and len(t) > 1
    }


def jaccard(a: set, b: set) -> float:
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


def main() -> int:
    p = argparse.ArgumentParser(
        description="Audit a domain's deck for near-duplicate fronts."
    )
    p.add_argument("domain", help="domain name (must exist under domains/)")
    p.add_argument(
        "--threshold",
        type=float,
        default=0.5,
        help="Jaccard threshold (0.0-1.0, default 0.5)",
    )
    p.add_argument("--chapter", help="filter to one chapter (e.g. vol1-ch11)")
    p.add_argument("--area", help="filter to one area")
    p.add_argument("--max-pairs", type=int, default=50, help="cap output (default 50)")
    args = p.parse_args()

    deck_path = ROOT / "domains" / args.domain / "data" / "flashcards.json"
    if not deck_path.exists():
        print(f"ERROR: deck not found: {deck_path}", file=sys.stderr)
        return 1

    try:
        deck = json.loads(deck_path.read_text())["deck"]
    except (json.JSONDecodeError, KeyError) as e:
        print(f"ERROR: failed to load deck: {e}", file=sys.stderr)
        return 1

    # filter
    cards = deck
    if args.chapter:
        cards = [c for c in cards if c.get("chapter") == args.chapter]
    if args.area:
        cards = [c for c in cards if c.get("area") == args.area]

    if len(cards) < 2:
        print(f"Only {len(cards)} card(s) match filter — nothing to compare.")
        return 0

    # precompute tokens
    tokenized = [(c, tokenize(c.get("front", ""))) for c in cards]

    # all pairs (O(N²) — fine for decks up to a few thousand)
    pairs = []
    for (c1, t1), (c2, t2) in combinations(tokenized, 2):
        s = jaccard(t1, t2)
        if s >= args.threshold:
            pairs.append((s, c1, c2))

    pairs.sort(key=lambda x: -x[0])

    scope = f"{args.domain}"
    if args.chapter:
        scope += f" · chapter={args.chapter}"
    if args.area:
        scope += f" · area={args.area}"

    print(
        f"Flash audit — {scope} · {len(cards)} cards · threshold {args.threshold:.2f}"
    )
    print()

    if not pairs:
        print("No candidate pairs found. Deck looks clean.")
        return 0

    shown = pairs[: args.max_pairs]
    print(
        f"{len(pairs)} candidate pair(s){' — showing top ' + str(args.max_pairs) if len(pairs) > args.max_pairs else ''}:"
    )
    print()

    for sim, c1, c2 in shown:
        print(f"[{sim:.2f}]")
        print(f"  {c1['id']}  {c1.get('front', '')}")
        print(f"  {c2['id']}  {c2.get('front', '')}")
        # if both share chapter or topic, hint at the likely merge target (earliest id)
        keep = c1["id"] if c1["id"] < c2["id"] else c2["id"]
        drop = c2["id"] if keep == c1["id"] else c1["id"]
        print(f"  → consider: merge into {keep}, remove {drop}")
        print()

    print(f"Run `/learn {args.domain} flash audit --threshold 0.4` for a wider net,")
    print(f"or `--chapter <ch>` / `--area <a>` to scope. No state changed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
