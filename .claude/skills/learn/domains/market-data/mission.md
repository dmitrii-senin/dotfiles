# Mission: market-data

## Why
Become the **service owner of the CME feed handler and the CME market-data domain** at the firm.
I'm coming from Big Tech (Meta) with 12 years of low-level C++/Rust and serialization depth (custom
Thrift ser/deser), but **no prop-trading / hedge-fund domain experience** and no production exposure to
the I/O+kernel layer that decides market-data latency (multicast, kernel-bypass, timestamping, NIC/CPU
tuning) or to CME operational reliability. This domain closes that gap so I can own and improve the
infrastructure with authority, not just read the code.

## What success looks like
- I understand the **end-to-end CME market-data workflow** — wire → SBE decode → book build → publish —
  and can reason about each stage's reliability and performance tradeoffs from first principles.
- I can drive **reliability and performance** improvements (gap/snapshot recovery, A/B arbitration,
  receive strategy, latency budget) and defend the decisions with measurement.
- The I/O/kernel layer I've never shipped (multicast, `recvmmsg`/`io_uring`/busy-poll, NIC tuning, CPU
  isolation, HW timestamping) becomes working knowledge, not theory.
- I carry the **service-owner mindset**: what to monitor, what "reliable market data" means, the
  trading-day lifecycle, how recovery works under load.

## Deadline / cadence
**3 weeks before joining**, then continuous. This is a continuous-mastery domain (like `perf`), not
exam-gated. The 3-week prototyping roadmap (`attic/trading-prep.md`) is captured as the **challenge bank**
(8 build projects), to be worked in order but without hard dates.

## Constraints / style
Strong fundamentals — skip generic C++/CS basics; go deep on the MD-specific stack. Anchor to the real
hot-path budget (**1–100µs**) and always pair a claim with the measurement that confirms it
(`perf` top-down, HdrHistogram, `perf c2c`). **Public sources only** — never encode firm-internal
systems, code, or strategy. Cross-reference the `perf` domain for the deepest CPU/cache/concurrency theory.
