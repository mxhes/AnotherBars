local h = ...
local fakes = dofile("tests/fakes.lua")

local FILES = { "Core/Util.lua", "Core/Theme.lua", "Core/DB.lua", "Core/Combat.lua", "Core/Look.lua",
  "Skin/Blizzard.lua", "Skin/Draw.lua", "Skin/Glow.lua", "Skin/Button.lua" }

local OPTS = { shading = "Skin", hotkey = true, count = true, macro = true, fontSize = 10 }

-- A fake Blizzard action button with the usual regions.
local function button(name)
  local b = fakes.frame(name)
  b.icon = fakes.frame()
  b.HotKey, b.Count, b.Name = fakes.frame(), fakes.frame(), fakes.frame()
  b.cooldown = fakes.frame()
  b.Flash = fakes.frame()
  b.action = 1
  local textures = {}
  for _, k in ipairs({ "Normal", "Highlight", "Pushed", "Checked" }) do
    local t = fakes.frame()
    textures[k] = t
    b["Get" .. k .. "Texture"] = function() return t end
  end
  b._tex = textures
  b.Update = function() end
  b.SetChecked = function(self, v) self._checked = v end
  b.GetChecked = function(self) return self._checked end
  return b
end

-- Loads the skin with a fake client; returns ns, client, cleanup.
local function setup(opts)
  local client = fakes.client(opts)
  local made = 0
  local create = _G.CreateFrame
  _G.CreateFrame = function(...) made = made + 1; return create(...) end
  local saved = { CreateFont = rawget(_G, "CreateFont"), IsUsableAction = rawget(_G, "IsUsableAction"),
    ActionButton_UpdateRangeIndicator = rawget(_G, "ActionButton_UpdateRangeIndicator") }
  _G.CreateFont = function(name) local f = fakes.frame(name); _G[name] = f; return f end
  _G.IsUsableAction = function() return true, false end
  _G.ActionButton_UpdateRangeIndicator = function() end
  local ns = h.load(FILES)
  ns.db, ns.chardb = ns.DB.init(nil, nil)
  local function cleanup()
    for k, v in pairs(saved) do _G[k] = v end
    for s = 6, 24 do _G["AnotherBarsCooldown" .. s] = nil end
    client.restore()
  end
  return ns, client, cleanup, function() return made end
end

local function shownCount(list)
  local n = 0
  for _, t in ipairs(list) do if t._shown then n = n + 1 end end
  return n
end

h.test("skin creates one overlay set", function()
  local ns, _, cleanup, made = setup()
  local b = button("ActionButton1")
  ns.Skin.Button.skin(b, OPTS)
  local first = made()
  h.eq(first > 0, true)
  ns.Skin.Button.skin(b, OPTS)
  h.eq(made(), first)
  cleanup()
end)

h.test("Blizzard textures go to alpha 0", function()
  local ns, _, cleanup = setup()
  local b = button("ActionButton1")
  ns.Skin.Button.skin(b, OPTS)
  for k, t in pairs(b._tex) do h.eq(t._alpha, 0, k) end
  h.eq(b.Flash._alpha, 0)
  cleanup()
end)

h.test("skin in combat waits for combat to end", function()
  local ns, client, cleanup, made = setup({ inCombat = true })
  local b = button("ActionButton1")
  ns.Skin.Button.skin(b, OPTS)
  h.eq(made() <= 1, true) -- at most the combat queue's own frame
  h.eq(ns.Skin.Button.state(b), nil)
  client.setCombat(false)
  client.fire("PLAYER_REGEN_ENABLED")
  h.eq(type(ns.Skin.Button.state(b)), "table")
  cleanup()
end)

h.test("a missing button is skipped", function()
  local ns, _, cleanup = setup()
  ns.Skin.Button.skin(nil, OPTS)
  cleanup()
end)

h.test("range hook tints the icon, a secret leaves Blizzard's tint", function()
  local ns, _, cleanup = setup()
  local b = button("ActionButton1")
  ns.Skin.Button.skin(b, OPTS)
  -- in range and usable: white (ours, but no tint to take back)
  b.icon._color = nil
  _G.ActionButton_UpdateRangeIndicator(b, true, fakes.secret(1))
  h.eq(b.icon._color, nil)
  _G.ActionButton_UpdateRangeIndicator(b, true, false)
  h.eq(b.icon._color, { 0.8, 0.1, 0.1, nil })
  cleanup()
end)

h.test("empty slot follows the icon", function()
  local ns, _, cleanup = setup()
  local b = button("ActionButton1")
  b.icon._shown = false
  ns.Skin.Button.skin(b, OPTS)
  local st = ns.Skin.Button.state(b)
  h.eq(st.empty._shown, true)
  b.icon._shown = true
  b:Update()
  h.eq(st.empty._shown, false)
  cleanup()
end)

