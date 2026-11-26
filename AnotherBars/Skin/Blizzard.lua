local ADDON, ns = ...

-- Every Blizzard name the skin uses, in one place: the regions of a button
-- and the update functions we hook. A name that is missing on Forever does
-- nothing (no error); fixing a wrong one is a change here only. Nothing here
-- writes to a Blizzard table: hooks go through hooksecurefunc / HookScript,
-- and what is hooked is remembered in our own weak table.
ns.Skin = ns.Skin or {}
local Blizzard = {}

local hooked = setmetatable({}, { __mode = "k" }) -- [target] = { [name] = true }

local function region(v)
  if type(v) == "table" then return v end
  return nil
end

-- The first of the fields that holds a region.
local function field(b, ...)
  for i = 1, select("#", ...) do
    local v = region(b[select(i, ...)])
    if v then return v end
  end
  return nil
end

local function method(b, name)
  local f = b[name]
  if type(f) ~= "function" then return nil end
  local ok, v = pcall(f, b)
  return ok and region(v) or nil
end

-- UNVERIFIED (check in client): the region names of ActionButton /
-- StanceButton / PetActionButton on Forever.
function Blizzard.regions(b)
  local out = { hide = {}, autocast = {} }
  if type(b) ~= "table" then return out end
  out.icon = field(b, "icon", "Icon")
  out.cooldown = field(b, "cooldown", "Cooldown")
  out.hotkey = field(b, "HotKey")
  out.count = field(b, "Count")
  out.name = field(b, "Name")
  out.mask = field(b, "IconMask")
  local function add(t) if t then out.hide[#out.hide + 1] = t end end
  add(method(b, "GetNormalTexture"))
  add(method(b, "GetHighlightTexture"))
  add(method(b, "GetPushedTexture"))
  add(method(b, "GetCheckedTexture"))
  for _, k in ipairs({ "Flash", "Border", "NewActionTexture", "SpellHighlightTexture", "SlotBackground", "SlotArt" }) do add(field(b, k)) end
  for _, k in ipairs({ "AutoCastOverlay", "AutoCastable", "AutoCastShine" }) do
    local t = field(b, k)
    if t then out.autocast[#out.autocast + 1] = t end
  end
  return out
end

-- hooksecurefunc(target, name, fn) once per target and name. False when
-- target[name] is not a function (the name does not exist here).
function Blizzard.hookOnce(target, name, fn)
  if type(target) ~= "table" or type(target[name]) ~= "function" then return false end
  local set = hooked[target]
  if not set then set = {}; hooked[target] = set end
  if set[name] then return true end
  set[name] = true
  if target == _G then hooksecurefunc(name, fn) else hooksecurefunc(target, name, fn) end
  return true
end

-- HookScript(event, fn) once per frame and event.
local function hookScript(b, event, fn)
  if type(b) ~= "table" or type(b.HookScript) ~= "function" then return end
  local set = hooked[b]
  if not set then set = {}; hooked[b] = set end
  local key = "script:" .. event
  if set[key] then return end
  set[key] = true
  b:HookScript(event, fn)
end

-- fn(button, inRange, checksRange) after Blizzard updates a button's range.
-- UNVERIFIED (check in client): the global ActionButton_UpdateRangeIndicator.
function Blizzard.onRange(fn)
  return Blizzard.hookOnce(_G, "ActionButton_UpdateRangeIndicator", function(b, checksRange, inRange)
    fn(b, inRange, checksRange)
  end)
end

-- fn(button) after Blizzard updates the button (action, usable).
-- UNVERIFIED (check in client): the Update / UpdateUsable methods.
function Blizzard.onUpdate(b, fn)
  Blizzard.hookOnce(b, "Update", function(self) fn(self) end)
  Blizzard.hookOnce(b, "UpdateUsable", function(self) fn(self) end)
end

-- fn(button, checked) after SetChecked (the value read back from the button).
function Blizzard.onChecked(b, fn)
  Blizzard.hookOnce(b, "SetChecked", function(self)
    local get, checked = self.GetChecked, nil
    if type(get) == "function" then checked = get(self) end
    fn(self, checked)
  end)
end

-- fn(button, pressed): keybind presses (SetButtonState) and mouse clicks.
function Blizzard.onPressed(b, fn)
  Blizzard.hookOnce(b, "SetButtonState", function(self, state) fn(self, state == "PUSHED") end)
  hookScript(b, "OnMouseDown", function(self) fn(self, true) end)
  hookScript(b, "OnMouseUp", function(self) fn(self, false) end)
end

-- fn(button, over) on mouse enter / leave.
function Blizzard.onHover(b, fn)
  hookScript(b, "OnEnter", function(self) fn(self, true) end)
  hookScript(b, "OnLeave", function(self) fn(self, false) end)
end

-- show(button) / hide(button) when Blizzard shows / hides its spell alert.
-- UNVERIFIED (check in client): ActionButtonSpellAlertManager (newer) or the
-- ActionButton_ShowOverlayGlow / HideOverlayGlow globals (older).
function Blizzard.onAlert(show, hide)
  local manager = rawget(_G, "ActionButtonSpellAlertManager")
  if type(manager) == "table" and type(manager.ShowAlert) == "function" then
    Blizzard.hookOnce(manager, "ShowAlert", function(_, b) show(b) end)
    Blizzard.hookOnce(manager, "HideAlert", function(_, b) hide(b) end)
    return true
  end
  local a = Blizzard.hookOnce(_G, "ActionButton_ShowOverlayGlow", function(b) show(b) end)
  local c = Blizzard.hookOnce(_G, "ActionButton_HideOverlayGlow", function(b) hide(b) end)
  return a or c
end

-- Blizzard's spell alert frame of a button (created on its first show).
-- UNVERIFIED (check in client): the SpellActivationAlert field.
function Blizzard.spellAlert(b)
  return type(b) == "table" and field(b, "SpellActivationAlert") or nil
end

local PET_BUTTONS = 10

-- fn(button, autoCastAllowed, autoCastEnabled) for each pet button after
-- Blizzard updates the pet bar. Returns the runner (call it once to start).
-- UNVERIFIED (check in client): PetActionBar:Update or PetActionBar_Update,
-- and GetPetActionInfo values 5 / 6.
function Blizzard.onPetUpdate(fn)
  local function run()
    local info = rawget(_G, "GetPetActionInfo")
    if type(info) ~= "function" then return end
    for i = 1, PET_BUTTONS do
      local b = rawget(_G, "PetActionButton" .. i)
      if b then
        local _, _, _, _, allowed, enabled = info(i)
        fn(b, allowed, enabled)
      end
    end
  end
  local bar = rawget(_G, "PetActionBar")
  if not Blizzard.hookOnce(bar, "Update", run) then Blizzard.hookOnce(_G, "PetActionBar_Update", run) end
  return run
end

-- fn(button) for each stance button after Blizzard updates the stance bar.
-- UNVERIFIED (check in client): StanceBar:UpdateState or StanceBar_UpdateState.
function Blizzard.onStanceUpdate(fn)
  local function run()
    for i = 1, 10 do
      local b = rawget(_G, "StanceButton" .. i)
      if b then fn(b) end
    end
  end
  local bar = rawget(_G, "StanceBar")
  if not Blizzard.hookOnce(bar, "UpdateState", run) then Blizzard.hookOnce(_G, "StanceBar_UpdateState", run) end
  return run
end

ns.Skin.Blizzard = Blizzard
