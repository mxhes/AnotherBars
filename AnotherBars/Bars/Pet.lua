local ADDON, ns = ...

-- The Pet Bar (Bars/Common.lua) plus the approved autocast badge on each pet
-- button (Skin/Autocast.lua), fed by Blizzard's pet bar updates.
ns.BarModules.Common.define("pet", function(spec)
  local Skin = ns.Skin
  for _, b in ipairs(ns.BarModules.Common.buttons(spec.id)) do
    local st = Skin.Button.state(b)
    Skin.Autocast.attach(b, st and st.front)
  end
  local run = Skin.Blizzard.onPetUpdate(function(b, allowed, enabled)
    Skin.Button.refresh(b)
    Skin.Autocast.set(b, allowed, enabled)
  end)
  if run then run() end
end)
