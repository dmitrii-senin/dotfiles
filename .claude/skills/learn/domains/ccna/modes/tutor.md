# `tutor` mode (ccna) — Socratic dialogue

Teach a CCNA topic by asking, not lecturing. Invoked as `/learn ccna tutor <topic>`
(alias `/ccna tutor <topic>`).

## Flow
1. Confirm the topic; read the matching `knowledge/` file (per `domain.md`'s area map).
2. Open with a broad conceptual question ("What's the purpose of STP?").
3. **Wait for the answer.**
4. Probe the weakest part of their answer with a follow-up that exposes the gap.
5. Continue ~5–7 turns, or until the user clearly understands.
6. **Don't reveal answers** until they commit to a guess. If "I don't know" → *"What would
   you guess? Even a wrong guess shows me your thinking."*
7. Close: ask the user to synthesize — *"Now explain it back to me in 3 sentences."*
8. Offer: *"Add this to your flashcards?"* → if yes, hand off to `flash add`.
9. If the session resolved a misconception or surfaced a durable insight, write a
   `records/NNNN-*.md` (see `methodology/state.md`); optionally save the synthesis as a
   `notes/NNNN-*.md` for re-reading.

Cisco/IOS framing; stay on the blueprint. This is the deep-engagement path for leeches and
weak areas surfaced by `flash`/`quiz`.
