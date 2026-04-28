# Drill State

Persistent state for `/neovim-mastery drill` and `warmup` modes. The coach reads this file before picking the next batch and updates it on every `done <id>` / `stuck <id> <details>` confirmation.

## Schema

```
last_practiced: YYYY-MM-DD
total_attempts: <int>
total_solved: <int>

## Drills
| id      | attempts | solved | stuck | last_seen   | box | weak_keys      | notes                  |
| ------- | -------- | ------ | ----- | ----------- | --- | -------------- | ---------------------- |

## Weak keys
- `<key>`: <stuck count>
```

- **box** — Leitner box. `1` = unseen / wrong recently (review every session), `2` = solved once (every 3 days), `3` = solved twice in a row (weekly), `4` = mastered (monthly). On `stuck <id>` reset to `1`. On `done <id>` increment by 1, capped at 4.
- **weak_keys** — comma-separated list of key tags from the drill that the user struggled with. Pulled from the drill's `tags`. Aggregated under the `## Weak keys` section.
- **notes** — coach's free-form notes (e.g. "user kept doing `2dd` instead of `d2d`").

## Selection rules

When the user runs `drill [domain]`:

1. Filter drills by `domain` if supplied (e.g. `drill word-motions` → `wm-*`).
2. Compute eligibility per drill:
   - `box=1` → eligible if `last_seen < today` (any time).
   - `box=2` → eligible if `last_seen < today − 3 days`.
   - `box=3` → eligible if `last_seen < today − 7 days`.
   - `box=4` → eligible if `last_seen < today − 30 days`.
3. Sort eligible drills by: (a) box ascending, (b) drills tagged with the user's weak keys (from `## Weak keys`), (c) `attempts` ascending.
4. Pick the first 5. Run them in order.

When the user runs `warmup`:

1. Filter to `level:1` drills only.
2. Same eligibility computation.
3. Pick 5 random eligible level-1 drills. Cap session at 5 minutes.

## Update rules

After each `done <id>`:
- `attempts += 1`, `solved += 1`, `box = min(box+1, 4)`, `last_seen = today`.
- Increment `total_attempts` and `total_solved`.

After each `stuck <id> [details]`:
- `attempts += 1`, `stuck += 1`, `box = 1`, `last_seen = today`.
- Add the drill's tag-keys to `weak_keys` for that drill, deduplicated.
- Increment the user's `## Weak keys` counters by 1 per tag.
- If `details` is supplied, append to `notes` (cap at 80 chars; truncate if needed).

After each `skip <id>`:
- No counters change. Mark as "skipped today" in-memory only (do not write).

## Initial state

