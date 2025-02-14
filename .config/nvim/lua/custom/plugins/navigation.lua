return {
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      CustomOilBar = function()
        local path = vim.fn.expand("%")
        path = path:gsub("oil://", "")
        return "  " .. vim.fn.fnamemodify(path, ":.")
      end

      require("oil").setup({
        default_file_explorer = true,
        delete_to_trash = false,
        skip_confirm_for_simple_edits = true,
        columns = { "icon" },
        keymaps = {
          ["<C-h>"] = false,
          ["<C-l>"] = false,
          ["<C-k>"] = false,
          ["<C-j>"] = false,
          ["<C-s>"] = { "actions.select", opts = { horizontal = true } },
          ["<C-v>"] = { "actions.select", opts = { vertical = true } },
          ["<C-t>"] = { "actions.select", opts = { tab = true } },
          ["<C-p>"] = "actions.preview",
          ["-"] = { "actions.parent", mode = "n" },
          ["_"] = { "actions.open_cwd", mode = "n" },
          ["`"] = { "actions.cd", mode = "n" },
          ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
          ["g."] = { "actions.toggle_hidden", mode = "n" },
          ["<CR>"] = "actions.select",
        },
        win_options = {
          wrap = true,
          winbar = "%{v:lua.CustomOilBar()}",
        },
        view_options = {
          show_hidden = true,
          natural_order = "fast",
          is_always_hidden = function(name, _)
            local folder_skip = { "..", ".", ".git" }
            return vim.tbl_contains(folder_skip, name) or name == ".." or name == ".git"
          end,
        },
      })

      vim.keymap.set("n", "<Leader>-", require("oil").toggle_float, { desc = "Open parent directory" })
      vim.keymap.set("n", "<Leader>_", function()
        require("oil").toggle_float(vim.fn.getcwd())
      end, { desc = "Open current working directory" })
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      {
        "<Leader>e",
        function()
          local root = require("custom.utils").root()
          vim.cmd("Neotree toggle dir=" .. root)
        end,
        desc = "File [E]xplorer (Root Dir)",
      },
      {
        "<leader>E",
        function()
          vim.cmd("Neotree toggle dir=" .. vim.uv.cwd())
        end,
        desc = "File [E]xplorer (cwd)",
      },
    },
    config = function()
      vim.fn.sign_define("DiagnosticSignError", { text = " ", texthl = "DiagnosticSignError" })
      vim.fn.sign_define("DiagnosticSignWarn", { text = " ", texthl = "DiagnosticSignWarn" })
      vim.fn.sign_define("DiagnosticSignInfo", { text = " ", texthl = "DiagnosticSignInfo" })
      vim.fn.sign_define("DiagnosticSignHint", { text = "󰌵", texthl = "DiagnosticSignHint" })

      require("neo-tree").setup({
        close_if_last_window = true,
        popup_border_style = "rounded",
        enable_git_status = true,
        enable_diagnostics = true,
        enable_modified_markers = true,
        sort_case_insensitive = true,
        source_selector = {
          winbar = true,
          content_layout = "center",
          sources = {
            { source = "filesystem", display_name = "  File " },
            { source = "git_status", display_name = "  Git " },
            { source = "buffers", display_name = " 󰈚 Buffs " },
          },
        },
        default_component_configs = {
          indent = {
            indent_size = 2,
            padding = 1,
            with_markers = true,
            indent_marker = "│",
            last_indent_marker = "└",
            highlight = "NeoTreeIndentMarker",
            with_expanders = true,
            expander_collapsed = "",
            expander_expanded = "",
            expander_highlight = "NeoTreeExpander",
          },
          icon = {
            folder_closed = "",
            folder_open = "",
            folder_empty = "",
            folder_empty_open = "",
          },
          modified = {
            symbol = " ",
            highlight = "NeoTreeModified",
          },
          name = {
            trailing_slash = false,
            use_git_status_colors = true,
            highlight = "NeoTreeFileName",
          },
          git_status = {
            symbols = {
              -- Change type
              added = "✚",
              deleted = "✖",
              modified = "",
              renamed = "󰁕",
              -- Status type
              untracked = "",
              ignored = "",
              unstaged = "󰄱",
              staged = "",
              conflict = "",
            },
          },
        },
        window = {
          position = "left",
          width = 30,
          mapping_options = {
            noremap = true,
            nowait = true,
          },
          mappings = {
            ["l"] = "open",
            ["h"] = "close_node",
            ["z"] = "close_all_nodes",
            ["<S-Tab>"] = "prev_source",
            ["<Tab>"] = "next_source",
            ["<cr>"] = "open",
            ["S"] = "split_with_window_picker",
            ["s"] = "vsplit_with_window_picker",
            ["t"] = "open_tabnew",
            ["w"] = "open_with_window_picker",
            ["C"] = "close_node",
            ["a"] = { "add", config = { show_path = "relative" } },
            ["A"] = "add_directory",
            ["d"] = "delete",
            ["r"] = "rename",
            ["y"] = "copy_to_clipboard",
            ["x"] = "cut_to_clipboard",
            ["p"] = "paste_from_clipboard",
            ["c"] = "copy",
            ["m"] = "move",
            ["q"] = "close_window",
            ["R"] = "refresh",
            ["?"] = "show_help",
            ["<Esc>"] = function(_)
              require("neo-tree.sources.filesystem.lib.filter_external").cancel()
              require("neo-tree.sources.common.preview").hide()
              vim.cmd([[ nohlsearch ]])
            end,
          },
        },
        nesting_rules = {},
        filesystem = {
          use_libuv_file_watcher = false,
          filtered_items = {
            visible = true, -- when true, they will just be displayed differently than normal items
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_by_name = { "node_modules" },
            hide_by_pattern = {}, -- uses glob style patterns
            never_show = { ".DS_Store", ".git" },
          },
          follow_current_file = { enabled = true },
          group_empty_dirs = true,
          hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree
          window = {
            mappings = {
              ["<bs>"] = "navigate_up",
              ["."] = "set_root",
              ["H"] = "toggle_hidden",
              ["/"] = "fuzzy_finder",
              ["D"] = "fuzzy_finder_directory",
              ["#"] = "fuzzy_sorter",
              ["f"] = "filter_on_submit",
              ["<c-x>"] = "clear_filter",
              ["[g"] = "prev_git_modified",
              ["]g"] = "next_git_modified",
            },
          },
        },
        buffers = {
          follow_current_file = { enabled = true },
          group_empty_dirs = true,
          show_unloaded = true,
          window = {
            mappings = {
              ["<bs>"] = "navigate_up",
              ["."] = "set_root",
              ["R"] = "refresh",
              ["a"] = "add",
              ["d"] = "delete",
              ["r"] = "rename",
              ["<c-r>"] = "refresh",
            },
          },
        },
        git_status = {
          window = {
            position = "float",
            mappings = {
              ["A"] = "git_add_all",
              ["gu"] = "git_unstage_file",
              ["ga"] = "git_add_file",
              ["gr"] = "git_revert_file",
              ["gc"] = "git_commit",
              ["gp"] = "git_push",
              ["gg"] = "git_commit_and_push",
            },
          },
        },
      })
    end,
  },
}
