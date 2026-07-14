local addonName, addon = ...

local TeamCard = {}

function TeamCard:Create(parent, team)
  local frame =
      addon.UI.Components.Panel:Create(
        parent,
        {
          width = 280,
          height = 90
        }
      )

  local name =
      addon.UI.Components.Label:Create(
        frame,
        {
          text = team.name
        }
      )

  name:SetPoint("TOPLEFT", 12, -12)

  for i = 1, 3 do
    local pet = team.pets[i] or "Empty"
    local label =
        addon.UI.Components.Label:Create(
          frame,
          {
            text =
                "Slot "
                .. i
                .. ": "
                .. pet
          }
        )

    label:SetPoint("TOPLEFT", 12, -20 - (i * 16))
  end

  return frame
end

addon.UI.Components.TeamCard = TeamCard
