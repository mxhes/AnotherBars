local h = ...
local fakes = dofile("tests/fakes.lua")

local FILES = { "Core/Util.lua", "Core/DB.lua", "Core/Modules.lua", "Core/Combat.lua", "Core/Options.lua",
  "Core/Bars.lua", "Core/Grid.lua", "Core/Layout.lua", "Spike/Spike.lua" }

local function load()
  local ns = h.load(FILES)
  ns.db, ns.chardb = ns.DB.init(nil, nil)
  return ns
end

h.test("one spike module per bar", function()
  local ns = load()
  local ids = {}
  for i, spec in ipairs(ns.Modules.list()) do
    ids[i] = spec.id
    h.eq(spec.kind, "bar")
    h.eq(spec.system.index, ns.Bars.get(spec.id).system)
    h.eq(spec.settings[1].controls[1].key, "padding0")
    h.eq(spec.defaults.padding0, false)
  end
  h.eq(ids, { "bar1", "bar2", "bar3", "bar4", "bar5", "bar6", "bar7", "bar8", "stance", "pet" })
end)

-- Starts the spike with Layout faked out; returns the ns and what it recorded.
local function started()
  local ns = load()
  local rec = { watched = {}, repacked = {}, said = {} }
  ns.Layout.watch = function(id, fn) rec.watched[id] = fn end
  ns.Layout.repack = function(id, padding) rec.repacked[#rec.repacked + 1] = { id, padding } end
  ns.Util.say = function(msg) rec.said[#rec.said + 1] = msg end
  local client = fakes.client()
  ns.Spike.start()
  client.restore()
  return ns, rec
end

h.test("layout callback repacks only bars with padding0 on", function()
  local ns, rec = started()
  h.eq(type(rec.watched.bar1), "function")
  h.eq(type(rec.watched.pet), "function")
  ns.DB.profile().modules.bar2 = { padding0 = true }
  rec.watched.bar1("bar1", false)
  rec.watched.bar2("bar2", false)
  h.eq(rec.repacked, { { "bar2", 0 } })
end)

h.test("log prints combat flag", function()
  local _, rec = started()
  rec.watched.stance("stance", true)
  rec.watched.bar1("bar1", false)
  h.eq(rec.said, { "Stance Bar laid out (in combat: yes)", "Action Bar 1 laid out (in combat: no)" })
end)

h.test("log can be turned off", function()
  local ns, rec = started()
  ns.Spike.command("log")
  rec.said = {}
  rec.watched.bar1("bar1", false)
  h.eq(rec.said, {})
end)

h.test("turning padding0 on repacks now", function()
  local ns, rec = started()
  local client = fakes.client()
  ns.Options.set("bar3", "padding0", true)
  client.restore()
  h.eq(rec.repacked, { { "bar3", 0 } })
end)
