local ADDON, ns = ...

-- Blizzard's bars that AnotherBars re-skins, in panel order. Pure data.
--   frame:  the bar frame's global name
--   button: the buttons' global name prefix (button .. 1 .. count)
--   system: the key in Enum.EditModeActionBarSystemIndices
-- UNVERIFIED (check in client): every frame / button name and system key on
-- Forever (docs/CHECKLIST.md, "Plan 1 spike").
local Bars = {}

Bars.list = {
  { id = "bar1", label = "Action Bar 1", frame = "MainMenuBar", button = "ActionButton", count = 12, system = "MainBar" },
  { id = "bar2", label = "Action Bar 2", frame = "MultiBarBottomLeft", button = "MultiBarBottomLeftButton", count = 12, system = "Bar2" },
  { id = "bar3", label = "Action Bar 3", frame = "MultiBarBottomRight", button = "MultiBarBottomRightButton", count = 12, system = "Bar3" },
  { id = "bar4", label = "Action Bar 4", frame = "MultiBarRight", button = "MultiBarRightButton", count = 12, system = "RightBar1" },
  { id = "bar5", label = "Action Bar 5", frame = "MultiBarLeft", button = "MultiBarLeftButton", count = 12, system = "RightBar2" },
  { id = "bar6", label = "Action Bar 6", frame = "MultiBar5", button = "MultiBar5Button", count = 12, system = "ExtraBar1" },
  { id = "bar7", label = "Action Bar 7", frame = "MultiBar6", button = "MultiBar6Button", count = 12, system = "ExtraBar2" },
  { id = "bar8", label = "Action Bar 8", frame = "MultiBar7", button = "MultiBar7Button", count = 12, system = "ExtraBar3" },
  { id = "stance", label = "Stance Bar", frame = "StanceBar", button = "StanceButton", count = 10, system = "StanceBar" },
  { id = "pet", label = "Pet Bar", frame = "PetActionBar", button = "PetActionButton", count = 10, system = "PetActionBar" },
}

local byId = {}
for _, bar in ipairs(Bars.list) do byId[bar.id] = bar end

function Bars.get(id)
  return byId[id]
end

ns.Bars = Bars
