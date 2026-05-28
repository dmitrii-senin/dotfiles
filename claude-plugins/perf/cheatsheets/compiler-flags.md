# compiler flags cheatsheet (GCC / Clang)

## optimization levels

```
-O0          # no optimization, fastest compile, best for debugging
-O1          # basic optimizations, reasonable compile time
-O2          # standard production level (recommended default)
-O3          # aggressive: auto-vectorization, loop unrolling, function cloning
-Os          # like -O2 but avoids size-increasing transforms
-Ofast       # -O3 + -ffast-math (BREAKS IEEE 754 compliance)
-Oz          # (Clang only) minimize code size aggressively
```

## architecture targeting

```
-march=native           # optimize for current CPU (not portable across machines)
-march=x86-64-v3        # AVX2 baseline (Haswell+, 2013)
-march=x86-64-v4        # AVX-512 baseline (Skylake-X+, 2017)
-mtune=<arch>           # tune instruction scheduling, no ISA requirement change
-mavx2                  # enable AVX2 extensions
-mavx512f               # enable AVX-512 foundation
-msse4.2                # enable SSE 4.2
-mpopcnt                # enable POPCNT instruction
-mbmi2                  # enable BMI2 (PDEP/PEXT)
```

Note: `-march` implies `-mtune` for the same arch. Use `-mtune` alone when you want scheduling hints but must run on older CPUs.

## vectorization controls

```
-ftree-vectorize                  # enable auto-vectorization (GCC 12+: on at -O2; older: -O3)
-funroll-loops                    # unroll loops where iteration count is known
-fno-unroll-loops                 # suppress loop unrolling
-ffast-math                       # -fno-math-errno -funsafe-math-optimizations
                                  #   -ffinite-math-only -fno-rounding-math
                                  #   -fno-signaling-nans -fcx-limited-range
                                  #   -fexcess-precision=fast
-fno-signed-zeros                 # treat +0.0 and -0.0 as identical
-fassociative-math                # allow reassociation of FP operations
-freciprocal-math                 # allow x/y -> x * (1/y)
```

Vectorization diagnostics:

```bash
# Clang — optimization remarks
clang -O2 -Rpass=loop-vectorize foo.cpp              # show what was vectorized
clang -O2 -Rpass-missed=loop-vectorize foo.cpp       # show what failed
clang -O2 -Rpass-analysis=loop-vectorize foo.cpp     # show analysis detail

# GCC — opt-info
gcc -O2 -fopt-info-vec foo.cpp                       # show vectorized loops
gcc -O2 -fopt-info-vec-missed foo.cpp                # show missed opportunities
gcc -O2 -fdump-tree-vect-details foo.cpp             # full vectorizer dump
```

Source pragmas:

```c
#pragma clang loop vectorize(enable)        // force vectorization attempt
#pragma clang loop vectorize_width(8)       // set vector width
#pragma clang loop interleave_count(4)      // set interleave factor
#pragma clang loop unroll_count(4)          // unroll 4x
#pragma GCC optimize("O3,unroll-loops")     // per-function optimization
#pragma GCC ivdep                           // ignore vector dependencies
```

## inlining controls

```
-finline-functions      # enable inlining beyond always_inline (part of -O2)
-finline-limit=N        # max function size (pseudo-instructions) eligible for inlining
-fno-inline             # disable all inlining (useful for profiling clarity)
```

```c
__attribute__((always_inline)) inline void f();   // force inline
__attribute__((noinline)) void g();               // prevent inline
```

## link-time optimization

```
-flto                   # full LTO (both GCC and Clang)
-flto=thin              # ThinLTO (Clang only) — faster link, parallel, better scalability
-flto=auto              # GCC parallel LTO (uses available cores)
-fwhole-program         # GCC: assume main() is entry point, everything else is internal
-fvisibility=hidden     # hide symbols by default (reduces export table, helps LTO)
```

Linker must also support LTO: use `gcc`/`clang` as linker driver, or pass `-flto` to `ld`.

## profile-guided optimization

GCC workflow:

```bash
gcc -O2 -fprofile-generate -o app app.c   # step 1: instrument
./app                                      # step 2: run representative workload
gcc -O2 -fprofile-use -o app app.c         # step 3: rebuild with profile data
```

Clang workflow:

```bash
clang -O2 -fprofile-instr-generate -o app app.c
./app                                                 # produces default.profraw
llvm-profdata merge -o app.profdata default.profraw
clang -O2 -fprofile-instr-use=app.profdata -o app app.c
```

AutoFDO (sample-based, no instrumentation overhead):

