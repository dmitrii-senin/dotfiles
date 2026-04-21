---
session: 14
title: Rust Workflow
phase: D
prerequisites: [8, 9, 11]
duration: 60 min
---

# Session 14 — Rust Workflow

## 1. Objective

Wire up a productive Rust daily workflow: rust-analyzer (direct via `vim.lsp.config`, NOT rustaceanvim — for now), inlay hints, codelldb debugging, and the cargo-in-terminal pattern. After this session, your Rust inner loop (edit → check → test → run → debug) is keyboard-driven and you understand the rustaceanvim tradeoff.

## 2. Why it matters

Rust's compiler is opinionated and produces excellent error messages — but only if you read them. Inlay hints are essential (the language has so much inferred typing). Cargo's terminal output is rich and worth keeping. The DAP setup you already have for C++ also handles Rust. The remaining question is rustaceanvim, and the honest answer is "probably not."

## 3. Core concepts

### rust-analyzer

Your config (`lspconfig.lua:98-106`) sets up rust-analyzer directly:

```lua
vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = { command = "clippy" },
      cargo = { allFeatures = true },
      procMacro = { enable = true },
    },
  },
})
```

What each does:
- **`checkOnSave = clippy`** — runs `cargo clippy` on save (instead of `cargo check`). Clippy = more lints. Slightly slower but catches more.
- **`cargo.allFeatures = true`** — enable ALL crate features for indexing. Great for libraries with many features; can cost CPU on huge graphs.
- **`procMacro.enable = true`** — support proc macros (serde, tracing, async-trait). Required for any non-trivial crate.

### Inlay hints

Rust is the language where inlay hints earn their keep. Type annotations on let-bindings, lifetime parameters, parameter names — all displayed as virtual text.

Your `lspconfig.lua:53-57` toggles them with `<Leader>th`. **For Rust, leave them on by default**; consider auto-enabling per-filetype:

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function() vim.lsp.inlay_hint.enable(true, { bufnr = 0 }) end,
})
```

### Code actions

Rust's code actions are the richest of any language. Common ones:
- "Add use statement" — auto-import.
- "Replace .into() with explicit conversion."
- "Inline variable / Extract variable / Extract function."
- "Add `#[derive(Debug)]`."
- "Convert match to if let."
- "Wrap in Some / Ok / Err."

`gra` opens the code action menu. Get used to checking it whenever the cursor lands on something dim/ambiguous.

### `runnables` and `debuggables`

rust-analyzer exposes these via Code Lenses (clickable annotations like ▶ Run / ▶ Debug above each `fn main` or `#[test]`). Standard Neovim doesn't render code lenses by default — you need `vim.lsp.codelens.refresh()` and `vim.lsp.codelens.run()`.

Wire it (in `LspAttach` for rust-analyzer):

```lua
if client and client.name == 'rust_analyzer' then
  vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
    buffer = event.buf,
    callback = vim.lsp.codelens.refresh,
  })
  map('<Leader>cl', vim.lsp.codelens.run, '[C]ode [L]ens run')
end
```

`<Leader>cl` to invoke. Code lenses appear above `fn` declarations.

### Cargo workflow — the terminal pattern

For Rust, the "build/test/run in terminal" pattern usually beats editor integration. Reasons:
- `cargo build` output has color, structured panels, progress.
- `cargo watch -x check` gives you live feedback you can keep visible in a zellij pane.
- `cargo test` output is rich; `--nocapture` and `--test-threads=1` are common; the editor doesn't help with these.

Recommended pane layout:
```
┌──────────────────┬──────────────────┐
│ nvim (editor)    │ cargo watch -x   │
│                  │   check          │
│                  ├──────────────────┤
│                  │ scratch terminal │
│                  │ (cargo run, etc) │
└──────────────────┴──────────────────┘
```

Use zellij to manage this; you already have zellij-nav so `<C-h/j/k/l>` works seamlessly.

### `:make` for Cargo (alternative)

