local h = ...

local function Art()
  return h.load({ "Core/Art.lua" }).Art
end

h.test("art regions per bar, empty for unknown bars", function()
  local A = Art()
  h.eq(#A.regionsFor("bar1"), 3)
  h.eq(A.regionsFor("nope"), {})
  h.eq(A.regionsFor(nil), {})
  h.eq(A.poolsFor("bar1"), { "dividerPool" })
  h.eq(A.poolsFor("bar2"), {})
end)

h.test("every art entry is a non-empty string", function()
  local A = Art()
  for _, list in ipairs({ A.REGIONS, A.POOLS }) do
    for id, paths in pairs(list) do
      for i, p in ipairs(paths) do h.eq(type(p) == "string" and p ~= "", true, id .. " #" .. i) end
    end
  end
end)
