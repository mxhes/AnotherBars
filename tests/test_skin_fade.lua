local h = ...
local fakes = dofile("tests/fakes.lua")

local FILES = { "Core/Util.lua", "Core/Bars.lua", "Core/Fade.lua", "Skin/Fade.lua" }

local function near(a, b) return a ~= nil and math.abs(a - b) < 1e-9 end

-- A fake MultiBarBottomLeft (bar2) with two buttons; the mouse is over
-- nothing until a test says so.
local function setup()
  local client = fakes.client()
  local bar = fakes.frame("MultiBarBottomLeft")
  _G.MultiBarBottomLeft = bar
  local buttons = {}
  for i = 1, 2 do
    local b = fakes.frame("MultiBarBottomLeftButton" .. i)
    b._shown = true
    _G["MultiBarBottomLeftButton" .. i] = b
    buttons[i] = b
  end
  local mouse = {}
  bar.IsMouseOver = function() return mouse.bar == true end
  for i, b in ipairs(buttons) do b.IsMouseOver = function() return mouse[i] == true end end
  local ns = h.load(FILES)
  local F = ns.Skin.Fade
  local function run(seconds)
    local d = F.state("bar2").frame
    local t = 0
    while t < seconds - 1e-9 do
      if d._shown and d._scripts.OnUpdate then d._scripts.OnUpdate(d, 0.05) end
      t = t + 0.05
    end
  end
  local function cleanup()
    _G.MultiBarBottomLeft = nil
    for i = 1, 2 do _G["MultiBarBottomLeftButton" .. i] = nil end
    F.setCombat(false)
    F.setEditMode(false)
    client.restore()
  end
  return ns, F, bar, mouse, run, client, cleanup
end

h.test("at 100% nothing touches the alpha", function()
  local _, F, bar, _, run, _, cleanup = setup()
  F.apply("bar2", { fadeAlpha = 100, fadeMouseover = true })
  run(1)
  h.eq(bar._alpha, nil)
  h.eq(F.state("bar2").frame._shown, false)
  cleanup()
end)

h.test("fades out of combat", function()
  local _, F, bar, _, run, _, cleanup = setup()
  F.apply("bar2", { fadeAlpha = 40, fadeMouseover = true })
  run(1)
  h.eq(near(bar._alpha, 0.4), true)
  cleanup()
end)

h.test("combat brings it to full from where it is", function()
  local _, F, bar, _, run, _, cleanup = setup()
  F.apply("bar2", { fadeAlpha = 40, fadeMouseover = true })
  run(1)
  F.setCombat(true)
  run(0.1)
  h.eq(near(bar._alpha, 0.9), true)
  run(0.2)
  h.eq(bar._alpha, 1)
  cleanup()
end)

h.test("mouse over the bar frame between buttons keeps it full", function()
  local _, F, bar, mouse, run, _, cleanup = setup()
  mouse.bar = true
  F.apply("bar2", { fadeAlpha = 40, fadeMouseover = true })
  run(1)
  h.eq(bar._alpha, nil) -- already full: never set
  mouse.bar, mouse[2] = false, true
  run(1)
  h.eq(bar._alpha, nil)
  mouse[2] = false
  run(1)
  h.eq(near(bar._alpha, 0.4), true)
  cleanup()
end)

h.test("mouse-over off ignores the mouse", function()
  local _, F, bar, mouse, run, _, cleanup = setup()
  mouse.bar = true
  F.apply("bar2", { fadeAlpha = 40, fadeMouseover = false })
  run(1)
  h.eq(near(bar._alpha, 0.4), true)
  cleanup()
end)

h.test("Edit Mode shows it full", function()
  local _, F, bar, _, run, _, cleanup = setup()
  F.apply("bar2", { fadeAlpha = 40, fadeMouseover = true })
  run(1)
  F.setEditMode(true)
  run(1)
  h.eq(bar._alpha, 1)
  F.setEditMode(false)
  run(1)
  h.eq(near(bar._alpha, 0.4), true)
  cleanup()
end)

h.test("back to 100% restores 1 once and stops", function()
  local _, F, bar, _, run, _, cleanup = setup()
  F.apply("bar2", { fadeAlpha = 40, fadeMouseover = true })
  run(1)
  local set = {}
  local orig = bar.SetAlpha
  bar.SetAlpha = function(self, a) set[#set + 1] = a; orig(self, a) end
  F.apply("bar2", { fadeAlpha = 100, fadeMouseover = true })
  run(1)
  h.eq(set, { 1 })
  h.eq(F.state("bar2").frame._shown, false)
  cleanup()
end)

h.test("combat events set the shared state", function()
  local _, F, bar, _, run, client, cleanup = setup()
  F.apply("bar2", { fadeAlpha = 40, fadeMouseover = true })
  run(1)
  client.fire("PLAYER_REGEN_DISABLED")
  run(1)
  h.eq(bar._alpha, 1)
  client.fire("PLAYER_REGEN_ENABLED")
  run(1)
  h.eq(near(bar._alpha, 0.4), true)
  cleanup()
end)

h.test("a missing bar is skipped", function()
  local _, F, _, _, _, _, cleanup = setup()
  _G.MultiBarBottomLeft = nil
  F.apply("bar2", { fadeAlpha = 40, fadeMouseover = true })
  F.apply("nope", { fadeAlpha = 40, fadeMouseover = true })
  cleanup()
end)
