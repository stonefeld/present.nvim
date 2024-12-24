local M = {}

package.loaded["present.utils"] = nil
local utils = require("present.utils")

M.setup = function()
  print("Present setup")
end

M.start_presenting = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  local parsed_lines = utils.parse_slides(lines)
  local current_slide = 1

  local windows = utils.create_window_configs()
  local background_float = utils.create_floating_window(windows.background)
  local header_float = utils.create_floating_window(windows.header)
  local body_float = utils.create_floating_window(windows.body)

  vim.bo[header_float.buf].filetype = "markdown"
  vim.bo[body_float.buf].filetype = "markdown"

  local set_slide_content = function(idx)
    local width = vim.o.columns
    local slide = parsed_lines.slides[idx]

    local padding = string.rep(" ", (width - #slide.title) / 2)
    local title = padding .. slide.title

    vim.api.nvim_buf_set_lines(header_float.buf, 0, -1, false, { title })
    vim.api.nvim_buf_set_lines(body_float.buf, 0, -1, false, slide.body)
  end

  vim.keymap.set("n", "n", function()
    current_slide = math.min(current_slide + 1, #parsed_lines.slides)
    set_slide_content(current_slide)
  end, { buffer = body_float.buf })

  vim.keymap.set("n", "p", function()
    current_slide = math.max(current_slide - 1, 1)
    set_slide_content(current_slide)
  end, { buffer = body_float.buf })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(body_float.win, true)
  end, { buffer = body_float.buf })

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

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = body_float.buf,
    callback = function()
      for key, value in pairs(restore) do
        vim.o[key] = value.original
      end

      pcall(vim.api.nvim_win_close, background_float.win, true)
      pcall(vim.api.nvim_win_close, header_float.win, true)
      pcall(vim.api.nvim_win_close, body_float.win, true)
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("present-resized", {}),
    callback = function()
      if not vim.api.nvim_win_is_valid(body_float.win) or body_float.win == nil then
        return
      end

      local updated_windows = utils.create_window_configs()
      vim.api.nvim_win_set_config(background_float.win, updated_windows.background)
      vim.api.nvim_win_set_config(header_float.win, updated_windows.header)
      vim.api.nvim_win_set_config(body_float.win, updated_windows.body)

      set_slide_content(current_slide)
    end,
  })

  set_slide_content(current_slide)
end

-- vim.print(utils.parse_slides({
--   "# Hello",
--   "This is something else",
--   "# World",
--   "This is a subtitle",
-- }))
M.start_presenting({ bufnr = 9 })

return M
