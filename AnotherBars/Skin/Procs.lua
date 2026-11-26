local ADDON, ns = ...

-- The proc glow from the client's proc events: SPELL_ACTIVATION_OVERLAY_GLOW_SHOW
-- / _HIDE name a spell; every skinned button whose action is that spell (or
-- a macro casting it) glows. Blizzard's alert functions are not called on
-- Forever (found with /abars glow: no alert reached the hook), so this is
-- the main path. Spell ids pass Util.plain first (a secret changes nothing).
ns.Skin = ns.Skin or {}
local Procs = {}

local active = {} -- [spellID] = true while the proc is up
local frame

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

local function update(b)
  local id = Procs.spellOf(b)
  ns.Skin.Button.setProc(b, id ~= nil and active[id] == true)
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
  "ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR", "PLAYER_ENTERING_WORLD" }

local function onEvent(_, event, spellID)
  if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
    local id = ns.Util.plain(spellID)
    if id == nil then return end
    active[id] = event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or nil
  elseif event == "PLAYER_ENTERING_WORLD" then
    seed()
  end
  Procs.updateAll()
end

function Procs.start()
  if not frame then
    frame = CreateFrame("Frame")
    for _, ev in ipairs(EVENTS) do pcall(frame.RegisterEvent, frame, ev) end
    frame:SetScript("OnEvent", onEvent)
  end
  seed()
  Procs.updateAll()
end

ns.Skin.Procs = Procs
