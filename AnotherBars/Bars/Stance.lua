local ADDON, ns = ...

-- The Stance Bar (Bars/Common.lua); the active stance shows the approved
-- active edge through SetChecked (Skin/Button.lua).
-- Blizzard updates the stance bar as a whole, so the empty slot and tint
-- are re-read after its update.
ns.BarModules.Common.define("stance", function()
  local run = ns.Skin.Blizzard.onStanceUpdate(function(b) ns.Skin.Button.refresh(b) end)
  if run then run() end
end)
