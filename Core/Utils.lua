local addonName, addon = ...

local Utils = {}

-------------------------------------------------
-- Table utilities
-------------------------------------------------
---@param source table
---@return table
function Utils:DeepCopy(source)
  if type(source) ~= "table" then
    return source
  end
  local copy = {}
  for key, value in pairs(source) do
    copy[key] = self:DeepCopy(value)
  end
  return copy
end

---@param value any
---@return boolean
function Utils:IsTable(value)
  return type(value) == "table"
end

-------------------------------------------------
-- String utilities
-------------------------------------------------
---@param value string
---@return string
function Utils:Trim(value)
  return value:match("^%s*(.-)%s*$")
end

---@param text string
---@param separator string
---@return table
function Utils:Split(text, separator)
  separator = separator or " "
  local result = {}
  for item in string.gmatch(
    text,
    "([^" .. separator .. "]+)"
  ) do
    table.insert(
      result,
      item
    )
  end
  return result
end

-------------------------------------------------
-- Math utilities
-------------------------------------------------
---@param value number
---@param minimum number
---@param maximum number
---@return number
function Utils:Clamp(value, minimum, maximum)
  if value < minimum then
    return minimum
  end
  if value > maximum then
    return maximum
  end
  return value
end

-------------------------------------------------
-- IDs
-------------------------------------------------
---@return string
function Utils:GenerateID()
  return string.format(
    "%x%x%x",
    time(),
    math.random(1000, 9999),
    math.random(1000, 9999)
  )
end

addon.Utils = Utils
