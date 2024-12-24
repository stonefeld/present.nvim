local M = {}

---Creates a floating window
---@param config vim.api.keyset.win_config: The configuration for the floating window
---@return { buf: number, win: number }: The buffer and window numbers
M.create_floating_window = function(config, enter)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, enter or false, config)
  return { buf = buf, win = win }
end

---@class present.Slides
---@field slides present.Slide[]: The slides of the file

---@class present.Slide
---@field title string: The title of the slide
---@field body string[]: The content of the slide

---Takes some lines and parses them
---@param lines string[]: The lines to parse
---@return present.Slides
M.parse_slides = function(lines)
  local slides = { slides = {} }

  ---@type present.Slide
  local current_slide = {
    title = "",
    body = {},
  }

  local separator = "^#"

  for _, line in ipairs(lines) do
    if line:find(separator) then
      if #current_slide.title > 0 then
        table.insert(slides.slides, current_slide)
      end

      current_slide = {
        title = line,
        body = {},
      }
    else
      table.insert(current_slide.body, line)
    end
  end

  table.insert(slides.slides, current_slide)

  return slides
end

---@class present.WindowConfigs
---@field background vim.api.keyset.win_config
---@field header vim.api.keyset.win_config
---@field body vim.api.keyset.win_config
---@field footer vim.api.keyset.win_config

---@return present.WindowConfigs
M.create_window_configs = function()
  local width = vim.o.columns
  local height = vim.o.lines

  local header_height = 1 + 2 -- 1 + border
  local footer_height = 1 -- 1, no border
  local body_height = height - header_height - footer_height - 2

  local body_indent = 8
  local body_width = width - body_indent

  return {
    background = {
      relative = "editor",
      width = width,
      height = height,
      style = "minimal",
      col = 0,
      row = 0,
      zindex = 1,
    },
    header = {
      relative = "editor",
      width = width,
      height = 1,
      style = "minimal",
      border = "rounded",
      -- border = { " ", " ", " ", " ", " ", " ", " ", " " },
      col = 0,
      row = 0,
      zindex = 2,
    },
    body = {
      relative = "editor",
      width = body_width,
      height = body_height,
      style = "minimal",
      border = { " ", " ", " ", " ", " ", " ", " ", " " },
      col = body_indent,
      row = 3,
      zindex = 2,
    },
    footer = {
      relative = "editor",
      width = width,
      height = 1,
      style = "minimal",
      col = 0,
      row = height - 1,
      zindex = 2,
    },
  }
end

return M
