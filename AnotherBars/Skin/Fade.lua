local ADDON, ns = ...

-- Fading (Core/Fade.lua): one driver frame of ours per bar animates the
-- bar frame's alpha. Only SetAlpha on the bar frame (allowed in combat,
-- Plan 1 spike); never Blizzard's UIFrameFade helpers (they write fadeInfo
-- onto the frame). A bar at 100% is never touched: no polling, no SetAlpha.
ns.Skin = ns.Skin or {}
local SkinFade = {}

local POLL = 0.1 -- seconds between mouse checks

local shared = { combat = false, editMode = false }
local drivers = {} -- [barId] = { frame, bar, opts, mouse, wait, alpha (ours), touched }
local events

function SkinFade.state(barId)
  return drivers[barId]
end

function SkinFade.setCombat(on)
  shared.combat = on and true or false
end

function SkinFade.setEditMode(on)
  shared.editMode = on and true or false
end

local function ensureEvents()
  if events then return end
  events = CreateFrame("Frame")
  events:RegisterEvent("PLAYER_REGEN_DISABLED")
  events:RegisterEvent("PLAYER_REGEN_ENABLED")
  events:SetScript("OnEvent", function(_, event) SkinFade.setCombat(event == "PLAYER_REGEN_DISABLED") end)
  SkinFade.setCombat(InCombatLockdown and InCombatLockdown())
end

-- The mouse over the bar frame (gaps included) or one of its shown buttons.
-- UNVERIFIED (check in client): IsMouseOver on the bar frame covers the
-- area between its buttons.
local function mouseOver(barId, frame)
  if frame.IsMouseOver and frame:IsMouseOver() then return true end
  local bar = ns.Bars.get(barId)
  for i = 1, bar.count do
    local b = rawget(_G, bar.button .. i)
    if b and b:IsShown() and b.IsMouseOver and b:IsMouseOver() then return true end
  end
  return false
end

local function onUpdate(d, elapsed)
  d.wait = d.wait - elapsed
  if d.wait <= 0 then
    d.wait = POLL
    d.mouse = mouseOver(d.id, d.bar)
  end
  local target = ns.Fade.target(d.opts, { combat = shared.combat, editMode = shared.editMode, mouse = d.mouse })
  -- Our own value, never GetAlpha: the client keeps alpha as a 32-bit
  -- float (it would never read back equal), and an outside change must not
  -- be fought. Once at the target nothing is written any more.
  local nextAlpha = ns.Fade.step(d.alpha, target, elapsed)
  if nextAlpha ~= d.alpha then
    d.alpha = nextAlpha
    d.bar:SetAlpha(nextAlpha)
    d.touched = true
  end
end

-- opts = { fadeAlpha, fadeMouseover }. Starts or stops the bar's driver.
function SkinFade.apply(barId, opts)
  local bar = ns.Bars.get(barId)
  local frame = bar and ns.Bars.frame(barId)
  if type(frame) ~= "table" then return end
  ensureEvents()
  local d = drivers[barId]
  if not d then
    d = { id = barId, frame = CreateFrame("Frame"), wait = 0, mouse = false }
    d.frame:Hide()
    d.frame:SetScript("OnUpdate", function(_, elapsed) onUpdate(d, elapsed) end)
    drivers[barId] = d
  end
  d.bar, d.opts = frame, opts
  if ns.Fade.active(opts.fadeAlpha) then
    d.wait = 0
    if d.alpha == nil then d.alpha = frame:GetAlpha() end
    d.frame:Show()
  else
    d.frame:Hide()
    d.alpha = nil
    if d.touched then
      d.touched = false
      frame:SetAlpha(1)
    end
  end
end

local function fmt(v)
  if type(v) ~= "number" then return tostring(v) end
  return string.format("%.2f", v)
end

-- Lines for /abars fade: the shared state, then each bar's driver.
function SkinFade.report()
  local lines = { "combat=" .. tostring(shared.combat) .. " editMode=" .. tostring(shared.editMode) }
  local ids = {}
  for id in pairs(drivers) do ids[#ids + 1] = id end
  table.sort(ids)
  for _, id in ipairs(ids) do
    local d = drivers[id]
    local on = d.frame:IsShown()
    local target = on and ns.Fade.target(d.opts, { combat = shared.combat, editMode = shared.editMode, mouse = d.mouse })
    local barMouse = d.bar.IsMouseOver and d.bar:IsMouseOver() or false
    lines[#lines + 1] = string.format("%s: %s alpha=%s target=%s mouse=%s barMouse=%s frameAlpha=%s",
      id, on and "on" or "off", fmt(d.alpha), fmt(target or nil), tostring(d.mouse), tostring(barMouse),
      fmt(ns.Util.plain(d.bar:GetAlpha())))
  end
  if #ids == 0 then lines[#lines + 1] = "no bar fades" end
  return lines
end

ns.Skin.Fade = SkinFade
