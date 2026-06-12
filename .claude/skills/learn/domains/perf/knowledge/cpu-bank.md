# CPU Microarchitecture Topic Bank
Updated: 2026-05-28

## beginner

### Pipeline stages and instruction flow
A modern x86-64 CPU pipeline has roughly 14-20 stages (Golden Cove/Alder Lake added one stage over Skylake) divided into a frontend (fetch, predecode, decode, allocate) and backend (execute, retire). Understanding where the frontend ends and backend begins at the allocation/rename stage is critical because TMA analysis splits bottlenecks at exactly this boundary. Every instruction flows in-order through the frontend, executes out-of-order in the backend, then retires in-order again.
**Key concepts:** fetch, decode, execute, retire, frontend/backend boundary, pipeline depth, in-order vs out-of-order
**Tip:** Pipeline depth determines branch misprediction cost: Skylake wastes ~16.5 cycles per mispredict on a uop-cache (DSB) hit and ~19-20 cycles on a DSB miss, because all speculatively-issued instructions after the branch must be flushed and re-fetched.
**Tool anchor:** `perf stat -e cycles,instructions,uops_issued.any,uops_retired.retire_slots -- ./bench`
**Drill:** You have two binaries: one with a tight arithmetic loop (add/mul chain), another with scattered branches. Predict which has higher IPC and explain how pipeline depth affects each differently. Then verify with `perf stat`.
**Tags:** pipeline, frontend, backend, pipeline-depth, fetch-decode-execute-retire

### IPC and what it tells you
Instructions Per Cycle (IPC) is the single most useful first-pass metric from `perf stat`. Modern superscalar cores can theoretically retire 4-6 uops/cycle (Skylake: 4 wide, Zen 4: 6 wide), but real workloads typically achieve 1.0-2.5 IPC. Low IPC (<1.0) means the pipeline is stalled, but the cause could be backend (cache misses, long-latency divides) or frontend (instruction fetch stalls, decode bottlenecks), and distinguishing between them requires TMA Level 1.
**Key concepts:** IPC, superscalar width, retire bandwidth, backend stall, frontend stall, uops vs instructions
**Tip:** IPC can be misleading with SIMD: a single AVX-512 instruction does the work of 16 scalar instructions, so a SIMD-heavy workload may show IPC of 0.8 while being perfectly efficient because each instruction does 16x more work.
**Tool anchor:** `perf stat -e cycles,instructions,cpu/event=0xc2,umask=0x02,name=uops_retired_retire_slots/ -- ./bench`
**Drill:** Your SBE decoder reports IPC 0.6 on one workload and IPC 2.8 on another. The first decodes variable-length messages from a large symbol universe; the second decodes fixed-length heartbeat messages. Explain the likely bottleneck in each case and what follow-up measurement confirms your hypothesis.
**Tags:** IPC, superscalar, retire-width, performance-metric, first-pass

### Branch prediction fundamentals
The CPU predicts branch outcomes before they are resolved so it can keep fetching instructions speculatively. The Branch Target Buffer (BTB) caches branch target addresses, while pattern history tables (PHT) and the TAGE predictor learn taken/not-taken patterns. A misprediction costs 14-20 cycles on modern cores because the pipeline must flush speculative work and restart from the correct path. The classic sorted-vs-unsorted array benchmark demonstrates how data-dependent branches defeat prediction.
**Key concepts:** BTB, pattern history table, misprediction penalty, speculative fetch, taken/not-taken
**Tip:** Branches with ~50% taken rate are the hardest to predict; if you can restructure your SBE decoder to process message types in sorted batches rather than arrival order, the branch predictor can lock onto the pattern.
**Tool anchor:** `perf stat -e branches,branch-misses,branch-load-misses,baclears.any -- ./bench`
**Drill:** Your CME MDP 3.0 decoder has a switch statement over 40 template IDs. `perf stat` reports 12% branch misprediction rate. The message stream has a Zipf distribution where 3 templates account for 80% of traffic. Explain why the mispredict rate is high despite the skew, and propose a code change to reduce it.
**Tags:** branch-prediction, BTB, misprediction-penalty, speculative-execution, sorted-array

### Instruction latency vs throughput
Every instruction has two performance numbers: latency (cycles from input ready to output available) and throughput (maximum operations per cycle when independent). An integer add has latency 1 and throughput 4/cycle on Skylake, while a 64-bit divide has latency 35-90 cycles and throughput one every 21-42 cycles. Pipelining means independent instructions overlap, so throughput matters for parallel operations while latency matters for dependent chains.
**Key concepts:** latency, reciprocal throughput, pipelining, dependency chain, instruction-level parallelism
**Tip:** A multiply with latency 3 in a dependency chain of 100 multiplies takes 300 cycles, but 100 independent multiplies take only 100 cycles (one per cycle throughput) because the pipeline overlaps them. Breaking dependency chains is often more valuable than reducing instruction count.
**Tool anchor:** `llvm-mca -mcpu=skylake -timeline -iterations=1 -output-asm-variant=1 < loop.s`
**Drill:** You have two loop implementations: one computes `acc = acc * data[i] + coeff[i]` (chained multiply-add), the other uses four independent accumulators merged at the end. Use llvm-mca to predict the throughput of each and explain the speedup from multiple accumulators.
**Tags:** latency, throughput, pipelining, dependency-chain, instruction-tables

