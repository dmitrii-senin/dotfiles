# Ownership Topic Bank — prop-HFT domain + feed-handler service ownership
Updated: 2026-06-12

> Scope: the service-owner mindset for a CME feed handler — what "reliable market data" means,
> the trading-day lifecycle, what to monitor, how recovery works under load, and the bridge from
> Big-Tech SRE practice (SLI/SLO/error budget, golden signals) to the 1–100µs MD hot path.
> Public sources only (CME Client Systems Wiki MDP 3.0 docs, CME education, Google SRE book/workbook).
> Systems/measurement theory is cross-linked to `/perf` rather than re-derived; here it is applied to
> the feed pipeline and the trading day. Precise claims flagged `⚠ verify` are unconfirmed numerics.

## beginner

### What "reliable market data" actually means
For a feed handler, "reliable" is not "no packets dropped" — UDP multicast guarantees loss. It means: the
published book is *correct* (matches the exchange book), *complete* (no silently-missing levels/instruments),
*timely* (within the latency budget), and *recoverable* (a gap is detected and repaired without corrupting
downstream state). CME builds reliability in layers: redundant A/B feeds (recover from single-feed loss),
sequence numbers (detect what A/B both missed), snapshot/recovery feeds (rebuild after a real gap), and
Channel Reset (rebuild after exchange-side book corruption). The owner's job is to know which layer fires
for which failure and to monitor each one.
**Key concepts:** correctness vs completeness vs timeliness, layered reliability, A/B redundancy, gap detection, recovery, the loss-is-normal mindset
**Tip:** "Stale is worse than lost" is the market-data inversion of normal systems thinking — a slow consumer should skip to the latest book (overwrite), never block the producer. Backpressure that stalls the hot path is a correctness bug, not a throttle.
**Tool anchor:** count published-vs-exchange book divergences per instrument at end of session; any nonzero is a P1.
**Drill:** A downstream strategy reports a stale bid for one instrument while every other instrument is fine. Walk the four reliability properties — which one failed, and which CME mechanism (A/B arbitration, sequence gap, snapshot recovery, channel reset) should have caught it?
**Tags:** reliability, correctness, completeness, timeliness, recovery, ownership

### The CME trading-day lifecycle
CME Globex runs the week as one continuous session with daily breaks, not 24×7. For equities and rates,
trading is Sunday 17:00 CT through Friday 16:00 CT, with a daily maintenance break 16:00–17:00 CT
(Mon–Thu) used for settlement and system maintenance. The session — not the calendar day — sets the
trade date: orders entered Sunday evening are dated for Monday. Each instrument walks states: Pre-Open
(order book builds, indicative opening price disseminated) → the final ~30s "no-cancel"/lockdown
(new orders allowed, no modify/cancel) → Open (continuous matching) → optional Pause/Reserved →
Close (resting day orders auto-cancelled). The handler must track this because book semantics change per state.
**Key concepts:** Sunday 17:00 CT open, 16:00–17:00 CT daily break, trade-date = session not calendar, Pre-Open, no-cancel/lockdown, Open, Close
**Tip:** Times are Central Time; CT is UTC-6 in winter, UTC-5 under daylight saving — a hard-coded UTC offset will be wrong half the year and silently shift your "is the market open?" logic.
**Tool anchor:** drive an internal market-state machine off SecurityStatus (35=f); alert if it disagrees with the published Market Schedule file.
**Drill:** Your handler logs "first trade" at 17:00:00 CT but your book had non-zero depth at 16:55. Is that a bug? Explain Pre-Open vs Open and what message told you the transition happened.
**Tags:** trading-day, lifecycle, market-state, pre-open, trade-date, central-time

