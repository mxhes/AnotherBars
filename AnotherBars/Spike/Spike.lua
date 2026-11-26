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

-- Diagnostic trace (debugging the jumbled Action Bar 1 after /reload):
-- each entry records why it was taken and every button of the bar with its
-- geometry and anchors, into AnotherBarsDB.spikeTrace (last TRACE_MAX
-- entries, readable from the saved variables file after /reload).
local TRACE_MAX = 60
local traceBar = "bar1"

local function round(v)
  if type(v) ~= "number" then return v end
  return math.floor(v * 10 + 0.5) / 10
end

local function snapshot(id)
  local bar = ns.Bars.get(id)
  local out = {}
  for i = 1, bar.count do
    local b = _G[bar.button .. i]
    if b then
      local points = {}
      for p = 1, (b.GetNumPoints and b:GetNumPoints() or 0) do
        local point, rel, relPoint, x, y = b:GetPoint(p)
        points[p] = string.format("%s>%s:%s %s,%s", tostring(point),
          rel and rel.GetName and rel:GetName() or tostring(rel), tostring(relPoint), tostring(round(x)), tostring(round(y)))
      end
      out[i] = string.format("%d shown=%s L=%s T=%s W=%s H=%s S=%s parent=%s | %s", i,
        tostring(b:IsShown()), tostring(round(b:GetLeft())), tostring(round(b:GetTop())),
        tostring(round(b:GetWidth())), tostring(round(b:GetHeight())), tostring(round(b:GetScale())),
        b.GetParent and b:GetParent() and b:GetParent().GetName and tostring(b:GetParent():GetName()) or "?",
        table.concat(points, " ; "))
    end
  end
  return out
end

function Spike.trace(reason, id)
  id = id or traceBar
  if not ns.db then return end
  local list = ns.db.spikeTrace
  if type(list) ~= "table" then list = {}; ns.db.spikeTrace = list end
  local now = type(GetTime) == "function" and GetTime() or 0
  list[#list + 1] = { reason = reason, bar = id, time = round(now),
    inCombat = type(InCombatLockdown) == "function" and InCombatLockdown() or false, buttons = snapshot(id) }
  while #list > TRACE_MAX do table.remove(list, 1) end
end

local function onLayout(id, inCombat)
  local bar = ns.Bars.get(id)
  if id == traceBar then Spike.trace("blizzard layout (before repack)", id) end
  if logging then
    ns.Util.say(string.format("%s laid out (in combat: %s)", bar.label, inCombat and "yes" or "no"))
  end
  if padding0(id) then
    ns.Layout.repack(id, 0)
    if id == traceBar then Spike.trace("after repack (layout)", id) end
  end
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
  if ns.db then ns.db.spikeTrace = {} end
  Spike.trace("ADDON_LOADED (before start repack)")
  for _, bar in ipairs(ns.Bars.list) do
    ns.Layout.watch(bar.id, onLayout)
    if padding0(bar.id) then ns.Layout.repack(bar.id, 0) end
  end
  Spike.trace("ADDON_LOADED (after start repack)")
  if ns.Core then ns.Core.commands.spike = Spike.command end
  -- Later load steps, to see when Blizzard's Edit Mode layout lands.
  if type(CreateFrame) == "function" then
    local f = CreateFrame("Frame")
    for _, ev in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "EDIT_MODE_LAYOUTS_UPDATED" }) do
      pcall(f.RegisterEvent, f, ev)
    end
    f:SetScript("OnEvent", function(_, event) Spike.trace(event) end)
  end
end

ns.Spike = Spike
