local h = ...

local function load()
  return h.load({ "Core/Util.lua", "Core/Reactive.lua" })
end

h.test("ids per class", function()
  local R = load().Reactive
  h.eq(R.idsFor("WARRIOR"), { 7384, 6572, 5308 })
  h.eq(R.idsFor("ROGUE"), { 14251 })
  h.eq(R.idsFor("HUNTER"), { 19306, 1495 })
  h.eq(R.idsFor("PALADIN"), { 24275 })
  h.eq(R.idsFor("MAGE"), {})
  h.eq(R.idsFor(nil), {})
end)

h.test("every list entry is a spell id with a name, no duplicates", function()
  local R = load().Reactive
  for class, list in pairs(R.SPELLS) do
    h.eq(type(class), "string")
    local seen = {}
    for i, entry in ipairs(list) do
      h.eq(type(entry.id) == "number" and entry.id > 0 and entry.id % 1 == 0, true, class .. " #" .. i)
      h.eq(type(entry.name) == "string" and entry.name ~= "", true, class .. " #" .. i .. " name")
      h.eq(seen[entry.id], nil, class .. " duplicate " .. entry.id)
      seen[entry.id] = true
    end
  end
end)

h.test("a new class or spell needs only a list line", function()
  local R = load().Reactive
  R.SPELLS.DRUID = { { id = 123, name = "Test" } }
  h.eq(R.idsFor("DRUID"), { 123 })
end)

h.test("isUp: usable and not on cooldown", function()
  local R = load().Reactive
  h.eq(R.isUp(true, false), true)
  h.eq(R.isUp(true, nil), true)
  h.eq(R.isUp(true, true), false)
  h.eq(R.isUp(false, false), false)
  h.eq(R.isUp(nil, false), nil)
end)