### Market and instrument states, and SecurityStatus (35=f)
CME disseminates state changes over market data via the Security Status message (FIX 35=f; SBE template
`SecurityStatus`). States apply at two scopes: a Group (e.g. a whole product group transitions together)
or a single Instrument. The trading status enum rides in tag 326-SecurityTradingStatus (e.g. value 17 =
"Ready to trade (start of session)") and the event in tag 1174-SecurityTradingEvent. The owner-critical rule: **the last Security Status message
sent takes precedence** — when a group goes Open, one group-level message can flip every instrument in it.
A handler that processes these out of order, or drops one, will publish a wrong state and downstream
strategies may trade (or refuse to trade) on it.
**Key concepts:** Security Status 35=f, SecurityStatus SBE template, group vs instrument scope, tag 326 trading status, tag 1174 trading event, last-message-wins
**Tip:** Never drop a SecurityStatus on the hot path "because it's not a book update" — missing one can leave you Open when the market is Paused. Pre-register it as a first-class message type, not a default-case skip.
**Tool anchor:** per-instrument counter of SecurityStatus transitions; reconcile against the Market Schedule file at end of day.
**Drill:** You see an instrument-level "Open" followed milliseconds later by a group-level "Pause" covering it. What state do you publish, and why does message order (not arrival order across A/B) matter here?
**Tags:** security-status, market-state, FIX-35f, tag-326, group-vs-instrument, ownership

### The MDP 3.0 packet header — sequence number and sending time
Every MDP 3.0 packet (Incremental, Recovery, Instrument Definition, TCP Replay) starts with a fixed binary
technical header: a 4-byte uint32 **packet sequence number** and an 8-byte uint64 **sending time** (nanoseconds).
Each SBE message inside the packet is framed by a 2-byte uint16 message size, and one packet can carry many
messages for many instruments. The packet sequence number is the owner's primary tool: arbitration and gap
detection operate on it. (Distinguish it from per-instrument RptSeq / tag 83 inside the message body, which
sequences updates for one SecurityID.) See `sbe-bank` for the SBE message header (block length/template id).
**Key concepts:** 4-byte packet seq num, 8-byte ns sending time, 2-byte uint16 msg size framing, many-msgs-per-packet, packet seq vs RptSeq (tag 83)
**Tip:** Sending time is the exchange's clock; pairing it with your own HW receive timestamp gives exchange→host latency — but only if your PTP is disciplined (see `lowlat-net`). Don't trust the delta if your clock is undisciplined.
**Tool anchor:** histogram (host_hw_rx_ts − packet sending_time) per packet to track exchange-to-host latency drift across the day.
**Drill:** Two packets arrive with the same packet sequence number, microseconds apart. Bug or expected? Now two arrive with seq N and N+2. Which mechanism handles each case?
**Tags:** packet-header, sequence-number, sending-time, wire-format, rptseq, measurement

### A/B feed arbitration
CME sends every incremental packet redundantly on two UDP feeds, A and B. Either can arrive first — order
between feeds is non-deterministic and outside CME's control (depends on network path). The owner runs the
recommended arbitration: listen to both, process by packet sequence number, **discard any sequence already
processed** (the duplicate from the slower feed), and treat a sequence gap as loss only when it is missing
from *both* feeds. A/B is the first line of defense; it cheaply recovers single-feed loss with zero recovery
traffic. Processing only one feed roughly doubles your gap rate and forces unnecessary snapshot recoveries.
**Key concepts:** redundant A/B UDP feeds, non-deterministic inter-feed order, dedupe by packet seq, gap = missing on both, first line of defense
**Tip:** Use SO_REUSEPORT and separate sockets/threads for A and B so one slow feed's softirq backlog can't head-of-line-block the other (see `feed-handler`). Arbitrate in a small lock-free structure keyed by seq, not a mutex-guarded map.
**Tool anchor:** track "won by A" vs "won by B" ratio and per-feed gap counts; a lopsided ratio or a one-sided gap spike points at a network-path problem on one feed.
**Drill:** Feed A's gap count is climbing but B is clean and arbitration still produces a complete stream. Is this a P1? What does it tell you, and what would make it a P1?
**Tags:** arbitration, A-B-feeds, deduplication, gap-detection, SO_REUSEPORT, redundancy

