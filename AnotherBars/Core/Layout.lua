local ADDON, ns = ...

-- Client glue for our padding on Blizzard's bars. Nothing here writes to a
-- Blizzard table: the hook goes through hooksecurefunc, and which bars are
-- hooked is kept in our own table. Re-anchoring runs out of combat only
-- (Combat.after); button 1 never moves.
local Layout = {}

local watched = {} -- [barId] = true once hooked
local callbacks = {} -- [barId] = onLayout

-- Calls onLayout(barId, inCombat) every time Blizzard lays out the bar.
-- UNVERIFIED (check in client): the bars' layout method is UpdateGridLayout
-- on Forever (docs/CHECKLIST.md, "Plan 1 spike").
function Layout.watch(barId, onLayout)
  local bar = ns.Bars.get(barId)
  local frame = bar and _G[bar.frame]
  if not frame or type(frame.UpdateGridLayout) ~= "function" then return end
  callbacks[barId] = callbacks[barId] or onLayout
  if watched[barId] then return end
  watched[barId] = true
  hooksecurefunc(frame, "UpdateGridLayout", function()
    local fn = callbacks[barId]
    if fn then fn(barId, InCombatLockdown() and true or false) end
  end)
end

-- The shown buttons of a bar, in order.
local function shownButtons(bar)
  local list = {}
  for i = 1, bar.count do
    local b = _G[bar.button .. i]
    if b and b:IsShown() then list[#list + 1] = b end
  end
  return list
end

-- Re-anchors the bar's shown buttons 2..n to button 1 with `padding` between
-- them, keeping Blizzard's rows, columns and direction (ns.Grid). Queued
-- until combat ends when in combat.
-- UNVERIFIED (check in client): buttons share one scale, so GetLeft / GetTop
-- differences and GetWidth / GetHeight are in the buttons' own units.
function Layout.repack(barId, padding)
  local bar = ns.Bars.get(barId)
  if not bar then return end
  ns.Combat.after("repack:" .. barId, function()
    local buttons = shownButtons(bar)
    local first = buttons[1]
    if not first then return end
    local x0, y0 = first:GetLeft(), first:GetTop()
    local w, h = first:GetWidth(), first:GetHeight()
    if not (x0 and y0 and w and h) then return end
    local offsets = {}
    for i, b in ipairs(buttons) do
      offsets[i] = { (b:GetLeft() or x0) - x0, (b:GetTop() or y0) - y0 }
    end
    local packed = ns.Grid.repack(offsets, w, h, padding)
    for i = 2, #buttons do
      local b = buttons[i]
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", first, "TOPLEFT", packed[i][1], packed[i][2])
    end
  end)
end

ns.Layout = Layout
