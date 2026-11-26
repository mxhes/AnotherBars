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

-- Per button, in our own weak table (never fields on Blizzard's buttons):
-- base = Blizzard's own anchor { point, rel, relPoint, x, y }, dx / dy = the
-- offset we added to it, set = the anchor we set last.
local state = setmetatable({}, { __mode = "k" })

local function near(a, b) return math.abs((a or 0) - (b or 0)) < 0.01 end

local function sameAnchor(a, b)
  return a and b and a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and near(a[4], b[4]) and near(a[5], b[5])
end

-- The button's single anchor, or nil when it has none or several.
local function anchorOf(b)
  if not (b.GetNumPoints and b:GetNumPoints() == 1) then return nil end
  local point, rel, relPoint, x, y = b:GetPoint(1)
  return { point, rel, relPoint, x or 0, y or 0 }
end

-- The button's state, renewed when Blizzard anchored it anew since our last
-- SetPoint (then Blizzard's anchor is the base and our offset is gone).
local function stateOf(b)
  local cur = anchorOf(b)
  local st = state[b]
  if st and sameAnchor(cur, st.set) then return st end
  st = { base = cur, dx = 0, dy = 0 }
  state[b] = st
  return st
end

-- Moves the bar's shown buttons 2..n so they sit `padding` apart from
-- button 1, keeping Blizzard's rows, columns and direction (ns.Grid). Each
-- button stays on Blizzard's own anchor (on the main bar: its container) with
-- only the offset changed, so when Blizzard moves the containers the buttons
-- follow, and a second repack gives the same result. Queued until combat ends.
-- UNVERIFIED (check in client): buttons share one scale, so GetLeft / GetTop
-- differences and GetWidth / GetHeight are in the buttons' own units.
function Layout.repack(barId, padding)
  local bar = ns.Bars.get(barId)
  if not bar then return end
  ns.Combat.after("repack:" .. barId, function()
    local buttons = shownButtons(bar)
    local first = buttons[1]
    if not first then return end
    local w, h = first:GetWidth(), first:GetHeight()
    if not (w and h) then return end
    -- where Blizzard has each button: its position minus our offset
    local pos, states = {}, {}
    for i, b in ipairs(buttons) do
      local st = stateOf(b)
      local l, t = b:GetLeft(), b:GetTop()
      if not (l and t) then return end
      states[i] = st
      pos[i] = { l - st.dx, t - st.dy }
    end
    local x0, y0 = pos[1][1], pos[1][2]
    local offsets = {}
    for i = 1, #buttons do offsets[i] = { pos[i][1] - x0, pos[i][2] - y0 } end
    local packed = ns.Grid.repack(offsets, w, h, padding)
    for i = 2, #buttons do
      local b, st = buttons[i], states[i]
      local base = st.base
      if base then
        st.dx = x0 + packed[i][1] - pos[i][1]
        st.dy = y0 + packed[i][2] - pos[i][2]
        st.set = { base[1], base[2], base[3], base[4] + st.dx, base[5] + st.dy }
        b:ClearAllPoints()
        b:SetPoint(st.set[1], st.set[2], st.set[3], st.set[4], st.set[5])
      end
    end
  end)
end

ns.Layout = Layout