### Heartbeats and liveness vs gap detection
MDP 3.0 sends an Admin Heartbeat (35=0 — standard technical header + FIX header only) on the real-time
and recovery feeds during periods of no activity, at a 30-second interval. Heartbeats answer "is the feed
alive when nothing is trading?" They are a **liveness** signal, not a data-loss signal. Data loss is detected
separately by gaps in the packet sequence number. These are two different alerts the owner must wire up:
silence past ~30s (no data *and* no heartbeat) means the feed/connection is dead; a sequence gap means data
was lost but the feed is alive. Confusing them — e.g. treating a quiet-but-healthy feed as dead — causes
false pages and unnecessary failovers.
**Key concepts:** Admin Heartbeat 35=0, 30s interval, liveness vs loss, silence = dead feed, sequence gap = lost data, two distinct alerts
**Tip:** Set the liveness timeout above 30s (e.g. ~35–40s) to tolerate one missed heartbeat; alert on *two* consecutive misses to avoid flapping. Gap detection has no such grace — act on the first true A+B gap.
**Tool anchor:** one timer per channel reset by any packet (data or heartbeat); fire "feed dead" if it expires.
**Drill:** A channel goes silent at 02:00 with no heartbeats; another shows a single-packet gap during a news burst. Which is a dead-feed page and which is a recovery event? What's the timeout you'd set for each?
**Tags:** heartbeat, liveness, 35-0, gap-detection, monitoring, alerting

### Channels and market data groups
CME organizes market data by *market data group* — a configuration of MDP channels carrying all the data for
a product or set of products. Every channel has its own A/B incremental feeds, its own recovery and
instrument-definition feeds, and its own independent packet sequence number space. The owner thinks per
channel: a gap, reset, or dead-feed event is scoped to one channel and one sequence space, not the whole
exchange. Monitoring, alerting, recovery, and capacity are all per-channel because that is the unit of
failure and the unit of sequencing. You subscribe only to the channels carrying the instruments you trade.
**Key concepts:** market data group, channel = own A/B + recovery + def feeds, independent per-channel sequence space, channel as the unit of failure, subscribe by product
**Tip:** Never share one sequence-tracking structure across channels — each channel's packet sequence numbers are independent, so a single global "last seq" produces phantom gaps. One arbitrator state per channel.
**Tool anchor:** per-channel panels for every signal; map each traded instrument to its channel so an incident's blast radius is "which products" not "which IP".
**Drill:** You see a sequence gap on channel 310 but channel 320 is clean. How many of your instruments are affected, and why can't channel 320's stream help recover 310's books?
**Tags:** channel, market-data-group, sequence-space, blast-radius, subscription

### Why the handler is the single point of truth for the book
Every downstream consumer (strategy, risk, analytics) sees the market only through the feed handler's
published book — they do not independently decode the wire. That makes the handler the single source of
truth: a decode bug, a missed SecurityStatus, a mis-applied incremental, or a skipped recovery propagates to
every consumer at once, and they cannot detect it because they have no other view. This is why correctness
(book parity with the exchange) outranks raw latency in the SLO hierarchy, and why the owner treats any
silent divergence as the most severe class of bug — it is wrong data that everyone trusts.
**Key concepts:** handler as single source of truth, consumers don't decode the wire, blast radius = all consumers, silent divergence = worst bug, correctness outranks latency
**Tip:** Build an independent parity checker (e.g. rebuild books from a second decoder or from CME DataMine pcaps offline) — you cannot rely on the same code path to catch its own correctness bugs.
**Tool anchor:** end-of-day book-parity diff against an independent rebuild; treat any nonzero divergence as P1 regardless of latency numbers.
**Drill:** Your latency SLO is green all week but a strategy lost money on one instrument's wrong price. Why did no consumer alert fire, and what independent check would have caught it?
**Tags:** source-of-truth, correctness, parity, blast-radius, ownership

