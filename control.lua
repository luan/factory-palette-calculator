local function tooltip(result)
  return {
    "",
    { "gui.fpal-click-tooltip" },
    " ",
    { "factory-palette.source.calculator.confirm" },
  }
end

local function evaluate_expression(expr)
  -- Basic sanitization
  expr = expr:gsub("%s+", "") -- Remove whitespace

  -- Use Lua's load with a restricted environment
  local fn, err = load("return " .. expr, "expr", "t", {})
  if not fn then
    return nil
  end

  local success, result = pcall(fn)
  if not success or type(result) ~= "number" then
    return nil
  end

  return result
end

local function looks_like_math(str)
  -- Remove all spaces and % characters
  str = str:gsub("%s+", "")
  str = str:gsub("%%", "")

  -- Must contain at least one number
  if not str:find("%d") then
    return false
  end

  -- Check for at least one operator
  local has_operator = false
  for _, op in ipairs({ "+", "-", "*", "/", "^" }) do
    if str:find(op, 1, true) then
      has_operator = true
      break
    end
  end

  if not has_operator then
    return false
  end

  -- Check for invalid characters
  for i = 1, #str do
    local c = str:sub(i, i)
    if not c:match("[%d%+%-%*%/%^%(%)%.]") then
      return false
    end
  end

  return true
end

local function search(player, player_table, query)
  if not looks_like_math(query) then
    return {}
  end

  -- Remove all spaces and % characters before evaluating
  local clean_query = query:gsub("%s+", "")
  clean_query = clean_query:gsub("%%", "")
  local result = evaluate_expression(clean_query)
  if not result then
    return {}
  end

  -- Format the result nicely
  local formatted_result = tostring(result)
  if math.floor(result) == result then
    formatted_result = string.format("%.0f", result)
  end

  -- Clean up the display query too
  local display_query = query:gsub("%%", "")

  local results = {
    {
      name = "calculator",
      caption = { "[color=white]" .. display_query .. " = " .. formatted_result .. "[/color]" },
      translation = display_query .. " = " .. formatted_result,
      result = formatted_result,
      remote = {
        "factory-palette.source.calculator",
        "select",
        { player_index = player.index, result = formatted_result },
      },
      tooltip = tooltip(),
    },
  }

  return results
end

local function select(data, modifiers)
  local player = game.players[data.player_index]
  if not player then
    return
  end

  -- Send the result to the chat
  player.print({ "", { "factory-palette.source.calculator.result" }, data.result })
  return true
end

-- Register our remote interfaces
remote.add_interface("factory-palette.source.calculator", {
  search = search,
  select = select,
})
