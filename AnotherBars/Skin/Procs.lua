local ADDON, ns = ...

-- Which skinned buttons show the proc glow. On Forever the game never
-- signals a proc (docs/CHECKLIST.md, Plan 3 results), so the main source is
-- our list of reactive spells (Core/Reactive.lua): a button whose spell (or
-- macro spell) has a listed spell's name glows while usable and off
-- cooldown. The game's proc events (SPELL_ACTIVATION_OVERLAY_GLOW_SHOW /
-- _HIDE) and Blizzard's alert hooks (Skin/Button.lua) stay as a second
-- source: a button glows when either says so. Client values pass
-- Util.plain first (a secret changes nothing).
ns.Skin = ns.Skin or {}
local Procs = {}

local active = {} -- [spellID] = true while the game's proc event says so
local reactiveUp = setmetatable({}, { __mode = "k" }) -- [button] = last known state
local frame

Procs.names = {} -- [spell name] = true: the player's reactive spells

-- UNVERIFIED (check in client): GetActionInfo returns "macro", spellID,
-- "spell" for a macro that shows a spell; GetMacroSpell for older macros.
function Procs.spellOf(b)
  local slot = b.action
  local info = rawget(_G, "GetActionInfo")
  if type(slot) ~= "number" or type(info) ~= "function" then return nil end
  local kind, id, sub = info(slot)
  kind, id, sub = ns.Util.plain(kind), ns.Util.plain(id), ns.Util.plain(sub)
  if kind == "spell" then return id end
  if kind == "macro" then
    if sub == "spell" then return id end
    local macroSpell = rawget(_G, "GetMacroSpell")
    if type(macroSpell) == "function" and id ~= nil then return ns.Util.plain(macroSpell(id)) end
  end
  return nil
end

-- A spell's name. UNVERIFIED (check in client): C_Spell.GetSpellName,
-- else GetSpellInfo.
local function nameOf(id)
  if id == nil then return nil end
  local api = rawget(_G, "C_Spell")
  if type(api) == "table" and type(api.GetSpellName) == "function" then
    return ns.Util.plainString(api.GetSpellName(id))
  end
  local info = rawget(_G, "GetSpellInfo")
  if type(info) == "function" then return ns.Util.plainString((info(id))) end
  return nil
end

-- Whether the spell is on cooldown: a boolean field only (no math on
-- cooldown numbers); nil when unknown.
-- UNVERIFIED (check in client): C_Spell.GetSpellCooldown(id).isActive.
local function onCooldown(id)
  local api = rawget(_G, "C_Spell")
  if type(api) ~= "table" or type(api.GetSpellCooldown) ~= "function" then return nil end
  local info = api.GetSpellCooldown(id)
  if type(info) ~= "table" then return nil end
  local v = ns.Util.plain(info.isActive)
  if type(v) == "boolean" then return v end
  return nil
end

-- The player's reactive spell names (Core/Reactive.lua by class).
local function buildNames()
  Procs.names = {}
  local unitClass = rawget(_G, "UnitClass")
  local token = nil
  if type(unitClass) == "function" then token = ns.Util.plainString(select(2, unitClass("player"))) end
  for _, id in ipairs(ns.Reactive.idsFor(token)) do
    local name = nameOf(id)
    if name then Procs.names[name] = true end
  end
end

function Procs.isReactive(b)
  local name = nameOf(Procs.spellOf(b))
  return name ~= nil and Procs.names[name] == true
end

local function reactive(b, id)
  if not Procs.isReactive(b) then
    reactiveUp[b] = nil
    return false
  end
  local isUsable = rawget(_G, "IsUsableAction")
  local usable = nil
  if type(isUsable) == "function" then usable = ns.Util.plain((isUsable(b.action))) end
  local up = ns.Reactive.isUp(usable, onCooldown(id))
  if up ~= nil then reactiveUp[b] = up end
  return reactiveUp[b] == true
end

local function update(b)
  local id = Procs.spellOf(b)
  local byEvent = id ~= nil and active[id] == true
  local byUse = reactive(b, id)
  ns.Skin.Button.setProc(b, byEvent or byUse)
end

function Procs.updateAll()
  ns.Skin.Button.each(update)
end

-- Procs already up (after /reload): asks the client for every button's spell.
-- UNVERIFIED (check in client): IsSpellOverlayed or
-- C_SpellActivationOverlay.IsSpellOverlayed.
local function seed()
  local api = rawget(_G, "C_SpellActivationOverlay")
  local is = (type(api) == "table" and api.IsSpellOverlayed) or rawget(_G, "IsSpellOverlayed")
  if type(is) ~= "function" then return end
  ns.Skin.Button.each(function(b)
    local id = Procs.spellOf(b)
    if id ~= nil and ns.Util.plain(is(id)) == true then active[id] = true end
  end)
end

local EVENTS = { "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE",
  "ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR", "PLAYER_ENTERING_WORLD",
  "ACTIONBAR_UPDATE_USABLE", "SPELL_UPDATE_USABLE", "ACTIONBAR_UPDATE_COOLDOWN", "SPELL_UPDATE_COOLDOWN",
  "PLAYER_TARGET_CHANGED", "UPDATE_SHAPESHIFT_FORM" }

local function onEvent(_, event, spellID)
  if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
    local id = ns.Util.plain(spellID)
    if id == nil then return end
    active[id] = event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or nil
  elseif event == "PLAYER_ENTERING_WORLD" then
    buildNames()
    seed()
  end
  Procs.updateAll()
end

function Procs.start()
  if not frame then
    frame = CreateFrame("Frame")
    for _, ev in ipairs(EVENTS) do pcall(frame.RegisterEvent, frame, ev) end
    -- Execute / Hammer of Wrath turn usable on the target's health.
    pcall(frame.RegisterUnitEvent, frame, "UNIT_HEALTH", "target")
    frame:SetScript("OnEvent", onEvent)
  end
  buildNames()
  seed()
  Procs.updateAll()
end

ns.Skin.Procs = Procs