```
last_practiced: 2026-04-27
total_attempts: 10
total_solved: 6

## Drills
| id    | attempts | solved | stuck | last_seen   | box | weak_keys | notes |
| ----- | -------- | ------ | ----- | ----------- | --- | --------- | ----- |
| hd-01 | 0        | 0      | 0     | -           | 1   |           |       |
| hd-02 | 0        | 0      | 0     | -           | 1   |           |       |
| hd-03 | 0        | 0      | 0     | -           | 1   |           |       |
| hd-04 | 0        | 0      | 0     | -           | 1   |           |       |
| hd-05 | 0        | 0      | 0     | -           | 1   |           |       |
| hd-06 | 0        | 0      | 0     | -           | 1   |           |       |
| hd-07 | 0        | 0      | 0     | -           | 1   |           |       |
| wm-01 | 0        | 0      | 0     | -           | 1   |           |       |
| wm-02 | 0        | 0      | 0     | -           | 1   |           |       |
| wm-03 | 0        | 0      | 0     | -           | 1   |           |       |
| wm-04 | 1        | 0      | 1     | 2026-04-26  | 1   | f, t      |       |
| wm-05 | 0        | 0      | 0     | -           | 1   |           |       |
| wm-06 | 0        | 0      | 0     | -           | 1   |           |       |
| wm-07 | 0        | 0      | 0     | -           | 1   |           |       |
| wm-08 | 0        | 0      | 0     | -           | 1   |           |       |
| wm-09 | 0        | 0      | 0     | -           | 1   |           |       |
| to-01 | 0        | 0      | 0     | -           | 1   |           |       |
| to-02 | 1        | 1      | 0     | 2026-04-26  | 2   |           |       |
| to-03 | 0        | 0      | 0     | -           | 1   |           |       |
| to-04 | 0        | 0      | 0     | -           | 1   |           |       |
| to-05 | 0        | 0      | 0     | -           | 1   |           |       |
| to-06 | 0        | 0      | 0     | -           | 1   |           |       |
| to-07 | 0        | 0      | 0     | -           | 1   |           |       |
| to-08 | 0        | 0      | 0     | -           | 1   |           |       |
| to-09 | 0        | 0      | 0     | -           | 1   |           |       |
| to-10 | 0        | 0      | 0     | -           | 1   |           |       |
| op-01 | 0        | 0      | 0     | -           | 1   |           |       |
| op-02 | 1        | 1      | 0     | 2026-04-26  | 2   |           |       |
| op-03 | 0        | 0      | 0     | -           | 1   |           |       |
| op-04 | 0        | 0      | 0     | -           | 1   |           |       |
| op-05 | 0        | 0      | 0     | -           | 1   |           |       |
| op-06 | 0        | 0      | 0     | -           | 1   |           |       |
| op-07 | 0        | 0      | 0     | -           | 1   |           |       |
| op-08 | 0        | 0      | 0     | -           | 1   |           |       |
| op-09 | 0        | 0      | 0     | -           | 1   |           |       |
| ss-01 | 0        | 0      | 0     | -           | 1   |           |       |
| ss-02 | 0        | 0      | 0     | -           | 1   |           |       |
| ss-03 | 0        | 0      | 0     | -           | 1   |           |       |
| ss-04 | 0        | 0      | 0     | -           | 1   |           |       |
| ss-05 | 0        | 0      | 0     | -           | 1   |           |       |
| ss-06 | 0        | 0      | 0     | -           | 1   |           |       |
| ss-07 | 0        | 0      | 0     | -           | 1   |           |       |
| ss-08 | 0        | 0      | 0     | -           | 1   |           |       |
| ss-09 | 0        | 0      | 0     | -           | 1   |           |       |
| mj-01 | 0        | 0      | 0     | -           | 1   |           |       |
| mj-02 | 0        | 0      | 0     | -           | 1   |           |       |
| mj-03 | 0        | 0      | 0     | -           | 1   |           |       |
| mj-04 | 1        | 0      | 1     | 2026-04-26  | 1   | last-edit |       |
| mj-05 | 0        | 0      | 0     | -           | 1   |           |       |
| mj-06 | 0        | 0      | 0     | -           | 1   |           |       |
| rg-01 | 0        | 0      | 0     | -           | 1   |           |       |
| rg-02 | 0        | 0      | 0     | -           | 1   |           |       |
| rg-03 | 0        | 0      | 0     | -           | 1   |           |       |
| rg-04 | 0        | 0      | 0     | -           | 1   |           |       |
| rg-05 | 0        | 0      | 0     | -           | 1   |           |       |
| rg-06 | 0        | 0      | 0     | -           | 1   |           |       |
| rg-07 | 0        | 0      | 0     | -           | 1   |           |       |
| mc-01 | 0        | 0      | 0     | -           | 1   |           |       |
| mc-02 | 0        | 0      | 0     | -           | 1   |           |       |
| mc-03 | 0        | 0      | 0     | -           | 1   |           |       |
| mc-04 | 0        | 0      | 0     | -           | 1   |           |       |
| mc-05 | 0        | 0      | 0     | -           | 1   |           |       |
| ex-01 | 0        | 0      | 0     | -           | 1   |           |       |
| ex-02 | 0        | 0      | 0     | -           | 1   |           |       |
| ex-03 | 0        | 0      | 0     | -           | 1   |           |       |
| ex-04 | 0        | 0      | 0     | -           | 1   |           |       |
| ex-05 | 0        | 0      | 0     | -           | 1   |           |       |
| ex-06 | 0        | 0      | 0     | -           | 1   |           |       |
| fw-01 | 0        | 0      | 0     | -           | 1   |           |       |
| fw-02 | 0        | 0      | 0     | -           | 1   |           |       |
| fw-03 | 0        | 0      | 0     | -           | 1   |           |       |
| fw-04 | 0        | 0      | 0     | -           | 1   |           |       |
| fw-05 | 0        | 0      | 0     | -           | 1   |           |       |
| lsp-01 | 0       | 0      | 0     | -           | 1   |           |       |
| lsp-02 | 1       | 0      | 1     | 2026-04-26  | 1   | definition |       |
| lsp-03 | 0       | 0      | 0     | -           | 1   |           |       |
| lsp-04 | 0       | 0      | 0     | -           | 1   |           |       |
| lsp-05 | 0       | 0      | 0     | -           | 1   |           |       |
| lsp-06 | 0       | 0      | 0     | -           | 1   |           |       |
| lsp-07 | 0       | 0      | 0     | -           | 1   |           |       |
| lsp-08 | 0       | 0      | 0     | -           | 1   |           |       |
| ts-01 | 0        | 0      | 0     | -           | 1   |           |       |
| ts-02 | 0        | 0      | 0     | -           | 1   |           |       |
| ts-03 | 0        | 0      | 0     | -           | 1   |           |       |
| ts-04 | 0        | 0      | 0     | -           | 1   |           |       |
| ts-05 | 0        | 0      | 0     | -           | 1   |           |       |
| td-01 | 1        | 0      | 1     | 2026-04-27  | 1   | hl, count | count after find, not embedded |
| td-02 | 1        | 1      | 0     | 2026-04-27  | 2   |           |       |
| td-03 | 1        | 1      | 0     | 2026-04-27  | 2   |           |       |
| td-04 | 1        | 1      | 0     | 2026-04-27  | 2   |           |       |
| td-05 | 1        | 1      | 0     | 2026-04-27  | 2   |           |       |
| td-06 | 0        | 0      | 0     | -           | 1   |           |       |
| td-07 | 0        | 0      | 0     | -           | 1   |           |       |
| td-08 | 0        | 0      | 0     | -           | 1   |           |       |
| td-09 | 0        | 0      | 0     | -           | 1   |           |       |
| td-10 | 0        | 0      | 0     | -           | 1   |           |       |
| td-11 | 0        | 0      | 0     | -           | 1   |           |       |
| td-12 | 0        | 0      | 0     | -           | 1   |           |       |
| td-13 | 0        | 0      | 0     | -           | 1   |           |       |
| td-14 | 0        | 0      | 0     | -           | 1   |           |       |
| td-15 | 0        | 0      | 0     | -           | 1   |           |       |
| td-16 | 0        | 0      | 0     | -           | 1   |           |       |
| td-17 | 0        | 0      | 0     | -           | 1   |           |       |
| td-18 | 0        | 0      | 0     | -           | 1   |           |       |
| td-19 | 0        | 0      | 0     | -           | 1   |           |       |
| td-20 | 0        | 0      | 0     | -           | 1   |           |       |
| td-21 | 0        | 0      | 0     | -           | 1   |           |       |
| td-22 | 0        | 0      | 0     | -           | 1   |           |       |
| td-23 | 0        | 0      | 0     | -           | 1   |           |       |
| td-24 | 0        | 0      | 0     | -           | 1   |           |       |
| td-25 | 0        | 0      | 0     | -           | 1   |           |       |
| td-26 | 0        | 0      | 0     | -           | 1   |           |       |
| td-27 | 0        | 0      | 0     | -           | 1   |           |       |
| td-28 | 0        | 0      | 0     | -           | 1   |           |       |
| td-29 | 0        | 0      | 0     | -           | 1   |           |       |
| td-30 | 0        | 0      | 0     | -           | 1   |           |       |
| td-31 | 0        | 0      | 0     | -           | 1   |           |       |
| td-32 | 0        | 0      | 0     | -           | 1   |           |       |

## Weak keys
- `f`: 1
- `t`: 1
- `last-edit`: 1
- `definition`: 1
- `hl`: 1
- `count`: 1
```

## Coach notes

- The state file is **markdown** so a human can scan it. The coach must rewrite the whole `## Drills` table and `## Weak keys` list each update. The table is now ~100 rows after `td-*` were added — still scannable, but watch the trend.
- **Never** remove drills from the table, even if they vanish from `motion-corpus.md` or `text-drill-corpus.md` (orphaned IDs are tolerable and may be re-added).
- When adding new drills to either corpus, also add a row here with `box=1, attempts=0, solved=0, stuck=0, last_seen=-`.
- If `last_practiced` is more than 14 days old, when the user opens any session, propose a `warmup` first.
- IDs come from two corpora: `<prefix>-NN` (buffer-based, from `motion-corpus.md`: `hd`, `wm`, `to`, `op`, `ss`, `mj`, `rg`, `mc`, `ex`, `fw`, `lsp`, `ts`) and `td-NN` (in-prompt simulated, from `text-drill-corpus.md`). The selection rules apply uniformly. `warmup` mode draws **only** from `motion-corpus.md` level:1 (not `td-*`) in v1.
