---
session: 15
title: Build / Run / Test / Debug Orchestration
phase: E
prerequisites: [12, 13, 14]
duration: 60 min
---

# Session 15 — Build / Run / Test / Debug Orchestration

## 1. Objective

Cross-language patterns for build orchestration, test runners, and debugging — and the honest answer for *when to leave Neovim entirely* and use a zellij pane. After this session, you have a clear mental map of: when to use `:make`, when to use `overseer.nvim`, when to use `neotest`, when to use `nvim-dap`, and when to just `:term` it.

## 2. Why it matters

The biggest mistake in IDE-style Neovim setups is "everything goes in the editor." Some workflows are genuinely better in a real shell. Knowing which is which is the difference between a smooth workflow and constant friction.

## 3. Core concepts

### The four orchestration tools

| Tool                  | Purpose                                            | Strengths                                                      | Weaknesses                                  |
| --------------------- | -------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------- |
| `:make` (built-in)    | Run `makeprg`, parse via `errorformat`, fill quickfix | Zero deps; quickfix integration; works with `]q/[q`; perfect for compile-fix loops | Single output; no parallel; no UI; one task at a time |
| `overseer.nvim`       | Named tasks, parallel runs, structured output, integration with quickfix/test runners | Multiple concurrent builds; named templates per project; result panel | Plugin to install; abstraction over `:make` |
| `neotest`             | Test discovery, run/jump-to-failure, gutter marks  | Per-test granularity; jumping; clean UI                        | Only for tests; per-language adapter needed |
| `nvim-dap`            | Step-through debugging                             | Editor-integrated breakpoints, variable inspection, REPL       | Setup is per-language; for one-offs, terminal CLI debugger is faster |

### When to use each

| Situation                                   | Recommended tool       | Why                                                          |
| ------------------------------------------- | ---------------------- | ------------------------------------------------------------ |
| C++ compile-fix loop                        | `:make` + quickfix     | Tightest feedback. `]q` to walk errors.                       |
| Multiple persistent dev servers             | zellij panes           | Each gets its own pane; no editor entanglement.              |
| Cargo check on save                         | `cargo watch -x check` in zellij pane | Cargo's output is rich; no editor wrapping needed.            |
| One-off Python REPL                         | `:term python3` or zellij pane | Both fine; use what's already open.                           |
| Pytest TDD loop                             | `:term pytest -x --ff -vv` (or neotest)  | Terminal is honest; neotest for jump-to-failing-test UX.      |
| Debug a tricky function                     | `nvim-dap`             | Editor-integrated breakpoints + step + inspect.              |
| Print-debugging sanity check                | `:term ./prog` or zellij pane | DAP setup overhead not worth it for two `printf`s.            |
| Multiple parallel tasks (build + test + lint) | `overseer.nvim`        | Named tasks; structured output per task.                     |

### `:make` deeper

```
:setlocal makeprg=ninja\ -C\ build      " escape spaces with backslash
:setlocal errorformat=%f:%l:%c:\ %m     " adapt to your tool's output
:make                                    " runs makeprg; output → :messages and quickfix
:copen                                    " browse errors
]q                                        " next error (your config)
```

Recommended: define `makeprg` per project via `~/.config/nvim/after/ftplugin/<filetype>.lua` or via a per-project `.nvim.lua` (Neovim 0.9+ project-local config — read `:help exrc`).

### `overseer.nvim` (not yet installed)

```lua
-- spec
{
  "stevearc/overseer.nvim",
  cmd = { "OverseerRun", "OverseerToggle" },
  keys = {
    { "<Leader>oo", "<Cmd>OverseerToggle<CR>", desc = "Overseer toggle" },
    { "<Leader>or", "<Cmd>OverseerRun<CR>", desc = "Overseer run" },
  },
  opts = {},
}
```

Tasks defined as templates in `lua/overseer/template/<name>.lua` or per-project in `.overseer/`. Each template specifies `cmd`, `args`, `cwd`, `components` (e.g., parser → quickfix integration).

