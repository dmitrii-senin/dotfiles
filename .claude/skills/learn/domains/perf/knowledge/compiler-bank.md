# Compiler & Codegen Topic Bank
Updated: 2026-05-28

## beginner

### Reading x86 disassembly: essential instructions
The x86-64 ISA is large, but a small subset dominates compiler output: mov (data transfer), lea (address arithmetic without memory access), add/sub/imul (integer math), cmp/test (flag-setting for branches), jcc (conditional jumps like je/jne/jl/jge), and call/ret (function invocation). Understanding AT&T syntax (source, destination) versus Intel syntax (destination, source) prevents constant confusion when switching between GCC default output and tools like Godbolt or perf annotate.
**Key concepts:** mov, lea, add/sub/imul, cmp/test, jcc, call/ret, AT&T vs Intel syntax
**Tip:** `lea` is often used for pure arithmetic (e.g., `lea rax, [rdi + rdi*2]` computes `rdi * 3`) with no memory access at all; mistaking it for a load is the most common disassembly misread.
**Tool anchor:** `objdump -d -M intel --no-show-raw-insn ./md_decoder | less`
**Drill:** Given a disassembly snippet with 8 instructions from an SBE field decoder, identify each instruction's purpose, determine whether any memory accesses occur, and rewrite the sequence in pseudocode.
**Tags:** x86, disassembly, assembly, instruction-set

### Optimization levels: -O0 through -O3 and -Os
GCC and Clang define optimization levels that enable progressively more aggressive transformations: -O0 (no optimization, debuggable), -O1 (basic without speed/size tradeoffs), -O2 (standard production level enabling inlining, vectorization, scheduling), -O3 (adds aggressive loop transformations and function cloning that can increase code size and occasionally slow down due to I-cache pressure), and -Os (optimizes for size, often faster than -O2 for cache-constrained workloads). -Ofast enables -ffast-math which breaks IEEE 754 compliance and can silently produce wrong results.
**Key concepts:** -O0, -O1, -O2, -O3, -Os, -Ofast, -ffast-math, I-cache pressure
**Tip:** -O3 is not always faster than -O2; the extra loop unrolling and function cloning can bloat the instruction footprint enough to cause I-cache misses that erase the gains, especially in large binaries.
**Tool anchor:** `for opt in O0 O1 O2 O3 Os; do echo "=== -$opt ===" && g++ -$opt -S -o /dev/stdout decoder.cpp | grep -c '^[[:space:]]*\.' ; done`
**Drill:** Compile your SBE message decoder at -O2 and -O3, measure code size with `size`, and benchmark both. If -O3 is slower, identify which pass caused the regression using `-fopt-info-all`.
**Tags:** optimization-levels, O2, O3, Os, Ofast

### Inlining decisions and attributes
The compiler inlines functions when the callee is small enough (typically a few dozen of GCC's internal pseudo-instructions for the auto-inline default — `max-inline-insns-auto`, ~30 in GCC 8+ and lower still in current releases, vs ~70 for explicitly-`inline` functions via `max-inline-insns-single`; `gcc -Q --help=params` prints your version's value) and the call site is hot enough to justify the code-size increase. `__attribute__((always_inline))` forces inlining regardless of cost, useful for tiny hot-path helpers like SBE field accessors. `__attribute__((noinline))` prevents inlining, essential for keeping cold error-handling paths from bloating hot functions. The `-finline-limit=N` flag adjusts the threshold globally.
**Key concepts:** inline threshold, always_inline, noinline, code size vs speed tradeoff, -finline-limit
**Tip:** Forcing `always_inline` on a function larger than ~50 instructions usually hurts performance by inflating the caller's instruction footprint; reserve it for trivial accessors and wrappers.
**Tool anchor:** `g++ -O2 -Rpass=inline -Rpass-missed=inline -c decoder.cpp 2>&1 | head -40`
**Drill:** Your SBE field accessor is not being inlined at -O2 in a hot loop. Use `-Rpass-missed=inline` to confirm, then apply `always_inline` and compare the generated assembly in Godbolt to verify the call was eliminated.
**Tags:** inlining, always_inline, noinline, code-size, threshold

### Compiler Explorer (Godbolt): effective usage
Compiler Explorer (godbolt.org) compiles code across hundreds of compiler versions and shows the assembly side-by-side with source coloring. Effective use includes: comparing GCC vs Clang output for the same function, toggling optimization levels to see which passes fire, using the "diff" view to compare two compilations, filtering out directives with the `-` button, and adding multiple compiler panes for A/B comparison. The "opt pipeline" viewer shows which LLVM passes ran.
**Key concepts:** source-assembly coloring, compiler comparison, diff view, directive filtering, opt pipeline
**Tip:** Add `static` to your function in Godbolt to prevent the compiler from keeping a callable version alongside the inlined one; otherwise you see duplicate codegen that clutters the output.
**Tool anchor:** `https://godbolt.org/ — use "Add new > Compiler" for side-by-side; pass -O2 -march=haswell -std=c++20`
**Drill:** Take a 10-line SBE field extraction function into Godbolt. Compare GCC 14 vs Clang 18 at -O2 with -march=haswell. Identify which compiler produces fewer instructions and whether either auto-vectorized the loop.
**Tags:** godbolt, compiler-explorer, comparison, visualization

