local function start_filesystem_preview(state)
  if not state or state.name ~= "filesystem" then
    return
  end

  vim.schedule(function()
    if
      not state.winid
      or not vim.api.nvim_win_is_valid(state.winid)
      or vim.api.nvim_get_current_win() ~= state.winid
      or vim.bo.filetype ~= "neo-tree"
      or not state.tree
    then
      return
    end

    local ok, node = pcall(state.tree.get_node, state.tree)
    local mapping = state.resolved_mappings and state.resolved_mappings.P
    local preview = require("neo-tree.sources.common.preview")
    if ok and node and mapping and not preview.is_active() then
      mapping.handler()
    end
  end)
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cond = not vim.g.vscode,
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle File Tree" },
      { "<leader>E", "<cmd>Neotree reveal<cr>", desc = "Reveal in File Tree" },
    },
    init = function()
      -- Open neo-tree automatically when nvim is started with a directory argument
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("neotree_start_directory", { clear = true }),
        desc = "Open neo-tree on directory",
        once = true,
        callback = function()
          if package.loaded["neo-tree"] then
            return
          end
          local arg = vim.fn.argv(0)
          if arg == "" then
            return
          end
          local stat = vim.uv.fs_stat(arg)
          if stat and stat.type == "directory" then
            vim.schedule(function()
              vim.cmd("Neotree show dir=" .. vim.fn.fnameescape(arg))
            end)
          end
        end,
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      event_handlers = {
        {
          event = "after_render",
          handler = start_filesystem_preview,
        },
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            local manager = require("neo-tree.sources.manager")
            local state = manager.get_state_for_window()
            start_filesystem_preview(state)
          end,
        },
        {
          event = "neo_tree_buffer_leave",
          handler = function()
            require("neo-tree.sources.common.preview").hide()
          end,
        },
        {
          event = "neo_tree_window_before_close",
          handler = function(args)
            if args.source == "filesystem" then
              require("neo-tree.sources.common.preview").hide()
            end
          end,
        },
      },

      enable_cursor_hijack = true,
      hide_root_node = true,
      retain_hidden_root_indent = false,
      keep_altfile = true,
      open_files_in_last_window = true,

      default_component_configs = {
        indent = {
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
        },
        name = {
          highlight_opened_files = "all",
        },
      },

      filesystem = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true,
        },
        use_libuv_file_watcher = true,
        hijack_netrw_behavior = "open_default",
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      window = {
        position = "left",
        width = 32,
        mappings = {
          ["<CR>"] = "open",
          ["<2-LeftMouse>"] = "open",
          ["P"] = {
            "toggle_preview",
            config = {
              use_float = false,
              use_snacks_image = false,
              use_image_nvim = false,
            },
          },
          ["<C-f>"] = {
            "scroll_preview",
            config = { direction = -10 },
          },
          ["<C-b>"] = {
            "scroll_preview",
            config = { direction = 10 },
          },
          ["<C-h>"] = false,
          ["<C-j>"] = false,
          ["<C-k>"] = false,
          ["<C-l>"] = false,
        },
      },
    },
  },
}