OPTIONAL upgrade. Worth it if you have repeated multi-step tasks (configure → build → test → lint).

### `neotest` (not yet installed)

```lua
-- spec
{
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    -- adapters per language:
    "nvim-neotest/neotest-python",
    "nvim-neotest/neotest-rust",
    -- C++: try "alfaix/neotest-gtest" or write your own
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-python"),
        require("neotest-rust"),
      },
    })
  end,
}
```

Maps (proposed, fits `<Leader>t*`):
- `<Leader>tn` — run nearest test
- `<Leader>tf` — run file
- `<Leader>tt` — run all
- `<Leader>ts` — toggle test summary panel
- `<Leader>to` — toggle output panel
- `[t` `]t` — prev/next failed test

OPTIONAL. The terminal pattern (`:term pytest -x --ff`, `:term cargo test`) is honest and works.

### `nvim-dap` patterns shared across languages

Your config wires:
- `<Leader>db` toggle breakpoint
- `<Leader>dc` continue (also: launch on first call)
- `<Leader>do` step over
- `<Leader>di` step into
- `<Leader>du` toggle DAP UI

What's missing (worth adding for completeness):

| Map (proposed)        | Action                                                     |
| --------------------- | ---------------------------------------------------------- |
| `<Leader>dO` (capital) | Step out (`require('dap').step_out()`)                    |
| `<Leader>dr`          | Open REPL (`require('dap').repl.open()`)                   |
| `<Leader>dl`          | Run last config (`require('dap').run_last()`)              |
| `<Leader>dB`          | Conditional breakpoint (`require('dap').set_breakpoint(vim.fn.input('Condition: '))`) |
| `<Leader>dt`          | Terminate (`require('dap').terminate()`)                   |

These all fit your `<Leader>d*` debug prefix.

### Terminal patterns in your environment

You're on **zellij**. Recommendations:

- **Editor + persistent build pane**: open zellij with a 2-pane layout. Left = nvim. Right = terminal where you keep `cargo watch`, `pytest -x --ff`, etc. running.
- **Inside-Neovim `:term`**: useful for scratch shells, one-off commands. `<C-\><C-n>` to leave terminal-mode.
- **Toggleterm**: your config has it; use it for "appear/disappear" terminal sessions where the lifetime is short. For long-running tasks, prefer zellij panes (they survive nvim restart).

### Slime / REPL-driven Python/Lua/Rust

