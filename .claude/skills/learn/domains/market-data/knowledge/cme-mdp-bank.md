# CME MDP 3.0 Workflow Topic Bank
Updated: 2026-06-12
Scope: CME Globex Market Data Platform (MDP 3.0) protocol workflow — packet structure, message
types 46/52/48/30, channels, sequence numbers, gap detection, A/B arbitration, snapshot/TCP recovery,
channel reset, market state, schema evolution. The *wire encoding* (SBE) lives in the `sbe` bank; this
bank is the protocol *semantics* a feed-handler owner reasons about.
Sources: CME Group Client Systems Wiki (EPICSANDBOX Confluence: MDP 3.0 pages — Packet Structure,
Event Based Messaging, Incremental Refresh, Trade Summary, Snapshot/Market Recovery, Recovery Services,
Channel Reset, Security Status, System Startup, Dissemination, Incremental Feed Arbitration); CME public
SBE schema `templates_FixBinary.xml` (template IDs verified against Open-Markets-Initiative generated
codec, schema v1.10); EPAM `java-cme-mdp3-handler`; Databento GLBX.MDP3 docs. Public only.
Cross-links: SBE wire format → `sbe`; multicast I/O + gap/recovery mechanics → `feed-handler`;
book building from incrementals → `orderbook`; deep CPU/branch theory → `/perf cpu`.

## beginner

### What MDP 3.0 is and where it sits
CME Globex Market Data Platform 3.0 is the real-time market-data dissemination protocol for all CME Group
products (futures, options, spreads). It carries FIX 5.0 SP2 *semantics* (message types, tags) but encodes
them in SBE binary on the wire — MDP 3.0 replaced the older FAST encoding in the mid-2010s. Data flows as
SBE-encoded UDP multicast: a feed handler joins multicast groups, decodes each datagram, rebuilds order
books, and republishes normalized state downstream. As a service owner you reason at three layers: the
*transport* (UDP multicast, A/B redundancy), the *protocol* (packets, sequence numbers, message types,
recovery), and the *book* (applying incrementals to maintain L2/L3 state). This bank is the middle layer.
**Key concepts:** Globex, FIX 5.0 SP2 semantics + SBE encoding, UDP multicast, replaced FAST, A/B feeds
**Tip:** "MDP 3.0" names the *protocol/workflow*; "SBE" names the *byte encoding*. They are separable: same
SBE codec, different protocol rules (gap detection, recovery) are what this bank covers.
**Source anchor:** CME "CME MDP 3.0 Market Data"; CME "MDP 3.0 - Dissemination".
**Drill:** A teammate says "we already have an SBE decoder, so MDP 3.0 is done." Name three protocol-level
concerns the SBE codec does NOT solve, and which feed/channel each lives on.
**Tags:** mdp3, overview, globex, sbe-vs-protocol, transport

### The binary packet header and packet/message independence
On the wire CME does not send a bare message. Each UDP datagram opens with a 12-byte binary packet header:
a 4-byte packet sequence number (`uint32`, little-endian) used for gap detection, then an 8-byte sending
time (`uint64`, nanoseconds since Unix epoch). After the header, one or more messages follow; each message
is framed by a 2-byte (`uint16`) message-size field, then its 8-byte SBE message header, then its body.
Crucially, MDP 3.0 decouples *events* from *packets*: one datagram can carry many messages for many
instruments, and one matching event can span several sequential datagrams. Packet boundaries are NOT
message boundaries and NOT event boundaries.
**Key concepts:** 12-byte packet header, 4B seq num + 8B sending-time, 2B message-size framing, multi-msg
per packet, single event over multiple packets
**Tip:** Detect gaps at the *packet* level (the 4-byte field) before you parse any bodies — it's the
cheapest, earliest signal that something is missing. (Wire-format byte details: see `sbe`.)
**Source anchor:** CME "MDP 3.0 - Packet Structure with Event Based Messaging"; "MDP 3.0 - SBE Technical
Headers".
**Drill:** A datagram with packet seq 5000 holds 3 messages; the next datagram is seq 5002. Where in your
receive loop do you flag the gap, and why is per-packet (not per-message) sequencing the right granularity?
(Recovery actions: `feed-handler`.)
**Tags:** mdp3, packet-header, sequence-number, framing, event-independence

