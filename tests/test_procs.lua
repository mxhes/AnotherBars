local h = ...
local fakes = dofile("tests/fakes.lua")

local FILES = { "Core/Util.lua", "Core/Theme.lua", "Core/DB.lua", "Core/Combat.lua", "Core/Look.lua",
  "Core/Reactive.lua", "Skin/Blizzard.lua", "Skin/Draw.lua", "Skin/Glow.lua", "Skin/Button.lua", "Skin/Procs.lua" }

-- actions[slot] = { type, id, subType }
-- opts: class (UnitClass token, default WARRIOR), usable[slot], cooldown[id]
-- (an info table for C_Spell.GetSpellCooldown).
local NAMES = { [7384] = "Overpower", [7887] = "Overpower", [133] = "Fireball", [100] = "Strike",
  [200] = "Smite", [300] = "Heal", [400] = "Shout", [500] = "Hamstring" }
local function setup(actions, overlayed, opts)
  opts = opts or {}
  local client = fakes.client()
  local saved = {}
  local usable = opts.usable or {}
  local globals = {
    UnitClass = function() return "Warrior", opts.class or "WARRIOR" end,
    IsUsableAction = function(slot) return usable[slot] or false, false end,
    C_Spell = { GetSpellName = function(id) return NAMES[id] end,
      GetSpellCooldown = function(id) return opts.cooldown and opts.cooldown[id] end },
    GetActionInfo = function(slot) local a = actions[slot]; if a then return a[1], a[2], a[3] end end,
    IsSpellOverlayed = function(id) return overlayed and overlayed[id] or false end,
    GetMacroSpell = function(i) if i == 7 then return 300 end end,
    CreateFont = function(name) return fakes.frame(name) end,
  }
  for k, v in pairs(globals) do saved[k] = rawget(_G, k); _G[k] = v end
  local ns = h.load(FILES)
  ns.db, ns.chardb = ns.DB.init(nil, nil)
  local function button(name, slot)
    local b = fakes.frame(name)
    b.icon = fakes.frame()
    b.action = slot
    ns.Skin.Button.skin(b, {})
    return b
  end
  local function cleanup()
    for k, v in pairs(saved) do _G[k] = v end
    client.restore()
  end
  return ns, client, button, cleanup, usable
end

local function glowing(ns, b) return ns.Skin.Button.state(b).glow.frame._shown end