```
:setlocal makeprg=cargo\ build
:setlocal errorformat=%-G,%-Gerror[%t%n]:\ %m,%E%f:%l:%c\ %m,%C\ %m,%-Z
```

Honestly: not worth it. The terminal pattern is better here.

### Debugging — codelldb

`dap.lua:43` shares the codelldb config with C++:

```lua
dap.configurations.rust = dap.configurations.cpp
```

So `<Leader>db/dc/do/di/du` Just Work. Build with `cargo build` first (debug symbols on by default in dev profile), then point DAP at the binary in `target/debug/<crate>`.

For tests, you typically need to know the test binary name (cargo generates one per test target). Easier: use `<Leader>cl` (code lens) → "Debug" above a `#[test]` once code lenses are wired.

### Crates.nvim (optional)

[`saecki/crates.nvim`](https://github.com/saecki/crates.nvim) shows version info inline in `Cargo.toml`:

```toml
serde = "1.0.193"   # latest: 1.0.205, semver-compatible
tokio = "1.32"      # outdated: 1.40 available
```

Useful when bumping deps. LOW-priority audit candidate.

### rustaceanvim — the tradeoff

[`mrcjkb/rustaceanvim`](https://github.com/mrcjkb/rustaceanvim) is a wrapper around rust-analyzer providing:
- Auto-config (no `vim.lsp.config('rust_analyzer', ...)` needed).
- Native code lens runnable / debuggable triggers.
- Cargo subcommand integration (`:RustAnalyzer reload`, etc.).
- Test runner integration (better than DAP for one-off tests).

**Cost:**
- Diverges from how your other LSPs are wired (you explicitly set up clangd / pyright / lua_ls via `vim.lsp.config`; rust would now go through a wrapper).
- Hidden behavior — your `LspAttach` autocmd may need tweaks because rustaceanvim's setup happens via different events.
- Adds a plugin to the spec.

**Recommendation:** stay direct. If you find yourself frustrated by code-lens ergonomics or test-debug flows, revisit. Don't add rustaceanvim preemptively.

## 4. Config notes

Your setup (already in place):
- rust_analyzer via `vim.lsp.config` with `clippy` + `allFeatures` + `procMacro`.
- DAP shares cpp config (good).
- Format via rustfmt through conform (`conform.lua:21`).
- Treesitter has `rust` parser.

**Gaps:**
- Inlay hints not auto-enabled per-filetype (toggle works but defaults off).
- No code lens wiring.
- No crates.nvim.

## 5. Concrete examples

### Open a Rust crate

```bash
cd ~/projects/mycrate
nvim src/main.rs
```

`:LspInfo` shows rust_analyzer attached. `gd` works on stdlib. `K` shows full type info. `grr` finds references across the crate.

### Refactor with code actions

Cursor on `let x = some_fn();`:
- `gra` → see actions like "Inline variable", "Add explicit type".
- Cursor on `unwrap()` → "Replace with `?`" (in a function returning `Result`).
- Cursor on `Vec<i32>` → "Replace with `[i32]`" if applicable.

### Run a single test in terminal

```
:term cargo test some_test_name -- --nocapture
```

Or open a zellij pane: `<C-...> ` (your zellij prefix), then `cargo watch -x 'test some_test_name'`.

### Debug a binary

1. `cargo build` (terminal).
2. In Neovim, set breakpoint with `<Leader>db`.
3. `<Leader>dc` → enter `target/debug/mycrate` as program path.
4. Step with `<Leader>do/di`. Inspect in DAP UI.

### Bump a dep (with crates.nvim)

If installed: open `Cargo.toml`, see versions inline, `<Leader>cu` to update one.

Without: edit `Cargo.toml` manually, then `cargo update -p <crate>` in terminal.

## 6. Shortcuts to memorize

### ESSENTIAL
`K gd grr gri gra grn gO gW`  (LSP defaults — code action is HEAVILY used in Rust)
`<Leader>cf <Leader>cd`  (format + line diagnostics)
`<Leader>th`  (toggle inlay hints)
`]e [e ]w [w ]d [d`  (diagnostic nav)
`<Leader>db dc do di du`  (DAP)
`:term cargo build/test/run`  (terminal pattern)

### OPTIONAL
`<Leader>cl`  (code lens — propose adding)
`:lua = vim.lsp.get_clients({ name = "rust_analyzer" })[1].server_capabilities`
`:LspRestart` (when rust-analyzer gets confused after Cargo.toml changes)

### ADVANCED
`vim.lsp.codelens.run()` — programmatic code lens invocation
Per-project `.cargo/config.toml` for compiler flags
Custom DAP config for parameterized binary launches

## 7. Drills

1. Open a Rust file. Cursor on a `let x = foo();`. Confirm inlay hint shows the inferred type. Toggle off with `<Leader>th`. Toggle back on.
2. Cursor on an `unwrap()` in a function that returns `Result`. `gra` → confirm "Replace with `?`" appears.
3. In `:term`, run `cargo build` in your project. Verify error output is colored and readable. Use `<C-\><C-n>` to leave terminal mode, scroll, navigate to filename, `gf` to jump.
4. Set a breakpoint at a `fn main` entry. `<Leader>dc`, point at `target/debug/mycrate`. Step in with `<Leader>di`.
5. (Optional setup) Wire code lens (see §9). Test by hovering above `fn main` → see the ▶ Run lens. `<Leader>cl` to invoke.

## 8. Troubleshooting

- **"rust-analyzer is slow / OOMs."** `cargo.allFeatures = true` (your setting) on a feature-heavy workspace can spike memory. Try `allFeatures = false` and pick specific features explicitly.
- **"Procedural macros don't expand."** `procMacro.enable = true` (you have this). Also need `cargo build` to have run at least once so the macros are compiled.
- **"`gd` jumps to a `.rlib` decompiled view I can't read."** That's stdlib without source. `rustup component add rust-src` fixes it.
- **"`cargo build` fails but `cargo check` succeeds."** Linker issue. Check `cargo --verbose build` for the underlying error.
- **"DAP doesn't stop at breakpoint."** Build was Release (no debug symbols). Use `cargo build` (default debug profile) or `cargo build --profile dev`.

## 9. Optional config edit

**Auto-enable inlay hints for Rust (small QoL):**

```diff
--- a/.config/nvim/lua/custom/core/autocmds.lua  (or new file)
+++ b/.config/nvim/lua/custom/core/autocmds.lua
+vim.api.nvim_create_autocmd("FileType", {
+  pattern = "rust",
+  callback = function()
+    vim.defer_fn(function()
+      vim.lsp.inlay_hint.enable(true, { bufnr = 0 })
+    end, 100)
+  end,
+})
```

**Wire code lens for rust-analyzer (in `lspconfig.lua` LspAttach):**

```diff
--- a/.config/nvim/lua/custom/plugins/lspconfig.lua
+++ b/.config/nvim/lua/custom/plugins/lspconfig.lua
@@ -57,6 +57,17 @@
         end, "[T]oggle Inlay [H]ints")
       end
+
+      if client and client:supports_method('textDocument/codeLens') then
+        vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
+          buffer = event.buf,
+          callback = function()
+            vim.lsp.codelens.refresh({ bufnr = event.buf })
+          end,
+        })
+        map('<Leader>cl', vim.lsp.codelens.run, '[C]ode [L]ens run')
+      end
     end,
```

Both ASK before applying.

## 10. Next-step upgrades

- **crates.nvim** for `Cargo.toml` version info. LOW-priority but pleasant.
- **`cargo watch -x check`** in a zellij pane. Live feedback without leaving the editor.
- **`cargo expand`** to view macro expansions (terminal). Pair with `:term cargo expand <module>`.
- **`bacon`** — alternative to `cargo watch` with prettier output. Optional.

## 11. Connects to

Next: **Session 15 — Build / Run / Test / Debug Orchestration**. You've seen language-specific tooling. Now let's look at the cross-language patterns: overseer, neotest, nvim-dap idioms shared across C++/Python/Rust.
