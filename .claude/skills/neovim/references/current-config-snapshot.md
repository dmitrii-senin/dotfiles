# Reference: Current Config Snapshot

> **Snapshot date:** 2026-04-25
> **Neovim target:** ≥ 0.12.x
> **Path:** `~/x/dotfiles/.config/nvim/` (symlinked from `~/.config/nvim/`)
>
> This is a **cached inventory** of what the user's config contains. It exists so the coach doesn't have to re-glob and re-read every session. **Refresh it whenever you run `/neovim audit`** or detect a drift between this snapshot and the actual files.

## Bootstrap

- `init.lua` — bootstraps `lazy.nvim` from `stdpath('data') .. '/lazy/lazy.nvim'`, configures lazy with `rocks` enabled (`server = https://nvim-neorocks.github.io/rocks-binaries/`), `colorscheme = catppuccin-macchiato`, `checker.enabled = true` (notify off), `change_detection.notify = false`. Loads `custom.utils.globals` after lazy setup.

## Core (`lua/custom/core/`)

- `init.lua` — requires `options`, `keymaps`, `autocmds`.
- `options.lua` — leader=`<Space>`, localleader=`\`. Notable opts: `clipboard = unnamedplus` (skipped if SSH), `relativenumber + number`, `signcolumn = yes`, `inccommand = nosplit`, `grepprg = rg --vimgrep`, `grepformat = %f:%l:%c:%m`, `laststatus = 3`, `splitbelow + splitright`, `undofile`, `pumblend = 10`, `pumheight = 10`, `timeoutlen = 300`, `scrolloff = 4`, `expandtab`, `tabstop=2 shiftwidth=2`. `g.autoformat = true`, `g.have_nerd_font = true`.
- `keymaps.lua` — see `references/keymaps.md` for the full taxonomy. **Includes `vim.snippet` jump maps** `<C-l>`/`<C-h>` in insert+select modes (added 2026-04-25).
- `autocmds.lua` — (read on demand)
- `health.lua` — `:checkhealth custom` provider. Asserts required-on-PATH (`rg`, `fd`, `git`, `lazygit`), recommended runtimes (`python3`, `cargo`, `node`, `g++`, `make`), and mason-managed binaries (clangd, rust-analyzer, pyright, lua-language-server, stylua, clang-format, prettier, ruff, codelldb, debugpy). Verifies Neovim ≥ 0.11. (added 2026-04-25)

## Plugins (`lua/custom/plugins/`)

| File                  | Plugin                                                | Purpose / notable config                                                                          |
| --------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `catppuccin.lua`      | `catppuccin/nvim`                                     | macchiato theme.                                                                                  |
| `conform.lua`         | `stevearc/conform.nvim`                               | Format-on-save (1000ms timeout). cpp/c → clang-format Google; py → ruff_format; rust → rustfmt; lua → stylua; web → prettier. `<Leader>cf` to format. |
| `dap.lua`             | `mfussenegger/nvim-dap` + `dap-ui` + `dap-python`     | codelldb adapter (`stdpath('data')/mason/bin/codelldb`); shared `cpp/rust/c` configurations. **Maps:** `<Leader>db` toggle bp, `<Leader>dB` conditional bp, `<Leader>dc` continue, `<Leader>do` step over, `<Leader>dO` step out, `<Leader>di` step into, `<Leader>dr` toggle REPL, `<Leader>dl` run last, `<Leader>dt` terminate, `<Leader>du` toggle UI. Auto open/close UI on session lifecycle. dap-python wired with `python3`. (DAP keymaps completed 2026-04-25.) |
| `gitsigns.lua`        | `gitsigns.nvim`                                       | Hunk navigation `]h`/`[h`. **Action maps moved to `<Leader>g*` (was `<Leader>h*`) on 2026-04-25** to free `<Leader>h` for Help. `<Leader>gs/gr/gS/gR/gu/gp/gb/gB/gd/gD`. Selection text-object `ih`. |
| `lazygit.lua`         | `kdheepak/lazygit.nvim` (or similar)                  | (read on demand) — terminal-style git porcelain.                                                  |
| `lint.lua`            | `mfussenegger/nvim-lint`                              | (read on demand) — async linters feeding `vim.diagnostic`.                                        |
| `lspconfig.lua`       | `neovim/nvim-lspconfig`                               | **Modern API.** Uses `vim.lsp.config(name, opts)` + `vim.lsp.enable({...})`. Native completion via `vim.lsp.completion.enable(true, id, buf, {autotrigger=true})` in LspAttach. CursorHold document-highlight. Inlay-hint toggle `<Leader>th`. **`vim.lsp.foldexpr` wired in LspAttach** when server supports textDocument/foldingRange (added 2026-04-25). **Servers:** `lua_ls`, `clangd`, `rust_analyzer`, `pyright`. clangd flags: `--background-index --clang-tidy --header-insertion=iwyu --completion-style=detailed --function-arg-placeholders --fallback-style=Google`. rust-analyzer settings: `checkOnSave = clippy`, `cargo.allFeatures = true`, `procMacro.enable = true`. **Telescope overrides for LSP maps:** `gd → lsp_definitions`, `grr → lsp_references`, `gri → lsp_implementations`, `gO → lsp_document_symbols`, `gW → lsp_dynamic_workspace_symbols`, `<Leader>ft → lsp_type_definitions`. |
| `mason.lua`           | `williamboman/mason.nvim` + `mason-tool-installer.nvim` | `<Leader>M` opens Mason. **`mason-tool-installer` enabled (2026-04-25)** with `ensure_installed = { lua-language-server, clangd, rust-analyzer, pyright, stylua, clang-format, prettier, ruff, rustfmt, clangtidy, codelldb, debugpy }`, `run_on_start = true`, `start_delay = 3000`. |
| `oil.lua`             | `stevearc/oil.nvim`                                   | Edit directories as buffers. **Sole file explorer** (neo-tree dropped 2026-04-25). Maps `<Leader>-` (parent), `<Leader>_` (cwd), `<Leader>e`/`<Leader>E` (explorer aliases). |
| `telescope.lua`       | `nvim-telescope/telescope.nvim`                       | Fuzzy finder. Provides LSP-override pickers (see `lspconfig.lua`). `lazy = false`. **Dead `cmd = "Telescope"` removed 2026-04-25.** (read on demand for prefix maps)|
| `toggleterm.lua`      | `akinsho/toggleterm.nvim`                             | (read on demand) — terminal toggle.                                                                |
| `treesitter.lua`      | `nvim-treesitter/nvim-treesitter` + `-textobjects`    | **New install API:** `require('nvim-treesitter').install(parsers)` with explicit parser list. FileType autocmd starts treesitter (`pcall(vim.treesitter.start)`). Fold via `v:lua.vim.treesitter.foldexpr()`. **textobjects:** `lookahead=true`, `set_jumps=true`. Maps `aa/ia/af/if/ac/ic`, `]m/[m/]]/[[/]M/[M/][/[]`, swap `<Leader>a/<Leader>A`. |
| `trouble.lua`         | `folke/trouble.nvim`                                  | (read on demand) — diagnostics panel.                                                              |
| `which-key.lua`       | `folke/which-key.nvim`                                | (read on demand) — keymap discoverability.                                                         |
| `todo-comments.lua`   | `folke/todo-comments.nvim`                            | (read on demand) — TODO/FIXME highlights.                                                          |
| `zellij-nav.lua`      | `swaits/zellij-nav.nvim`                              | Seamless `<C-h/j/k/l>` between vim windows and zellij panes. **The user runs zellij**, not tmux. Keymap `desc` flattened to top-level (was nested under `opts`) on 2026-04-25. |

## LSP servers configured

| Server          | Status     | Notable config / flags                                                                                                                            |
| --------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lua_ls`        | configured | `runtime.version = LuaJIT`; `diagnostics.globals = {vim}`; `workspace.library = vim.api.nvim_get_runtime_file('', true)`; `checkThirdParty = false`. |
| `clangd`        | configured | `--background-index --clang-tidy --header-insertion=iwyu --completion-style=detailed --function-arg-placeholders --fallback-style=Google`.        |
| `rust_analyzer` | configured | `checkOnSave = clippy`; `cargo.allFeatures = true`; `procMacro.enable = true`.                                                                    |
| `pyright`       | configured | Default settings.                                                                                                                                  |

## Formatters (conform.nvim)

| Filetype      | Formatter      | Notes                          |
| ------------- | -------------- | ------------------------------ |
| `cpp`, `c`    | `clang_format` | `--style=Google`               |
| `python`      | `ruff_format`  |                                |
| `rust`        | `rustfmt`      |                                |
| `lua`         | `stylua`       | (`stylua.toml` at repo root)   |
| `javascript`, `typescript`, `jsx`, `tsx`, `json`, `html`, `css`, `yaml`, `markdown`, `graphql` | `prettier` | |

## Linters (nvim-lint) — TBD

(Not yet read. When session 8 or audit runs, read `lint.lua` and update this section.)

## Treesitter parsers

`asm awk bash c cmake cpp csv diff disassembly dockerfile doxygen go html javascript jq json json5 lua luadoc make markdown markdown_inline nasm objdump python rust sql starlark tmux tsx typescript vim xml yaml`

## DAP adapters & configurations

- **codelldb** — `command = stdpath('data')/mason/bin/codelldb`, `args = { '--port', '${port}' }`.
- **`dap.configurations.cpp`** — codelldb launch with file picker; `cwd = workspaceFolder`.
- **`dap.configurations.rust`** — same as cpp.
- **`dap.configurations.c`** — same as cpp.
- **dap-python** — `setup('python3')` (uses active venv automatically).

## Keymap taxonomy

See `references/keymaps.md`.

## Notable opportunities (audit candidates)

See `references/customization.md` for the ranked list. High-impact items remaining (post-2026-04-25 bundle):
- Add `ruff` as an LSP (currently only formatter).
- Try `basedpyright` instead of `pyright`.
- Add `aerial.nvim` outline / sticky symbol header (deferred from conservative bundle).
- Add `nvim-dap-virtual-text` (deferred).
- Add `overseer.nvim` task runner (deferred).
- Add `neotest` (deferred).

## Gaps

Closed on 2026-04-25:
- ✅ `vim.lsp.foldexpr` wired in LspAttach.
- ✅ `vim.snippet` jump keymaps `<C-l>`/`<C-h>` in insert+select.
- ✅ Complete DAP keymaps (`<Leader>dB/dO/dr/dl/dt`).
- ✅ `<Leader>h` collision resolved (gitsigns moved to `<Leader>g*`).
- ✅ Dropped dead `<Leader>xf` shell-and-run.
- ✅ Single file explorer (oil; neo-tree dropped).
- ✅ Fixed telescope dual-trigger spec.
- ✅ Fixed zellij-nav keymap desc shape.
- ✅ Enabled `mason-tool-installer` with full ensure_installed.
- ✅ Added `lua/custom/health.lua` for `:checkhealth custom`.

Still missing:
- No test runner (no neotest).
- No build-task runner (no overseer).
- No diffview.
- No DAP virtual text.
- No code outline (aerial / outline.nvim).
- No AI completion bridge.
- `autocmds.lua` is sparse (no yank-highlight, no cursor-restore, etc.).

## Last-session marker

```
last_session: (none)
last_session_date: (n/a)
notes_for_next_session: (none)
```

The coach updates this section after every full session. Use it to drive the no-args mode of `/neovim`.