### x86-64 register file and calling convention
x86-64 has 16 general-purpose registers (RAX-R15), 16 SSE/AVX registers (XMM0-15, extended to YMM/ZMM), and specialized registers (RIP, RFLAGS, segment). The System V AMD64 ABI passes the first 6 integer arguments in RDI, RSI, RDX, RCX, R8, R9 and first 8 FP arguments in XMM0-7, with RAX/RCX/RDX/R8-R11 caller-saved and RBX/RBP/R12-R15 callee-saved. Understanding this is essential for reading `perf annotate` output and diagnosing register pressure.
**Key concepts:** GPRs, caller-saved, callee-saved, red zone, parameter passing, register pressure, XMM/YMM/ZMM
**Tip:** If `perf annotate` shows excessive spills to stack (`mov [rsp+X], reg`) in your hot loop, the compiler ran out of registers. Reducing live variables, breaking the function apart, or using `__attribute__((regcall))` for internal calls can eliminate the spills.
**Tool anchor:** `objdump -d -M intel ./md_handler | grep -A 50 '<decode_message>:'`
**Drill:** `perf annotate` shows your SBE decode loop spending 15% of cycles on `mov` instructions to/from `[rsp+...]` offsets. The loop body uses 18 local variables. Explain what is happening, why it costs cycles, and propose two strategies to reduce register pressure.
**Tags:** registers, calling-convention, System-V-ABI, register-pressure, spill

### The fetch-decode frontend
The frontend must deliver a steady stream of decoded uops to the backend. On Skylake, the fetch unit reads 16 bytes per cycle from the L1i cache, the predecoder identifies instruction boundaries (variable-length x86 makes this hard), and the decoder converts up to 4 instructions/cycle into uops (with one complex decoder handling multi-uop instructions). Any stall here starves the entire pipeline regardless of how fast the backend is.
**Key concepts:** 16-byte fetch window, predecode, instruction length decoding, 4-wide decode, complex decoder, fetch bubble
**Tip:** A 16-byte fetch window can hold anywhere from 1 to ~10 instructions depending on instruction length. Dense code (short instructions like `add`, `cmp`) feeds the decoder better than bloated code full of 8-byte immediates or REX prefixes.
**Tool anchor:** `perf stat -e idq.dsb_uops,idq.mite_uops,idq.ms_uops -- ./bench`
**Drill:** Your SBE decoder spends 25% of uops coming through MITE (legacy decode) instead of the DSB (uop cache). The hot loop is 40 instructions averaging 5 bytes each. Calculate whether the loop fits in the DSB and explain what could cause DSB misses for a loop this size.
**Tags:** frontend, fetch, decode, MITE, instruction-length, fetch-bandwidth

### Retirement and in-order commit
Although instructions execute out-of-order, they must retire (commit results to architectural state) in original program order to maintain precise exceptions and correct program behavior. The Reorder Buffer (ROB) tracks all in-flight instructions and retires them from the head at up to 4-8 uops/cycle (Skylake: 4, Zen 4: 6). If retirement stalls (due to a long-latency instruction at ROB head), the ROB fills and the entire pipeline backs up.
**Key concepts:** reorder buffer, in-order retirement, precise exceptions, retire width, ROB-head stall
**Tip:** A single cache-missing load at the ROB head does not stall retirement if later independent instructions have already completed; retirement stalls only when the oldest unretired instruction is still waiting. This is why OoO execution is so effective at hiding latency for independent work.
**Tool anchor:** `perf stat -e uops_retired.retire_slots,uops_issued.any,resource_stalls.rob -- ./bench`
**Drill:** `perf stat` shows `resource_stalls.rob` is 30% of cycles for your order book update function. The function processes a linked-list traversal with pointer chasing. Explain why the ROB fills up and how converting the linked list to a flat array would change the ROB utilization.
**Tags:** retirement, ROB, in-order-commit, precise-exceptions, retire-width

### Clock frequency, turbo boost, and thermal throttling
A CPU's base frequency (e.g., 2.4 GHz) is guaranteed under sustained all-core load, while turbo boost can push single-core frequency to 5.0+ GHz when thermal and power budgets allow. P-states control this dynamically, but thermal throttling can drop frequency below base under extreme heat. For benchmarking and latency-sensitive market data applications, frequency instability introduces measurement noise and unpredictable performance.
**Key concepts:** base frequency, turbo boost, P-states, thermal throttling, frequency governor, TSC vs core clock
**Tip:** Pin the CPU governor to `performance` with `cpupower frequency-set -g performance` before benchmarking; the `schedutil` governor introduces 10-50us frequency transition latencies that pollute latency measurements and can cause 20%+ variance between runs.
**Tool anchor:** `perf stat -e cycles,ref-cycles,cpu-clock -- ./bench` (compare cycles vs ref-cycles: if cycles < ref-cycles, the core ran below TSC frequency due to throttling)
**Drill:** Your SBE decoder benchmark shows 15% variance across runs. `turbostat` reveals core frequency swinging between 2.8 GHz and 4.7 GHz. Explain three steps to stabilize frequency for reproducible benchmarks and how to detect frequency throttling in a production monitoring context.
**Tags:** clock-frequency, turbo-boost, thermal-throttling, P-states, benchmarking-stability

## intermediate

