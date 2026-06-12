# SBE (Simple Binary Encoding) Topic Bank
Updated: 2026-06-12
Scope: SBE as used by CME MDP 3.0 — wire format, schema, flyweight zero-copy decode, C++23 codec.
Sources: FIX Trading Community SBE spec (v1.0 RC3/RC4), Real Logic / Aeron `simple-binary-encoding`
wiki, CME Globex Client Systems Wiki (MDP 3.0 / SBE pages), cppreference (C++20/23). Public only.
Cross-links: deep CPU/cache/branch theory lives in `/perf` (cpu, mem); decode-pipeline I/O in `feed-handler`.

## beginner

### What SBE is and why CME uses it
Simple Binary Encoding is an OSI layer-6 presentation format for financial messages, standardized by the FIX Trading Community and reference-implemented by Real Logic (the Aeron team). It is a *fixed-position* binary codec: fields occupy proximate space with no tags, no delimiters, and no length pointers for fixed fields — the opposite of tag=value FIX or the older FAST encoding. CME replaced FAST with SBE in MDP 3.0 precisely because fixed-length fields, native little-endian byte order, and field alignment let a client decode with simple pointer arithmetic instead of bit-unpacking. For a feed handler this is the difference between a few ns per field (compute an offset, load) and tens of ns of branchy unpacking — directly relevant to the 1-100µs hot-path budget.
**Key concepts:** layer-6 presentation, fixed-position, no tags/delimiters, replaced FAST, little-endian, direct access
**Tip:** SBE's core design principle is *sequential streaming access with no backtracking* — the encode/decode order is fixed by the schema. Decode fields in schema order or you corrupt internal cursor state.
**Source anchor:** Real Logic SBE wiki (Java Users Guide); CME "SBE - Streamlined Market Data Message Formats".
**Drill:** Your predecessor decoded MDP 3.0 from a tag=value FIX gateway and saw ~2µs/message in the parser. The SBE feed handler does the same logical work in ~80ns. Name three structural properties of SBE that account for the gap and the one `perf` counter you'd check to confirm the parser is no longer the bottleneck.
**Tags:** sbe, overview, fast-vs-sbe, fixed-position, cme-mdp

### The SBE message header (8 bytes)
Every SBE message is preceded by a fixed message header: a composite of four `uint16` fields — `blockLength`, `templateId`, `schemaId`, `version` — totaling 8 bytes, little-endian. `templateId` selects which message layout (flyweight) to apply; `schemaId` identifies the schema; `version` is the schema version for extension; `blockLength` is the size of the message *root block* (fixed fields only, before any repeating groups or var-data). The header is a fixed size and is NOT counted in `blockLength`. Decode always reads the header first, then dispatches on `templateId`.
**Key concepts:** blockLength, templateId, schemaId, version, 4×uint16 = 8 bytes, root block size
**Tip:** `blockLength` excludes the header and excludes groups/var-data. It is the cursor advance from "after header" to "first group dimension" — the basis for forward/backward version compatibility.
**Source anchor:** FIX SBE v1.0 message-structure doc; CME "MDP 3.0 - SBE Message Header".
**Drill:** You read a header `blockLength=11, templateId=46, schemaId=1, version=13`. Your codec was generated against version 9 where template 46's root block was 11 bytes. Can you safely decode all root fields? What does `version=13` tell you to expect after the root block, and which header field would have changed if v13 *appended* a root field?
**Tags:** sbe, message-header, blocklength, template-id, dispatch

### The CME MDP 3.0 binary packet header
On the multicast wire, CME does not send a bare SBE message. Each UDP datagram begins with a 12-byte CME *binary packet header*: a 4-byte packet sequence number (`uint32`) used for gap detection, then an 8-byte sending-time timestamp (`uint64`, nanoseconds since epoch). After that, one or more messages follow, each framed by a 2-byte (`uint16`) message-size field, then that message's 8-byte SBE header, then its body. A single datagram can carry many messages, and a matching event can span several datagrams — so packet boundaries are not message boundaries.
**Key concepts:** 4-byte seq num, 8-byte sending time, 12-byte packet header, 2-byte message size framing, multiple msgs/packet
**Tip:** Gap detection runs on the *packet* sequence number (the 4-byte field), not per-message — detect a hole as early as possible at the datagram level before parsing bodies.
**Source anchor:** CME "MDP 3.0 - SBE Technical Headers"; CME "MDP 3.0 - SBE Message Header".
**Drill:** A datagram carries packet seq 5000, sending-time T, then three messages. You see the next datagram is packet seq 5002. Where in your loop do you detect the gap, what do you do with the 5000 datagram you already parsed, and why is per-packet (not per-message) sequencing the right granularity? (See `feed-handler` for recovery; `cme-mdp` for A/B arbitration.)
**Tags:** sbe, cme-packet-header, sequence-number, framing, gap-detection