h.test("glow follows the proc events of the button's spell", function()
  local ns, client, button, cleanup = setup({ [1] = { "spell", 100 }, [2] = { "spell", 200 } })
  local b1, b2 = button("ActionButton1", 1), button("ActionButton2", 2)
  ns.Skin.Procs.start()
  client.fire("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 100)
  h.eq(glowing(ns, b1), true)
  h.eq(glowing(ns, b2), false)
  client.fire("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", 100)
  h.eq(glowing(ns, b1), false)
  cleanup()
end)

h.test("a macro that casts the spell glows too", function()
  local ns, client, button, cleanup = setup({ [3] = { "macro", 7 }, [4] = { "macro", 400, "spell" } })
  local m1, m2 = button("ActionButton3", 3), button("ActionButton4", 4)
  ns.Skin.Procs.start()
  client.fire("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 300)
  client.fire("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 400)
  h.eq(glowing(ns, m1), true)
  h.eq(glowing(ns, m2), true)
  cleanup()
end)

h.test("a spell dragged onto a button during a proc glows", function()
  local actions = { [1] = { "spell", 100 } }
  local ns, client, button, cleanup = setup(actions)
  local b = button("ActionButton1", 1)
  ns.Skin.Procs.start()
  client.fire("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 500)
  h.eq(glowing(ns, b), false)
  actions[1] = { "spell", 500 }
  client.fire("ACTIONBAR_SLOT_CHANGED", 1)
  h.eq(glowing(ns, b), true)
  cleanup()
end)

h.test("a proc already up at start glows", function()
  local ns, _, button, cleanup = setup({ [1] = { "spell", 100 } }, { [100] = true })
  local b = button("ActionButton1", 1)
  ns.Skin.Procs.start()
  h.eq(glowing(ns, b), true)
  cleanup()
end)

h.test("secret spell ids change nothing", function()
  local ns, client, button, cleanup = setup({ [1] = { "spell", 100 } })
  local b = button("ActionButton1", 1)
  ns.Skin.Procs.start()
  client.fire("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", fakes.secret(1))
  h.eq(glowing(ns, b), false)
  cleanup()
end)

h.test("a reactive spell glows while usable (any rank)", function()
  local ns, client, button, cleanup, usable = setup({ [1] = { "spell", 7887 } })
  local b = button("ActionButton1", 1)
  ns.Skin.Procs.start()
  h.eq(glowing(ns, b), false)
  usable[1] = true
  client.fire("ACTIONBAR_UPDATE_USABLE")
  h.eq(glowing(ns, b), true)
  usable[1] = false
  client.fire("ACTIONBAR_UPDATE_USABLE")
  h.eq(glowing(ns, b), false)
  cleanup()
end)

h.test("on cooldown it does not glow", function()
  local ns, client, button, cleanup = setup({ [1] = { "spell", 7384 } }, nil,
    { usable = { [1] = true }, cooldown = { [7384] = { isActive = true } } })
  local b = button("ActionButton1", 1)
  ns.Skin.Procs.start()
  client.fire("SPELL_UPDATE_COOLDOWN")
  h.eq(glowing(ns, b), false)
  cleanup()
end)

h.test("unknown cooldown glows on usability", function()
  local ns, _, button, cleanup = setup({ [1] = { "spell", 7384 } }, nil, { usable = { [1] = true } })
  local b = button("ActionButton1", 1)
  ns.Skin.Procs.start()
  h.eq(glowing(ns, b), true)
  cleanup()
end)

h.test("a secret usable keeps the last state", function()
  local ns, client, button, cleanup, usable = setup({ [1] = { "spell", 7384 } }, nil, { usable = { [1] = true } })
  local b = button("ActionButton1", 1)
  ns.Skin.Procs.start()
  h.eq(glowing(ns, b), true)
  usable[1] = fakes.secret(1)
  client.fire("ACTIONBAR_UPDATE_USABLE")
  h.eq(glowing(ns, b), true)
  cleanup()
end)

h.test("a non-reactive spell never glows from usability", function()
  local ns, _, button, cleanup = setup({ [1] = { "spell", 133 } }, nil, { usable = { [1] = true } })
  local b = button("ActionButton1", 1)
  ns.Skin.Procs.start()
  h.eq(glowing(ns, b), false)
  cleanup()
end)

h.test("a macro casting Overpower glows", function()
  local ns, _, button, cleanup = setup({ [2] = { "macro", 7384, "spell" } }, nil, { usable = { [2] = true } })
  local b = button("ActionButton2", 2)
  ns.Skin.Procs.start()
  h.eq(glowing(ns, b), true)
  cleanup()
end)

h.test("event proc or reactive: either one glows", function()
  local ns, client, button, cleanup = setup({ [1] = { "spell", 7384 } })
  local b = button("ActionButton1", 1)
  ns.Skin.Procs.start()
  client.fire("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 7384)
  h.eq(glowing(ns, b), true)
  client.fire("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", 7384)
  h.eq(glowing(ns, b), false)
  cleanup()
end)

h.test("a class without reactive spells stays dark", function()
  local ns, client, button, cleanup = setup({ [1] = { "spell", 7384 } }, nil,
    { class = "MAGE", usable = { [1] = true } })
  local b = button("ActionButton1", 1)
  ns.Skin.Procs.start()
  client.fire("ACTIONBAR_UPDATE_USABLE")
  h.eq(glowing(ns, b), false)
  cleanup()
end)
