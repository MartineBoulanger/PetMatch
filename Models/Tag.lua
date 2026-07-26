local _, addon = ...

addon.Models = addon.Models or {}

local Tag = {}

function Tag:Create(name)
  local tag

  if addon.Models.Base
      and addon.Models.Base.New then
    tag = addon.Models.Base:New()
  else
    tag = {
      id = tostring(time())
          .. "-"
          .. tostring(math.random(100000, 999999)),
      created = time(),
      modified = time(),
    }
  end

  tag.name = name or "New Tag"
  tag.color = nil
  tag.order = 0

  return tag
end

addon.Models.Tag = Tag
