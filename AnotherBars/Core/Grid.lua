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

-- The smallest |v| above 0.5 along one axis (Blizzard's button + padding
-- step), or nil when every button sits on the same line.
local function step(offsets, axis)
  local best
  for _, o in ipairs(offsets) do
    local d = math.abs(o[axis])
    if d > 0.5 and (not best or d < best) then best = d end
  end
  return best
end

-- offsets -> { { col, row }, ... } (integers, signs kept).
function Grid.cells(offsets)
  local sx, sy = step(offsets, 1), step(offsets, 2)
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
  return Grid.offsets(Grid.cells(offsets), w, h, padding)
end

ns.Grid = Grid
