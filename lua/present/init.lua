local M = {}

package.loaded["present.utils"] = nil
local utils = require("present.utils")

local state = {
  parsed_lines = {},
  current_slide = 1,
  floats = {},
}

local set_slide_content = function(idx)
  local width = vim.o.columns
  local slide = state.parsed_lines.slides[idx]

  local padding = string.rep(" ", (width - #slide.title) / 2)
  local title = padding .. slide.title

  vim.api.nvim_buf_set_lines(state.floats.header.buf, 0, -1, false, { title })
  vim.api.nvim_buf_set_lines(state.floats.body.buf, 0, -1, false, slide.body)

  local footer = string.format("  %d / %d | %s", state.current_slide, #state.parsed_lines.slides, state.title)
  vim.api.nvim_buf_set_lines(state.floats.footer.buf, 0, -1, false, { footer })
end

---@param callback fun(name: string, float: { win: number, buf: number})
local foreach_float = function(callback)
  for name, float in pairs(state.floats) do
    callback(name, float)
  end
end

local present_keymap = function(mode, key, callback)
  vim.keymap.set(mode, key, callback, { buffer = state.floats.body.buf })
end

M.setup = function()
  -- create a custom command to execute the presentation
  vim.api.nvim_create_user_command("Present", function()
    M.start_presenting({ bufnr = vim.api.nvim_get_current_buf() })
  end, {})
end

M.start_presenting = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  -- First set the options
  local restore = {
    cmdheight = {
      original = vim.o.cmdheight,
      present = 0,
    },
    conceallevel = {
      original = vim.o.conceallevel,
      present = 2,
    },
  }

  for key, value in pairs(restore) do
    vim.o[key] = value.present
  end

  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  state.parsed_lines = utils.parse_slides(lines)
  state.current_slide = 1
  state.title = vim.fn.expand("%:t")

  local windows = utils.create_window_configs()
  state.floats.background = utils.create_floating_window(windows.background)
  state.floats.header = utils.create_floating_window(windows.header)
  state.floats.body = utils.create_floating_window(windows.body, true)
  state.floats.footer = utils.create_floating_window(windows.footer)

  foreach_float(function(_, float)
    vim.bo[float.buf].filetype = "markdown"
  end)

  present_keymap("n", "n", function()
    state.current_slide = math.min(state.current_slide + 1, #state.parsed_lines.slides)
    set_slide_content(state.current_slide)
  end)

  present_keymap("n", "p", function()
    state.current_slide = math.max(state.current_slide - 1, 1)
    set_slide_content(state.current_slide)
  end)

  present_keymap("n", "q", function()
    vim.api.nvim_win_close(state.floats.body.win, true)
  end)

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = state.floats.body.buf,
    callback = function()
      for key, value in pairs(restore) do
        vim.o[key] = value.original
      end

      foreach_float(function(_, float)
        pcall(vim.api.nvim_win_close, float.win, true)
      end)
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("present-resized", {}),
    callback = function()
      if not vim.api.nvim_win_is_valid(state.floats.body.win) or state.floats.body.win == nil then
        return
      end

      local updated_windows = utils.create_window_configs()
      foreach_float(function(name, float)
        vim.api.nvim_win_set_config(float.win, updated_windows[name])
      end)

      set_slide_content(state.current_slide)
    end,
  })

  set_slide_content(state.current_slide)
end

M._parse_slides = utils.parse_slides

return M