### Debug info and frame pointers for profiling
Profiling tools need two things to produce useful output: debug info (-g) for mapping addresses to source lines, and reliable stack unwinding for call graphs. On x86-64, GCC defaults to `-fomit-frame-pointer`, which breaks frame-pointer-based stack walking. The fix is either `-fno-omit-frame-pointer` (adds ~1-2% overhead but enables fast FP-based unwinding) or using DWARF unwinding (`perf record --call-graph dwarf`, higher overhead). Without these, `perf report` shows `[unknown]` frames.
**Key concepts:** -g, -fno-omit-frame-pointer, DWARF, frame-pointer unwinding, -gdwarf-4
**Tip:** Compile production binaries with `-g -fno-omit-frame-pointer` and strip debug info into a separate file; you get zero-cost symbols via `perf --symfs` without shipping debug info in the binary.
**Tool anchor:** `g++ -O2 -g -fno-omit-frame-pointer -o md_decoder decoder.cpp && perf record --call-graph fp -p $(pgrep md_decoder) -- sleep 10`
**Drill:** You profile your feed handler and `perf report` shows `[unknown]` in 60% of stack frames. Diagnose whether the issue is missing debug info, missing frame pointers, or both. Fix the build flags and re-profile to get clean stacks.
**Tags:** debug-info, frame-pointer, DWARF, perf, profiling

### Understanding compiler warnings for performance
Beyond catching bugs, specific compiler warnings flag performance-relevant issues: `-Wconversion` catches implicit narrowing that may indicate unintended type promotion loops, `-Wsign-compare` flags mixed signed/unsigned comparisons that prevent vectorization, `-Wpadded` reveals struct padding waste, and `-Wdisabled-optimization` tells you when a function is too complex for the optimizer. Using `-Wall -Wextra` is the minimum; `-Wpedantic` adds standards-compliance checks.
**Key concepts:** -Wall, -Wextra, -Wpadded, -Wconversion, -Wdisabled-optimization
**Tip:** `-Wpadded` in GCC reports every struct where the compiler inserted padding bytes; reordering members from largest to smallest alignment eliminates the waste and can shrink your hot data structures.
**Tool anchor:** `g++ -O2 -Wall -Wextra -Wpadded -Wconversion -c order_book.cpp 2>&1 | grep -E 'padding|conversion|disabled'`
**Drill:** Compile your order book struct with `-Wpadded` and identify how many bytes of padding the compiler inserted. Reorder the members to eliminate padding and verify with `sizeof()` that the struct shrank.
**Tags:** warnings, Wpadded, Wconversion, struct-layout, diagnostics

### Constant folding and dead code elimination
The compiler evaluates expressions with known values at compile time (constant folding) and removes code that can never execute or whose results are never used (dead code elimination). Together they mean that benchmark code like `int x = 2 * 3; if (false) { heavy_work(); }` compiles to almost nothing. Understanding these passes prevents writing benchmarks that measure nothing and explains why adding `const` or `constexpr` can change generated code.
**Key concepts:** constant folding, dead code elimination, constexpr, side-effect preservation, benchmark::DoNotOptimize
**Tip:** If your Google Benchmark shows suspiciously low nanosecond times, the compiler likely constant-folded your computation; use `benchmark::DoNotOptimize()` to force the result to be materialized.
**Tool anchor:** `g++ -O2 -masm=intel -S -o - fold_test.cpp | grep -v '^\s*\.' | grep -v '^\s*$'` to see how little code remains after folding
**Drill:** Write a function that decodes a fixed SBE message at compile time (all inputs are constexpr). Verify in Godbolt that the compiler replaces the entire decode with a constant. Then make one input non-constexpr and observe the codegen difference.
**Tags:** constant-folding, dead-code-elimination, constexpr, benchmark

### Strength reduction and loop transformations
Strength reduction replaces expensive operations with cheaper equivalents: multiply by a power of two becomes a left shift, division by a constant becomes a multiply-and-shift sequence, modulo by a power of two becomes a bitwise AND. Loop-invariant code motion (LICM) hoists computations that produce the same result every iteration out of the loop body. These optimizations are automatic at -O2 but understanding them helps you write code the compiler can transform.
**Key concepts:** strength reduction, multiply-to-shift, division-by-constant, LICM, induction variables
**Tip:** Division by a non-power-of-two constant is never compiled to a `div` instruction; the compiler uses a magic-number multiply-and-shift sequence that is several times faster (roughly 2-10x, since `div`/`idiv` is ~12-44 cycles vs ~3-7 for `imul` plus a shift), so do not manually replace `x / 10` with a lookup table.
**Tool anchor:** `echo 'int f(int x) { return x / 7; }' | g++ -O2 -masm=intel -S -x c++ -o - - | grep -A5 'f:'` to see the magic multiply
**Drill:** Write a loop that computes `array[i] * 8 + base_offset` for each element. Inspect the assembly at -O2 and verify the compiler replaced the multiply with a shift and hoisted `base_offset` out of the loop.
**Tags:** strength-reduction, LICM, loop-transformation, shift, division

