# PMC events for branch misprediction analysis

## The event ladder

| Pass | Events | Question |
|------|--------|----------|
| **1. Triage** | `branches,branch-misses` | Is branch misprediction a problem at all? |
| **2. TMA** | `TopdownL1` / `toplev.py -l2` | Bad Speculation vs other categories? |
| **3. Decompose** | `br_misp_retired.{cond,ind_call,near_call,near_return}` | Which branch *type*? |
| **4. Cost** | `int_misc.recovery_cycles,baclears.any,machine_clears.count` | How many cycles lost? |
| **5. Locate** | `perf record -e br_misp_retired.all_branches:pp` → `perf annotate -M intel` | Which instruction? |

## Key events

- `BR_MISP_RETIRED.ALL_BRANCHES` — all retired mispredicted branches (= `branch-misses` alias)
- `br_misp_retired.cond` — conditional (je/jne/jg…); data-dependent branches, switch cases
- `br_misp_retired.ind_call` — indirect calls (virtual dispatch, function pointers)
- `br_misp_retired.near_return` — RET mispredictions (RSB overflow from deep call stacks)
- `br_misp_retired.near_call` — direct + indirect CALLs
- `BACLEARS.ANY` — frontend re-steers (BTB miss/correction); high = cold code or BTB thrashing
- `int_misc.recovery_cycles` — cycles in misprediction + machine-clear recovery (both!)
- `int_misc.clear_resteer_cycles` — subset: frontend re-steer cycles after a clear
- `machine_clears.count` — not branch misses; memory-ordering violations, FP assists, etc.

## Diagnostic insights

- **Cost vs rate**: `recovery_cycles / mispredicts` = actual cycles per mispredict. If >> 20, deep speculation is being squashed (many in-flight uops flushed per event).
- **High recovery, low branch-misses**: check `machine_clears.count` — machine clears also cost recovery cycles but don't show in branch-miss counters.
- **Low baclears + high branch-misses**: BTB knows the branch sites (hot code), but can't predict *which target* (indirect/pattern problem).
- **High baclears + low branch-misses**: cold code or BTB capacity issue; final prediction is fine but frontend wastes cycles re-steering.

## Fixes by branch type

- **ind_call high**: top-N if-else fast path, CRTP devirtualization, PGO, sort input by type
- **cond high**: branchless (cmov/arithmetic), profile-guided branch ordering, data sorting
- **near_return high**: flatten call depth below RSB capacity (16-32 entries)

Sources: Intel Optimization Manual Appendix B; Intel SDM Vol 3B Table 19-1; Denis Bakhvalov Ch. 6; pmu-tools event lists.
