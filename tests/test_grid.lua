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
  local cells = Grid().cells(o, 36, 36)
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
  local cells = Grid().cells({ { 0, 0 }, { 38.3, 0.2 } }, 36, 36)
  h.eq(cells[2], { 1, 0 })
end)

h.test("column and row steps are separate", function()
  -- a vertical bar: columns 0 only, rows step 40
  h.eq(Grid().repack({ { 0, 0 }, { 0, -40 }, { 0, -80 } }, 30, 30, 1), { { 0, 0 }, { 0, -31 }, { 0, -62 } })
end)

h.test("a hidden middle button keeps the columns", function()
  -- buttons 1 and 3 shown (button 2 hidden): 76 px is two steps of 38
  h.eq(Grid().cells({ { 0, 0 }, { 76, 0 }, { 114, 0 } }, 36, 36), { { 0, 0 }, { 2, 0 }, { 3, 0 } })
  h.eq(Grid().repack({ { 0, 0 }, { 76, 0 } }, 36, 36, 0), { { 0, 0 }, { 72, 0 } })
end)

h.test("a hidden middle row keeps the rows", function()
  h.eq(Grid().cells({ { 0, 0 }, { 0, -80 } }, 36, 36), { { 0, 0 }, { 0, -2 } })
end)

h.test("spacing: padding, or icons 1 px apart at 0", function()
  h.eq(Grid().spacing(2, 3), 2)
  h.eq(Grid().spacing(0, 3), -5)
  h.eq(Grid().spacing(0, 2), -3)
end)

h.test("dividers between neighbouring cells", function()
  local cells = { { 0, 0 }, { 1, 0 }, { 2, 0 }, { 0, -1 }, { 1, -1 }, { 2, -1 } }
  local d = Grid().dividers(cells)
  local v, hz, has12 = 0, 0, false
  for _, p in ipairs(d) do
    if p[3] == "v" then v = v + 1 else hz = hz + 1 end
    if p[1] == 1 and p[2] == 2 and p[3] == "v" then has12 = true end
    if p[3] == "h" then h.eq(cells[p[1]][2] - cells[p[2]][2], 1) end
  end
  h.eq({ v, hz, has12 }, { 4, 3, true })
  h.eq(Grid().dividers({ { 0, 0 } }), {})
end)

h.test("dividers: left one first, any growth direction", function()
  h.eq(Grid().dividers({ { 0, 0 }, { -1, 0 } }), { { 2, 1, "v" } })
end)