## intermediate

### Auto-vectorization
The compiler can automatically convert scalar loops into SIMD (Single Instruction Multiple Data) operations that process 4, 8, or 16 elements per instruction using SSE/AVX registers. Requirements include: countable trip count, no loop-carried dependencies, aligned/contiguous memory access, and no early exits. The `-Rpass=loop-vectorize` flag (Clang) or `-fopt-info-vec-all` (GCC) reports which loops vectorized and which failed with reasons.
**Key concepts:** SIMD, loop-carried dependency, trip count, alignment, vectorization report
**Tip:** A loop with an `if` branch inside can still vectorize if the compiler can convert it to a masked operation; but a loop with a data-dependent early `break` almost never vectorizes.
**Tool anchor:** `g++ -O2 -march=haswell -fopt-info-vec-all -c decoder.cpp 2>&1 | grep -E 'vectorized|not vectorized'`
**Drill:** Write a loop that sums an array of uint32_t prices. Compile with `-fopt-info-vec-all` and confirm vectorization. Then add a branch (`if (prices[i] > threshold) sum += prices[i]`) and check if it still vectorizes. If not, rewrite to enable it.
**Tags:** auto-vectorization, SIMD, SSE, AVX, loop-vectorize

### Aliasing and __restrict__
When two pointers might refer to the same memory (aliasing), the compiler cannot reorder or combine loads and stores through them, which prevents vectorization and many other optimizations. The C99 `restrict` keyword (C++ `__restrict__` as a compiler extension) promises the compiler that pointers do not alias, unlocking dramatically better codegen. The strict aliasing rule (-fstrict-aliasing, on by default at -O2) also allows the compiler to assume pointers of different types do not alias, but `char*` and `memcpy` bypass this.
**Key concepts:** pointer aliasing, __restrict__, strict aliasing, -fno-strict-aliasing, type punning
**Tip:** If your SBE decoder casts `char*` to `uint64_t*` for fast field reads, this violates strict aliasing; use `memcpy` instead, which modern compilers optimize to the same single load instruction but without undefined behavior.
**Tool anchor:** `echo 'void f(int* __restrict__ a, int* __restrict__ b, int n) { for(int i=0;i<n;i++) a[i]+=b[i]; }' | g++ -O2 -march=haswell -fopt-info-vec -x c++ -o /dev/null -c - 2>&1`
**Drill:** Write a function that copies fields between two SBE message buffers using pointer parameters. Compile without `__restrict__` and note the vectorization failure in the optimization report. Add `__restrict__` and observe the codegen improvement.
**Tags:** aliasing, restrict, strict-aliasing, pointer, vectorization

### Link-time optimization (LTO)
LTO defers optimization until link time, when the compiler can see all translation units together, enabling cross-module inlining, dead function elimination, and interprocedural constant propagation. Thin LTO partitions the work for parallel compilation with most of the benefit and much less build-time overhead than full (monolithic) LTO. The tradeoff is significantly longer link times and higher memory usage, which can be prohibitive for large codebases.
**Key concepts:** whole-program visibility, thin LTO, full LTO, cross-module inlining, link-time, -flto
**Tip:** Thin LTO (`-flto=thin`) gives 90% of full LTO's performance benefit at roughly 2x link time instead of 10x; always prefer it unless you have proven the last 10% matters.
**Tool anchor:** `g++ -O2 -flto=auto -o md_decoder decoder.cpp book.cpp feed.cpp && size md_decoder` (GCC auto-parallelizes LTO jobs)
**Drill:** Build your market data application with and without `-flto=auto`. Compare binary sizes with `size`, then benchmark both. Identify which cross-module inlining decisions LTO made by comparing `perf report` profiles.
**Tags:** LTO, thin-LTO, link-time, cross-module, inlining

### Profile-guided optimization (PGO)
PGO uses runtime profiling data to guide compiler decisions: branch probabilities determine block layout, hot loops get more aggressive optimization, cold functions are placed in separate sections, and inlining budgets are allocated to the paths that actually execute. The workflow is three steps: compile with `-fprofile-generate`, run with representative workload to produce `.gcda` files, then recompile with `-fprofile-use`. Gains of 10-20% are typical for branch-heavy code like protocol parsers.
**Key concepts:** instrumented build, profdata, -fprofile-generate, -fprofile-use, branch layout, representative workload
**Tip:** The profiling workload must be representative of production; if you train PGO with unit tests, the compiler will optimize the error paths your tests exercise and de-optimize the hot paths production uses.
**Tool anchor:** `g++ -O2 -fprofile-generate -o md_decoder_inst decoder.cpp && ./md_decoder_inst < replay.pcap && g++ -O2 -fprofile-use -o md_decoder_opt decoder.cpp`
**Drill:** Build your SBE decoder with PGO using a packet capture as the training workload. Measure the throughput improvement over plain -O2. Then intentionally use a non-representative workload (empty messages only) for training and observe the performance regression.
**Tags:** PGO, profile-guided, branch-layout, profdata, instrumentation

