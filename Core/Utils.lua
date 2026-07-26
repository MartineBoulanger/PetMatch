local _, addon = ...

local Utils = {}

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

function Utils:IsTable(value)
  return type(value) == "table"
end

function Utils:Trim(value)
  return value:match("^%s*(.-)%s*$")
end

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

function Utils:Clamp(value, minimum, maximum)
  if value < minimum then
    return minimum
  end
  if value > maximum then
    return maximum
  end
  return value
end

function Utils:GenerateID()
  return string.format(
    "%x%x%x",
    time(),
    math.random(1000, 9999),
    math.random(1000, 9999)
  )
end

addon.Utils = Utils
