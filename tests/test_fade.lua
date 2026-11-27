local h = ...

local function Fade()
  return h.load({ "Core/Util.lua", "Core/Fade.lua" }).Fade
end

local function near(a, b) return math.abs(a - b) < 1e-9 end

h.test("target: faded out of combat, full in combat, Edit Mode or mouse-over", function()
  local F = Fade()
  local on = { fadeAlpha = 40, fadeMouseover = true }
  h.eq(near(F.target(on, {}), 0.4), true)
  h.eq(F.target(on, { combat = true }), 1)
  h.eq(F.target(on, { editMode = true }), 1)
  h.eq(F.target(on, { mouse = true }), 1)
  h.eq(near(F.target({ fadeAlpha = 40, fadeMouseover = false }, { mouse = true }), 0.4), true)
  h.eq(F.target({ fadeAlpha = 0, fadeMouseover = true }, {}), 0)
end)

h.test("step: 0.2 s up, 0.5 s down, no overshoot", function()
  local F = Fade()
  h.eq(near(F.step(0.4, 1, 0.1), 0.9), true)
  h.eq(near(F.step(1, 0.4, 0.1), 0.8), true)
  h.eq(F.step(0.95, 1, 0.1), 1)
  h.eq(F.step(0.5, 0.5, 1), 0.5)
  h.eq(F.step(0.45, 0.4, 0.1), 0.4)
end)

h.test("active below 100 only", function()
  local F = Fade()
  h.eq(F.active(100), false)
  h.eq(F.active(95), true)
  h.eq(F.active(nil), false)
end)