### Loop unrolling: compiler heuristics and manual control
Loop unrolling replicates the loop body N times to reduce branch overhead and enable instruction-level parallelism between iterations. The compiler unrolls automatically when it estimates the benefit outweighs the code-size cost, controlled by `-funroll-loops` (GCC) and internal heuristics. Manual control via `#pragma GCC unroll N` or `#pragma clang loop unroll_count(N)` overrides the heuristic. Over-unrolling increases instruction-cache pressure and register pressure, potentially causing spills.
**Key concepts:** unroll factor, branch overhead, ILP, I-cache pressure, register pressure, pragma unroll
**Tip:** If `perf annotate` shows your hot loop's unrolled body spans more than ~1KB of instructions, the unrolling is likely counterproductive due to I-cache and uop-cache thrashing.
**Tool anchor:** `echo '#pragma GCC optimize("unroll-loops")' > /dev/null && g++ -O2 -funroll-loops -S -o - loop.cpp | grep -c 'jmp\|je\|jne'` to count branches
**Drill:** Write a loop that processes 1024 SBE messages from a buffer. Compile with and without `-funroll-loops` and compare instruction count. Then add `#pragma GCC unroll 8` and check if it reduces or increases the hot-loop instruction footprint.
**Tags:** unrolling, pragma, ILP, I-cache, register-pressure

### Tail call optimization and its constraints
Tail call optimization (TCO) reuses the current stack frame when a function's last action is calling another function (or itself), converting recursion into iteration with O(1) stack usage. TCO requires: the call is in tail position, no destructors need to run after the call (a major constraint in C++), the calling convention matches, and the compiler can prove no address of a local is retained. Clang supports `[[clang::musttail]]` to guarantee TCO or emit a compile error.
**Key concepts:** tail position, stack frame reuse, musttail, destructor constraint, calling convention
**Tip:** In C++, any local variable with a non-trivial destructor (including `std::string`, `std::unique_ptr`, `std::lock_guard`) prevents TCO because the destructor runs after the call returns, breaking the tail position requirement.
**Tool anchor:** `echo 'int f(int n, int acc) { if (n==0) return acc; return f(n-1, acc+n); }' | g++ -O2 -masm=intel -S -x c++ -o - - | grep -E 'call|jmp'` to verify TCO (should show `jmp` not `call`)
**Drill:** Write a recursive message chain walker that traverses linked SBE repeating groups. Verify whether TCO fires by checking the assembly. If it does not, identify the blocker (destructor, non-tail position, or ABI mismatch) and refactor to enable it.
**Tags:** TCO, tail-call, recursion, musttail, stack

### SIMD intrinsics: SSE/AVX programming
When auto-vectorization fails, SIMD intrinsics give direct access to vector instructions: `_mm256_loadu_si256` loads 32 bytes, `_mm256_cmpeq_epi8` compares 32 bytes at once, `_mm256_movemask_epi8` extracts comparison results to a bitmask. The `immintrin.h` header provides all intrinsics for SSE through AVX-512. Intrinsics are more portable than inline assembly, auto-allocate registers, and allow the compiler to schedule around them. The tradeoff is non-trivial development and maintenance cost.
**Key concepts:** _mm256_* functions, immintrin.h, __m256i, load/store, mask, intrinsics vs inline asm
**Tip:** Always use unaligned loads (`_mm256_loadu_si256`) unless you have guaranteed alignment; the performance difference between aligned and unaligned loads disappeared with Haswell and the segfault risk of `_mm256_load_si256` on unaligned data is not worth it.
**Tool anchor:** `g++ -O2 -mavx2 -masm=intel -S -o - simd_scan.cpp | grep -E 'vmovdqu|vpcmpeqb|vpmovmskb'` to verify intrinsics compiled to expected instructions
**Drill:** Write an AVX2 function that scans a buffer for a specific byte value (e.g., SOH delimiter 0x01 in a FIX message). Compare throughput against a scalar `memchr`-based version and explain when the SIMD version wins or loses.
**Tags:** SIMD, intrinsics, AVX2, SSE, immintrin

