local ADDON, ns = ...

-- Pure rules of the approved button look (docs/mockups/APPROVED.md §4, §7):
-- which skin, edge lines, shading, icon tints and text sizes. No WoW globals;
-- Skin/Button.lua turns the answers into textures.
local Look = {}

-- The round (Classic) edge as three lines, outside in (mockup buttons.js).
local ROUND_SHADES = { 0.35, 1, 1 }

local SHADING = { Bronze = "bronze", Raised = "raised", Flat = "flat" }

-- The skin of the active profile; Classic when missing or unknown.
function Look.skin()
  local T = ns.Theme
  local profile = ns.DB and ns.db and ns.DB.profile()
  local id = profile and profile.skin
  return (type(id) == "string" and T.skins[id]) or T.skins.classic
end

-- The edge lines of a button: { inset, color } outside in, on panelBorder,
-- or on goldLine while hovered.
function Look.edges(border, hover)
  local T = ns.Theme
  local base = hover and T.colors.goldLine or T.colors.panelBorder
  local out = {}
  if border == "round" then
    for i, k in ipairs(ROUND_SHADES) do out[i] = { inset = i - 1, color = T.scaleColor(base, k) } end
    return out
  end
  for i, r in ipairs(T.edgeRects(border)) do
    out[i] = { inset = r.inset, color = T.scaleColor(base, r.shade) }
  end
  return out
end

-- How far the icon sits inside the button edge.
function Look.edgeWidth(border)
  if border == "round" then return #ROUND_SHADES end
  return #ns.Theme.edgeRects(border)
end

-- A bar's shading pick ("Skin", "Bronze", "Raised", "Flat") as the skin's
-- Buttons part name.
function Look.shading(pick, skin)
  return SHADING[pick] or (skin and skin.buttons) or "bronze"
end

-- The icon's color from plain range / usable / mana flags; nil when a flag
-- it needs is unknown (a secret value): the caller then leaves Blizzard's
-- own tint.
function Look.iconTint(inRange, usable, noMana)
  if inRange == nil then return nil end
  if inRange == false then return { 0.8, 0.1, 0.1 } end
  if usable == nil then return nil end
  if usable then return { 1, 1, 1 } end
  if noMana == nil then return nil end
  if noMana then return { 0.5, 0.5, 1 } end
  return { 0.55, 0.55, 0.55, desaturate = true }
end

-- Text sizes from the hotkey size (approved at 40 px: hotkey 10, count 12,
-- macro name 9, cooldown time 15).
function Look.fontSizes(size)
  if not ns.Util.isNumber(size) then size = 10 end
  local function r(v) return math.floor(v + 0.5) end
  return { hotkey = size, count = r(size * 1.2), macro = r(size * 0.9), cooldown = r(size * 1.5) }
end

ns.Look = Look