### The four message types you must handle (46/52/48/30)
The seed scopes four templates. In the modern SBE schema (verified against schema v1.10) their numeric
template IDs are: **MDIncrementalRefreshBook = 46** (real-time book updates, MBP and MBO full-depth),
**SnapshotFullRefresh = 52** (full-book snapshot, used by Market Recovery), **MDIncrementalRefreshTradeSummary
= 48** (the trade message — the seed's "MDIncrementalRefreshTrade"; the schema renamed it TradeSummary),
and **SecurityStatus = 30** (instrument/group market-state changes). The decoder reads the SBE message
header, dispatches on `templateId`, and applies the right book/state logic. Template 46 is the dominant
message type — CME notes most events consist solely of Market Data Incremental Refresh (35=X) messages.
**Key concepts:** templateId dispatch, 46=IncrementalRefreshBook, 52=SnapshotFullRefresh,
48=IncrementalRefreshTradeSummary, 30=SecurityStatus
**Tip:** Template IDs are **schema-version-specific**. The same MDIncrementalRefreshBook was template **32**
in an older schema and **46** in current schemas. Never hardcode IDs across schema upgrades — read them
from the schema you compiled against. (Schema evolution: advanced topic below.)
**Source anchor:** CME `templates_FixBinary.xml` (SBE MDP Core schema); CME "MDP 3.0 - Message Schema".
**Drill:** Your dispatch `switch` has cases 46/52/48/30. CME ships a schema where IncrementalRefreshBook is
template 32. What breaks, and what's the correct way to bind template ID → handler so an upgrade can't
silently misroute the bulk of your traffic?
**Tags:** mdp3, template-id, message-types, dispatch, 46-52-48-30

### MDUpdateAction — how a book entry changes
Inside MDIncrementalRefreshBook (46), the repeating group `NoMDEntries` carries per-entry actions in tag
279 `MDUpdateAction` (an `int8`/enum): **New = 0**, **Change = 1**, **Delete = 2**, **DeleteThru = 3**,
**DeleteFrom = 4**, **Overlay = 5** (null sentinel 255). New inserts a price level (shift levels down),
Change updates quantity/orders at an existing level, Delete removes a level (shift up). DeleteThru/DeleteFrom
clear ranges; Overlay replaces a level wholesale. Each entry also carries `MDPriceLevel` (tag 1023, the
1-based depth level) so you know exactly which level to touch.
**Key concepts:** MDUpdateAction tag 279, New=0/Change=1/Delete=2/DeleteThru=3/DeleteFrom=4/Overlay=5,
MDPriceLevel=1023
**Tip:** New and Delete imply a *shift* of the levels below/above; Change does not. Getting the shift wrong
double-counts or drops a level — the classic book-build correctness bug. (Book mechanics: `orderbook`.)
**Source anchor:** EPAM `java-cme-mdp3-handler` generated `MDUpdateAction`; CME "MDP 3.0 - Market by Order -
Book Management".
**Drill:** You receive `MDUpdateAction=New, MDPriceLevel=2` for the bid. What happens to the price levels
currently at level 2 and below, and how does this differ from `MDUpdateAction=Change, MDPriceLevel=2`?
**Tags:** mdp3, mdupdateaction, book-update, price-level, new-change-delete

### MDEntryType — what kind of entry this is
Tag 269 `MDEntryType` (a `char`) classifies each entry. Book-relevant values: **Bid = '0'**, **Offer =
'1'**, **ImpliedBid = 'E'**, **ImpliedOffer = 'F'**, **BookReset = 'J'**. **Trade = '2'** appears in the
trade summary. Statistic entries include OpenPrice '4', SettlementPrice '6', session High '7' / Low '8',
VWAP '9', ClearedVolume 'B', OpenInterest 'C', ElectronicVolume 'e'. So a single incremental message can
mix book updates, implied-book updates, and statistics — you branch on `MDEntryType` per entry.
**Key concepts:** MDEntryType tag 269 (char), Bid '0' / Offer '1', ImpliedBid 'E' / ImpliedOffer 'F',
Trade '2', BookReset 'J', statistic types '4'/'6'/'7'/'8'/'9'/'B'/'C'/'e'
**Tip:** The book-management subset is just {'0','1','E','F','J'}. Everything else is a statistic or trade
and must NOT touch your bid/offer ladder. A switch that routes 'B'/'C'/'e' into the book corrupts depth.
**Source anchor:** CME SBE schema `MDEntryType` enum (Open-Markets-Initiative codec); CME "MDP 3.0 - Implied
Book".
**Drill:** In one MDIncrementalRefreshBook you see entries with MDEntryType '0','1','E','C'. Which two
update the order book, which updates the implied book, and which is a statistic you'd route elsewhere?
**Tags:** mdp3, mdentrytype, bid-offer, implied, statistics, char-enum

### Prices: fixed-point mantissa with a constant exponent
MDP 3.0 never sends a float price. Each price (e.g. MDEntryPx, tag 270) is a fixed-point decimal: a signed
64-bit `int64` mantissa with a **constant exponent of -9** in current schemas (`PRICENULL9`), so the real
price = mantissa × 10⁻⁹. The exponent is a `constant`-presence field — it costs zero wire bytes; the decoder
synthesizes -9. An *optional* price signals "no value" with the int64 max sentinel
**9223372036854775807** (0x7FFFFFFFFFFFFFFF). Older schemas used exponent -7; the value is schema-version
dependent, so read it from the schema, don't assume.
**Key concepts:** int64 mantissa × 10^exponent, constant exponent -9 (PRICENULL9), null = 9223372036854775807,
older schemas exponent -7
**Tip:** Keep prices as scaled integers end-to-end (don't divide to double on the hot path). Integer compare
is exact and avoids the FP divider; a stray `mantissa / pow(10,9)` puts a 35–90-cycle divide on every price.
(FP-divider cost + reciprocal trick: `/perf cpu`.)
**Source anchor:** CME "MDP 3.0 - SBE Decoding Example" (PRICENULL9 composite); OnixS decimal-type docs.
**Drill:** You read mantissa 98890000000 with constant exponent -9. What's the price? If a different field
reads mantissa 9223372036854775807, what does that mean, and what must your decode do before using it?
**Tags:** mdp3, price-encoding, mantissa-exponent, pricenull, fixed-point

### A and B feeds — the first layer of loss protection
CME sends every incremental packet twice, on two independent UDP multicast feeds, **Feed A** and **Feed B**,
with identical content and identical packet sequence numbers. UDP is lossy and unordered; CME strongly
recommends consuming *both* feeds and arbitrating between them: take whichever copy of each packet seq
arrives first and discard the duplicate. A drop on one line is invisible because the other line fills it.
A/B arbitration is the cheapest, fastest recovery — it needs no request/response and no book rebuild.
**Key concepts:** Feed A + Feed B, identical content + identical seq numbers, consume both, first-wins
arbitration, dedup by packet seq
**Tip:** Arbitration is per packet sequence number: keep a "next expected seq", accept the first feed to
deliver it, drop the slow duplicate. You only declare a real gap when *both* A and B have moved past the
missing seq. (Receive-side mechanics + buffering: `feed-handler`.)
**Source anchor:** CME "MDP 3.0 - Dissemination"; "MDP 3.0 - Incremental Feed Arbitration"; EPAM handler
README (arbitrates A/B; reports loss only when both feeds exceed the seq threshold).
**Drill:** A is at seq 100, B lags at 95. You're waiting on 96. A jumps to 101. When do you (a) emit 96–100
to the book, (b) declare a true gap? Why must arbitration be per-feed-independent before you declare loss?
**Tags:** mdp3, ab-feeds, arbitration, redundancy, dedup, gap-threshold

## intermediate

### Gap detection on packet sequence numbers
Each channel has its own packet sequence number that increments by 1 per packet and **resets weekly**
(typically Sunday startup). Detection is simple: track next-expected-seq; if an arriving packet's seq is
greater than expected (after A/B arbitration), one or more packets were lost on both lines. The correct
response is conservative: assume every book on the channel may now be stale, because you don't yet know
which instruments the missing packet(s) touched. You then enter recovery (snapshot or TCP replay) while
optionally queuing live incrementals to replay after resync.
**Key concepts:** per-channel monotonic seq, +1 per packet, weekly reset, next-expected tracking, gap ⇒
assume books stale, queue-then-resync
**Tip:** Gap detection is the *protocol* signal; the *response* (snapshot vs TCP replay vs natural refresh)
is a policy decision driven by gap size and which feed has it. Keep detection in the hot path; push recovery
to a cold path so the common (no-gap) case stays branch-predictable. (Cold-path isolation: `/perf cpu`.)
**Source anchor:** CME "MDP 3.0 - Recovery Services"; "MDP 3.0 - Packet Structure"; OnixS packet-gap-detection.
**Drill:** You detect a gap of exactly 1 packet on the incremental channel. Both A and B missed it. Walk the
decision: snapshot recovery, TCP replay, or natural refresh? What gap-size and current-day constraints push
you toward each?
**Tags:** mdp3, gap-detection, sequence-number, weekly-reset, recovery-trigger

### RptSeq — per-instrument sequencing for surgical recovery
Beyond the packet sequence number (channel-wide), each instrument carries tag 83 `RptSeq`, a per-instrument
report sequence that increments by 1 for every update to that security. This lets you recover surgically:
when a packet gap occurs, instruments whose RptSeq stays contiguous were not affected and can keep updating,
while only instruments with an RptSeq jump need resync. RptSeq is also how you reconcile a snapshot against
live incrementals during recovery — the snapshot carries the instrument's last RptSeq.
**Key concepts:** RptSeq tag 83, per-instrument +1, contiguity ⇒ unaffected, per-instrument recovery,
snapshot reconciliation
**Tip:** Two sequence spaces, two jobs: packet seq = "did I lose a datagram on this channel?"; RptSeq = "is
*this instrument's* stream intact?" Per-instrument recovery (keep feeding unaffected instruments) is what
keeps a 1-packet loss from blacking out the whole channel.
**Source anchor:** CME "MDP 3.0 - Market Data Incremental Refresh" (RptSeq); EPAM handler (per-instrument
recovery logic).
**Drill:** A packet gap hits the channel. Instrument X's next update has RptSeq contiguous with its last;
instrument Y's RptSeq jumped by 5. What do you do with X vs Y, and how does this avoid a full-channel rebuild?
**Tags:** mdp3, rptseq, per-instrument, surgical-recovery, reconciliation

### MatchEventIndicator — transactional event boundaries
Tag 5799 `MatchEventIndicator` is a bitfield on every incremental message that marks the boundaries of a
matching event so clients can apply updates *transactionally* — only publish the book when the event is
consistent. The high bit is **EndOfEvent**: set when this is the last message of the event. Other bits flag
the last message of a category within the event: LastTradeMsg, LastVolumeMsg, LastQuoteMsg, LastStatsMsg,
LastImpliedMsg, plus RecoveryMsg. A single event can span multiple packets, so you accumulate until you see
EndOfEvent, then publish a coherent snapshot to consumers.
**Key concepts:** MatchEventIndicator tag 5799, bitfield, EndOfEvent (high bit), Last{Trade,Volume,Quote,
Stats,Implied}Msg, RecoveryMsg, transactional apply
**Tip:** Don't publish per-message — publish per-event. Implied-book updates are sent *last* in an event; if
implied updates spill to a later packet, the earlier packet carries NO EndOfEvent. Publishing early shows a
torn book. (Coherent publish to consumers: `orderbook`, `systems` shm bus.)
**Source anchor:** CME "MDP 3.0 - Event Based Market Data Messaging"; SBE `MatchEventIndicator` composite.
**Drill:** You've applied two packets of an event; neither has EndOfEvent set. A third packet finishes the
implied book and sets EndOfEvent. If you'd published after packet 1, what inconsistency would a consumer see,
and why does CME defer implied updates to the end of the event?
**Tags:** mdp3, matcheventindicator, end-of-event, transactional, implied-ordering

### Snapshot recovery (SnapshotFullRefresh, 52) and LastMsgSeqNumProcessed
When both A and B drop a packet and the gap is large or not current-day, you recover from the Market Recovery
(snapshot) feed, which continuously replays full-book SnapshotFullRefresh (52) messages — one per active
instrument — in a loop at a configurable packets/sec. Each snapshot carries tag 369 `LastMsgSeqNumProcessed`:
the incremental packet sequence number the snapshot reflects. Recovery: join the incremental feed and queue
its packets; join the recovery feed; for each snapshot, set the book, then drop all queued incrementals with
packet seq ≤ LastMsgSeqNumProcessed and apply the rest. You must process one full snapshot loop (starting at
the loop's seq 1) to recover every instrument.
**Key concepts:** Market Recovery feed, SnapshotFullRefresh=52, LastMsgSeqNumProcessed tag 369, queue
incrementals then reconcile, full loop from seq 1, configurable replay rate
**Tip:** The snapshot loop order is not guaranteed; completeness is guaranteed only by processing one full
iteration. tag 911 `TotNumReports` tells you the loop size — compare across iterations to catch instruments
added mid-recovery. (Snapshot↔incremental transition correctness: `orderbook`; feed mechanics: `feed-handler`.)
**Source anchor:** CME "MDP 3.0 - Market Data Snapshot - Full Recovery"; "MDP 3.0 - Recovery Services".
**Drill:** A snapshot for instrument X has LastMsgSeqNumProcessed=4000. You've queued incrementals 3990–4010
for X. After setting the book from the snapshot, which queued incrementals do you discard, which do you
apply, and in what order? How do you avoid both double-counting and a missed level?
**Tags:** mdp3, snapshot-recovery, snapshotfullrefresh, lastmsgseqnumprocessed, reconciliation

### TCP replay — targeted current-day recovery
For a small gap on the current trading day, TCP historical replay is faster than a full snapshot loop. The
client opens a TCP connection and sends a Market Data Request (35=V) naming the start/end packet sequence
range to resend; CME replays exactly those packets. Limit: a **maximum of 2,000 messages** per request, and
**only the current day's** messages are available. It's the middle tier of the recovery hierarchy: A/B
arbitration handles single-line loss; TCP replay handles small current-day gaps; snapshot recovery handles
large gaps, stale state, or cross-day rebuilds.
**Key concepts:** TCP historical replay, Market Data Request 35=V, start/end seq range, ≤2000 messages,
current-day only, middle recovery tier
**Tip:** Choose by gap size and recency: ≤2000 msgs and today → TCP replay (least disruptive); otherwise →
snapshot. Don't TCP-replay a 50k-packet gap; you'll exceed the cap and serialize on a TCP round-trip while
live data piles up. (Connection/backpressure handling: `feed-handler`.)
**Source anchor:** CME "MDP 3.0 - TCP Recovery"; "MDP 3.0 - Recovery Services".
**Drill:** Two gaps: (a) 120 packets, 10:00 today; (b) 9,000 packets spanning yesterday's close. Pick the
recovery tier for each and justify against the 2,000-message and current-day-only limits.
**Tags:** mdp3, tcp-replay, targeted-recovery, 2000-limit, recovery-hierarchy

### Instrument definitions and the dense SecurityID space
Before you can build a book you need the instrument's definition (tick size, multiplier, implied eligibility,
etc.), delivered as Security Definition (35=d) messages on a dedicated Instrument Definition feed that
replays at a constant configurable rate (A primary, B backup). Each definition carries a 32-bit `SecurityID`
that CME assigns densely per instrument group — which is exactly why feed handlers index books by a
pre-allocated `array[SecurityID]` rather than a hash map. During Sunday startup, definitions are sent on the
incremental feed with tag 980 `SecurityUpdateAction=A` (Add) for every instrument, whether or not it traded
last week.
**Key concepts:** Security Definition 35=d, definition feed (A primary/B backup), dense int32 SecurityID,
array dispatch, Sunday startup SecurityUpdateAction=A
**Tip:** Process definitions before (or alongside) incrementals — an incremental for an unknown SecurityID
means you joined late or missed a definition. Dense IDs make array dispatch O(1) with no hashing. (Dispatch
array layout, cache cost, prefetch: `orderbook`, `systems`.)
**Source anchor:** CME "MDP 3.0 - System Startup"; "MDP 3.0 - Dissemination"; Databento GLBX.MDP3.
**Drill:** You get an MDIncrementalRefreshBook for a SecurityID you have no definition for. List two causes
and the recovery action for each. Why are dense SecurityIDs the property that makes array-indexed dispatch
beat a hash map on the hot path?
**Tags:** mdp3, instrument-definition, securityid, dense-ids, array-dispatch, startup

### Channels, market data groups, and config.xml
Market data is partitioned into **channels**; each channel is a market data group serving a product set, and
each carries separate A/B multicast lanes for three feed types: **incremental** (real-time), **snapshot**
(market recovery), and **definition** (instrument). The authoritative map of channel → multicast
address:port for every lane is the **config.xml** file CME publishes on its FTP (cmegroup.com/ftp) / SFTP
(sftpng.cmegroup.com) site, alongside the SBE `templates_FixBinary.xml` schema. CME updates these files
periodically; if you filter by source IP you must redeploy config.xml before the change date or you'll drop
the feed.
**Key concepts:** channel = market data group, three lane types (inc/snap/def) × A/B, config.xml on FTP/SFTP,
templates_FixBinary.xml, periodic updates
**Tip:** A channel has ~6 multicast joins to track: {inc, snap, def} × {A, B}. config.xml is operational
state, not code — a stale config.xml is a silent outage. (Multicast join / IGMP / SO_REUSEPORT: `feed-handler`,
`lowlat-net`.)
**Source anchor:** CME "MDP 3.0 - CME Globex Market Data Channel Guide"; "MDP 3.0 - Dissemination".
**Drill:** Sketch the multicast subscriptions for one channel. CME announces new source IPs for that channel
effective next Monday. If your host firewalls by source IP, what exactly fails and when if you don't update
config.xml first?
**Tags:** mdp3, channels, config-xml, multicast-lanes, ftp, operations

### The implied book (2-deep) and event ordering
For implied-eligible futures, CME publishes a separate **2-deep** implied best bid/ask (top 2 levels only),
flagged via MDEntryType ImpliedBid 'E' / ImpliedOffer 'F' and designated on the Security Definition by tag
1022 `MDFeedType=GBI`. Implied book maintenance uses the same New/Change/Delete actions, but because it's
only 2-deep, a New shifts and the level past 2 is dropped. Implied updates are always the **last** update of
an event — if they spill to a later packet, the earlier packet carries no EndOfEvent. Implied data is never
sent in MBO (order-level) format.
**Key concepts:** 2-deep implied book, ImpliedBid 'E'/ImpliedOffer 'F', MDFeedType=GBI, shift-and-drop past
level 2, implied = last in event, never MBO
**Tip:** Keep the implied book as a separate 2-level structure from the direct book; some strategies want
direct-only, some want the merged top. Merging into one ladder doubles its width and the cache footprint —
measure before you merge. (Merge-vs-separate book cost: `orderbook`.)
**Source anchor:** CME "MDP 3.0 - Implied Book".
**Drill:** An event updates the direct book in packet 1 (no EndOfEvent) and the implied book in packet 2
(EndOfEvent set). Why this order? If you maintain a merged top-of-book, what's the cache cost of doubling the
ladder width vs keeping implied separate?
**Tags:** mdp3, implied-book, 2-deep, mdfeedtype-gbi, event-ordering

### Trade Summary (48): aggressor side and order-level detail
MDIncrementalRefreshTradeSummary (48) reports executed trades. The summary level carries Trade entries
(MDEntryType '2', sent only when ≥1 *actual* — non-implied — order participates), with fill price, fill
quantity (tag 271), and `NumberOfOrders` (tag 346). Tag 5797 `AggressorSide` says which side triggered the
trade (0=none, 1=Buy, 2=Sell); when defined, the first order-detail entry is the aggressor and its quantity
equals the summary fill quantity. Optional order-level detail rides in tag 37705 `NoOrderIDEntries`
(anonymous OrderID + last qty per resting order). A single match's order detail can split across packets;
across all splits, total NumberOfOrders equals total NoOrderIDEntries, in corresponding order.
**Key concepts:** TradeSummary=48, Trade '2' (≥1 actual order), AggressorSide tag 5797 (0/1/2), summary
fill qty tag 271, NumberOfOrders tag 346, NoOrderIDEntries tag 37705, split across packets reconciles
**Tip:** If you only need price/size/count, process the summary level and skip order detail (cheaper). For
leg trades of a spread, no Trade '2' is sent — an ElectronicVolume 'e' update is sent instead. End-of-trades
for an event is flagged by MatchEventIndicator LastTradeMsg.
**Source anchor:** CME "MDP 3.0 - Trade Summary"; "MDP 3.0 - Trade Summary Order Level Detail".
**Drill:** A Trade Summary has AggressorSide=1 (Buy), summary fill qty 50, NumberOfOrders=3, but
NoOrderIDEntries reports only 2 OrderIDs with a continuation expected. What does the first order-detail
entry's quantity equal, and where does the third order's detail arrive?
**Tags:** mdp3, trade-summary, aggressor-side, order-detail, noorderidentries, reconciliation

## advanced

### Security Status (30) and the trading-day state machine
SecurityStatus (30) drives the instrument/group market-state machine. Tag 326 `SecurityTradingStatus`
enumerates states: TradingHalt=2, Close=4, NewPriceIndication=15, ReadyToTrade=17, NotAvailableForTrading=18,
PreOpen=21, PreCross=24, Cross=25, PostClose=26, NoChange=103. Tag 1174 `SecurityTradingEvent` qualifies it:
NoCancel=1, ResetStatistics=4, ImpliedMatchingOn=5/Off=6, EndOfWorkup=7. Tag 327 `HaltReason` gives a reason
(e.g. 6 = Recovery in process during a failover). A feed handler must react: on a halt/close, freeze or clear
the book per policy; on ResetStatistics, clear stats; transitions like PreOpen→Cross→ReadyToTrade gate when
trades and price discovery resume.
**Key concepts:** SecurityStatus=30, SecurityTradingStatus tag 326 (Halt=2/Close=4/ReadyToTrade=17/PreOpen=21
/Cross=25...), SecurityTradingEvent tag 1174 (NoCancel=1/ResetStats=4/EndOfWorkup=7), HaltReason tag 327
**Tip:** A SecurityStatus inside an event signals there may be *another* set of incrementals after the state
change — keep reading to EndOfEvent. State transitions are rare branches: keep the status handler off the hot
book-update path so it never pollutes branch prediction for the common book-update case. (Rare-branch cost: `/perf cpu`.)
**Source anchor:** CME "MDP 3.0 - Security Status"; "MDP 3.0 - Market Data Security Status".
**Drill:** You get SecurityStatus 326=2 (TradingHalt) mid-event, then more incremental data before EndOfEvent.
Do you apply the trailing incrementals? What do you do to the book on a halt vs a Close (4), and why is
SecurityTradingEvent ResetStatistics=4 a separate concern from the book?
**Tags:** mdp3, security-status, trading-status, state-machine, halt-close, security-trading-event

### Channel Reset (template 4, MDEntryType 'J') — the nuclear option
A Channel Reset signals that CME's own books on a channel are corrupted (e.g. a dual-component failure). It
arrives inline on the incremental feed as an MDIncrementalRefresh with **MDEntryType 'J' (BookReset)** and
tag 1180 `ApplID` present; it maps to the **ChannelReset** template (id 4 in schema v1.10). On receipt the
client must **empty every order book and clear statistics** for the impacted channel, then accept the resent
book and statistics that follow. This is distinct from the *weekly* packet-sequence reset (Sunday startup):
channel reset is an unscheduled corruption recovery; the weekly reset is the normal start-of-week seq=1.
**Key concepts:** ChannelReset template 4, MDEntryType 'J' (BookReset), ApplID tag 1180, empty all books +
clear stats, resent state follows, distinct from weekly seq reset
**Tip:** Channel reset ≠ weekly reset ≠ snapshot recovery. Reset = "wipe and rebuild from what I'm about to
resend." Settlement/daily stats are NOT resent on a channel reset, so don't expect them back automatically.
**Source anchor:** CME "MDP 3.0 - Channel Reset"; "MDP 3.0 - Market Data Incremental Refresh - Channel Reset".
**Drill:** You receive MDEntryType='J' on the incremental feed. List the exact state you wipe, what you
expect to arrive next, and one piece of state that is NOT resent. How is your handler's response different
from a Sunday startup where packet seq simply returns to 1?
**Tags:** mdp3, channel-reset, bookreset, dual-component-failure, empty-book, weekly-reset

### Weekly lifecycle: Sunday startup, weekly seq reset, end-of-week
The CME trading week is a cycle a feed-handler owner must script around. **Sunday startup**: before market
open, all instrument definitions, price limits, and banding are disseminated on the incremental A/B feeds;
definitions carry SecurityUpdateAction=A (Add) for *every* instrument. CME sends Heartbeat (35=0) on the
recovery and definition feeds at a 30-second interval until recovery data begins, then stops heartbeating.
Each channel's **packet sequence number resets weekly** (starts at 1 for the new week). Books from last week
are gone; you rebuild from the fresh definitions and incrementals. End-of-week brings settlement and close
states via SecurityStatus and statistic entries.
**Key concepts:** Sunday startup, definitions+limits+banding on incremental A/B, SecurityUpdateAction=A for
all, 30s heartbeats until recovery data, weekly per-channel seq reset to 1, settlement at week end
**Tip:** Your gap-detection state must reset cleanly at the weekly rollover — a "next-expected seq" carried
from last week will false-positive a giant gap at seq 1. Treat the weekly reset as a known boundary, not a
gap. (Trading-day/lifecycle ownership: `ownership`.)
**Source anchor:** CME "MDP 3.0 - System Startup"; "MDP 3.0 - Packet Structure" (weekly seq reset).
**Drill:** Monday 00:01 your handler logs a gap of "expected 4.2M, got 1." What actually happened, why did
naive gap detection fire, and how should the handler distinguish the weekly reset from a real loss of
millions of packets?
**Tags:** mdp3, weekly-lifecycle, sunday-startup, seq-reset, heartbeat, settlement

### Schema evolution: decoding across versions without mispredicting
CME versions the SBE schema and ships changes that your codec must survive. Two safe extension rules: (1)
appending a field to a message body increases that message's `blockLength` but keeps the same templateId and
schemaId, bumping `version`; (2) a new message gets a new templateId. Forward/backward compatibility hinges
on **always trusting the on-wire `blockLength`** to advance to the first repeating group, never a hardcoded
constant — a v2 that appended a root field will have a larger blockLength than your v1 codec compiled with.
The dangerous hot-path mistake is branching on `version` per message: a v1→v2 cutover starts at ~0% v2 and
mispredicts every v2 message (~15 cycles each). A version-indexed function-pointer table is predictable
because versions don't interleave per instrument.
**Key concepts:** schemaId/version/templateId/blockLength roles, append-field rule (blockLength↑, version↑,
templateId same), new-message rule (new templateId), trust wire blockLength, version dispatch via table not
branch
**Tip:** Read root fields by static offset (safe — fixed fields precede groups), then jump by *wire*
blockLength to the first group dimension. This is exactly what lets a v1 codec read a v2 message's shared
prefix. Template IDs are also version-specific (IncrementalRefreshBook was 32, now 46) — bind via table.
(Branch-vs-table dispatch and misprediction cost: `/perf cpu`; SBE blockLength mechanics: `sbe`.)
**Source anchor:** CME "MDP 3.0 - Message Schema" (versioning, blockLength padding to 8B); FIX SBE spec
(extension/versioning).
**Drill:** CME ships schema v13 that appends one optional field to template 46's root block; your codec was
generated against v9. Can you still read all your fields? What header field changed, how do you find the
first repeating group, and why is a per-message `if (version >= 13)` the wrong way to handle the new field?
**Tags:** mdp3, schema-evolution, versioning, blocklength, template-id-stability, dispatch

### Designing the dispatch + recovery hot/cold split for the 1–100µs budget
Tie it together for the budget. Hot path (per packet, must stay 1–100µs): arbitrate A/B by packet seq,
detect gap, frame messages, dispatch on templateId, apply book updates, accumulate to EndOfEvent, publish.
Cold path (rare, may be slow): gap → recovery (snapshot/TCP), channel reset, schema rollover, status
transitions. The owner's design discipline: keep the common case (template 46, no gap, EndOfEvent set)
straight-line and branch-predictable; push every rare branch (gap, reset, unknown template, status change)
behind `[[unlikely]]` / a noinline cold function so it never bloats I-cache or trains the predictor wrong.
Never log or allocate on the hot path — count anomalies into a counter and inspect on a background thread.
**Key concepts:** hot path (arbitrate/detect/frame/dispatch/apply/publish) vs cold path (recovery/reset/
status), common case = template 46 no-gap, [[unlikely]]/noinline cold paths, no log/alloc on hot path,
background anomaly counters
**Tip:** Measure before deciding what's hot: per-stage timestamps (t_receive→t_parsed→t_book→t_published)
plus TMA top-down tell you whether you're frontend-bound (I-cache from over-inlined recovery code) or
backend-bound (cache misses in the book). (Per-stage timing + HdrHistogram: `measurement`; top-down: `/perf
methodology`.)
**Source anchor:** Synthesis of CME workflow (above) with the seed's hot/cold-path design notes;
measurement/branch theory cross-linked.
**Drill:** Top-down says your handler is Frontend Bound at 30% under burst, and the unknown-template counter
is nonzero. Connect the two: how could recovery/error code laid out next to the dispatch loop cause frontend
stalls on the common path, and what's the layout fix? Which `perf` counter confirms it?
**Tags:** mdp3, hot-cold-split, dispatch-design, latency-budget, branch-layout, measurement