h.test("checked shows the active edge", function()
  local ns, _, cleanup = setup()
  local b = button("ActionButton1")
  ns.Skin.Button.skin(b, OPTS)
  local st = ns.Skin.Button.state(b)
  h.eq(shownCount(st.active), 0)
  b:SetChecked(true)
  h.eq(shownCount(st.active), #st.active)
  b:SetChecked(false)
  h.eq(shownCount(st.active), 0)
  cleanup()
end)

h.test("texts off use alpha, never Hide", function()
  local ns, _, cleanup = setup()
  local b = button("ActionButton1")
  ns.Skin.Button.skin(b, { shading = "Skin", hotkey = false, count = true, macro = false, fontSize = 12 })
  h.eq(b.HotKey._alpha, 0)
  h.eq(b.Name._alpha, 0)
  h.eq(b.Count._alpha, 1)
  for _, c in ipairs(b.HotKey.calls) do h.eq(c[1] ~= "Hide", true) end
  h.eq(b.HotKey._font[2], 12)
  h.eq(b.Count._font[2], 14)
  cleanup()
end)

h.test("skin change relayouts the same overlay", function()
  local ns, _, cleanup, made = setup()
  local b = button("ActionButton1")
  ns.Skin.Button.skin(b, OPTS)
  local n = made()
  local st = ns.Skin.Button.state(b)
  ns.DB.profile().skin = "forge"
  ns.Skin.Button.relayoutAll()
  h.eq(made(), n)
  local rects = 0
  for _, r in ipairs(st.rects) do if r[1]._shown then rects = rects + 1 end end
  h.eq(rects, 5)
  cleanup()
end)

h.test("glow shows over the button and mutes Blizzard's alert", function()
  local ns, _, cleanup = setup()
  local b = button("ActionButton1")
  b.SpellActivationAlert = fakes.frame()
  ns.Skin.Button.skin(b, OPTS)
  local st = ns.Skin.Button.state(b)
  h.eq(st.glow.frame._shown, false)
  st.glow:show()
  h.eq(st.glow.frame._shown, true)
  h.eq(b.SpellActivationAlert._alpha, 0)
  st.glow:hide()
  h.eq(st.glow.frame._shown, false)
  cleanup()
end)

h.test("no field written on a skinned button", function()
  local ns, _, cleanup = setup()
  local b = button("ActionButton1")
  -- hooks replace methods (hooksecurefunc); everything else must stay
  local before = {}
  for k in pairs(b) do before[k] = true end
  ns.Skin.Button.skin(b, OPTS)
  local hooks = { Update = true, SetChecked = true, UpdateUsable = true, SetButtonState = true }
  for k in pairs(b) do
    if not before[k] and not hooks[k] and k ~= "calls" then error("new field on button: " .. tostring(k)) end
  end
  cleanup()
end)

h.test("final: refresh clears the empty look once the icon shows", function()
  local ns, _, cleanup = setup()
  local b = button("PetActionButton1")
  b.Update = nil -- pet buttons have no per-button Update
  b.icon._shown = false
  ns.Skin.Button.skin(b, OPTS)
  local st = ns.Skin.Button.state(b)
  h.eq(st.empty._shown, true)
  b.icon._shown = true
  ns.Skin.Button.refresh(b)
  h.eq(st.empty._shown, false)
  cleanup()
end)

h.test("final: our red tint is undone when the next tint is unknown", function()
  local ns, _, cleanup = setup()
  local b = button("ActionButton1")
  ns.Skin.Button.skin(b, OPTS)
  _G.ActionButton_UpdateRangeIndicator(b, true, false)
  h.eq(b.icon._color, { 0.8, 0.1, 0.1, nil })
  _G.IsUsableAction = function() return fakes.secret(1), false end
  _G.ActionButton_UpdateRangeIndicator(b, true, true)
  h.eq(b.icon._color, { 1, 1, 1, nil })
  cleanup()
end)

h.test("final: buttons without an action keep Blizzard's icon tint", function()
  local ns, _, cleanup = setup()
  local b = button("StanceButton1")
  b.action = nil
  ns.Skin.Button.skin(b, OPTS)
  h.eq(b.icon._color, nil)
  cleanup()
end)

h.test("final: Blizzard's slot art goes to alpha 0", function()
  local ns, _, cleanup = setup()
  local b = button("ActionButton1")
  b.SlotBackground, b.SlotArt = fakes.frame(), fakes.frame()
  ns.Skin.Button.skin(b, OPTS)
  h.eq(b.SlotBackground._alpha, 0)
  h.eq(b.SlotArt._alpha, 0)
  cleanup()
end)

-- The game can clear the checked flag without calling SetChecked (seen in
-- the client: GetChecked false, gold edge still on). Every chance re-reads it.
local function stuckChecked()
  local ns, client, cleanup = setup()
  local b = button("ActionButton1")
  b.SetButtonState = function() end
  ns.Skin.Button.skin(b, OPTS)
  local st = ns.Skin.Button.state(b)
  b:SetChecked(true)
  h.eq(shownCount(st.active), #st.active)
  b._checked = false -- cleared inside the game, no SetChecked call
  return ns, client, cleanup, b, st
end

h.test("checked cleared by the game: Update re-reads it", function()
  local _, _, cleanup, b, st = stuckChecked()
  b:Update()
  h.eq(shownCount(st.active), 0)
  cleanup()
end)

h.test("checked cleared by the game: releasing the key re-reads it", function()
  local _, _, cleanup, b, st = stuckChecked()
  b:SetButtonState("NORMAL")
  h.eq(shownCount(st.active), 0)
  cleanup()
end)

h.test("checked cleared by the game: after a click it is re-read", function()
  local _, _, cleanup, b, st = stuckChecked()
  b._scripts.PostClick(b, "LeftButton", false)
  h.eq(shownCount(st.active), 0)
  cleanup()
end)

h.test("checked cleared by the game: ACTIONBAR_UPDATE_STATE re-reads every button", function()
  local _, client, cleanup, _, st = stuckChecked()
  client.fire("ACTIONBAR_UPDATE_STATE")
  h.eq(shownCount(st.active), 0)
  cleanup()
end)

h.test("a secret checked value keeps the edge", function()
  local _, client, cleanup, b, st = stuckChecked()
  b._checked = fakes.secret(1)
  fakes.withGlobals({ issecretvalue = fakes.isSecret }, function()
    b:Update()
    client.fire("ACTIONBAR_UPDATE_STATE")
  end)
  h.eq(shownCount(st.active), #st.active)
  cleanup()
end)

-- Padding 0 (APPROVED.md §6): the bar frame draws panel and border, the
-- button keeps its icon size and draws its states inside the icon.
local FRAMED = { shading = "Skin", hotkey = true, count = true, macro = true, fontSize = 10, framed = true }

local function firstPoint(t, name)
  for _, p in ipairs(t._points or {}) do if p[1] == name then return { p[4], p[5] } end end
end

h.test("framed hides fill, backdrop and edges", function()
  local ns, _, cleanup = setup()
  ns.DB.profile().skin = "slate"
  local b = button("ActionButton1")
  ns.Skin.Button.skin(b, FRAMED)
  local st = ns.Skin.Button.state(b)
  h.eq(st.fill._shown, false)
  h.eq(st.back._backdrop, nil)
  local rects = 0
  for _, r in ipairs(st.rects) do if r[1]._shown then rects = rects + 1 end end
  h.eq(rects, 0)
  h.eq(firstPoint(b.icon, "TOPLEFT"), { 2, -2 })
  cleanup()
end)

h.test("framed hover draws the inner gold edge", function()
  local ns, _, cleanup = setup()
  local b = button("ActionButton1")
  ns.Skin.Button.skin(b, FRAMED)
  local st = ns.Skin.Button.state(b)
  h.eq(shownCount(st.hoverEdge), 0)
  b._scripts.OnEnter(b)
  h.eq(shownCount(st.hoverEdge), 4)
  b._scripts.OnLeave(b)
  h.eq(shownCount(st.hoverEdge), 0)
  cleanup()
end)

h.test("not framed: hover never shows the inner edge", function()
  local ns, _, cleanup = setup()
  local b = button("ActionButton1")
  ns.Skin.Button.skin(b, OPTS)
  b._scripts.OnEnter(b)
  h.eq(shownCount(ns.Skin.Button.state(b).hoverEdge), 0)
  cleanup()
end)

h.test("framed overlays stay inside the icon", function()
  local ns, _, cleanup = setup()
  ns.DB.profile().skin = "slate"
  local b = button("ActionButton1")
  ns.Skin.Button.skin(b, FRAMED)
  local st = ns.Skin.Button.state(b)
  for _, t in ipairs({ st.hoverFill, st.pressedFill, st.empty }) do h.eq(firstPoint(t, "TOPLEFT"), { 2, -2 }) end
  cleanup()
end)

h.test("framed glow sits around the icon", function()
  local ns, _, cleanup = setup()
  ns.DB.profile().skin = "slate"
  local g = ns.Theme.button.glow
  local pad = g.out + g.outer
  local b = button("ActionButton1")
  ns.Skin.Button.skin(b, FRAMED)
  local frame = ns.Skin.Button.state(b).glow.frame
  h.eq(firstPoint(frame, "TOPLEFT"), { -pad + 2, pad - 2 })
  ns.Skin.Button.skin(b, OPTS)
  h.eq(firstPoint(frame, "TOPLEFT"), { -pad, pad })
  cleanup()
end)

h.test("back to padding 2 restores the per-button look", function()
  local ns, _, cleanup = setup()
  ns.DB.profile().skin = "slate"
  local b = button("ActionButton1")
  ns.Skin.Button.skin(b, FRAMED)
  ns.Skin.Button.skin(b, OPTS)
  local st = ns.Skin.Button.state(b)
  h.eq(st.fill._shown, true)
  local rects = 0
  for _, r in ipairs(st.rects) do if r[1]._shown then rects = rects + 1 end end
  h.eq(rects, 2)
  b._scripts.OnEnter(b)
  h.eq(shownCount(st.hoverEdge), 0)
  cleanup()
end)
