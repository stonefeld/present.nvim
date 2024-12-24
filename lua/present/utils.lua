local M = {}

---Creates a floating window
---@param config vim.api.keyset.win_config: The configuration for the floating window
---@return { buf: number, win: number }: The buffer and window numbers
M.create_floating_window = function(config)
  -- Create a buffer
  local buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer

  -- Create the floating window
  local win = vim.api.nvim_open_win(buf, true, config)

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
---@field background vim.api.keyset.win_config: The name of the window
---@field header vim.api.keyset.win_config: The name of the window
---@field body vim.api.keyset.win_config: The name of the window

---@return present.WindowConfigs
M.create_window_configs = function()
  local width = vim.o.columns
  local height = vim.o.lines

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
      width = width - 8,
      height = height - 5,
      style = "minimal",
      border = { " ", " ", " ", " ", " ", " ", " ", " " },
      col = 8,
      row = 3,
      zindex = 2,
    },
    -- footer = {},
  }
end

return M