### Function multiversioning and runtime dispatch
Function multiversioning compiles multiple versions of a function targeting different CPU features (SSE4.2, AVX2, AVX-512) and selects the best one at runtime. GCC's `__attribute__((target("avx2")))` creates explicit versions, while `__attribute__((target_clones("avx2","sse4.2","default")))` generates all variants automatically. The GNU ifunc mechanism resolves the correct version at dynamic link time (once, not per call). This lets a single binary run optimally on heterogeneous server fleets.
**Key concepts:** target attribute, target_clones, ifunc, runtime dispatch, __builtin_cpu_supports, CPU features
**Tip:** `target_clones` adds ~100 bytes of resolver overhead per function; use it only on hot functions where the architectural difference matters, not on every function in your codebase.
**Tool anchor:** `echo '__attribute__((target_clones("avx2","sse4.2","default"))) int sum(const int* a, int n) { int s=0; for(int i=0;i<n;i++) s+=a[i]; return s; }' | g++ -O2 -masm=intel -S -x c++ -o - -`
**Drill:** Take your SBE field checksum function and add `target_clones("avx2","sse4.2","default")`. Verify in the assembly that three versions are generated. Benchmark on your machine and confirm the AVX2 version is selected at runtime.
**Tags:** multiversioning, target_clones, ifunc, dispatch, CPU-features

### Compiler memory model and reordering
The compiler may reorder, combine, or eliminate memory accesses as long as the observable behavior of a single-threaded program is preserved (the "as-if" rule). This is distinct from hardware reordering: even on x86 (which has a strong hardware memory model), the compiler can reorder stores and loads freely. `volatile` prevents only compiler reordering of that specific variable but provides no atomicity or hardware fence. `std::atomic` with appropriate memory orders is the correct tool; `asm volatile("" ::: "memory")` acts as a compiler-only barrier without a hardware fence.
**Key concepts:** as-if rule, compiler barrier, volatile, std::atomic, asm volatile memory clobber, compiler vs hardware reordering
**Tip:** `volatile` on a shared counter does not make it thread-safe; it only prevents the compiler from caching it in a register. You still need `std::atomic` for correctness across threads.
**Tool anchor:** `echo 'void spin(volatile int* flag) { while(!*flag); }' | g++ -O2 -masm=intel -S -x c++ -o - - | grep -A10 'spin'` to see volatile preventing load hoisting
**Drill:** Write a spin-wait loop for a market data ready flag using `volatile`, `std::atomic<int>` with `memory_order_acquire`, and a plain `int`. Compare the assembly for all three and identify which one the compiler hoists the load out of the loop.
**Tags:** memory-model, volatile, atomic, compiler-barrier, reordering

### Alignment directives and codegen impact
Alignment affects performance at multiple levels: data alignment determines whether loads/stores cross cache-line boundaries (64-byte penalty), function alignment affects instruction fetch efficiency, and loop alignment ensures hot loops start at optimal addresses for the uop cache (typically 32-byte boundaries). `alignas(N)` controls data alignment, `-falign-functions=N` and `-falign-loops=N` control code alignment, and the compiler inserts NOP padding to achieve requested alignment.
**Key concepts:** alignas, cache-line crossing, function alignment, loop alignment, NOP padding, uop cache
**Tip:** On Intel CPUs, a tight loop that crosses a 32-byte boundary may decode slower because it spans two uop-cache entries; `-falign-loops=32` fixes this at the cost of code-size increase from NOP padding.
**Tool anchor:** `g++ -O2 -falign-functions=64 -falign-loops=32 -S -o - hot_loop.cpp | grep -E '\.p2align|nop'`
**Drill:** Use `perf stat -e frontend_retired.dsb_miss` to measure uop-cache misses in your SBE decoder. Then recompile with `-falign-loops=32` and measure again. Calculate the percentage improvement and whether the code-size increase is acceptable.
**Tags:** alignment, alignas, cache-line, loop-alignment, NOP-padding

### Devirtualization and indirect call optimization
Virtual function calls (via vtable lookup) incur an indirect branch that the CPU must predict, plus they prevent inlining. The compiler can devirtualize when it can prove the dynamic type: `final` classes/methods, local variables with known type, or PGO-guided speculative devirtualization (inserting a type check and direct call for the most common type, with fallback to virtual dispatch). Marking classes and methods `final` is the cheapest optimization for virtual-heavy C++ code.
**Key concepts:** vtable, indirect branch, final keyword, speculative devirtualization, PGO devirt
**Tip:** Adding `final` to a class that is never subclassed costs nothing and lets the compiler replace every virtual call through a pointer to that class with a direct call, enabling inlining of the method body.
**Tool anchor:** `g++ -O2 -Rpass=devirt -c handler.cpp 2>&1` (Clang) or check assembly for `call` vs `call [rax]` to distinguish direct from indirect calls
**Drill:** Create a base `MessageHandler` with a virtual `onMessage()` method and a derived `MDPHandler` that overrides it. Call through a base pointer and inspect the assembly. Then add `final` to `MDPHandler` and observe the call change from indirect to direct.
**Tags:** devirtualization, vtable, final, indirect-call, PGO

