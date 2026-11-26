local ADDON, ns = ...

-- Plan 1 client spike (deleted in Plan 3). One module per Blizzard bar with a
-- single "Spike: padding 0" checkbox on the bar's own Edit Mode panel, a chat
-- line every time Blizzard lays out a bar (with the combat flag), and
-- /abars spike alpha to try SetAlpha on a bar in combat. The questions it
-- answers are in docs/CHECKLIST.md ("Plan 1 spike").
local Spike = {}

local L = ns.L
local logging = true

local function padding0(id)
  return ns.Options.get(id, "padding0") == true
end

for _, bar in ipairs(ns.Bars.list) do
  ns.Modules.define{
    id = bar.id,
    label = bar.label,
    kind = "bar",
    system = { index = bar.system },
    defaults = { padding0 = false },
    settings = {
      { section = "Spike", controls = {
        { key = "padding0", type = "checkbox", label = "Spike: padding 0",
          tooltip = "Closes the gaps between this bar's buttons (test build)" },
      } },
    },
    apply = function(spec, key, value)
      if key ~= "padding0" then return end
      if value then
        ns.Layout.repack(spec.id, 0)
      else
        ns.Util.say(L["Type /reload to apply"])
      end
    end,
  }
end

local function onLayout(id, inCombat)
  local bar = ns.Bars.get(id)
  if logging then
    ns.Util.say(string.format("%s laid out (in combat: %s)", bar.label, inCombat and "yes" or "no"))
  end
  if padding0(id) then ns.Layout.repack(id, 0) end
end

local half = false

-- /abars spike log | alpha
function Spike.command(rest)
  if rest == "log" then
    logging = not logging
    ns.Util.say("spike log " .. (logging and "on" or "off"))
  elseif rest == "alpha" then
    -- UNVERIFIED (check in client): SetAlpha on a protected bar in combat.
    local bar = _G[ns.Bars.get("bar2").frame]
    if not bar then return ns.Util.say("Action Bar 2 not found") end
    half = not half
    local ok, err = pcall(bar.SetAlpha, bar, half and 0.5 or 1)
    ns.Util.say(string.format("SetAlpha(%s) in combat: %s -> %s", half and "0.5" or "1",
      InCombatLockdown() and "yes" or "no", ok and "ok" or tostring(err)))
  else
    ns.Util.say("/abars spike log | alpha")
  end
end

function Spike.start()
  for _, bar in ipairs(ns.Bars.list) do
    ns.Layout.watch(bar.id, onLayout)
    if padding0(bar.id) then ns.Layout.repack(bar.id, 0) end
  end
  if ns.Core then ns.Core.commands.spike = Spike.command end
end

ns.Spike = Spike