### SBE primitive types and their sizes
SBE primitives map 1:1 to C++ scalar types: `char` (1B), `int8`/`uint8` (1B), `int16`/`uint16` (2B), `int32`/`uint32` (4B), `int64`/`uint64` (8B), `float` (4B, IEEE-754 binary32), `double` (8B, IEEE-754 binary64). Default byte order is `littleEndian` (settable per type via `byteOrder`). Every fixed field has a compile-time-known size and a static offset within its block, which is exactly what makes the flyweight-overlay decode possible.
**Key concepts:** char/int{8,16,32,64}/uint{8,16,32,64}/float/double, byte sizes, littleEndian default, static offsets
**Tip:** Because CME is little-endian and x86-64 is little-endian, integer field reads are a plain aligned load — `std::byteswap` is a no-op you can compile out with `if constexpr (std::endian::native != std::endian::little)`.
**Source anchor:** Real Logic SBE "FIX SBE XML Primer"; FIX SBE v1.0 field-encoding doc.
**Drill:** You templatize your codec to also parse a big-endian feed (ICE/Eurex). For a field accessed exactly once, do you eager-swap at parse time or lazy-swap (`std::byteswap`) at access time? For a field accessed five times per message? Justify with cycle counts and name the break-even rule.
**Tags:** sbe, primitive-types, byte-sizes, endianness, little-endian

### Schema XML — fields, groups, data and their ordering
An SBE message schema is XML. A `<message>` contains `<field>` (fixed), `<group>` (repeating), and `<data>` (variable-length) elements, and the order on the wire follows the schema element order under a hard rule: **all `<field>` precede all `<group>`, and all `<group>` precede all `<data>`.** This guarantees all fixed fields sit at the front with static offsets, repeating groups in the middle, and variable-length data last. Var-data is only ever allowed at the end of a message or at the end of a repeating-group entry.
**Key concepts:** schema XML, field/group/data, ordering rule fields<groups<data, var-data only at end
**Tip:** This ordering is *why* fixed fields keep constant offsets even when a message has groups: nothing variable-length can appear before a fixed field. The first group's dimension sits exactly at `header + blockLength`.
**Source anchor:** Real Logic SBE "FIX SBE XML Primer" / Java Users Guide.
**Drill:** A teammate proposes adding a variable-length `text` field between two fixed root fields of template 46 "to keep related data together." Explain why the SBE tool rejects this, and where the field must go instead to stay decodable.
**Tags:** sbe, schema-xml, field-ordering, var-data, layout-rules

### Presence: required, optional, constant
Each field has a `presence` attribute: `required` (default), `optional`, or `constant`. A `required` field always carries a value. An `optional` field reserves its fixed space but signals "not set" with a type-specific `nullValue` sentinel on the wire. A `constant` field is defined entirely in the schema and is **not transmitted on the wire at all** — it costs zero bytes and the decoder synthesizes the value. CME uses constant presence heavily (e.g., the price exponent), shrinking the wire footprint.
**Key concepts:** presence required/optional/constant, nullValue sentinel, constant = zero wire bytes
**Tip:** Constant fields are free bandwidth and free decode — they never touch the buffer. Optional fields still occupy their fixed slot (so offsets stay static); only their *meaning* is "null" via the sentinel.
**Source anchor:** Real Logic SBE "FIX SBE XML Primer"; FIX SBE v1.0 field-encoding doc.
**Drill:** Template 46's price exponent is `presence="constant" value="-9"`. How many bytes does the exponent occupy on the wire? When you decode a price mantissa, where does the `-9` come from, and what does that save versus a `decimal` composite that transmits the exponent?
**Tags:** sbe, presence, optional, constant, nullvalue

## intermediate