### Out-of-order execution and the ROB
Out-of-order (OoO) execution lets the CPU find independent instructions to execute while waiting for slow operations (cache misses, divides) to complete. The ROB (224 entries on Skylake, 512 on Golden Cove) tracks all in-flight uops, register renaming eliminates false WAR/WAW dependencies by mapping architectural registers to a larger physical register file (~180-280 registers), and reservation stations hold uops waiting for their operands. The OoO window size determines how much latency the CPU can hide.
**Key concepts:** ROB, register renaming, reservation stations, physical register file, OoO window, WAR/WAW elimination
**Tip:** The effective OoO window is often smaller than the ROB because the scheduler (reservation station) is smaller (~97 entries on Skylake). A long-latency miss fills the scheduler first, stalling dispatch before the ROB is full.
**Tool anchor:** `perf stat -e resource_stalls.any,resource_stalls.rob,resource_stalls.rs -- ./bench`
**Drill:** Your pointer-chasing hash-map lookup has a critical path of load -> use -> load -> use with L3 latency (~40 cycles per load). If the ROB has 224 entries and your loop body is 20 uops, how many iterations can be in-flight simultaneously? How does this change with Golden Cove's 512-entry ROB?
**Tags:** out-of-order, ROB, register-renaming, reservation-station, OoO-window

### uop cache (DSB) and decode bottlenecks
The Decoded Stream Buffer (DSB) is a ~1500-2000 uop cache that stores already-decoded uops, bypassing the slow MITE legacy decode path on subsequent executions. DSB hits deliver up to 6 uops/cycle (vs 4-5 from MITE). DSB thrashing occurs when the working set of hot code exceeds DSB capacity (32 sets x 8 ways, mapped by instruction address), and instruction alignment within 32-byte regions affects DSB utilization since each DSB set maps to a 32-byte aligned code region.
**Key concepts:** DSB (uop cache), MITE (legacy decode), DSB capacity, 32-byte alignment, DSB thrashing, IDQ
**Tip:** After the Intel JCC erratum microcode update, conditional branches that cross or end on a 32-byte boundary cannot be cached in the DSB, forcing MITE decode. Use `-Wa,-mbranches-within-32B-boundaries` with GCC/Clang to avoid this penalty.
**Tool anchor:** `perf stat -e idq.dsb_uops,idq.mite_uops,idq.dsb_cycles,frontend_retired.dsb_miss -- ./bench`
**Drill:** After adding detailed logging to your SBE decoder, `perf stat` shows `idq.mite_uops` jumped from 5% to 40% of total uops. Code size increased from 12KB to 48KB in the hot path. Diagnose the bottleneck, explain the DSB capacity math, and propose a fix that does not remove the logging.
**Tags:** DSB, uop-cache, MITE, decode-bottleneck, JCC-erratum, 32-byte-alignment

### TMA Level 1: the four buckets
Intel's Top-down Microarchitecture Analysis splits every pipeline slot into exactly one of four categories: Frontend Bound (slots wasted because the frontend did not deliver uops), Backend Bound (slots wasted because the backend could not accept uops), Bad Speculation (slots used by uops that were ultimately discarded due to misprediction or machine clear), and Retiring (slots used by uops that successfully committed). These four must sum to 100%, giving a definitive first-pass bottleneck classification.
**Key concepts:** pipeline slots, Frontend Bound, Backend Bound, Bad Speculation, Retiring, slot utilization
**Tip:** Retiring above 50% does not mean "no bottleneck": if IPC is still low, it means the instructions themselves are inefficient (e.g., scalar code that should be vectorized). High Retiring with low IPC calls for algorithmic or SIMD optimization, not microarchitectural tuning.
**Tool anchor:** `perf stat -M TopdownL1 -- ./bench` (or `perf stat --topdown -- ./bench` on perf < 5.8)
**Drill:** TMA Level 1 for two versions of your CME decoder: v1 shows {Frontend: 8%, Backend: 60%, Bad Spec: 7%, Retiring: 25%}; v2 after optimization shows {Frontend: 25%, Backend: 15%, Bad Spec: 5%, Retiring: 55%}. Explain what the optimization likely fixed, why Frontend Bound increased, and whether v2 needs further work.
**Tags:** TMA, TopdownL1, Frontend-Bound, Backend-Bound, Bad-Speculation, Retiring

### SIMD execution units and port pressure
Modern CPUs have 6-8 execution ports, each connected to specific functional units. On Skylake, ports 0/1/5 handle vector ALU, port 0 handles FP divides, ports 2/3 handle loads, port 4 handles stores, and port 7 handles simple store address calculation. When multiple instructions compete for the same port, port contention limits throughput even if other ports are idle. AVX-512 further complicates this because heavy 512-bit operations may shut down port 1 vector execution.
**Key concepts:** execution ports, port contention, functional units, AVX-512 port restrictions, port binding
**Tip:** On Skylake, `vpand` (bitwise AND) can run on ports 0, 1, or 5, but `vpmullw` (16-bit multiply) only runs on ports 0 and 1 (it cannot use port 5). If your SBE decoder interleaves AND and MULTIPLY operations, the multiplies become the bottleneck because they are restricted to the two p0/p1 vector multiply units.
**Tool anchor:** `perf stat -e uops_dispatched_port.port_0,uops_dispatched_port.port_1,uops_dispatched_port.port_2,uops_dispatched_port.port_3,uops_dispatched_port.port_5 -- ./bench`
**Drill:** `perf stat` shows port 0 at 95% utilization while ports 1 and 5 are at 30%. Your hot loop contains SIMD shift, multiply, and add operations. Use llvm-mca or Intel intrinsics guide to determine which instructions are port-0-only and propose instruction substitutions to balance port pressure.
**Tags:** execution-ports, port-contention, SIMD, AVX-512, functional-units, Skylake

