local h = ...
local fakes = dofile("tests/fakes.lua")

local function load()
  return h.load({ "Core/Util.lua", "Skin/Blizzard.lua" })
end

-- A fake Blizzard action button with the usual regions.
local function button(name)
  local b = fakes.frame(name)
  b.icon = fakes.frame()
  b.HotKey, b.Count, b.Name = fakes.frame(), fakes.frame(), fakes.frame()
  b.cooldown = fakes.frame()
  b.Flash = fakes.frame()
  b.IconMask = fakes.frame()
  local normal = fakes.frame()
  b.GetNormalTexture = function() return normal end
  b._normal = normal
  return b
end

h.test("regions lists a button's parts", function()
  local ns = load()
  local b = button("ActionButton1")
  local r = ns.Skin.Blizzard.regions(b)
  h.eq(r.icon, b.icon)
  h.eq(r.hotkey, b.HotKey)
  h.eq(r.count, b.Count)
  h.eq(r.name, b.Name)
  h.eq(r.cooldown, b.cooldown)
  h.eq(r.mask, b.IconMask)
  local hide = {}
  for _, t in ipairs(r.hide) do hide[t] = true end
  h.eq(hide[b._normal], true)
  h.eq(hide[b.Flash], true)
end)

h.test("regions of a bare frame are empty, no error", function()
  local ns = load()
  local r = ns.Skin.Blizzard.regions(fakes.frame("Bare"))
  h.eq(r.icon, nil)
  h.eq(r.hide, {})
  h.eq(r.autocast, {})
end)

h.test("hookOnce hooks a target and name once", function()
  local ns = load()
  local client = fakes.client()
  local n = 0
  local real = _G.hooksecurefunc
  _G.hooksecurefunc = function(...) n = n + 1; return real(...) end
  local t = { Update = function() end }
  local seen = 0
  ns.Skin.Blizzard.hookOnce(t, "Update", function() seen = seen + 1 end)
  ns.Skin.Blizzard.hookOnce(t, "Update", function() seen = seen + 1 end)
  t.Update()
  h.eq(n, 1)
  h.eq(seen, 1)
  h.eq(ns.Skin.Blizzard.hookOnce(t, "Missing", function() end), false)
  client.restore()
end)

h.test("alerts hook the manager when it exists", function()
  local ns = load()
  local client = fakes.client()
  local shown = {}
  local manager = { ShowAlert = function() end, HideAlert = function() end }
  fakes.withGlobals({ ActionButtonSpellAlertManager = manager }, function()
    ns.Skin.Blizzard.onAlert(function(b) shown[#shown + 1] = { "show", b } end,
      function(b) shown[#shown + 1] = { "hide", b } end)
    manager:ShowAlert("b1")
    manager:HideAlert("b1")
  end)
  h.eq(shown, { { "show", "b1" }, { "hide", "b1" } })
  client.restore()
end)

h.test("alerts fall back to the global glow functions", function()
  local ns = load()
  local client = fakes.client()
  local shown = {}
  fakes.withGlobals({ ActionButtonSpellAlertManager = fakes.NIL,
    ActionButton_ShowOverlayGlow = function() end, ActionButton_HideOverlayGlow = function() end }, function()
    ns.Skin.Blizzard.onAlert(function(b) shown[#shown + 1] = { "show", b } end,
      function(b) shown[#shown + 1] = { "hide", b } end)
    _G.ActionButton_ShowOverlayGlow("b2")
    _G.ActionButton_HideOverlayGlow("b2")
  end)
  h.eq(shown, { { "show", "b2" }, { "hide", "b2" } })
  client.restore()
end)

h.test("pet update passes autocast allowed and enabled", function()
  local ns = load()
  local client = fakes.client()
  local got = {}
  local bar = { Update = function() end }
  local b1 = fakes.frame("PetActionButton1")
  fakes.withGlobals({ PetActionBar = bar, PetActionButton1 = b1,
    GetPetActionInfo = function(i) if i == 1 then return "Bite", 1, false, false, true, false end end }, function()
    ns.Skin.Blizzard.onPetUpdate(function(b, allowed, enabled) got[#got + 1] = { b, allowed, enabled } end)
    bar:Update()
  end)
  h.eq(got, { { b1, true, false } })
  client.restore()
end)

h.test("button hooks pass plain state", function()
  local ns = load()
  local client = fakes.client()
  local B = ns.Skin.Blizzard
  local b = button("ActionButton2")
  b.Update = function() end
  b.SetChecked = function(self, v) self._checked = v end
  b.GetChecked = function(self) return self._checked end
  b.SetButtonState = function() end
  local got = {}
  B.onUpdate(b, function() got[#got + 1] = "update" end)
  B.onChecked(b, function(_, on) got[#got + 1] = { "checked", on } end)
  B.onPressed(b, function(_, on) got[#got + 1] = { "pressed", on } end)
  B.onHover(b, function(_, on) got[#got + 1] = { "hover", on } end)
  b:Update()
  b:SetChecked(true)
  b:SetButtonState("PUSHED")
  b:SetButtonState("NORMAL")
  b:GetScript("OnEnter")(b)
  b:GetScript("OnLeave")(b)
  b:GetScript("OnMouseDown")(b)
  h.eq(got, { "update", { "checked", true }, { "pressed", true }, { "pressed", false },
    { "hover", true }, { "hover", false }, { "pressed", true } })
  client.restore()
end)

h.test("range hook passes inRange and checksRange", function()
  local ns = load()
  local client = fakes.client()
  local got = {}
  fakes.withGlobals({ ActionButton_UpdateRangeIndicator = function() end }, function()
    ns.Skin.Blizzard.onRange(function(b, inRange, checks) got[#got + 1] = { b, inRange, checks } end)
    _G.ActionButton_UpdateRangeIndicator("b", true, false)
  end)
  h.eq(got, { { "b", false, true } })
  client.restore()
end)