### Optional-field null sentinels (the exact values)
For an `optional` field, SBE reserves one extreme of the type's range as the null indicator. The spec defaults: `int8` null = -128 (range -127..127); `uint8` = 255 (0..254); `int16` = -32768 (-32767..32767); `uint16` = 65535 (0..65534); `int32` = -2^31 (-2^31+1 .. 2^31-1); `uint32` = 2^32-1 (0xFFFFFFFF); `int64` = -2^63; `uint64` = 2^64-1; `char` null = NUL (0); `float`/`double` null = quiet NaN. A schema may override `nullValue` explicitly. **Watch the collision trap:** if you define a `validValue`/enum value equal to the implicit sentinel (e.g. 65535 for a uint16), it collides with "null."
**Key concepts:** null sentinels per type, uint16=65535, int64=-2^63, char=0, float/double=NaN, override, collision trap
**Tip:** Null does NOT mean "use a default" — default handling is an application concern, not an encoding one. Check the sentinel, then decide.
**Source anchor:** FIX SBE v1.0 field-encoding doc (default ranges/null table); Real Logic issue threads on null collision.
**Drill:** Your decoder reads `MDEntrySize` (a `uint32` quantity) and gets `0xFFFFFFFF`. Is this a 4-billion-lot order or a null? How do you tell, and what is the branchless way to fold the null check into your level-update without mispredicting (cross-ref `/perf cpu` branchless select)?
**Tags:** sbe, null-values, sentinels, optional, nan, collision