### Macro-fusion and micro-fusion
Macro-fusion merges two adjacent instructions (typically CMP/TEST + Jcc) into a single uop, effectively increasing decode and issue bandwidth for free. Micro-fusion combines a memory operand with an ALU operation (e.g., `add rax, [rbx]`) into a single uop at the frontend, though it may "unfuse" into two uops at the scheduler on some microarchitectures. Fusion failures due to RIP-relative addressing or unsupported instruction combinations leave performance on the table.
**Key concepts:** macro-fusion, micro-fusion, CMP+Jcc fusion, unfusion, decode bandwidth, addressing modes
**Tip:** Micro-fused indexed addressing modes (`add rax, [rbx+rcx*8]`) unfuse into two uops at the rename stage on Haswell+, consuming extra scheduler entries. Base+displacement addressing (`add rax, [rbx+8]`) stays fused. This matters in tight loops where scheduler capacity is the bottleneck.
**Tool anchor:** `llvm-mca -mcpu=skylake -resource-pressure -bottleneck-analysis -output-asm-variant=1 < loop.s`
**Drill:** Two versions of an inner loop: v1 uses `cmp eax, [rbx+rcx*8]` followed by `jl .loop`, v2 uses `cmp eax, edx` followed by `jl .loop` with a separate `mov edx, [rbx+rcx*8]`. Analyze with llvm-mca: which has fewer uops? Which has better throughput? Explain the micro-fusion and macro-fusion behavior in each.
**Tags:** macro-fusion, micro-fusion, CMP-Jcc, unfusion, addressing-modes, decode-bandwidth

### Loop buffer and loop stream detector
The Loop Stream Detector (LSD) detects small loops (up to ~64 uops on Skylake) that fit entirely in the IDQ and replays them without re-fetching or re-decoding, saving frontend power and bandwidth. When active, the loop is served from a locked-down queue. However, the LSD was disabled via microcode update on some Skylake/Kaby Lake steppings due to an erratum, and nested loops or loops with branches that exit frequently may not engage the LSD.
**Key concepts:** LSD, IDQ replay, loop detection, LSD engagement criteria, microcode disable, lockstep replay
**Tip:** Check if your CPU's LSD is active with `perf stat -e lsd.uops,lsd.cycles_active`: if both are zero, the LSD was likely disabled by microcode. On these CPUs, the DSB serves small loops instead, which is still fast but burns slightly more power.
**Tool anchor:** `perf stat -e lsd.uops,lsd.cycles_active,idq.dsb_uops,idq.mite_uops -- ./bench`
**Drill:** Your SBE decode loop is 48 uops. On server A (Skylake, microcode 0xCC), `lsd.uops` shows 0. On server B (Ice Lake), `lsd.uops` accounts for 90% of delivered uops. Explain the discrepancy, determine whether it causes a measurable performance difference, and describe what measurement would show it.
**Tags:** LSD, loop-buffer, IDQ, loop-detection, microcode-erratum

### Branch prediction advanced
Beyond simple taken/not-taken prediction, modern CPUs have specialized predictors: the indirect branch predictor (for virtual function calls and switch statements), the Return Stack Buffer (RSB, 16-32 entries) for call/return pairs, the loop predictor that detects fixed iteration counts, and the TAGE predictor that uses multiple history lengths to capture complex patterns. Understanding which predictor handles which branch type reveals why some patterns are inherently hard to predict.
**Key concepts:** indirect branch predictor, RSB, loop predictor, TAGE, history length, predictor capacity
**Tip:** Deep call stacks (>16-32 levels) overflow the RSB, causing return mispredictions. If your SBE decoder uses deeply nested template recursion (common in C++ codec generators), flattening the call structure eliminates RSB overflows.
**Tool anchor:** `perf stat -e branch-misses,br_misp_retired.all_branches,br_misp_retired.near_call,br_misp_retired.near_return -- ./bench`
**Drill:** Your CME MDP 3.0 decoder uses virtual dispatch (`virtual void decode()`) for 40 message types. `perf stat` shows `br_misp_retired.near_call` is 8% of all branch misses. The message stream alternates between 5 types unpredictably. Explain why the indirect branch predictor struggles and propose two alternative dispatch mechanisms with better prediction behavior.
**Tags:** branch-prediction, indirect-branch, RSB, TAGE, loop-predictor, virtual-dispatch

### Speculative execution and its performance cost
The CPU speculatively executes past unresolved branches, pending loads, and even store-to-load forwarding. When speculation is correct, it hides latency. When wrong, the CPU must squash all speculative work, flush the pipeline, and re-steer the frontend. The Branch Order Buffer (BOB) saves architectural checkpoints to enable fast recovery. Speculation depth (how far ahead the CPU runs) is limited by ROB size and resource availability, and deeper speculation increases the cost of each mispredict.
**Key concepts:** speculative execution, branch order buffer, pipeline squash, speculation depth, re-steer cost, Spectre
**Tip:** Spectre mitigations (retpolines, IBRS) deliberately cripple speculation on indirect branches. If your post-mitigation workload shows 15-30% regression, the cost is not the mitigation instructions themselves but the lost speculation window that previously hid latency.
**Tool anchor:** `perf stat -e baclears.any,machine_clears.count,int_misc.recovery_cycles -- ./bench`
**Drill:** `perf stat` shows `int_misc.recovery_cycles` at 25% of total cycles for your feed handler's message dispatch loop. `branch-misses` is at 3%, which seems low. Explain how 3% misprediction can consume 25% of cycles (hint: consider the pipeline depth and the number of instructions squashed per mispredict). Calculate the average squash cost.
**Tags:** speculative-execution, squash, recovery-cycles, speculation-depth, Spectre, BOB

