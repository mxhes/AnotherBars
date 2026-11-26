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

ns.Grid = Grid