### Cold/hot function attributes and section placement
The `__attribute__((hot))` and `__attribute__((cold))` annotations tell the compiler which functions are performance-critical and which are rarely executed (error paths, logging). Hot functions are placed in `.text.hot` sections and get more aggressive optimization, while cold functions go to `.text.unlikely` with size-optimized codegen. This improves I-cache and I-TLB utilization by co-locating hot code. PGO achieves this automatically, but manual annotation is valuable without PGO.
**Key concepts:** hot/cold attributes, .text.hot, .text.unlikely, I-cache locality, section placement, -freorder-functions
**Tip:** Moving error-handling code to a `__attribute__((cold, noinline))` helper function is doubly effective: the cold attribute puts it in a separate section, and noinline keeps it from bloating the hot caller.
**Tool anchor:** `g++ -O2 -c handler.cpp && readelf -S handler.o | grep -E '\.text|\.unlikely'` to verify section placement
**Drill:** Identify the error-handling path in your SBE decoder (malformed message handling). Mark it `cold, noinline` and the main decode loop `hot`. Compare the binary layout before and after using `objdump -d -M intel --section=.text.hot`.
**Tags:** hot, cold, section-placement, I-cache, code-layout

## advanced

### Register allocation and spill analysis
x86-64 has 16 general-purpose registers (rax-r15, minus rsp/rbp), and when a function needs more live values than registers, the compiler spills values to the stack. Spills appear as `mov [rsp+offset], reg` (store) and `mov reg, [rsp+offset]` (reload) in the hot path. High register pressure comes from wide live ranges, large unrolled loops, and excessive inlining. `perf annotate` revealing hot spill instructions means register pressure is the bottleneck, often fixable by reducing live variables or splitting the function.
**Key concepts:** 16 GPR, register pressure, spill/reload, live range, stack slots
**Tip:** If `perf annotate` shows a `mov` to `[rsp+N]` consuming significant samples, that is a register spill stalling on the store buffer; consider splitting the function or reducing the unroll factor to decrease register pressure.
**Tool anchor:** `g++ -O2 -S -o - hot_func.cpp | grep -c 'rsp' ` to count stack accesses as a rough spill proxy
**Drill:** Take your hottest SBE decode function and count the stack spills in the assembly. Experiment with reducing the loop unroll factor (`#pragma GCC unroll 2` vs 4 vs 8) and graph the relationship between unroll factor, spill count, and benchmark throughput.
**Tags:** register-allocation, spill, register-pressure, live-range, stack

### Compiler attributes and builtins for performance
GCC and Clang provide builtins that convey programmer knowledge to the optimizer: `__builtin_expect(expr, val)` (C++20 `[[likely]]`/`[[unlikely]]`) guides branch prediction layout, `__builtin_prefetch(addr, rw, locality)` inserts prefetch instructions, `__builtin_unreachable()` eliminates impossible code paths, and `__builtin_assume_aligned(ptr, N)` promises pointer alignment. Each gives the compiler information it cannot deduce, enabling better codegen for the specific case.
**Key concepts:** __builtin_expect, [[likely]], __builtin_prefetch, __builtin_unreachable, __builtin_assume_aligned
**Tip:** `__builtin_unreachable()` in a default switch case lets the compiler eliminate the bounds check entirely; but if the "impossible" case ever occurs, you get silent undefined behavior instead of a crash, so pair it with an assert in debug builds.
**Tool anchor:** `echo 'int f(int x) { switch(x) { case 0: return 1; case 1: return 2; default: __builtin_unreachable(); } }' | g++ -O2 -masm=intel -S -x c++ -o - -`
**Drill:** Add `__builtin_expect` to the hot path branch in your CME MDP3 message type switch statement (expecting the most common message type). Compare the assembly layout before and after, verifying that the expected case now falls through without a taken branch.
**Tags:** builtins, likely, prefetch, unreachable, assume_aligned

### Reading compiler optimization reports
Both GCC and Clang can emit detailed reports about which optimizations were applied, which were attempted but failed, and why. Clang uses `-Rpass=<regex>` (applied), `-Rpass-missed=<regex>` (failed), and `-Rpass-analysis=<regex>` (detailed reasoning). GCC uses `-fopt-info-<type>-<dest>` with types like `vec`, `inline`, `loop`, `all`. These reports are the definitive way to understand why the compiler did or did not optimize a specific code pattern, replacing guesswork with evidence.
**Key concepts:** -Rpass, -Rpass-missed, -Rpass-analysis, -fopt-info-all, optimization remarks, YAML output
**Tip:** Pipe `-Rpass-missed=.*` output through `sort | uniq -c | sort -rn` to find the most common missed optimization across your entire codebase; this reveals systemic patterns (e.g., aliasing blocking vectorization everywhere).
**Tool anchor:** `clang++ -O2 -Rpass-missed='.*' -Rpass-analysis='.*' -c decoder.cpp 2>&1 | head -60` or `g++ -O2 -fopt-info-all-optall -c decoder.cpp 2>&1 | head -60`
**Drill:** Compile your SBE decoder with full optimization remarks. Find every loop that failed to vectorize, categorize the reasons (aliasing, non-unit-stride, data dependency), and fix the most impactful one. Re-run the report to confirm the fix worked.
**Tags:** optimization-report, Rpass, fopt-info, diagnostics, vectorization