### Execution port scheduling
The scheduler (reservation station) dispatches uops to execution ports based on port availability, operand readiness, and age. On Skylake, the 97-entry scheduler must decide which port to assign uops to, and suboptimal scheduling (e.g., always picking port 0 when port 1 is equally valid) can cause artificial port contention. The scheduler generally uses oldest-ready-first policy. Alder Lake's hybrid architecture adds complexity with different port configurations on P-cores vs E-cores.
**Key concepts:** scheduler, reservation station, port assignment, oldest-ready-first, P-core vs E-core, scheduling latency
**Tip:** The scheduler does not look ahead to balance port pressure globally; it assigns ports greedily at dispatch time. This means instruction ordering in the binary can affect port utilization: reordering independent instructions to alternate between port-0-only and port-1-only operations can improve throughput by 10-15%.
**Tool anchor:** `perf stat -e uops_dispatched_port.port_0,uops_dispatched_port.port_1,uops_dispatched_port.port_5,uops_dispatched_port.port_6,resource_stalls.rs -- ./bench`
**Drill:** llvm-mca reports your loop is port-5-bound at 1.5 cycles/iteration, but `perf stat` on real hardware shows 1.2 cycles/iteration. Explain why real hardware can beat llvm-mca's prediction (hint: consider scheduler optimism vs pessimism and port randomization). When would real hardware be slower than llvm-mca predicts?
**Tags:** scheduler, reservation-station, port-scheduling, P-core, E-core, oldest-ready-first

### Frontend bandwidth vs latency bottlenecks
Frontend problems fall into two categories: bandwidth (the frontend delivers uops but too slowly, limiting throughput) and latency (the frontend stalls completely for multiple cycles, creating bubbles). Bandwidth bottlenecks arise from MITE decode width limits (4 uops/cycle) or code density; latency bottlenecks arise from L1i misses, iTLB misses, or DSB-to-MITE switching penalties. TMA Level 2 Frontend Bound splits into Fetch Latency (L1i/iTLB misses) and Fetch Bandwidth (decode width issues).
**Key concepts:** fetch latency, fetch bandwidth, L1i miss, iTLB miss, DSB-MITE switch, frontend bubbles
**Tip:** A DSB-to-MITE switch costs ~2-3 cycles of pipeline bubble. If your hot path crosses a DSB set boundary frequently (e.g., a function called from many sites that does not fit in one 32-byte region), code alignment or PGO-based layout can eliminate these switches.
**Tool anchor:** `perf stat -e frontend_retired.dsb_miss,frontend_retired.itlb_miss,frontend_retired.l1i_miss,idq.all_dsb_cycles_any_uops,idq.all_mite_cycles_any_uops -- ./bench`
**Drill:** TMA shows Frontend Bound at 30%, with Level 2 split as Fetch Latency 22%, Fetch Bandwidth 8%. Your binary is 15MB with many template instantiations. Identify the most likely cause of the fetch latency issue, explain why large C++ binaries are particularly susceptible, and propose a build-system fix.
**Tags:** frontend-bandwidth, frontend-latency, L1i, iTLB, DSB-MITE-switch, code-layout

### Integer vs floating-point pipeline
Integer and floating-point operations use different execution units with different latency/throughput characteristics. Integer multiply is 3 cycles on Skylake, integer divide is 20-90 cycles and not fully pipelined. FP add/multiply are 4 cycles latency with 0.5 cycle throughput (2 per cycle), but FP divide is 11-14 cycles with 4-cycle throughput. The x87 FPU (80-bit extended precision) still exists but is slower and has limited register access compared to scalar SSE/AVX.
**Key concepts:** INT vs FP latency, FP divider, pipelined vs non-pipelined, x87, SSE scalar, AVX scalar, divide throughput
**Tip:** If your SBE decoder converts fixed-point price fields to double using division, replace the division with multiplication by a precomputed reciprocal: FP multiply throughput is 2/cycle vs FP divide throughput of one every 4 cycles on Skylake.
**Tool anchor:** `perf stat -e arith.divider_active,fp_arith_inst_retired.scalar_double,fp_arith_inst_retired.scalar_single -- ./bench`
**Drill:** Your CME MDP 3.0 decoder converts 8-digit implied-decimal prices to doubles. The current code uses `price_double = mantissa / pow(10.0, exponent)`. `perf stat` shows `arith.divider_active` at 40% of cycles. Rewrite the conversion to avoid division and predict the speedup using instruction latency tables.
**Tags:** integer-pipeline, floating-point, divider, x87, SSE, reciprocal-multiply

### Instruction cache (L1i) and iTLB pressure
The L1 instruction cache (32KB, 8-way, 64B lines) and instruction TLB (128 entries for 4KB pages on Skylake) serve the frontend fetch unit. Large code footprints from C++ template bloat, heavy inlining, or link-time code layout can exceed L1i capacity and iTLB reach (128 * 4KB = 512KB of code), causing frontend stalls that show up as Fetch Latency in TMA. PGO and BOLT can reorganize code layout to pack hot code together.
**Key concepts:** L1i cache, iTLB, code footprint, template bloat, PGO, BOLT, huge pages for code
**Tip:** Map your hot code to 2MB huge pages using `-z max-page-size=0x200000` at link time or `madvise(MADV_HUGEPAGE)` on the text segment. This reduces iTLB pressure from 128 entries * 4KB = 512KB reach to 128 entries * 2MB = 256MB reach, effectively eliminating iTLB misses for most binaries.
**Tool anchor:** `perf stat -e L1-icache-load-misses,iTLB-load-misses,frontend_retired.l1i_miss,frontend_retired.itlb_miss -- ./bench`
**Drill:** Your market data platform binary is 80MB after aggressive template instantiation for SBE codecs. `perf stat` shows 5M iTLB-load-misses/sec and L1i miss rate of 8%. Calculate the iTLB reach with 4KB pages, explain why 80MB of code does not fit, and compare the cost of three mitigations: PGO, BOLT, and huge pages.
**Tags:** L1i, iTLB, code-footprint, template-bloat, PGO, BOLT, huge-pages

