local map = vim.keymap.set

-- better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

map("n", "<Leader>L", "<Cmd>Lazy<CR>", { desc = "Run Lazy" })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Resize window using <alt-shift> arrow keys (alt for tmux panes, alt-shift for vim windows)
map("n", "<M-S-Up>", "<Cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<M-S-Down>", "<Cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<M-S-Left>", "<Cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })
map("n", "<M-S-Right>", "<Cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })

-- buffers
map("n", "<S-h>", "<Cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<Cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<Cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<Cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<Leader>bb", "<Cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<Leader>`", "<Cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<Leader>bD", "<Cmd>:bd<cr>", { desc = "Delete Buffer and Window" })

-- Clear search with <esc>
map({ "i", "n" }, "<esc>", "<Cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })

-- save file
map({ "i", "x", "n", "s" }, "<C-s>", "<Cmd>w<cr><esc>", { desc = "Save File" })

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- new file
map("n", "<Leader>fn", "<Cmd>enew<cr>", { desc = "New File" })

map("n", "<Leader>ll", "<Cmd>lopen<cr>", { desc = "Location List" })
map("n", "<Leader>lq", "<Cmd>copen<cr>", { desc = "Quickfix List" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- diagnostic
local diagnostic_goto = function(next, severity)
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    vim.diagnostic.jump({ count = next and 1 or -1, severity = severity })
  end
end
map("n", "<Leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- quit
map("n", "<Leader>qq", "<Cmd>qa<cr>", { desc = "Quit All" })

-- windows
map("n", "<Leader>ws", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<Leader>wv", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<Leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

-- tabs
map("n", "<Leader><tab>l", "<Cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<Leader><tab>o", "<Cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<Leader><tab>f", "<Cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<Leader><tab><tab>", "<Cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<Leader><tab>]", "<Cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<Leader><tab>d", "<Cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<Leader><tab>[", "<Cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- Code execution
map("n", "<Leader>xf", function()
  local ft = vim.bo.filetype
  local file = vim.fn.expand("%")
  if ft == "lua" then
    vim.cmd("source %")
  else
    local cmds = {
      cpp = "g++ -std=c++20 -O2 -o /tmp/a.out " .. file .. " && /tmp/a.out",
      c = "gcc -O2 -o /tmp/a.out " .. file .. " && /tmp/a.out",
      python = "python3 " .. file,
      rust = "cargo run",
    }
    if cmds[ft] then
      vim.cmd("split | terminal " .. cmds[ft])
    end
  end
end, { desc = "E[x]ecute [F]ile" })

map("n", "<Leader>xx", "<Cmd>.lua<CR>", { desc = "E[x]ecute Line (Lua)" })
map("v", "<Leader>xx", "<Cmd>.lua<CR>", { desc = "E[x]ecute Selection (Lua)" })

-- Help for a Word Under Cursor
map("n", "<Leader>hh", function(...)
  vim.cmd("help " .. vim.fn.expand("<cword>"))
end, { desc = "Help: Run 'help:' for current word" })

map("n", "<Leader>hH", function(...)
  for word in string.gmatch(vim.fn.expand("<cWORD>"), "[^(]+") do
    vim.cmd("help " .. word)
    break
  end
end, { desc = "Help: Run 'help:' for current WORD" })

map("n", "<Leader>hm", function(...)
  vim.cmd("Man " .. vim.fn.expand("<cword>"))
end, { desc = "Help: Run 'Man:' for current word" })

map("n", "<Leader>hM", function(...)
  for word in string.gmatch(vim.fn.expand("<cWORD>"), "[^(]+") do
    vim.cmd("Man " .. word)
    break
  end
end, { desc = "Help: Run 'Man:' for current WORD" })
