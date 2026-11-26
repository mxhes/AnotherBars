local ADDON, ns = ...

-- The Settings window: an "AnotherBars" page in Blizzard's own Settings
-- panel (native controls, no art of ours) with the addon-wide skin and one
-- on / off box per bar. Profiles come in a later plan. The pure parts
-- (choices, setSkin, toggle) are tested; register / open touch the client.
ns.UI = ns.UI or {}
local Settings = {}

local L = ns.L
local category

-- The skins in choice order: { value, label }.
function Settings.skinChoices()
  local T = ns.Theme
  local out = {}
  for _, id in ipairs(T.skinOrder) do out[#out + 1] = { value = id, label = T.skins[id].label } end
  return out
end

-- Stores the skin of the active profile and relayouts every skinned
-- button (out of combat). False for an unknown skin.
function Settings.setSkin(id)
  if type(id) ~= "string" or not ns.Theme.skins[id] then return false end
  ns.DB.profile().skin = id
  ns.Combat.after("relayout", function()
    ns.Skin.Button.relayoutAll()
    ns.Skin.Autocast.relayoutAll()
  end)
  return true
end

-- Turns a bar's look on (skinned now) or off. Returns true when the change
-- needs a /reload (the skin can't be taken off live).
function Settings.toggle(id, on)
  if on then
    ns.Modules.setEnabled(id, true)
    local spec = ns.Modules.get(id)
    if spec and spec.create then
      ns.Combat.after("create:" .. id, function() spec.create(spec) end)
    end
    return false
  end
  return ns.Modules.setEnabled(id, false)
end

-- UNVERIFIED (check in client): Settings.RegisterVerticalLayoutCategory,
-- RegisterProxySetting, CreateDropdown, CreateControlTextContainer,
-- CreateCheckbox, RegisterAddOnCategory on Forever.
function Settings.register()
  local api = rawget(_G, "Settings")
  if type(api) ~= "table" or type(api.RegisterVerticalLayoutCategory) ~= "function" then return end
  category = api.RegisterVerticalLayoutCategory("AnotherBars")
  local types = api.VarType or {}

  local skin = api.RegisterProxySetting(category, "ANOTHERBARS_SKIN", types.String or "string", L["Skin"],
    "classic", function() return ns.Look.skin().id end, function(v) Settings.setSkin(v) end)
  api.CreateDropdown(category, skin, function()
    local c = api.CreateControlTextContainer()
    for _, choice in ipairs(Settings.skinChoices()) do c:Add(choice.value, L[choice.label]) end
    return c:GetData()
  end, L["Border and decoration style of all bars"])

  for _, spec in ipairs(ns.Modules.list()) do
    if spec.kind == "bar" then
      local id = spec.id
      local setting = api.RegisterProxySetting(category, "ANOTHERBARS_BAR_" .. id, types.Boolean or "boolean",
        L[spec.label], true, function() return ns.Modules.isEnabled(id) end,
        function(v) if Settings.toggle(id, v) then ns.Util.say(L["Type /reload to apply"]) end end)
      api.CreateCheckbox(category, setting, L["Turns this bar's look on or off"])
    end
  end
  api.RegisterAddOnCategory(category)
end

function Settings.open()
  local api = rawget(_G, "Settings")
  if not category or type(api) ~= "table" or type(api.OpenToCategory) ~= "function" then return end
  api.OpenToCategory(category:GetID())
end

ns.UI.Settings = Settings