## advanced

### TMA Level 2-3: drilling into bottleneck categories
TMA Level 2 splits Backend Bound into Memory Bound and Core Bound, and splits Frontend Bound into Fetch Latency and Fetch Bandwidth. Level 3 further decomposes Memory Bound into L1 Bound, L2 Bound, L3 Bound, DRAM Bound, and Store Bound; Core Bound into Divider and Ports Utilization. Each leaf node maps to specific PMC events and has concrete optimization strategies. Interpreting these requires understanding that nodes represent slots wasted at each level of the memory hierarchy or execution unit.
**Key concepts:** Memory Bound, Core Bound, L1/L2/L3/DRAM Bound, Store Bound, Divider, Ports Utilization
**Tip:** DRAM Bound above 20% with high L3 miss rate almost always means your working set exceeds L3. But check Store Bound too: a write-heavy workload can appear DRAM Bound when the real issue is store buffer saturation from non-temporal stores or excessive dirty cache-line evictions.
**Tool anchor:** `toplev.py -l3 --no-desc --nodes='!+MicroSequencer,+Divider,+Ports_Utilization,+L1_Bound,+L2_Bound,+L3_Bound,+DRAM_Bound,+Store_Bound' -- ./bench`
**Drill:** toplev Level 3 for your order book shows: L1_Bound 5%, L2_Bound 8%, L3_Bound 30%, DRAM_Bound 25%, Store_Bound 2%. The order book is a B-tree with 2M price levels. Explain which level of cache hierarchy limits performance, estimate the working set size from the L3/DRAM ratio, and propose a structural change to shift the balance toward L2/L1.
**Tags:** TMA, Level2, Level3, Memory-Bound, Core-Bound, DRAM-Bound, Store-Bound

### SMT (Hyperthreading) resource contention
Simultaneous Multithreading (SMT/Hyperthreading) shares most microarchitectural resources between two logical cores: the L1i cache, DSB, execution ports, and L1d/L2 caches are shared, while the ROB and some scheduler resources are partitioned (statically or dynamically). SMT helps when one thread is stalled (freeing resources for the other), but hurts when both threads compete for the same bottleneck resource. For latency-sensitive market data paths, HT siblings on the same core can add 20-30% noise.
**Key concepts:** logical core, physical core, resource sharing, ROB partitioning, cache contention, jitter
**Tip:** For your latency-sensitive feed handler, disable the HT sibling of the pinned core using `echo 0 > /sys/devices/system/cpu/cpuN/online` where N is the sibling. This gives your thread the full ROB (224 entries instead of ~112) and eliminates L1d cache contention, typically reducing p99 tail latency by 15-30%.
**Tool anchor:** `perf stat -e topdown-retiring,topdown-be-bound,topdown-fe-bound,topdown-bad-spec -C 3 -- sleep 10` (run with and without HT sibling active to see TMA shift)
**Drill:** Your SBE decoder pinned to core 3 shows IPC 2.1 with HT sibling idle. When a logging thread is placed on the HT sibling, IPC drops to 1.4. `perf stat` shows L1d cache misses doubled and `resource_stalls.any` tripled. Identify which shared resources are contended, explain the IPC drop mechanism, and recommend a core assignment strategy.
**Tags:** SMT, Hyperthreading, resource-sharing, ROB-partitioning, cache-contention, tail-latency