### Repeating groups and the groupSizeEncoding dimension
A `<group>` is a repeating block of fields. It is preceded on the wire by a *group dimension*, the `groupSizeEncoding` composite: `blockLength` (`uint16`, the size of ONE group entry's fixed block) followed by `numInGroup` (the entry count). `numInGroup` is `uint8` by default (up to 256 entries) or `uint16` (up to 65536); a group cannot exceed 65536 entries. CME's `MDIncrementalRefreshBook` (template 46) carries its price-level updates in the `NoMDEntries` group (tag 268) — the dimension's `numInGroup` is how many level updates are in this message.
**Key concepts:** group dimension, groupSizeEncoding = blockLength(uint16)+numInGroup, uint8≤256/uint16≤65536, NoMDEntries
**Tip:** The group's own `blockLength` (per-entry size) is *separate* from the message header's `blockLength` (root-block size). The per-entry blockLength is what lets you stride entry→entry and skip unknown trailing fields added in a later version.
**Source anchor:** Real Logic SBE "FIX SBE XML Primer"; CME "MDP 3.0 - Market Data Incremental Refresh - MBP and MBOFD".
**Drill:** You decode template 46 with `numInGroup=8`, per-entry `blockLength=32`. Your codec was built when entries were 32 bytes; the live schema's entries are 40 bytes (8 bytes appended). Using only the wire `blockLength`, how do you advance from entry i to entry i+1 without reading garbage, and what do you do with the extra 8 bytes per entry?
**Tags:** sbe, repeating-groups, group-dimension, numingroup, blocklength, stride

### Variable-length data (var-data) encoding
A `<data>` field holds variable-length bytes (strings, binary) and may appear only at the end of a message or the end of a group entry. Its wire form is the `varDataEncoding` composite: a `length` prefix (commonly `uint16`, allowing up to 65535 bytes; use `uint32` for larger) followed by `length` raw bytes (`varData`). There is no static offset for var-data — its position depends on everything before it — so it must be read strictly in sequence, and it advances the decoder's internal cursor. The total encoded length of a message is unknown until decode completes.
**Key concepts:** var-data, varDataEncoding = length+varData, length prefix uint16/uint32, end-of-block only, cursor-advancing, no static offset
**Tip:** CME var-data fields are typically small; bound them. A pool/slab with a fixed max (e.g. 256B) keeps the hot path allocation-free — never `malloc` per message (cross-ref `/perf mem` allocators).
**Source anchor:** Real Logic SBE "FIX SBE XML Primer" / Java Users Guide.
**Drill:** A message has two var-data fields back to back. You access the second one first (a bug). Explain how SBE's cursor model silently returns corrupt bytes rather than throwing, and why the C++ flyweight's "read in schema order" contract is a correctness invariant, not just a style rule.
**Tags:** sbe, var-data, length-prefix, cursor, sequential-access

### Enum and set (bitset) encoding
SBE `enum` encodes a small choice as a `char` or `uint8` (or a named type over those), listing `<validValue>` entries. A `set` (bitset) encodes independent boolean flags packed into one `uint8`/`uint16`/`uint32`/`uint64`, with each `<choice>` naming a bit position. Both decode to a single integer load plus a compare/mask — no branching to unpack. In CME, `MDUpdateAction` (New=0, Change=1, Delete=2, plus Overlay) and `MDEntryType` (Bid=0, Offer=1, Trade=2) are enums in the `NoMDEntries` group.
**Key concepts:** enum over char/uint8, validValue, set/bitset over uint8..uint64, choice = bit position, MDUpdateAction, MDEntryType
**Tip:** Use `std::to_underlying` (C++23) on an SBE enum field to switch/index without a cast. An optional enum's "null" is the null of its underlying primitive (e.g. 255 for uint8) — the spec doesn't give enums their own nullValue.
**Source anchor:** Real Logic SBE "FIX SBE XML Primer"; CME MDP 3.0 incremental-refresh field docs.
**Drill:** Your dispatch on `MDUpdateAction` is a 4-way switch. The stream is ~70% Change, ~20% New, ~10% Delete. Predict the branch-misprediction behavior, and decide whether a jump table or an `if`-chain ordered by frequency is better here (cross-ref `/perf cpu` branch prediction).
**Tags:** sbe, enum, set, bitset, mdupdateaction, mdentrytype

### Decimal/price encoding: mantissa + exponent
SBE prices are scaled decimals: a signed integer `mantissa` times 10^`exponent`. The spec's `decimal` composite is `int64` mantissa + `int8` exponent (9 bytes, exponent on the wire); `decimal64` is `int64` mantissa + *constant* exponent (8 bytes); `decimal32` is `int32` mantissa + constant exponent (4 bytes). CME's `MDEntryPx` uses a fixed-point form: an `int64` mantissa transmitted on the wire with a **constant exponent of -9** (the "PRICE9" type, post the 2018 7→9 precision upgrade). The exponent is not sent; recover the real price by dividing the mantissa by 10^9.
**Key concepts:** scaled decimal mantissa×10^exp, decimal/decimal64/decimal32, CME PRICE9 = int64 mantissa + constant exp -9, divide by 1e9
**Tip:** Keep prices as integer mantissas internally — never convert to `double` on the hot path. Integer compares in the book are exact and fast; float divide is ~11-14 cycles and risks denormal assists (cross-ref `/perf cpu` divider / fp-assist).
**Source anchor:** FIX SBE v1.0 field-encoding (decimal composites); CME MDP 3.0 SBE decoding example / OnixS PRICE9 notes.
**Drill:** You decode `MDEntryPx` mantissa = 98745000000 under PRICE9. What is the real price? If you instead see the older v8 schema (exponent -7), what mantissa encodes the same 98.745? Why does keeping the mantissa as `int64` (not converting to double) matter for book correctness and for `perf` IPC?
**Tags:** sbe, decimal, price, mantissa-exponent, price9, fixed-point

### CME MDP 3.0 message templates (the four you decode)
CME defines all message types in one versioned SBE schema (`templates_FixBinary.xml`, updated ~weekly on the public CME FTP/SFTP). The four core templates for a book-building feed handler: **46 = MDIncrementalRefreshBook** (MBP/MBOFD book updates, the high-volume path), **52 = SnapshotFullRefresh** (full book snapshot for recovery on the snapshot channel), **48 = MDIncrementalRefreshTradeSummary** (trade prints), **30 = SecurityStatus** (instrument/group state: open, halt, pause). Related-but-distinct templates exist (MDIncrementalRefreshOrderBook, SnapshotFullRefreshTCP, SecurityStatusWorkup) — dispatch strictly on `templateId`.
**Key concepts:** single schema file, 46/52/48/30, incremental vs snapshot, trade summary, security status, weekly versioning
**Tip:** Pre-register every known `templateId` at startup. On the hot path, an unknown ID must NOT log (a log call can block and blow your tail) — bump a counter and inspect it on a background thread (cross-ref `feed-handler`).
**Source anchor:** CME "MDP 3.0 - Message Schema" / "Message Specification"; CME incremental & snapshot pages.
**Drill:** Mid-session a new `templateId=49` appears that your codec doesn't know. What does your dispatch do, how do you skip the message safely using only the header, and why is "skip + count" safer than "log + investigate" inline?
**Tags:** sbe, cme-templates, template-id, 46-52-48-30, dispatch, schema-versioning

### The NoMDEntries group of MDIncrementalRefreshBook
Template 46's repeating group `NoMDEntries` (tag 268) carries the per-level book updates. Each entry's fields (reference layout): `MDEntryPx` (270, decimal price), `MDEntrySize` (271, quantity), `SecurityID` (48, the instrument id you dispatch on), `RptSeq` (83, per-instrument report sequence), `NumberOfOrders` (346), `MDPriceLevel` (1023, book depth level), `MDUpdateAction` (279, New/Change/Delete), `MDEntryType` (269, Bid/Offer/Trade). One message can update several instruments and several levels; entries are segregated by `MDEntryType`.
**Key concepts:** NoMDEntries(268), MDEntryPx/MDEntrySize/SecurityID/RptSeq/NumberOfOrders/MDPriceLevel/MDUpdateAction/MDEntryType, per-entry fields
**Tip:** `RptSeq` (83) is per-instrument — use it for per-book gap detection and snapshot↔incremental reconciliation, independent of the packet sequence number used for datagram-level gaps.
**Source anchor:** CME "MDP 3.0 - Market Data Incremental Refresh - MBP and MBOFD"; epam java-cme-mdp3-handler README.
**Drill:** A single template-46 message has `numInGroup=12` spanning 3 instruments. Walk the decode: how do you route each entry to the right book by `SecurityID` (array-indexed dispatch, not a hash — see `orderbook`), apply `MDUpdateAction` at `MDPriceLevel`, and use `RptSeq` to verify you didn't miss an update for that instrument?
**Tags:** sbe, nomdentries, incremental-refresh, securityid, rptseq, book-update

## advanced

### Flyweight zero-copy decode (the core pattern)
The flyweight pattern overlays typed accessors directly on the received buffer — no deserialize-to-struct, no `memcpy` for fixed fields. Fixed root fields have static offsets, so an accessor is "base pointer + constant offset, then load." After the first group, offsets become dynamic, so post-group fields use a *cursor* (Aeron's approach): direct accessors for the fixed root, cursor-based accessors that advance through groups and var-data. Decoding 50 instruments × hundreds of thousands of msgs/sec demands this: a copy-to-struct codec touches each field twice (copy then read) and pollutes cache.
**Key concepts:** flyweight overlay, zero-copy, static offsets for root, cursor for post-group, direct vs cursor accessors, no memcpy
**Tip:** Benchmark flyweight vs naive copy-to-struct on your message mix. On x86-64 the flyweight should win on L1 miss rate and IPC; quantify with `perf stat -e L1-dcache-load-misses,instructions,cycles` (cross-ref `measurement`).
**Source anchor:** Real Logic SBE wiki (Cpp User Guide); mechanical-sympathy.blogspot SBE article.
**Drill:** Your flyweight accessor for a post-group field returns wrong data when groups have variable entry counts. Explain why a compile-time constant offset can't work after a group, how the cursor fixes it, and what invariant ("read in schema order") the cursor model imposes on your call sites.
**Tags:** sbe, flyweight, zero-copy, cursor, accessors, decode-pattern

### C++23 start_lifetime_as — UB-free buffer overlay
Casting `reinterpret_cast<const Msg*>(buf+off)` and dereferencing is undefined behavior even when the bytes are correct: no `Msg` object's lifetime ever began in that storage, and you violate strict aliasing. The optimizer is allowed to break it. C++23 `std::start_lifetime_as<T>(p)` *implicitly creates* an object of implicit-lifetime type `T` in existing, properly-aligned storage — running no constructor, touching no bytes, returning a usable `T*` — making the overlay defined behavior. Requirements: `T` is implicit-lifetime / trivially copyable, and `p` is aligned for `T` with `>= sizeof(T)` bytes. On x86-64 it compiles identically to the old cast but is portable and sanitizer-clean.
**Key concepts:** reinterpret_cast = UB (no lifetime + strict aliasing), start_lifetime_as implicit object creation, no ctor/no copy, alignment + size precondition, trivially copyable
**Tip:** `start_lifetime_as` returns a pointer *into* the buffer (zero copy) — ideal for a 100+ byte SBE root. `std::bit_cast<T>` *copies* to a local — fine for small ≤register-width fields, wasteful for the whole message. Pick by size.
**Source anchor:** cppreference (start_lifetime_as, bit_cast); P2590 (Doumler) explicit lifetime management.
**Drill:** You overlay template 46's root with `start_lifetime_as<MDIncrementalRefreshBook46>(buf+12+2+8)`. With UBSan on it sometimes fires. The bytes look right. Diagnose the most likely cause (hint: the offset), and give two fixes — one that changes the struct, one that changes the buffer handling.
**Tags:** sbe, start_lifetime_as, cpp23, undefined-behavior, strict-aliasing, zero-copy

### Alignment, packing, and the concatenation problem
`start_lifetime_as<T>(p)` requires `p` aligned for `T`. CME concatenates messages tightly in a datagram — message N starts right after N-1, at an offset that is usually NOT 8-byte aligned. So the second-and-later messages may be misaligned for a struct containing `int64` fields (`alignof==8`). Options: (a) `memcpy` each message to an aligned staging buffer before overlay (cheap if the target is L1-hot), or (b) declare the flyweight `#pragma pack(1)` / byte-aligned and accept that field reads are unaligned. On modern Intel, an unaligned access that stays within a cache line is effectively free; an access that splits a cache line costs a small extra penalty (on recent cores roughly a couple of cycles for loads), and one that crosses a 4 KiB page boundary is markedly more expensive — large enough that you avoid it on the hot path.
**Key concepts:** alignof, tight concatenation, misaligned message N, aligned staging buffer vs packed struct, unaligned-access cost
**Tip:** Align the *receive buffer* to 64B (cache line) so message 0 is aligned and SIMD-friendly. For later messages, copy-to-aligned-staging is usually cheaper and safer than betting on the microarchitecture's unaligned tolerance.
**Source anchor:** seed deep-dive (Memory/Cache/Alignment); cppreference start_lifetime_as alignment precondition; Agner Fog via `/perf mem`.
**Drill:** Datagram has 5 messages of sizes 71, 40, 88, 32, 56 bytes after the 12-byte packet header. Which message start offsets are 8-byte aligned? For the misaligned ones, justify copy-to-staging vs packed-struct given the message is re-read 6 times during decode + book update.
**Tags:** sbe, alignment, packing, concatenation, staging-buffer, unaligned-access

### Schema evolution on the wire (append-only)
SBE evolves backward-compatibly under one rule: **append optional fields only at the end of a block** (root block or a group entry's block). Never remove, reorder, resize, or retype an existing field — decoding is positional, so any of those shifts every later offset. When you append, `blockLength` grows; an older decoder uses the `blockLength`/`version` it knows (`actingBlockLength`, `actingVersion`) and simply stops at the old block boundary, returning null for fields it doesn't know. New message types get a new `templateId` (non-disruptive — unknown IDs are skippable). Composites cannot be extended in place; that needs a new template/version.
**Key concepts:** append-only at end of block, never remove/reorder, blockLength grows, actingBlockLength/actingVersion, extension fields must be optional, new msg = new templateId, composites can't grow
**Tip:** Skip-by-blockLength is the whole trick: read root fields up to *your* known size, then jump to `header + wireBlockLength` to reach the first group regardless of fields appended after you compiled.
**Source anchor:** Real Logic SBE "Message Versioning" wiki; CME template-extension notes ("blockLength increases ... new field can be ignored").
**Drill:** v9 → v13 appended a `uint64` to template 46's root, so wire `blockLength` went from 11 to 19. Your codec is v9. Decode v13 messages correctly: where do you find the first `NoMDEntries` dimension, and why must the appended field have been `optional`? Now design v9→v13 *dispatch* that doesn't mispredict every v13 message (hint: function-pointer table by version, not a per-message branch — see seed + `/perf cpu`).
**Tags:** sbe, schema-evolution, append-only, blocklength, acting-version, backward-compat

### Template-ID dispatch without mispredicting
After reading the header, you select the decoder by `templateId` (and sometimes `version`). The message mix is skewed — ~80%+ MDIncrementalRefreshBook (46), then trades (48), rarely snapshot/status — so a `switch` is predicted well after the predictor learns the pattern (<100 iterations). The dangerous case is the rare-but-not-never branch (a rare template, a schema-version transition): the predictor assumes "not taken" and eats ~15 cycles each time it is. The seed's fix for version transitions is a function-pointer table indexed by version (an indirect call, predicted via the BTB, predictable because versions don't interleave per instrument) rather than a per-message branch.
**Key concepts:** templateId switch, skewed distribution predicts well, rare branch = 15-cycle tax, version transition, function-pointer table, BTB vs PHT
**Tip:** Don't add a hot-path branch for an event that's near-0% then occasionally nonzero — that's a misprediction generator. Either make it a table dispatch or hoist it off the hot path. Measure with `perf stat -e branch-misses` before and after (cross-ref `/perf cpu` indirect-branch, `measurement`).
**Source anchor:** seed "Schema evolution on the hot path"; `/perf cpu` branch-prediction bank.
**Drill:** `perf stat` shows 12% branch-miss rate on your dispatch even though 80% of messages are template 46. Given the Zipf-skewed mix, explain why the misprediction is high anyway, and propose a code change (batching by template? jump table? sorted processing?) plus the counter that confirms the win.
**Tags:** sbe, dispatch, branch-prediction, template-id, function-pointer-table, misprediction

### std::expected error handling off the exception path
A hot-path decoder must not throw — exception unwinding pulls in unwind tables and bloats I-cache, and a throw on a malformed message can blow your tail latency. C++23 `std::expected<T, E>` returns either a decoded value or a structured error with no exceptions, no `bool`+out-param, giving a Rust-`Result`-like API. Use it for parse results (truncated message, unknown template, bad blockLength) and for I/O wrappers around syscalls (cross-ref `feed-handler`). The happy path stays a plain return; the error path is data, not control-flow unwinding.
**Key concepts:** std::expected<T,E>, no exceptions on hot path, unwind-table/I-cache cost, structured errors, parse + I/O wrappers
**Tip:** Pair `std::expected` with `[[unlikely]]` on the error check so the compiler lays out the hot path contiguously (better I-cache locality) — the dynamic predictor isn't helped, but code layout is (cross-ref `/perf cpu` I-cache).
**Source anchor:** cppreference (std::expected); seed projects 2 & 5 design notes.
**Drill:** Your decoder currently throws `std::runtime_error` on a truncated message; p99.9 has a 30µs spike that correlates with malformed-message bursts. Explain the mechanism, refactor the signature to `std::expected<DecodedMsg, ParseError>`, and state what you'd measure to confirm the tail improved (HdrHistogram p999, I-cache misses).
**Tags:** sbe, std-expected, error-handling, no-exceptions, tail-latency, cpp23

### Validating the codec against ground truth
A handwritten flyweight is only correct if its offsets match the schema. Guardrails: `static_assert(sizeof(Root) == expectedBlockLength)` and `static_assert(offsetof(...))` against the schema's computed offsets; `-Wpadded` to catch silent struct padding that shifts fields; round-trip tests (Rust encoder → C++ decoder, per the seed's two-sided design); and integration tests against real CME pcaps from CME DataMine. A 1-byte padding mistake (a `bool` before a `double` inserting 7 bytes) silently misaligns every later field and corrupts the book without crashing.
**Key concepts:** static_assert sizeof/offsetof vs schema, -Wpadded, round-trip encode/decode, CME DataMine pcaps, padding bugs
**Tip:** Compare your decoded output field-by-field against a known-good reference decoder (e.g. a public Python SBE decoder) on the same pcap before trusting the C++ path. Mismatches localize the bad offset fast.
**Source anchor:** seed "Verification" + alignment deep-dive; CME DataMine (sample captures); public reference decoders (tfgm/sbedecoder).
**Drill:** Your book ends a replay with bids and offers crossed for one instrument; another instrument is fine. The flyweight compiles clean. Outline a bisection: which `static_assert`/`offsetof` check, which `-W` flag, and which reference-decoder diff would localize a 4-byte offset error introduced by an appended-but-misplaced optional field.
**Tags:** sbe, validation, static-assert, offsetof, pcap, correctness