### Instruction scheduling and software pipelining
The compiler reorders independent instructions to fill pipeline bubbles and maximize instruction-level parallelism (ILP). On in-order cores this is critical; on out-of-order x86 cores it still matters because it affects decode bandwidth and can help the hardware scheduler. Software pipelining (modulo scheduling) overlaps iterations of a loop so that loads from iteration N+1 start while iteration N is computing. The `-fschedule-insns` and `-fschedule-insns2` flags control pre-RA and post-RA scheduling.
**Key concepts:** instruction scheduling, ILP, pipeline bubble, modulo scheduling, pre-RA/post-RA scheduling
**Tip:** On modern out-of-order x86 CPUs, compiler scheduling matters most at the decode/frontend stage; a sequence of dependent instructions that the hardware reorders anyway still costs frontend bandwidth to crack into uops.
**Tool anchor:** `g++ -O2 -fschedule-insns -fschedule-insns2 -masm=intel -S -o sched.s decoder.cpp && g++ -O2 -fno-schedule-insns -fno-schedule-insns2 -masm=intel -S -o nosched.s decoder.cpp && diff sched.s nosched.s | head -40`
**Drill:** Take a sequence of 6 independent loads followed by 6 dependent computations in your SBE decoder. Compare the scheduled assembly (default -O2) with `-fno-schedule-insns2` output. Count the pipeline bubbles in each version by analyzing instruction latencies.
**Tags:** scheduling, ILP, pipeline, modulo-scheduling, frontend

### Interprocedural optimization beyond LTO
Even within a single translation unit, interprocedural analysis (IPA) passes can propagate constants across function boundaries (IPA-CP), eliminate dead arguments (IPA-SRA), and clone functions specialized for specific call sites. With LTO, these passes see the whole program. `-fipa-pta` enables interprocedural points-to analysis for better alias information. Understanding IPA passes explains why moving a function to a different file can change performance.
**Key concepts:** IPA-CP, IPA-SRA, function cloning, interprocedural points-to analysis, -fipa-pta
**Tip:** If moving a hot function from a .cpp file to a header (making it visible to callers) improves performance, the gain likely comes from IPA constant propagation that was blocked by the translation unit boundary; LTO would achieve the same without the header move.
**Tool anchor:** `g++ -O2 -fipa-pta -fdump-ipa-cp -c decoder.cpp && cat decoder.cpp.*.ipa-cp` to see constant propagation decisions
**Drill:** Create two translation units: one with a `decode(const char* buf, int msg_type)` function and one calling it with a constant `msg_type`. Build with and without LTO and compare whether the constant was propagated and the switch on `msg_type` was eliminated.
**Tags:** IPA, constant-propagation, SRA, function-cloning, interprocedural

### Polyhedral optimization and loop nest transformations
Polyhedral optimization models nested loops as integer polyhedra and applies mathematically optimal transformations: tiling (blocking for cache), interchange (reordering loop nesting for spatial locality), fusion (merging loops over the same iteration space), and fission (splitting loops to reduce register pressure). GCC's Graphite and LLVM's Polly implement these. They are most effective for dense linear algebra and structured data processing, less so for pointer-chasing code.
**Key concepts:** polyhedral model, tiling, interchange, fusion, fission, Graphite, Polly
**Tip:** Loop interchange — swapping the inner and outer loop — can improve performance by 10x for column-major access patterns in row-major languages; the polyhedral model detects this automatically, but only if the loops have affine bounds.
**Tool anchor:** `clang++ -O2 -mllvm -polly -mllvm -polly-vectorizer=stripmine -Rpass-analysis=polly -c matrix.cpp 2>&1` to see Polly's transformation decisions
**Drill:** Write a naive matrix transpose with `dst[j][i] = src[i][j]` in a doubly-nested loop. Compile with and without Polly (or manually tile with 64-element blocks). Measure the cache-miss rate with `perf stat -e cache-misses` for both versions.
**Tags:** polyhedral, tiling, interchange, fusion, Polly, Graphite

