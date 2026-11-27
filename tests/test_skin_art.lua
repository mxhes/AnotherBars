local h = ...
local fakes = dofile("tests/fakes.lua")

local FILES = { "Core/Util.lua", "Core/Combat.lua", "Core/Bars.lua", "Core/Art.lua", "Skin/Art.lua" }

-- A fake MainMenuBar: EndCaps at alpha 1, BorderArt at 0.6, no Background,
-- and a divider pool with two active dividers.
local function setup(inCombat)
  local client = fakes.client({ inCombat = inCombat })
  local bar = fakes.frame("MainMenuBar")
  bar.EndCaps = fakes.frame()
  bar.BorderArt = fakes.frame()
  bar.BorderArt._alpha = 0.6
  local d1, d2 = fakes.frame(), fakes.frame()
  bar.dividerPool = { EnumerateActive = function() return pairs({ [d1] = true, [d2] = true }) end }
  _G.MainMenuBar = bar
  local ns = h.load(FILES)
  local function cleanup()
    _G.MainMenuBar = nil
    client.restore()
  end
  return ns, client, bar, { d1, d2 }, cleanup
end

h.test("hide sets the listed art and the pool's dividers to alpha 0", function()
  local ns, _, bar, dividers, cleanup = setup(false)
  ns.Skin.Art.apply("bar1", true)
  h.eq(bar.EndCaps._alpha, 0)
  h.eq(bar.BorderArt._alpha, 0)
  h.eq(dividers[1]._alpha, 0)
  h.eq(dividers[2]._alpha, 0)
  cleanup()
end)

h.test("show gives back the alpha each region had", function()
  local ns, _, bar, dividers, cleanup = setup(false)
  ns.Skin.Art.apply("bar1", true)
  ns.Skin.Art.apply("bar1", false)
  h.eq(bar.EndCaps._alpha, 1)
  h.eq(bar.BorderArt._alpha, 0.6)
  h.eq(dividers[1]._alpha, 1)
  cleanup()
end)

h.test("hiding twice keeps the first alpha", function()
  local ns, _, bar, _, cleanup = setup(false)
  ns.Skin.Art.apply("bar1", true)
  ns.Skin.Art.apply("bar1", true)
  ns.Skin.Art.apply("bar1", false)
  h.eq(bar.BorderArt._alpha, 0.6)
  cleanup()
end)

h.test("show without a hide changes nothing", function()
  local ns, _, bar, _, cleanup = setup(false)
  ns.Skin.Art.apply("bar1", false)
  h.eq(bar.BorderArt._alpha, 0.6)
  h.eq(#bar.BorderArt.calls, 0)
  cleanup()
end)

h.test("in combat the art waits for combat to end", function()
  local ns, client, bar, _, cleanup = setup(true)
  ns.Skin.Art.apply("bar1", true)
  h.eq(bar.EndCaps._alpha, nil)
  client.setCombat(false)
  client.fire("PLAYER_REGEN_ENABLED")
  h.eq(bar.EndCaps._alpha, 0)
  cleanup()
end)

h.test("missing names and bars without art are skipped", function()
  local ns, _, bar, _, cleanup = setup(false)
  bar.dividerPool = nil
  ns.Skin.Art.apply("bar1", true) -- no Background, no pool
  h.eq(bar.EndCaps._alpha, 0)
  ns.Skin.Art.apply("bar2", true) -- MultiBarBottomLeft does not exist
  ns.Skin.Art.apply("nope", true)
  _G.MainMenuBar = nil
  ns.Skin.Art.apply("bar1", true)
  cleanup()
end)