### ILP and critical path analysis
Instruction-Level Parallelism (ILP) is the amount of independent work the OoO engine can find and overlap. The critical path through a computation is the longest chain of dependent instructions; it sets the minimum execution time regardless of the number of execution units. Analyzing the critical path requires building a data dependency graph and finding the longest weighted path (weighted by instruction latency). Loop-carried dependencies are especially important because they limit ILP across iterations.
**Key concepts:** ILP, critical path, data dependency graph, loop-carried dependency, independent chains, accumulator splitting
**Tip:** A single loop-carried dependency of latency 4 (e.g., FP add into the next iteration's accumulator) limits throughput to 1 iteration per 4 cycles regardless of loop body size. Splitting into 4 independent accumulators achieves 4x throughput by breaking the loop-carried chain.
**Tool anchor:** `llvm-mca -mcpu=skylake -timeline -bottleneck-analysis -iterations=100 -output-asm-variant=1 < hot_loop.s`
**Drill:** Your SBE decoder's hot loop computes a running CRC32: `crc = _mm_crc32_u64(crc, data[i])`. CRC32 has latency 3 on Skylake. The loop body is 5 uops. Calculate the critical path length, the achieved throughput in iterations/cycle, and design a 3-way interleaved CRC computation that processes 3 independent message chunks to achieve 3x throughput.
**Tags:** ILP, critical-path, loop-carried-dependency, accumulator-splitting, dependency-graph

### Machine clears and their causes
A machine clear flushes the entire pipeline (like a branch mispredict but more expensive) when the CPU detects that speculative execution violated a correctness constraint. Common causes: memory ordering violations (a load speculatively forwarded a value that a later store invalidated), FP assists (denormal numbers requiring microcode), self-modifying code (store to an address in the instruction stream), and memory disambiguation failures. Machine clears are invisible in branch-miss counters but show up in TMA Bad Speculation.
**Key concepts:** machine clear, memory ordering clear, FP assist, SMC detection, disambiguation, pipeline nuke
**Tip:** If TMA shows high Bad Speculation but branch misses are low, machine clears are the likely culprit. Check `perf stat -e machine_clears.count,machine_clears.memory_ordering`: memory ordering clears often indicate false sharing or a producer-consumer pattern where one core stores and another core loads the same cache line with unfortunate timing.
**Tool anchor:** `perf stat -e machine_clears.count,machine_clears.memory_ordering,machine_clears.smc,assists.any -- ./bench`
**Drill:** Your multi-threaded market data system shows TMA Bad Speculation at 18% but branch misses at only 1%. `machine_clears.memory_ordering` is 500K/sec. The hot path has a shared `std::atomic<uint64_t> sequence_number` read by consumer threads. Explain the memory ordering clear mechanism, why atomics can trigger it, and propose a redesign using a single-producer pattern.
**Tags:** machine-clear, memory-ordering, FP-assist, SMC, pipeline-flush, Bad-Speculation

### Microcode assists and performance penalties
Certain operations cannot be handled by the hardware execution units and fall back to microcode ROM sequences called assists. Common triggers: denormalized floating-point numbers (DAZ/FTZ flags not set), x87 operations on modern pipelines, page table updates (accessed/dirty bit assists), and complex instructions like CPUID or RDTSC. Each assist traps to microcode, serializes the pipeline, and can cost hundreds of cycles.
**Key concepts:** microcode assist, denormal FP, DAZ/FTZ, page walk assist, A/D bit, serializing instruction
**Tip:** Add `-ffast-math` or manually set DAZ/FTZ flags (`_mm_setcsr(_mm_getcsr() | 0x8040)`) in your SBE decoder's initialization to flush denormals to zero. A single denormal value in a price calculation can trigger an assist costing ~160 cycles, turning a 4-cycle FP multiply into a 164-cycle stall.
**Tool anchor:** `perf stat -e assists.any,fp_assist.any,machine_clears.count,idq.ms_uops -- ./bench`
**Drill:** After a market event, your price normalization function slows down 40x for certain instruments. `perf stat` shows `fp_assist.any` skyrocketed to 2M/sec. The affected instruments have prices near 1e-308. Explain the denormal assist mechanism, calculate the per-assist cost from the throughput drop, and implement the DAZ/FTZ fix.
**Tags:** microcode-assist, denormal, DAZ-FTZ, page-walk, serializing, fp-assist

### AVX-512 frequency throttling and license levels
Intel CPUs implement three AVX frequency license levels: L0 (no throttle, basic SSE/AVX-128), L1 (light throttle, AVX-256 heavy/AVX-512 light), and L2 (heavy throttle, AVX-512 heavy operations like FP multiply). Transitioning from L0 to L2 can drop core frequency by 200-600 MHz with a transition latency of ~20,000 cycles (~6-8us). For market data applications with sporadic AVX-512 usage, the frequency recovery time after AVX-512 instructions may negate the SIMD throughput benefit.
**Key concepts:** L0/L1/L2 license, frequency throttling, voltage transition, vzeroupper, steady-state penalty, warm-up cost
**Tip:** A single AVX-512 instruction in a rarely-executed error path can throttle the entire core for ~670us (2 million cycles recovery time on Skylake-SP). Isolate AVX-512 code to functions called only in bulk processing paths, and always emit `vzeroupper` before returning to scalar code.
**Tool anchor:** `perf stat -e core_power.lvl0_turbo_license,core_power.lvl1_turbo_license,core_power.lvl2_turbo_license -- ./bench` (available on Skylake-SP and later server parts)
**Drill:** Your SBE decoder uses AVX-512 for bulk message parsing but falls back to scalar for single-message decoding. After processing a burst of 1000 messages with AVX-512, the next scalar message takes 15us instead of the usual 3us. Explain the frequency throttling mechanism, calculate the recovery penalty, and design a strategy that uses AVX-512 only when batch size exceeds a break-even threshold.
**Tags:** AVX-512, frequency-throttling, license-levels, vzeroupper, voltage-transition

### Branch misprediction recovery mechanics
When a branch mispredicts, the CPU must: (1) detect the mispredict when the branch executes and compares the prediction, (2) flush all younger uops from the pipeline using the Branch Order Buffer (BOB) checkpoint, (3) restore the register rename table to the checkpoint state, (4) re-steer the frontend to the correct path. The total recovery latency depends on pipeline depth and the number of in-flight uops that must be squashed. Newer architectures (Golden Cove) implement faster recovery by overlapping re-steer with flush.
**Key concepts:** mispredict detection, BOB checkpoint, rename table restoration, frontend re-steer, recovery latency, fast recovery
**Tip:** The recovery cost is not fixed: a mispredict detected early in the pipeline (few uops to squash) recovers faster than one detected late (ROB nearly full of speculative work). This means frequently-mispredicted branches near the beginning of a long straight-line sequence are more costly than those near the end.
**Tool anchor:** `perf stat -e int_misc.recovery_cycles,int_misc.clear_resteer_cycles,baclears.any,br_misp_retired.all_branches -- ./bench`
**Drill:** Two functions have identical 5% branch mispredict rates. Function A has 10 uops between branches; function B has 200 uops between branches. `perf stat` shows function B spends 3x more cycles in `int_misc.recovery_cycles`. Explain why misprediction cost scales with inter-branch distance, calculate the approximate squash cost per mispredict for each, and determine which function benefits more from branch optimization.
**Tags:** misprediction-recovery, BOB, pipeline-flush, re-steer, recovery-latency, fast-recovery

### ROB/RS sizing and back-pressure
The ROB and Reservation Station (RS) are the two main OoO engine queues, and either can become the bottleneck. ROB-full stalls occur when too many instructions are in-flight (typically due to long-latency cache misses at the ROB head). RS-full stalls occur when too many uops are waiting for operands (typically due to many independent instructions all waiting for the same long-latency result). Since the RS (97 entries on Skylake) is much smaller than the ROB (224 entries), RS pressure often limits effective OoO window before the ROB does.
**Key concepts:** ROB-full stall, RS-full stall, back-pressure, effective OoO window, queue sizing, resource_stalls
**Tip:** If `resource_stalls.rs` is high but `resource_stalls.rob` is low, the CPU found plenty of independent work to issue (filling the RS) but the work all depends on slow results. This is the signature of a gather pattern: many independent loads to unpredictable addresses all missing cache simultaneously.
**Tool anchor:** `perf stat -e resource_stalls.rob,resource_stalls.rs,resource_stalls.any,resource_stalls.sb -- ./bench`
**Drill:** Your order book lookup function shows `resource_stalls.rs` at 35% of cycles and `resource_stalls.rob` at 2%. The function issues 8 independent hash-map probes per update. Explain why the RS fills before the ROB, calculate how many cache-missing loads can be in-flight simultaneously given the RS size, and propose a software prefetching strategy.
**Tags:** ROB, reservation-station, back-pressure, resource-stalls, OoO-window, gather-pattern

### Comparing Intel vs AMD microarchitectures
Intel (Golden Cove/Raptor Cove) and AMD (Zen 4/Zen 5) differ in key structural parameters: decode width (6 vs 4), ROB size (512 vs 320), scheduler entries (different partitioning), cache hierarchy (Intel: 1.25MB L2, AMD: 1MB L2 with different associativity), and PMC event naming. Code optimized for one may bottleneck differently on the other. AMD's separate INT and FP scheduler vs Intel's unified RS, and Intel's larger L1d (Golden Cove 48KB vs Zen 4 32KB) affect optimization priorities.
**Key concepts:** Zen 4/5, Golden Cove, decode width, ROB size, cache sizes, PMC event names, structural differences
**Tip:** AMD Zen 4 has a 32-entry return address stack vs Intel's 16-entry RSB. If your workload has deep call stacks (16-32 levels), it will mispredict returns on Intel but not AMD. Profile on both architectures before concluding a branch prediction problem is fundamental vs architectural.
**Tool anchor:** `perf stat -e ex_ret_brn_misp,ex_ret_brn,ls_dispatch.ld_dispatch,ls_dispatch.store_dispatch -- ./bench` (AMD PMC events; compare with Intel equivalents `br_misp_retired.all_branches,br_inst_retired.all_branches,mem_inst_retired.all_loads,mem_inst_retired.all_stores`)
**Drill:** Your SBE decoder achieves IPC 2.8 on AMD Zen 4 but only IPC 1.9 on Intel Alder Lake for the same binary. TMA on Intel shows 25% Frontend Bound (Fetch Bandwidth). AMD has 4-wide decode + op cache vs Intel's 6-wide decode + DSB. Explain the apparent paradox (AMD is narrower but faster), identify the Intel-specific bottleneck, and propose a fix that helps Intel without hurting AMD.
**Tags:** Intel-vs-AMD, Zen4, Golden-Cove, PMC-naming, cross-architecture, structural-comparison

### Using llvm-mca for static analysis
LLVM Machine Code Analyzer (llvm-mca) simulates instruction execution on a modeled CPU pipeline, providing throughput estimates, resource pressure analysis, timeline views of instruction flow, and bottleneck identification without running any code. It models dispatch, execution, and retirement but does not model caches, branch prediction, or memory. This makes it ideal for analyzing tight computational loops where cache behavior is known (everything in L1) but uarch behavior is not.
**Key concepts:** static analysis, throughput simulation, resource pressure, timeline view, bottleneck report, model limitations
**Tip:** llvm-mca's bottleneck analysis (`-bottleneck-analysis`) tells you whether your loop is latency-bound (critical path through dependencies) or throughput-bound (port pressure). If it says "throughput bottleneck," check the resource pressure view to find the saturated port; if "latency bottleneck," look at the timeline for the longest dependency chain.
**Tool anchor:** `printf '.intel_syntax noprefix\n.loop:\nvmulps ymm2, ymm0, ymm1\nvaddps ymm3, ymm3, ymm2\ndec ecx\njnz .loop\n' | llvm-mca -mcpu=skylake -timeline -bottleneck-analysis -resource-pressure -iterations=100 -output-asm-variant=1`
**Drill:** Extract the hot loop from your SBE decoder's field parsing function using `objdump -d`, isolate it into a .s file, and run llvm-mca with `-mcpu=skylake -timeline -bottleneck-analysis`. The report shows throughput of 2.5 cycles/iteration but your actual measurement shows 8 cycles/iteration. List three reasons the static analysis underestimates the real cost and describe how to close the gap in your analysis.
**Tags:** llvm-mca, static-analysis, throughput, resource-pressure, timeline, bottleneck-analysis