### Sanitizer overhead and production alternatives
Address Sanitizer (ASan) adds ~2x slowdown and 3x memory overhead, Thread Sanitizer (TSan) adds ~5-15x slowdown and 5-10x memory, Memory Sanitizer (MSan) adds ~3x slowdown, while Undefined Behavior Sanitizer (UBSan) adds near-zero overhead for most checks. `-fsanitize-recover=undefined` lets UBSan log errors without crashing, enabling production use. For production, hardware-assisted alternatives like ARM MTE or Intel MPX (deprecated) and sampling-based approaches reduce overhead to acceptable levels.
**Key concepts:** ASan ~2x, TSan ~5-15x, UBSan ~0, -fsanitize-recover, HWASAN, production tradeoffs
**Tip:** UBSan's integer overflow and shift checks have essentially zero overhead and catch real bugs in production; there is almost no reason not to ship with `-fsanitize=undefined -fsanitize-recover=undefined -fno-sanitize=vptr` in production.
**Tool anchor:** `g++ -O2 -fsanitize=undefined -fsanitize-recover=undefined -fno-sanitize-recover=null,return -o md_decoder decoder.cpp` for production-safe UBSan
**Drill:** Build your SBE decoder with each sanitizer (ASan, TSan, UBSan) separately. Benchmark each against the unsanitized version, recording the overhead multiplier. Then configure UBSan with `-fsanitize-recover` and verify the overhead is acceptable for your production latency budget.
**Tags:** sanitizer, ASan, TSan, UBSan, production, overhead

### Cross-compilation and target-specific tuning
`-march=native` optimizes for the build machine's exact CPU, using all available instruction set extensions. `-march=x86-64-v3` targets a baseline (AVX2+FMA+BMI), `-mtune=skylake` optimizes scheduling for Skylake without requiring its instruction extensions, and the distinction matters for portable binaries. Cross-compilation for a different target (e.g., building on a dev laptop for a colocated server) requires matching the server's `-march` exactly or the binary may crash with SIGILL on unsupported instructions.
**Key concepts:** -march, -mtune, -march=native, x86-64-v3, microarchitecture, SIGILL, feature levels
**Tip:** `g++ -march=native -Q --help=target | grep -E 'march|enabled'` shows exactly which features `-march=native` enables on your machine; use this to determine the equivalent explicit `-march` flag for reproducible builds.
**Tool anchor:** `g++ -march=native -Q --help=target 2>&1 | head -20` and `g++ -march=x86-64-v3 -dM -E - < /dev/null | grep -E 'AVX|SSE|BMI|FMA'`
**Drill:** Build your SBE decoder with `-march=native` on your dev machine and `-march=x86-64-v3` for the production fleet. Compare the assembly of your hottest function and identify which instructions differ. Benchmark both on the target hardware.
**Tags:** march, mtune, cross-compilation, x86-64-v3, microarchitecture

### Whole-program devirtualization
Whole-program devirtualization (WPD) uses LTO's whole-program visibility to prove that a virtual call has only one possible target across the entire program, replacing the indirect call with a direct one. This requires class hierarchy analysis (CHA) to determine all subclasses. Thin LTO supports WPD with `-fwhole-program-vtables` (Clang) or `-fdevirtualize` (GCC, on by default). The `final` keyword on methods or classes provides local proof that is cheaper to analyze but WPD goes further by examining the entire linked program.
**Key concepts:** whole-program vtables, class hierarchy analysis, thin LTO WPD, -fwhole-program-vtables, -fdevirtualize
**Tip:** WPD can devirtualize calls that `final` cannot: if a base class method is virtual and has only one override anywhere in the program, WPD resolves it without any source code changes.
**Tool anchor:** `clang++ -O2 -flto=thin -fwhole-program-vtables -fvisibility=hidden -Rpass=devirt -c handler.cpp 2>&1`
**Drill:** Create a class hierarchy with a base `Decoder` and three derived decoders (`MDPDecoder`, `FIXDecoder`, `SBEDecoder`). Build a program that only instantiates `MDPDecoder`. Compile with thin LTO + WPD and verify that the virtual calls are devirtualized. Then add a second instantiation and observe which calls remain virtual.
**Tags:** WPD, devirtualization, LTO, class-hierarchy, vtable

### Custom LLVM passes for domain-specific optimization
LLVM's pass infrastructure allows writing custom optimization passes as shared libraries loaded via `opt -load`. A pass receives LLVM IR functions and can analyze, transform, or instrument them. For a market data system, domain-specific passes could recognize SBE decode patterns and replace them with optimal instruction sequences, insert prefetch instructions before known access patterns, or enforce coding standards at the IR level. The new pass manager uses `PassInfoMixin` and registers via `PassPluginLibraryInfo`.
**Key concepts:** LLVM IR, pass manager, PassInfoMixin, opt -load, analysis vs transformation pass, FunctionPass
**Tip:** Start with an analysis pass (read-only, no IR modification) that dumps statistics about your codebase before attempting a transformation pass; most of the value is in the analysis, and wrong transformations produce miscompiles that are nightmarish to debug.
**Tool anchor:** `clang++ -O2 -emit-llvm -c decoder.cpp -o decoder.bc && opt -load ./my_pass.so -my-analysis decoder.bc -disable-output 2>&1`
**Drill:** Write a minimal LLVM analysis pass that counts the number of indirect calls (virtual calls) in each function of your market data decoder IR. Run it on your codebase and identify which functions have the most indirect calls, then correlate with `perf report` to see if those functions are hot.
**Tags:** LLVM, custom-pass, IR, opt, domain-specific