## intermediate

### Snapshot recovery and LastMsgSeqNumProcessed (tag 369)
When A and B both miss packets, the handler recovers from the Market Recovery (snapshot) feed, which carries
a full picture of every book with activity since the start of the week. The snapshot's SnapshotFullRefresh
(SBE) carries tag 369-LastMsgSeqNumProcessed: the incremental packet sequence number the snapshot is
consistent with. The procedure: queue live incrementals for the affected channel(s); read the recovery feed;
per instrument, take the snapshot then **drop all queued incrementals with packet seq < 369** and apply those
with seq ≥ 369. When done for all instruments, resume normal processing and *disconnect from the recovery
feed* (CME requires recovery use be recovery-only). This is the late-joiner / post-gap rebuild path.
**Key concepts:** Market Recovery snapshot feed, SnapshotFullRefresh, tag 369 LastMsgSeqNumProcessed, queue-then-reconcile, drop seq<369, disconnect when done
**Tip:** Don't pause the *whole* handler during recovery — per-instrument recovery lets unaffected instruments keep flowing while only the gapped ones rebuild. A global pause turns one instrument's gap into a fleet-wide latency spike.
**Tool anchor:** time-to-recover per instrument (gap detected → book consistent); alert if it exceeds your SLO budget for a single recovery.
**Drill:** During recovery, an instrument appears in both the snapshot and your queued incrementals but tag 60-TransactTime differs between them. What does CME say to do, and why can't you just apply the snapshot and move on?
**Tags:** snapshot-recovery, tag-369, late-joiner, per-instrument-recovery, reconciliation

### Channel Reset (269-MDEntryType=J)
A Channel Reset is the heavy hammer: it signals the exchange-side order books on a channel are corrupted
(a dual-component failure) and must be rebuilt from scratch. It arrives on the Incremental feed as a Market
Data Incremental Refresh carrying tag 269-MDEntryType=J (SBE template `ChannelReset`). On receipt the handler
must discard all book state for that channel and recover from snapshots — it is *not* a sequence gap and you
cannot patch through it. For the owner this is a rare but high-severity event: it invalidates every book on
the channel at once, so downstream consumers must be told "books reset" so they don't act on pre-reset state.
**Key concepts:** Channel Reset, 269-MDEntryType=J, ChannelReset SBE template, exchange-side corruption, discard-all-and-rebuild, channel-wide blast radius
**Tip:** Propagate a "reset" marker downstream (e.g. a sequence-reset event on your shm bus) so consumers flush their mirror of the book; silently rebuilding upstream while a consumer holds stale levels is a correctness bug.
**Tool anchor:** counter on 269=J events; any occurrence is an incident with a runbook (flush, recover, notify consumers, confirm book parity).
**Drill:** You receive 269=J on one channel at 09:31. Walk the runbook: what state do you discard, what feed do you recover from, what do you tell downstream, and how do you confirm you're whole again?
**Tags:** channel-reset, 269-J, book-corruption, runbook, incident, blast-radius

### Start-of-week startup and instrument definitions
Sunday startup is a distinct lifecycle phase with its own rules. Before the weekly open, all market data —
instrument definitions, price limits/banding, books, statistics — flows on the Incremental A/B feeds. During
startup, recovery and instrument-definition feeds send 30s heartbeats until recovery data begins, then stop.
Security Definition (35=d) messages during Sunday startup all carry tag 980-SecurityUpdateAction=A (Add),
even for instruments that existed last week. Instrument Definition feeds replay definitions at a constant
configurable packets-per-second rate for late joiners and mid-week recovery. The owner must treat the weekly
cold start as its own runbook: definitions first, then books; an instrument with no definition can't be dispatched.
**Key concepts:** Sunday startup, instrument definitions first, Security Definition 35=d, tag 980 = Add, constant replay rate, weekly cold start
**Tip:** Pre-allocate book/dispatch structures off the Sunday definition set (CME SecurityIDs are dense integers — array-index dispatch, see `orderbook`). Allocating on first-trade during Monday's open is a hot-path malloc bomb.
**Tool anchor:** count instrument definitions received at startup vs expected from the schedule; gate "ready to publish" on definitions-complete.
**Drill:** Monday 17:00, a burst hits an instrument you have no definition for. What went wrong in your startup sequence, and what's the safe behavior — drop, queue, or recover?
**Tags:** startup, instrument-definition, 35-d, tag-980, weekly-lifecycle, cold-start

