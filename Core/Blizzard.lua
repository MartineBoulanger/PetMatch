local addonName, addon = ...

local Blizzard = {}

function Blizzard:Initialize()
  addon.Logger:Info(
    "Blizzard.lua initialized"
  )
  local watcher =
      CreateFrame("Frame")
  watcher:RegisterEvent(
    "ADDON_LOADED"
  )
  watcher:RegisterEvent(
    "PLAYER_LOGIN"
  )
  watcher:RegisterEvent(
    "PLAYER_ENTERING_WORLD"
  )
  watcher:SetScript(
    "OnEvent",
    function(_, event)
      if event == "ADDON_LOADED"
          or event == "PLAYER_LOGIN"
          or event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(
          1,
          function()
            self:TryHook()
          end
        )
      end
    end
  )
end

function Blizzard:TryHook()
  if self.Hooked then
    return
  end
  if not C_PetJournal then
    return
  end
  addon.Logger:Info(
    "Pet Journal API available"
  )
  self.Hooked = true
  hooksecurefunc(
    "ToggleCollectionsJournal",
    function()
      C_Timer.After(
        0.1,
        function()
          self:CreatePetJournalPanel()
        end
      )
    end
  )
end

function Blizzard:CreatePetJournalPanel()
  if addon.UI
      and addon.UI.TeamPanel then
    addon.UI.TeamPanel:Initialize()
  end
end

addon.Blizzard = Blizzard

addon.ModuleManager:Register(
  "Blizzard",
  Blizzard
)
