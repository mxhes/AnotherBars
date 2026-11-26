local h = ...

local function Grid()
  return h.load({ "Core/Grid.lua" }).Grid
end

h.test("one row at padding 0", function()
  h.eq(Grid().repack({ { 0, 0 }, { 38, 0 }, { 76, 0 } }, 36, 36, 0), { { 0, 0 }, { 36, 0 }, { 72, 0 } })
end)

h.test("keeps rows and columns", function()
  local o = { { 0, 0 }, { 38, 0 }, { 76, 0 }, { 0, -38 }, { 38, -38 }, { 76, -38 } }
  h.eq(Grid().repack(o, 36, 36, 0), { { 0, 0 }, { 36, 0 }, { 72, 0 }, { 0, -36 }, { 36, -36 }, { 72, -36 } })
end)

h.test("partial last row", function()
  local o = { { 0, 0 }, { 38, 0 }, { 76, 0 }, { 0, -38 }, { 38, -38 } }
  local cells = Grid().cells(o)
  h.eq(cells[4], { 0, -1 })
  h.eq(cells[5], { 1, -1 })
  h.eq(Grid().repack(o, 36, 36, 2)[5], { 38, -38 })
end)

h.test("negative directions keep sign", function()
  h.eq(Grid().repack({ { 0, 0 }, { -40, 0 } }, 36, 36, 0), { { 0, 0 }, { -36, 0 } })
end)

h.test("single button", function()
  h.eq(Grid().repack({ { 0, 0 } }, 36, 36, 0), { { 0, 0 } })
end)

h.test("rounds small drift", function()
  local cells = Grid().cells({ { 0, 0 }, { 38.3, 0.2 } })
  h.eq(cells[2], { 1, 0 })
end)

h.test("column and row steps are separate", function()
  -- a vertical bar: columns 0 only, rows step 40
  h.eq(Grid().repack({ { 0, 0 }, { 0, -40 }, { 0, -80 } }, 30, 30, 1), { { 0, 0 }, { 0, -31 }, { 0, -62 } })
end)
