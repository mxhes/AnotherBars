local ADDON, ns = ...

-- Pure. Padding math for Blizzard's bars. An offset is a button's top-left
-- corner relative to button 1's top-left ({ x, y }, button 1 = { 0, 0 }),
-- taken from frame geometry, never from client secret values. Blizzard's
-- rows, columns, order and growth direction are read from the offsets and
-- kept; only the gaps change. Button 1 never moves.
local Grid = {}

local function round(v)
  return math.floor(v + 0.5)
end

-- Blizzard's button + padding step along one axis, or nil when every button
-- sits on the same line. The smallest distance above 0.5 may span several
-- steps when buttons in between are hidden (empty slots): as Blizzard's
-- padding is smaller than a button, it spans floor(distance / size) steps.
local function step(offsets, axis, size)
  local best
  for _, o in ipairs(offsets) do
    local d = math.abs(o[axis])
    if d > 0.5 and (not best or d < best) then best = d end
  end
  if not best then return nil end
  local n = (type(size) == "number" and size > 0) and math.max(1, math.floor(best / size)) or 1
  return best / n
end

-- offsets -> { { col, row }, ... } (integers, signs kept); w / h are the
-- button size.
function Grid.cells(offsets, w, h)
  local sx, sy = step(offsets, 1, w), step(offsets, 2, h)
  local cells = {}
  for i, o in ipairs(offsets) do
    cells[i] = { sx and round(o[1] / sx) or 0, sy and round(o[2] / sy) or 0 }
  end
  return cells
end

-- cells -> offsets for buttons of size w x h with `padding` between them.
function Grid.offsets(cells, w, h, padding)
  local out = {}
  for i, c in ipairs(cells) do
    out[i] = { c[1] * (w + padding), c[2] * (h + padding) }
  end
  return out
end

function Grid.repack(offsets, w, h, padding)
  return Grid.offsets(Grid.cells(offsets, w, h), w, h, padding)
end

-- The gap passed to Grid.repack: `padding` above 0; at 0 the buttons
-- overlap so their icons (inset by `edge`) sit 1 px apart.
function Grid.spacing(padding, edge)
  if padding > 0 then return padding end
  return 1 - 2 * edge
end

-- Neighbouring cells: { i, j, axis }, "v" for a vertical line between two
-- cells of a row (i on the left), "h" for a horizontal line between two
-- cells of a column (i on top; up is +y).
function Grid.dividers(cells)
  local out = {}
  for i, a in ipairs(cells) do
    for j, b in ipairs(cells) do
      if a[2] == b[2] and b[1] - a[1] == 1 then out[#out + 1] = { i, j, "v" } end
      if a[1] == b[1] and a[2] - b[2] == 1 then out[#out + 1] = { i, j, "h" } end
    end
  end
  return out
end

ns.Grid = Grid
