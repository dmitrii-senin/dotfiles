---
session: 12
title: C++ Workflow
phase: D
prerequisites: [8, 9, 11]
duration: 60 min
---

# Session 12 — C++ Workflow

## 1. Objective

Wire up a productive C++ daily workflow: clangd with `compile_commands.json`, header/source switching, build via overseer or `:make`, codelldb debugging, quickfix-driven error navigation. After this session, your C++ inner loop (edit → build → fix → run → debug) is entirely keyboard-driven.

## 2. Why it matters

C++ is the language where IDE features pay back the most. Without LSP, you're guessing at template error messages. Without `compile_commands.json`, clangd is blind. Without DAP, you're `printf`-debugging. With all three wired correctly, Neovim is a peer of CLion — and faster to start.

## 3. Core concepts

### `compile_commands.json` — the single most important file

Clangd needs this. It's a JSON array of `{directory, command, file}` records that tells clangd how each `.cpp` is compiled (which flags, which includes, which standard). Without it, clangd guesses (poorly, especially for templated/macro-heavy code).

**How to generate it:**

| Build system | Command                                                                          |
| ------------ | -------------------------------------------------------------------------------- |
| **CMake**    | `cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && ln -sf build/compile_commands.json .` |
| **Bazel**    | `bazel run @hedron_compile_commands//:refresh_all`                                |
| **Meson**    | meson generates it in build dir; `ln -sf build/compile_commands.json .`           |
| **Make / hand-rolled** | `bear -- make`                                                          |
| **Bear (general)** | `bear -- <build-cmd>`                                                       |

The symlink to project root is conventional — clangd searches up the tree for it.

### Clangd flags (your config)

```
clangd
  --background-index            " index headers in background, persists in ~/.cache/clangd
  --clang-tidy                  " inline clang-tidy diagnostics
  --header-insertion=iwyu       " include-what-you-use semantics for auto-imports
  --completion-style=detailed   " full signatures in completion menu
  --function-arg-placeholders   " inserts (arg1, arg2) snippets when completing functions
  --fallback-style=Google       " formatting style when no .clang-format
```

Per-project overrides go in `.clangd` (YAML at project root):

```yaml
CompileFlags:
  Add: [-Wall, -std=c++20]
Index:
  Background: Build
Diagnostics:
  ClangTidy:
    Add: [bugprone-*, performance-*]
    Remove: [readability-*]
```

### Header / source switching

Clangd provides `textDocument/switchSourceHeader`. Wire it:

```lua
vim.keymap.set("n", "<Leader>ch", function()
  local clients = vim.lsp.get_clients({ name = "clangd" })
  if #clients == 0 then return end
  clients[1]:request("textDocument/switchSourceHeader", { uri = vim.uri_from_bufnr(0) }, function(err, result)
    if err or not result then return end
    vim.cmd("edit " .. vim.uri_to_fname(result))
  end)
end, { desc = "[C]++ switch [H]eader/source" })
```

Add this to `lspconfig.lua` inside the `if client.name == "clangd"` branch in `LspAttach`. Or any per-filetype location. **Fits your `<Leader>c*` code prefix.**

### Building

Two patterns:

**A) `:make` + `errorformat`** — Vim-native. `:make` runs `makeprg`, parses output via `errorformat`, fills quickfix.

```
:setlocal makeprg=ninja\ -C\ build\ -j8
:make
:copen
]q  " navigate errors
```

`errorformat` defaults work for gcc/clang; `:set efm?` to inspect. If your build emits non-standard format, customize with `:setlocal errorformat=%f:%l:%c:\ %m`.

**B) `overseer.nvim`** — task runner with structured output, parallel runs, named templates. Recommended if you have multiple build configurations (Debug, Release, Tests). Not yet in your config; OPTIONAL upgrade.

### Running

`:!./build/myapp <args>` for a quick run. For interactive programs (REPLs, servers): `:term ./build/myapp`. Or open a zellij pane (your environment) and run there — simpler.

### Debugging — codelldb via nvim-dap

Your `dap.lua:24-44` already wires codelldb for C++/Rust:

```lua
dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  executable = {
    command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
    args = { "--port", "${port}" },
  },
}
dap.configurations.cpp = {
  {
    name = "Launch",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
  },
}
```