### Velocity Logic, price banding, and Reserved/Pause states
Market integrity controls change book behavior and the owner must model them, not just pass them through.
Price banding rejects single orders priced too far from the last price (it does not stop market orders).
Velocity Logic catches prices moving *too far, too fast* within a tiny rolling look-back window; on trigger
the matching engine suspends and the instrument enters Reserved/Pre-Open — orders can be entered/modified/
cancelled, an indicative opening price is published, but no matches occur, then trading resumes. For a lead-
month instrument in some groups (equities, metals, energy, treasuries, FX) the *whole group* goes Pre-Open.
All of this is announced via SecurityStatus (35=f). Equity index futures also have market-wide 7%/13%/20%
circuit breakers coordinated with the cash market.
**Key concepts:** price banding (too far), Velocity Logic (too far too fast), Reserved/Pre-Open + indicative price, group-wide on lead month, 7/13/20% equity breakers, announced via 35=f
**Tip:** During a Velocity Logic pause your book is valid but *not matching* — publish the state so strategies don't mistake a frozen top-of-book for a tradeable one. A correct book in the wrong state is still a wrong signal.
**Tool anchor:** correlate SecurityStatus Pause/Reserved transitions with p99 message-rate spikes; these are exactly the bursts that stress your receive path.
**Drill:** A news event triggers Velocity Logic on a lead-month contract; message rate to that group spikes 20×. What two things happen at once (state change + burst), and how do each stress a different part of your handler?
**Tags:** velocity-logic, price-banding, reserved-state, circuit-breaker, burst, market-integrity

### SLI / SLO / error budget for a feed handler
Borrow the Google SRE framework but redefine the SLI for MD. An SLI is a ratio of good events to total
events. The good MD SLIs: tick-to-publish latency (e.g. fraction of book updates published within X µs),
book correctness (fraction of session-ends with zero divergence), and recovery time (fraction of gaps
recovered within Y ms). The SLO is the target over a window (commonly 28/30 days, or per-session for MD).
The error budget is 1 − SLO: a 99.9% within-budget SLO permits 0.1% of updates to miss. For latency SLIs
**percentiles, not averages** — the median hides the tail; p99/p999 is the "plausible worst case" that a
strategy actually trades against. The error budget gates change: blow it and you freeze risky deploys until
you're back in budget.
**Key concepts:** SLI = good/total, MD SLIs (tick-to-publish, correctness, recovery time), SLO target + window, error budget = 1−SLO, percentiles over averages, budget gates change
**Tip:** Your latency SLI must split successful from failed paths — "fast then wrong" (a corrupted book published quickly) is not a good event. Count a published-but-incorrect update as a budget burn, not a success.
**Tool anchor:** HdrHistogram of tick-to-publish per stage (see `measurement`); SLO = p999 under N µs; track budget burn per session.
**Drill:** Define three SLIs for your handler, pick SLO targets, and state the error budget for each. For the latency one, why is p999-under-budget a better SLI than mean-under-budget for a market-data consumer?
**Tags:** SLI, SLO, error-budget, percentiles, reliability-target, sre

