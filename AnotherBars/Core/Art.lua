local ADDON, ns = ...

-- Blizzard's bar art that "Hide Blizzard art" hides (Skin/Art.lua). Pure
-- data. A name the client does not have is skipped.
--
-- TO ADD A REGION: one dot path (from the bar frame, e.g. "EndCaps" for
-- MainMenuBar.EndCaps) in REGIONS under the bar's id (Core/Bars.lua). A
-- pool of art Blizzard makes on each layout (its objects are hidden too)
-- goes in POOLS.
-- UNVERIFIED (check in client): every name below (docs/CHECKLIST.md).
local Art = {}

Art.REGIONS = {
  bar1 = { "EndCaps", "BorderArt", "Background" },
}

Art.POOLS = {
  bar1 = { "dividerPool" },
}

local function copy(list)
  local out = {}
  for i, v in ipairs(list or {}) do out[i] = v end
  return out
end

function Art.regionsFor(barId)
  return copy(Art.REGIONS[barId or ""])
end

function Art.poolsFor(barId)
  return copy(Art.POOLS[barId or ""])
end

ns.Art = Art