The launch flow:
1. `<Leader>db` toggle breakpoint.
2. `<Leader>dc` continue (first time: prompts for executable path).
3. DAP UI auto-opens (your config's `dap.listeners.after.event_initialized`).
4. `<Leader>do` step over · `<Leader>di` step into · `<Leader>du` toggle UI.

For a one-off debug, this works. For repeated debugging, add **named configurations**:

```lua
table.insert(dap.configurations.cpp, {
  name = "Run unit tests",
  type = "codelldb",
  request = "launch",
  program = "${workspaceFolder}/build/tests",
  args = { "--gtest_filter=*" },
  cwd = "${workspaceFolder}",
  stopOnEntry = false,
})
```

Then `<Leader>dc` shows a list to pick from.

## 4. Config notes

Your `lspconfig.lua:86-96` and `dap.lua:32-42` cover this workflow today. Gaps:
- No `<Leader>ch` header/source switch (proposable).
- No `makeprg` per-project (you can set ad-hoc per-buffer; or use overseer).
- No named DAP configs (single "Launch" with file picker).

## 5. Concrete examples

### Generate `compile_commands.json` for a CMake project

```bash
cd ~/projects/myapp
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ln -sf build/compile_commands.json .
```

Open a `.cpp` file in Neovim. Wait for clangd to index (`:LspInfo` shows `clangd` attached, `~/.cache/clangd/index/myapp/` populates). Now `gd` works on third-party headers, `K` shows real types.

### Edit-build-fix loop

1. Edit `src/foo.cpp`.
2. `:make` (after setting `makeprg`).
3. `:copen` if errors.
4. `]q` to first error. Fix. `:w`.
5. `]q` again. Repeat.
6. `:cclose` when clean.

### Header/source toggle

Cursor in `.cpp`. `<Leader>ch` → opens corresponding `.h`. Press again → back to `.cpp`.

### Debug a segfault

1. Build with debug symbols: `cmake --build build --target myapp` (assuming `CMAKE_BUILD_TYPE=Debug`).
2. Open the file with the suspected line. `<Leader>db` to set breakpoint.
3. `<Leader>dc` → enter `build/myapp` as executable path. Args via additional prompt or named config.
4. Step through with `<Leader>do`/`<Leader>di`. Inspect locals in DAP UI's Variables panel.
5. `<Leader>du` to hide UI when done. `:lua require('dap').terminate()` to kill the session.

### When to leave Neovim

For a rapid build loop with hot-reload, run `cmake --build build --target myapp` in a zellij pane. For ad-hoc binary inspection, `:term ldd ./build/myapp` or `:!objdump -d ./build/myapp | less`.

## 6. Shortcuts to memorize

### ESSENTIAL (all your existing maps + clangd-specific)
`gd grr gri gra grn gO gW K`  (LSP defaults)
`<Leader>cf` format · `<Leader>cd` line diagnostics
`]e [e ]w [w ]d [d`  (diagnostic nav)
`:make :copen ]q [q :cdo s/.../.../g | update`  (build/error loop)
`<Leader>db dc do di du`  (DAP)

### OPTIONAL
`<Leader>ch` (header/source switch — propose adding)
`<Leader>th` (toggle inlay hints — useful for templates)
`:LspRestart`  (when clangd gets confused after compile_commands changes)
`:lua vim.lsp.buf.format({ async = true })` (async format — alternative to your conform)

### ADVANCED
`:lua = vim.lsp.get_clients({ name = "clangd" })[1].server_capabilities`
`.clangd` per-project YAML for fine-grained tuning
Named DAP configurations for parameterized launches

## 7. Drills

1. In a C++ project, confirm `compile_commands.json` exists at root. Open a `.cpp`, run `:LspInfo` — clangd should show as attached with the project root as `root_dir`.
2. Press `K` on a `std::vector<int>` declaration. Confirm hover shows the full template type. Press `gd` on `vector` to follow into `<vector>`.
3. With at least one compile error in your project, run `:make`. Use `]q`/`[q` to navigate. Fix one. `:cnext` again.
4. Set a breakpoint with `<Leader>db`. Start debug with `<Leader>dc`. Step over once with `<Leader>do`. Inspect a local in DAP UI. Terminate with `:lua require('dap').terminate()`.
5. (Optional setup) Add the `<Leader>ch` header/source switch keymap. Test on any `.cpp` ↔ `.h` pair.

## 8. Troubleshooting

- **"clangd doesn't find my includes."** No `compile_commands.json`, or it doesn't include this file. Run `clangd --check=path/to/file.cpp` from the project root to inspect.
- **"clangd indexes forever on a huge project."** First-time pass takes minutes (sometimes hours for LLVM-scale repos). Subsequent runs are incremental. To speed up: `--background-index-priority=low` to keep CPU free for builds; or `Index: Background: Build` in `.clangd` to only index files in `compile_commands.json`.
- **"`:make` does nothing."** Set `makeprg` first: `:setlocal makeprg=ninja\ -C\ build` (escape spaces). Or use overseer.
- **"DAP says `codelldb: command not found`."** Run `:MasonInstall codelldb`. Verify path: `ls ~/.local/share/nvim/mason/bin/codelldb`.
- **"DAP UI doesn't open."** Confirm `nvim-dap-ui` is installed and `dap.listeners.after.event_initialized["dapui_config"] = dapui.open` is in your config (`dap.lua:47`).

## 9. Optional config edit

**Add `<Leader>ch` for header/source switch (in `lspconfig.lua` LspAttach):**

```diff
--- a/.config/nvim/lua/custom/plugins/lspconfig.lua
+++ b/.config/nvim/lua/custom/plugins/lspconfig.lua
@@ -57,6 +57,16 @@
         end, "[T]oggle Inlay [H]ints")
       end
+
+      if client and client.name == 'clangd' then
+        map('<Leader>ch', function()
+          client:request('textDocument/switchSourceHeader', { uri = vim.uri_from_bufnr(0) }, function(err, result)
+            if err or not result then return end
+            vim.cmd('edit ' .. vim.uri_to_fname(result))
+          end, 0)
+        end, '[C]++ switch [H]eader/source')
+      end
     end,
   })
```

ASK before applying.

**Optional named DAP config** for a known binary, in `dap.lua`:

```diff
 dap.configurations.cpp = {
   {
     name = "Launch (prompt)",
     type = "codelldb",
     ...
   },
+  {
+    name = "Run tests",
+    type = "codelldb",
+    request = "launch",
+    program = "${workspaceFolder}/build/tests",
+    cwd = "${workspaceFolder}",
+    stopOnEntry = false,
+  },
 }
```

Adapt `program` per-project.

## 10. Next-step upgrades

- **overseer.nvim** for build orchestration with named tasks (CMake configure / build / test / clean as separate, persistent tasks).
- **clangd-extensions.nvim** for per-position type hints, AST visualizer, and includes graph. OPTIONAL — your inlay hints already cover most of this.
- **Per-project `.clangd`** YAML for finer control of clang-tidy checks.

## 11. Connects to

Next: **Session 13 — Python Workflow**. Different inner loop: virtualenvs, pytest, debugpy. Many of the same primitives (LSP, quickfix), different tooling stack.
