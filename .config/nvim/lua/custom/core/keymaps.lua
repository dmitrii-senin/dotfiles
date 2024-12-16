local map = vim.keymap.set

-- better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<Cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<Cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<Cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<Cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

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

-- commenting
map("n", "gco", "o<esc>Vcx<esc><Cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><Cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- lazy
map("n", "<Leader>l", "<Cmd>Lazy<cr>", { desc = "Lazy" })

-- new file
map("n", "<Leader>fn", "<Cmd>enew<cr>", { desc = "New File" })

map("n", "<Leader>xl", "<Cmd>lopen<cr>", { desc = "Location List" })
map("n", "<Leader>xq", "<Cmd>copen<cr>", { desc = "Quickfix List" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- diagnostic
local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end
map("n", "<Leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
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

-- Quick Lua Execution
map("n", "<Leader><Leader>x", "<Cmd>source %<CR>", { desc = "Execute the current file" })
map("n", "<Leader>x", "<Cmd>.lua<CR>", { desc = "Execute the current line" })
map("v", "<Leader>x", "<Cmd>.lua<CR>", { desc = "Execute the current selected lines" })

-- Help for a Word Under Cursor
map("n", "<Leader>hh", function(...) vim.cmd("help " .. vim.fn.expand("<cword>")) end, { desc = "Help: Run 'help:' for current word" })
map("n", "<Leader>hH", function(...) vim.cmd("help " .. vim.fn.expand("<cWORD>")) end, { desc = "Help: Run 'help:' for current WORD" })
map("n", "<Leader>hm", function(...) vim.cmd("help " .. vim.fn.expand("<cword>")) end, { desc = "Help: Run 'Man:' for current word" })
map("n", "<Leader>hM", function(...) vim.cmd("help " .. vim.fn.expand("<cword>")) end, { desc = "Help: Run 'Man:' for current WORD" })
