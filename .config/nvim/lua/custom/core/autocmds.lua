local function augroup(name)
  return vim.api.nvim_create_augroup("custom-" .. name, { clear = true })
end

local autocmd = vim.api.nvim_create_autocmd

autocmd("FileType", {
  group = augroup("close_with_esc"),
  pattern = {
    "lazy",
    "help",
    "lspinfo",
    "man",
    "notify",
    "qf",
    "startuptime",
    "checkhealth",
    "oil",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "<Esc>", "<Cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})