[`vim-slime`](https://github.com/jpalardy/vim-slime) sends visually-selected lines to a terminal (or zellij pane). Useful for live data exploration in Python. NOT installed; skip unless you do REPL-driven work.

## 4. Config notes

Your `dap.lua` is solid for the basic loop. Gaps:
- No step-out, REPL-open, run-last, conditional-breakpoint maps.
- No overseer (build orchestration).
- No neotest (test discovery).
- DAP listeners auto-open/close UI — good.

## 5. Concrete examples

### C++ build-fix loop

```
:setlocal makeprg=ninja\ -C\ build -j8
:make                            " run ninja; on error, fills quickfix
:copen                           " review
]q                               " jump to first error
" fix
:w
:make                            " rebuild
```

### Python pytest TDD loop (terminal pattern)

In a zellij pane next to nvim:
```
$ cargo install cargo-watch  # one-time (Rust)
$ pytest --testmon-noselect tests/test_foo.py::test_bar -x --ff -vv
```
Re-run with `↑<CR>` after edits. Or use `pytest-watch` (`ptw`) for auto-rerun.

In Neovim, no plugin needed — your edit-save cycle is enough.

### Rust cargo watch pane

```
$ cargo watch -x 'check --tests' -x 'clippy --fixall' -x 'test --no-fail-fast'
```

Edit in nvim; cargo-watch re-runs on save. Visible in adjacent zellij pane.

### Multi-task overseer (if installed)

`<Leader>or` opens template picker. Pick "CMake configure". Pick "CMake build" (runs in parallel). Pick "Run tests". All three run with structured output panels. Failures aggregated.

### Debug a Python test under cursor

Cursor on `def test_foo(...)`:
```
:lua require('dap-python').test_method()
```

DAP UI opens. Step with `<Leader>do/di`. Inspect locals. Terminate with `:lua require('dap').terminate()` (or proposed `<Leader>dt` map).

## 6. Shortcuts to memorize

### ESSENTIAL
`:make :copen ]q [q :cdo s/.../.../g | update`  (compile-fix loop)
`:term <cmd>  <C-\\><C-n>  i`  (terminal toggle in/out)
`<Leader>db dc do di du`  (DAP — your maps)

### OPTIONAL
`:terminal` (alias `:term`); `:tabnew | term` for full-tab terminal
DAP additions worth adding:
`<Leader>dO` step out · `<Leader>dr` REPL · `<Leader>dl` run last · `<Leader>dB` conditional bp · `<Leader>dt` terminate

### ADVANCED
`overseer` for multi-task orchestration (when you outgrow `:make`)
`neotest` for test discovery with gutter marks (when terminal pytest/cargo-test feels limiting)
`vim-slime` for REPL-driven exploration

## 7. Drills

1. Set `makeprg` for a project: `:setlocal makeprg=cmake\ --build\ build`. Run `:make`. Confirm errors land in quickfix.
2. Open `:term`, run `ls`. Press `<C-\><C-n>` to leave terminal mode. Yank a line. Press `i` to re-enter. `<Esc>` doesn't leave terminal-mode by default.
3. Set a breakpoint. Use `<Leader>dc` to start. Use `<Leader>do` to step. Use `<Leader>du` to toggle UI. Terminate with `:lua require('dap').terminate()`.
4. Set up a zellij pane with `cargo watch -x check` (or equivalent). Edit a file in nvim. Watch the pane re-run.
5. (If neotest were installed) `<Leader>tn` to run nearest test. (If not, use `:term pytest -k <test_name>` instead.)

## 8. Troubleshooting

- **"`:make` does nothing."** `makeprg` not set, or no errors to parse. `:set makeprg?` to inspect. `:messages` to see output.
- **"Quickfix is empty after `:make`."** `errorformat` doesn't match the tool's output. `:set errorformat?` to inspect; consult `:help errorformat`.
- **"DAP UI panes are mispositioned."** `dap-ui` setup options. `require('dapui').setup({ layouts = { ... } })` to customize.
- **"`:term` doesn't honor my shell."** Set `vim.opt.shell = '/usr/bin/zsh'` or set `$SHELL` before launching nvim.
- **"Breakpoints don't hit."** Build was Release / no debug symbols. Or you're attached to the wrong process.

## 9. Optional config edit

**Add the missing DAP maps:**

```diff
--- a/.config/nvim/lua/custom/plugins/dap.lua
+++ b/.config/nvim/lua/custom/plugins/dap.lua
@@ -10,6 +10,11 @@
       { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
       { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
       { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
+      { "<leader>dO", function() require("dap").step_out() end, desc = "Step Out" },
+      { "<leader>dr", function() require("dap").repl.open() end, desc = "Open REPL" },
+      { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
+      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Cond: ")) end, desc = "Conditional Breakpoint" },
+      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
     },
```

ASK before applying.

**Optional: install overseer or neotest** based on your appetite. Both are real upgrades; both add complexity. Don't install both at once.

## 10. Next-step upgrades

- **`overseer.nvim`** when you find yourself running 3+ named tasks regularly.
- **`neotest`** when terminal pytest/cargo-test feels limiting.
- **`vim-slime`** for REPL-driven Python/Lua exploration.
- Per-project `.nvim.lua` (with `:set exrc`) for project-specific `makeprg`/DAP configs.

## 11. Connects to

Next: **Session 16 — Git, Performance, and Long-Term Config Evolution**. The final session: keeping the config healthy at year five, profiling startup, and the git workflow that keeps you fast.
