-- :checkhealth custom — verifies the user's external toolchain.
-- See `:help health-dev`.
--
-- Run after a fresh `:MasonToolsInstall` or on a new machine to confirm the
-- editor's IDE features have what they need (debuggers, formatters, fuzzy
-- finders, git tools, language runtimes).

local M = {}

local h = vim.health

local required_path = {
  { bin = "rg",      reason = "telescope live_grep, :grep" },
  { bin = "fd",      reason = "telescope find_files (fast path)" },
  { bin = "git",     reason = "gitsigns, lazygit, vim's git commands" },
  { bin = "lazygit", reason = "<Leader>L → :LazyGit" },
}

local language_runtimes = {
  { bin = "python3", reason = "dap-python, pyright, ruff" },
  { bin = "cargo",   reason = "rust-analyzer, debug builds" },
  { bin = "node",    reason = "many LSPs (pyright, tsserver, prettier)" },
  { bin = "g++",     reason = "C++ compile" },
  { bin = "make",    reason = ":make + quickfix" },
}

-- Mason-managed binaries — checked relative to mason's bin dir, not $PATH.
local mason_bins = {
  { bin = "clangd",         reason = "C/C++ LSP" },
  { bin = "rust-analyzer",  reason = "Rust LSP" },
  { bin = "pyright",        reason = "Python LSP" },
  { bin = "lua-language-server", reason = "Lua LSP" },
  { bin = "stylua",         reason = "Lua formatter" },
  { bin = "clang-format",   reason = "C/C++ formatter" },
  { bin = "prettier",       reason = "Web formatter" },
  { bin = "ruff",           reason = "Python format + LSP" },
  { bin = "codelldb",       reason = "C/C++/Rust debugger (DAP)" },
  { bin = "debugpy",        reason = "Python debugger (DAP)" },
}

local function on_path(bin)
  return vim.fn.executable(bin) == 1
end

local function in_mason(bin)
  local p = vim.fn.stdpath("data") .. "/mason/bin/" .. bin
  return vim.uv.fs_stat(p) ~= nil
end

function M.check()
  h.start("Required tools (must be on $PATH)")
  for _, t in ipairs(required_path) do
    if on_path(t.bin) then
      h.ok(("`%s` found — %s"):format(t.bin, t.reason))
    else
      h.error(("`%s` missing — needed for %s"):format(t.bin, t.reason),
        ("Install via your package manager (e.g. `brew install %s`)."):format(t.bin))
    end
  end

  h.start("Language runtimes (recommended on $PATH)")
  for _, t in ipairs(language_runtimes) do
    if on_path(t.bin) then
      h.ok(("`%s` found — %s"):format(t.bin, t.reason))
    else
      h.warn(("`%s` not found — %s"):format(t.bin, t.reason))
    end
  end

  h.start("Mason-managed binaries (run :MasonToolsInstall to populate)")
  for _, t in ipairs(mason_bins) do
    if in_mason(t.bin) then
      h.ok(("mason: `%s` installed — %s"):format(t.bin, t.reason))
    elseif on_path(t.bin) then
      h.info(("`%s` on $PATH but not via mason — %s"):format(t.bin, t.reason))
    else
      h.warn(("`%s` missing — %s"):format(t.bin, t.reason),
        "Run `:MasonToolsInstall` (or `:Mason` to install manually).")
    end
  end

  h.start("Neovim version")
  local v = vim.version()
  local s = ("%d.%d.%d"):format(v.major, v.minor, v.patch)
  if vim.version.ge(v, { 0, 11, 0 }) then
    h.ok("Neovim " .. s .. " — supports the 0.11+ LSP API used by this config")
  else
    h.error("Neovim " .. s .. " — this config requires 0.11 or newer")
  end
  if vim.version.ge(v, { 0, 12, 0 }) then
    h.ok("Neovim " .. s .. " — has 0.12 features (vim.lsp.foldexpr, vim.pack)")
  else
    h.info("Neovim " .. s .. " — upgrade to 0.12+ to enable vim.lsp.foldexpr")
  end
end

return M