### The four golden signals, applied to the feed pipeline
Google's golden signals — latency, traffic, errors, saturation — map cleanly onto a feed handler. *Latency*:
tick-to-publish per stage (receive, decode, book, publish), tracked as percentiles. *Traffic*: packets/sec
and messages/sec per channel — your demand, and the thing that bursts at the open and on news. *Errors*:
sequence gaps, recoveries triggered, channel resets, decode failures, book-parity divergences. *Saturation*:
how full the pipeline is — socket receive-buffer occupancy, ring-buffer depth, NIC/CPU utilization on the
isolated cores. Saturation leads latency: a rising p99 over a one-minute window is an early warning the
receive path is filling before you actually drop. Interpret them together — high latency + high saturation +
low errors = overloaded but coping; low latency + high errors = a logic/correctness bug, not capacity.
**Key concepts:** latency/traffic/errors/saturation, per-stage latency, pps & mps, gaps/resets/parity as errors, rcvbuf & ring depth as saturation, saturation leads latency
**Tip:** Receive-buffer drops (the kernel discarding because your userspace didn't drain fast enough) are a saturation signal that *manifests* as errors — watch `netstat -su` RcvbufErrors / drops so you catch the cause, not just the symptom.
**Tool anchor:** dashboard with all four per channel; alert on p99 latency over a 1-min window as the leading saturation indicator.
**Drill:** Your gap rate (errors) spikes during the open but latency and CPU look fine. Saturation where? Walk the path from NIC ring → socket rcvbuf → your ring buffer and name the queue that's actually overflowing.
**Tags:** golden-signals, latency, traffic, errors, saturation, monitoring, dashboard

### Natural Refresh and recovery strategy choice
CME offers more than one recovery path, and the owner must choose deliberately. **Market Recovery (snapshot)**
feeds rebuild from a full per-instrument snapshot reconciled via tag 369 — the primary path, and CME requires
all client systems to certify for it. **Natural Refresh** rebuilds an MBP book passively by watching the live
incrementals until every level has been re-observed — no recovery feed needed, but unbounded recovery time
for quiet instruments. **TCP historical replay** requests a specific start/end packet sequence range, but CME
recommends it only for *small-scale* recovery. The decision is a tradeoff: snapshot recovery is bounded and
authoritative; natural refresh is zero-extra-bandwidth but slow; TCP replay is targeted but doesn't scale.
**Key concepts:** Market Recovery snapshot (primary, certify required), Natural Refresh (passive, unbounded time), TCP replay (small-scale, seq-range), recovery as a deliberate choice
**Tip:** Snapshot recovery + natural refresh in parallel is CME's recommended primary combination — snapshot bounds the worst case while natural refresh quietly repairs active instruments without waiting for the recovery cycle.
**Tool anchor:** record which recovery path repaired each gap and its time-to-recover; a rising share of TCP replay at scale is a design smell (it's the small-scale tool).
**Drill:** A burst gaps 200 instruments at once. Which recovery path do you lead with and why? When would TCP replay be the wrong choice here?
**Tags:** natural-refresh, snapshot-recovery, tcp-replay, recovery-strategy, tradeoff

## advanced

### Capacity planning for the burst, not the average
Market data is bursty by an order of magnitude or more: a quiet period might run tens of thousands of
msgs/sec while the open or a news event spikes toward ~10⁶ msgs/sec (the seed's scenarios model exactly
this). Sizing for the average guarantees you drop at the open — precisely when correctness matters most and
when Velocity Logic floods the very instruments people are trading. The owner sizes every queue (NIC ring,
socket rcvbuf, internal SPSC/shm ring) and every core budget for the *burst* and verifies headroom by
replaying a worst-case capture. `recvmmsg` batching only amortizes syscall cost when datagrams are actually
queued deep enough to return several per call — i.e. the burst regime, when the NIC ring is filling; at low
rates it degenerates to one packet per call and can add latency, so the real break-even is workload- and
kernel-specific and must be benchmarked on your own hardware (`recvmmsg(2)`; see `feed-handler`). Saturation
is forward-looking: project "at this growth, the open will overflow rcvbuf in N weeks."
**Key concepts:** burstiness (≫10× average), size for peak not mean, queue headroom at every stage, recvmmsg helps only when batches are deep (benchmark the break-even), replay worst-case capture, forward-looking saturation
**Tip:** A burst that fits your throughput but not your queue depth still drops — throughput and latency-under-burst are different SLOs. Measure recovery *depth and time* after a synthetic burst, not just steady-state p50.
**Tool anchor:** replay a market-open / news capture (CME DataMine pcap) at line rate; measure max queue depth and drop count per stage; that's your real capacity number.
**Drill:** Steady-state you handle 500k msgs/sec at p99 = 8µs with rcvbuf 10% full. A news burst hits 1M/sec for 3s. Which fails first — throughput, latency, or a queue — and what single number tells you how close you were to dropping?
**Tags:** capacity-planning, burst, queue-sizing, recvmmsg, forward-looking-saturation, drop-prevention

### Trading-day runbooks: the events the owner must rehearse
Reliable ownership is rehearsed, not improvised. The core MD runbooks: **Sunday cold start** (definitions
before books, gate publish on definitions-complete, verify against schedule); **sequence gap** (A/B
exhausted → per-instrument snapshot recovery → reconcile via tag 369 → disconnect recovery feed → confirm
parity); **Channel Reset 269=J** (discard channel books, recover, notify downstream, confirm parity);
**dead feed** (heartbeat-silence past timeout → failover / escalate, distinct from a gap); **Velocity
Logic / Reserved** (expect burst + state change, publish state, don't mistake frozen TOB for tradeable);
**daily 16:00 CT break** (resting orders cancel, no data, don't false-alarm on the quiet). Each needs a
trigger (the signal that fires it), an action, and a verification (how you confirm you're whole).
**Key concepts:** rehearsed runbooks, cold start, gap recovery, channel reset, dead feed, velocity logic, daily break, trigger→action→verify
**Tip:** Every runbook ends in a *parity check* — books match the exchange, instrument count matches the schedule, no instrument stuck mid-recovery. "Recovered" without a parity check is a hope, not a confirmation.
**Tool anchor:** end-of-session report: per-instrument book divergence count, gaps, recoveries, resets, max recovery time — the owner's daily reliability scorecard.
**Drill:** Pick the gap-recovery runbook and write its trigger, action, and verification. What's the one measurement that proves the recovery actually worked, and what false "recovered" looks like without it?
**Tags:** runbook, incident-response, parity-check, trading-day, ownership, verification

### What to monitor: tying signals to the trading day
A feed-handler dashboard is the trading day made observable. The owner watches, per channel/instrument:
arbitration health (A vs B win ratio, per-feed gaps), liveness (last-packet-age vs the 30s heartbeat),
recovery (snapshot recoveries triggered, time-to-recover, resets), correctness (book parity, decode
failures), latency (per-stage tick-to-publish percentiles), and saturation (rcvbuf occupancy, ring depth,
isolated-core utilization). Thresholds are *state-aware*: a 1-minute data silence is normal at 16:30 CT
(the break) and a P1 at 09:35 CT (the open). The discipline mirrors SRE — keep the page-path simple, alert
on user-impacting SLO burn (latency/correctness) rather than every transient, and make saturation the
leading indicator so you act before you drop, not after.
**Key concepts:** state-aware thresholds, arbitration/liveness/recovery/correctness/latency/saturation panels, SLO-burn alerting, simple page-path, saturation as leading indicator
**Tip:** Alert on the *rate of error-budget burn*, not raw error count — a few gaps overnight is noise; the same rate sustained through the open will blow the session SLO. Burn-rate alerting catches the trend, not the blip.
**Tool anchor:** one Grafana-style board per channel with all six panel groups; overlay the market-state timeline so silence/bursts are read in context.
**Drill:** Design the alert for "data silence." Make it not page at 16:30 CT but page within seconds at 09:35 CT. What context (market state, heartbeat age, channel) does the rule need?
**Tags:** monitoring, dashboard, state-aware-alerting, burn-rate, observability, ownership

### The Big-Tech → prop-HFT gap (public knowledge only)
The transferable Big-Tech skills are real but need re-pointing. Serialization depth transfers directly to
SBE flyweight decoding (see `sbe`); SRE practice (SLI/SLO/error budget, golden signals, runbooks, blameless
incident review) transfers to MD ownership — but the SLI is redefined around *correctness and µs-latency*,
not request success rate, and the budget window can be per-session. The genuinely new surface is the
I/O+kernel layer that decides MD latency: multicast receive (`recvmmsg`/busy-poll/`io_uring`), NIC tuning,
CPU isolation, HW timestamping/PTP, kernel-bypass awareness — none of which a typical web service exercises
(see `lowlat-net`, `feed-handler`). The other new surface is the *domain*: the trading-day lifecycle, market
states, and exchange recovery semantics above. The mental shift: a request-reply service optimizes the mean
and scales out; a feed handler optimizes the *tail* on a fixed, isolated core, because the strategy trades
against p999, and you cannot horizontally scale a single deterministic ordered feed.
**Key concepts:** SRE-transfers-but-SLI-redefined, serialization→SBE, new I/O/kernel surface, tail-not-mean, single deterministic feed (no horizontal scale-out), domain lifecycle as new knowledge
**Tip:** Resist scale-out instincts — adding receivers via SO_REUSEPORT parallelizes I/O but reintroduces shared-book contention and ordering complexity (see `feed-handler`/`systems`). For one feed, a single isolated fast core usually beats N contended ones.
**Tool anchor:** profile the full path with `perf` top-down + per-stage HdrHistogram (see `/perf methodology`, `measurement`); optimize the stage that owns the p999 tail, not the mean.
**Drill:** List three Big-Tech reliability practices that transfer to MD ownership unchanged, and two assumptions (scale-out, mean-latency SLI) you must abandon. For each abandoned one, say what replaces it in the MD world.
**Tags:** career-bridge, sre-transfer, tail-latency, kernel-bypass-awareness, domain-gap, ownership

### Change management on a deterministic single-instance service
A feed handler breaks the usual deploy playbook: you cannot canary 1% of traffic or blue/green a single
deterministic ordered feed mid-session, and a bad deploy is a fleet-wide correctness incident, not a
percentage of slow requests. So change management shifts to the trading-day calendar: deploy in the daily
maintenance break (16:00–17:00 CT) or over the weekend before Sunday startup, never mid-session; gate every
release on replaying CME DataMine pcaps through it to prove book parity and latency before it ever sees live
data; and let the error budget gate risk — if you've burned the budget, freeze non-critical changes. The
SRE error-budget policy still applies, but the *mechanism* of safe rollout is calendar windows plus capture
replay, not traffic splitting.
**Key concepts:** no canary/blue-green on one ordered feed, deploy in the daily break or weekend, gate on pcap-replay parity, error-budget freezes risk, calendar-driven change windows
**Tip:** Your pre-deploy gate is a regression harness over real captures (open burst, news spike, gap, channel reset) — if the new build doesn't reproduce book parity and stay in the latency SLO on those, it does not ship. Replay is your canary.
**Tool anchor:** CI that replays the burst-scenario suite (and DataMine pcaps) and fails the build on any book-parity divergence or p999 regression.
**Drill:** You have a latency fix that's green in micro-benchmarks. It's Tuesday 11:00 CT. When do you deploy, and what must pass first? Why is a mid-session canary not an option?
**Tags:** change-management, deploy-window, pcap-replay, error-budget-policy, regression-harness, ownership
