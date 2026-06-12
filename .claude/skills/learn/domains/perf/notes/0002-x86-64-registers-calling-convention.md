# 0002 — x86-64 register file & System V calling convention

date: 2026-06-12
area: cpu
topic: x86-64 register file and calling convention
sources: System V AMD64 psABI (§3.2 conventions, §3.2.1 register usage, §3.2.2 red zone);
         Agner Fog "Calling conventions" tables; Agner Fog microarch tables (store-fwd, PRF — ⚠ approximate)

## The register file

16 GPRs + 16 vector regs (XMM→YMM→ZMM; 32 ZMM with AVX-512):

```
GPRs:  RAX RBX RCX RDX  RSI RDI RBP RSP  R8 R9 R10 R11  R12 R13 R14 R15
```

Usable for computation:
- **15** — RSP is always the stack pointer.
- **14** if frame pointers are kept (`-fno-omit-frame-pointer`) — RBP reserved for the
  frame chain. At `-O2` the compiler omits FP by default and reclaims RBP.
- Trade-off: FP-on gives `perf record` clean stacks but costs one GPR. (This box builds
  FP-on.)
- These 16 are *architectural*; the OoO engine renames them onto a much larger physical
  register file (~180 int entries on Skylake ⚠ verify Agner). See [[note: OoO/ROB once done]].

## System V AMD64 convention (Linux/macOS; Windows x64 differs)

| Role | Registers (in order) |
|------|------|
| Integer/pointer args | RDI, RSI, RDX, RCX, R8, R9 (6) |
| FP/vector args | XMM0–XMM7 (8) |
| Integer return | RAX (RDX for 128-bit) |
| FP return | XMM0 (XMM1 for 128-bit) |

- Args beyond these + large aggregates (>16 B, or non-trivially-copyable C++ → class
  MEMORY) pass **on the stack**: caller stores before call, callee loads. A 7th `long`
  arg = memory traffic every call.
- **Red zone**: 128 B below RSP a **leaf** function may use with no RSP adjustment
  (psABI §3.2.2). Disabled in kernel (`-mno-red-zone`) — IRQs share the stack.

Clean example (Intel syntax):
```asm
long add3(long a, long b, long c) { return a + b + c; }
add3:
    lea  rax, [rdi + rsi]   ; a=RDI, b=RSI
    add  rax, rdx           ; c=RDX
    ret                     ; result in RAX
```

## Caller- vs callee-saved

```
Callee-saved (preserved): RBX RBP R12 R13 R14 R15          (6)
Caller-saved (volatile):  RAX RCX RDX RSI RDI R8 R9 R10 R11 (9)
ALL XMM/YMM/ZMM are caller-saved under System V.   (Windows x64: XMM6–15 callee-saved)
```

Hot-path consequence: a **non-inlined call inside a loop** forces the compiler to
store every *live caller-saved* value before the call and reload after (callee may
clobber). **Inlining erases this** save/restore dance.

## Register pressure & spills

When live values > registers, the allocator **spills** (store to stack) and **fills**
(reload). In a loop:
```asm
.loop:
    mov  rax, [rsp+0x18]    ; FILL  reload spilled value
    imul rax, [rbx+rcx*8]
    mov  [rsp+0x18], rax    ; SPILL store back
    ...
    jb   .loop
```
Tell: **loads *and* stores to the same `[rsp+X]` inside a loop**.

**Cost is NOT memory latency** (store-forwarding ~5 cyc ⚠ hides it). Cost is:
- extra **uops** → occupy ROB/RS → **shrink the OoO window** (less latency hidden);
- fills = **loads contending for the 2 load ports** (2 & 3 Skylake ⚠) — usually the
  real tax in a byte-streaming decode loop;
- code-size inflation → DSB/L1i pressure.

Pressure is set by **max simultaneously-live values**, not lexical variable count —
18 fields with non-overlapping live ranges (decode→store→discard) can spill zero times.

## Fixes (reduce pressure)
1. **Shorten live ranges** — decode→store→move on, don't precompute many values up front.
2. **Inline** hot callees; hoist cold/error paths out of the hot function.
3. **Don't take `&` of a hot local** — once the address escapes to a non-inlined callee
   it's pinned to the stack (can't be register-only).
4. **`restrict`** — kills alias-induced reloads. (See compiler area.)
5. **Shrink the working set** — decode only used fields; narrower struct.
6. **Use the 16 vector regs** — SIMD field extraction moves work off the GPRs.
7. `__attribute__((regcall))` for internal hot calls — more args in regs (⚠ Intel ext).

## Tool anchors
```bash
objdump -d -M intel ./md_handler | grep -A 60 '<decode_message>:'   # hunt [rsp+X] in the loop
perf annotate -s decode_message -M intel                             # cycles per instruction
```

## Takeaway
Spills aren't expensive because "memory is slow" — store-forwarding hides the latency;
they cost **uops + load-port slots + a shrunken OoO window**. Read `[rsp+X]` loop
traffic as *lost parallelism*, not lost memory bandwidth.