```bash
perf record -b -o perf.data -- ./app                  # record with branch stacks
create_llvm_prof --binary=app --out=app.afdo --profile=perf.data
clang -O2 -fprofile-sample-use=app.afdo -o app app.c
```

## optimization reports / diagnostics

```bash
# Clang remarks
clang -Rpass=<pass>              # show successful optimizations (e.g. loop-vectorize, inline)
clang -Rpass-missed=<pass>       # show missed optimizations
clang -Rpass-analysis=<pass>     # show analysis details
clang -Rpass='.*'                # all passes
clang -fsave-optimization-record # dump YAML record (view with opt-viewer.py or optview2)

# GCC opt-info
gcc -fopt-info-all               # everything
gcc -fopt-info-vec-missed        # missed vectorizations
gcc -fopt-info-inline            # inlining decisions
gcc -fopt-info-loop              # loop optimizations
```

## debug info and profiling

```
-g                                # full DWARF debug info
-g1                               # line tables only (smaller, enough for perf + addr2line)
-g2                               # default level (same as -g)
-g3                               # extra: includes macro definitions
-gdwarf-4                         # emit DWARF v4 (widely supported)
-gdwarf-5                         # emit DWARF v5 (split-dwarf friendly, smaller)
-gsplit-dwarf                     # .dwo files — speeds linking, smaller binary
-fno-omit-frame-pointer           # CRITICAL for perf record -g (frame pointer unwinding)
-mno-omit-leaf-frame-pointer      # also keep frame pointer in leaf functions (Clang)
-fno-optimize-sibling-calls       # disable tail call optimization (clearer call stacks)
-pg                               # instrument for gprof
```

Recommended profiling build:

```bash
gcc -O2 -g -fno-omit-frame-pointer -o app app.c      # optimized + debuggable + perf-friendly
```

## sanitizers

```
-fsanitize=address          # ASan: out-of-bounds, use-after-free (~2x slow, ~3x memory)
-fsanitize=thread           # TSan: data races (~5-15x slow, ~10x memory)
-fsanitize=undefined        # UBSan: signed overflow, null deref, etc. (~negligible overhead)
-fsanitize=memory           # MSan: uninitialized reads (~3x slow, Clang only)
-fsanitize=leak             # LSan: memory leak detection (standalone or built into ASan)
-fsanitize-recover=all      # don't abort on error (continue, useful for fuzzing)
-fno-sanitize-recover=all   # abort on first error (default for ASan)
```

Combine UBSan freely with ASan or MSan. ASan and TSan are mutually exclusive. ASan and MSan are mutually exclusive.

## performance-critical attributes

```c
__attribute__((hot))                          // place in hot section, optimize aggressively
__attribute__((cold))                         // place in cold section, optimize for size
__attribute__((flatten))                      // inline all callees into this function
__attribute__((pure))                         // no side effects, reads memory (allows CSE)
__attribute__((const))                        // no side effects, no memory reads (stronger than pure)
__attribute__((aligned(64)))                  // align to cache line
__builtin_expect(x, 1)                        // branch prediction hint (x is likely true)
__builtin_expect_with_probability(x, 1, 0.99) // GCC 9+: explicit probability
__builtin_prefetch(addr, 0, 3)                // prefetch for read, high temporal locality
__builtin_prefetch(addr, 1, 0)                // prefetch for write, no temporal locality
__builtin_unreachable()                       // hint: control flow never reaches here
```

```c
[[likely]]   if (x > 0) { ... }    // C++20 branch hint
[[unlikely]] if (x < 0) { ... }    // C++20 branch hint
```

```c
void f(int* __restrict__ a, int* __restrict__ b, int n);  // no-alias guarantee (enables vectorization)
```

## linker flags

```
-ffunction-sections                  # place each function in its own section
-fdata-sections                      # place each data object in its own section
-Wl,--gc-sections                    # discard unreferenced sections (dead code elimination)
-Wl,--icf=all                        # identical code folding (LLD / gold)
-Wl,--icf=safe                       # fold only address-insignificant functions
-Wl,-z,now                           # resolve all symbols at load time (faster runtime, slower startup)
-Wl,-z,relro                         # read-only relocations (security hardening)
-Wl,--as-needed                      # only link libraries that resolve a symbol (default in modern ld)
-Wl,-O1                              # linker optimization (string merge, etc.)
-Wl,--strip-all                      # strip all symbols (smallest binary, no debugging)
```

Typical production link:

```bash
gcc -O2 -flto -ffunction-sections -fdata-sections \
    -Wl,--gc-sections -Wl,--icf=safe -Wl,-z,relro,-z,now \
    -o app app.o
```
