local ADDON, ns = ...

-- All look-and-feel values live here so the art can be swapped in one place.
-- Ported from AnotherLedger; the ledger-only parts (coins, rows, tabs, window
-- sizes, color presets) are left out.
local Theme = {}

Theme.textures = {
  -- No certain retail leather path; a flat tile tinted with colors.panelTint.
  parchment = "Interface\\Buttons\\WHITE8X8",
  -- Rounded window edge (tinted with colors.panelBorder); the fill sits inside
  -- its curve (sizes.backdropInset), so the corners read round.
  frameBorder = "Interface\\Tooltips\\UI-Tooltip-Border",
  resizeGrip = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up",
  -- Bronze buttons: a thin 1 px edge (tinted per state) and the icon glyphs.
  buttonEdge = "Interface\\Buttons\\WHITE8X8",
  iconGear = "Interface\\Icons\\Trade_Engineering",
  iconClose = "Interface\\Buttons\\UI-StopButton",
  buttonHighlight = "Interface\\Buttons\\ButtonHilight-Square",
  -- A plain white triangle pointing right (turned by the widgets, tinted).
  arrow = "Interface\\ChatFrame\\ChatFrameExpandArrow",
  -- Skins (Theme.skins): the addon's own textures; grey-scale, tinted with
  -- the theme colors.
  skinDotted = "Interface\\AddOns\\AnotherBars\\Media\\Skins\\Dotted",
  -- A plain white tile for 1 px lines (edges and dividers).
  line = "Interface\\Buttons\\WHITE8X8",
  -- A white disc (the pet autocast badge's ring lines and fill).
  disc = "Interface\\AddOns\\AnotherBars\\Media\\Shapes\\Disc",
  -- The placeholder icon of Edit Mode samples.
  sampleIcon = "Interface\\Icons\\INV_Misc_QuestionMark",
}

Theme.fonts = {
  title = "GameFontNormal",
  body = "GameFontHighlight",
  number = "GameFontHighlight",
  small = "GameFontHighlightSmall",
  button = "GameFontHighlightSmall", -- white; the disabled state stays gray
  buttonHighlight = "GameFontHighlightSmall",
  buttonDisabled = "GameFontDisableSmall",
  file = "Fonts\\FRIZQT__.TTF",
}

-- Dark leather look: a dark warm brown panel with light text and bronze
-- buttons. tests/test_theme.lua pins the contrast.
Theme.colors = {
  ink = { 1, 1, 1, 1 },
  gold = { 1.00, 0.82, 0.00, 1 },
  -- Bright gold for lines (divider, edge); not for text.
  goldLine = { 1.00, 0.82, 0.20, 1 },
  divider = { 1.00, 0.82, 0.20, 0.85 },
  -- Dark warm leather brown, fully opaque (an opacity option scales the alpha).
  panelTint = { 0.15, 0.10, 0.06, 1 },
  -- A shade lighter and warmer than the panel so the frame reads.
  panelBorder = { 0.55, 0.42, 0.24, 1 },
  hint = { 0.68, 0.63, 0.55, 1 },
  -- Bronze dark buttons and input boxes.
  buttonFill = { 0.10, 0.07, 0.04, 0.95 },
  buttonEdge = { 0.55, 0.42, 0.24, 1 },
  buttonEdgeHover = { 1.00, 0.82, 0.20, 1 },
  buttonText = { 1, 1, 1, 1 },
  buttonTextDisabled = { 0.50, 0.46, 0.38, 1 },
  buttonWarnEdge = { 0.62, 0.24, 0.17, 1 },
  buttonWarnEdgeHover = { 0.90, 0.36, 0.26, 1 },
  buttonWarnText = { 1.00, 0.70, 0.62, 1 },
  inputFill = { 0.06, 0.04, 0.02, 0.95 },
  -- Tooltips: gold title, tan labels, white values, quiet notes, red
  -- warnings and green click hints, like the game's own tooltips.
  tipTitle = { 1.00, 0.82, 0.00, 1 },
  tipLabel = { 0.80, 0.74, 0.62, 1 },
  tipValue = { 1, 1, 1, 1 },
  tipNote = { 0.68, 0.63, 0.55, 1 },
  tipWarn = { 0.95, 0.38, 0.32, 1 },
  tipHint = { 0.25, 0.90, 0.25, 1 },
}


Theme.sizes = {
  padding = 8,
  -- Bronze buttons: edge thickness, fill inset, glyph padding of icon buttons.
  buttonEdge = 1,
  buttonInset = 1,
  iconButtonPad = 3,
  buttonHeight = 20,
  gripSize = 16,
  gripInset = 4,
  -- Window edge: the game tooltip's proportions (16 px edge, fill inset 5 px),
  -- so the square fill stays hidden behind the rounded corners.
  backdropTile = 16,
  backdropEdge = 16,
  backdropInset = 5,
  -- Skins: how far a sunken list box reaches past its list.
  listBoxPad = 3,
  -- How close (px) an edge or the center of a dragged AnotherBars frame has
  -- to be to a screen line or another AnotherBars frame to snap onto it.
  snapDistance = 8,
}

-- The approved action button (docs/mockups/APPROVED.md §4, §7): overlays,
-- the proc glow and the pet autocast badge. Sizes in px.
Theme.button = {
  swipeAlpha = 0.72,
  pressed = { 0, 0, 0, 0.3 },
  hover = { 1, 0.9, 0.59, 0.16 },
  emptyAlpha = 0.75,
  emptyShadow = { 0, 0, 0, 0.8 },
  emptyShadowSize = 6,
  macroColor = { 0.93, 0.87, 0.72, 1 },
  activeEdge = 2,
  activeGlow = 6,
  activeGlowAlpha = 0.6,
  roundEdgeSize = 8,
  iconCrop = 0.08,
  glow = { out = 5, line = 2, outer = 10, outerAlpha = 0.75, inner = 8, innerAlpha = 0.6,
    alphaLow = 0.55, alphaHigh = 1, scaleHigh = 1.06, period = 1.1 },
  badge = { size = 11, dot = 4, alphaLow = 0.7, alphaHigh = 1, period = 1.4 },
}

-- The ring line shades (outside in) of the round border (AnotherHUD).
Theme.ringRoundShades = { 0.35, 1, 1, 0.45 }

-- Pure. A color with r, g, b multiplied by `k` (clamped to 0..1); alpha kept.
function Theme.scaleColor(c, k)
  if type(k) ~= "number" or k ~= k then k = 1 end
  local function ch(v) return math.min(1, math.max(0, (v or 0) * k)) end
  return { ch(c[1]), ch(c[2]), ch(c[3]), c[4] or 1 }
end

-- Pure. "rrggbb" (a leading "#" allowed, any case) -> r, g, b in 0..1; nil
-- for anything else.
function Theme.hexToRGB(hex)
  if type(hex) ~= "string" then return nil end
  local r, g, b = hex:match("^#?(%x%x)(%x%x)(%x%x)$")
  if not r then return nil end
  return tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255
end

-- Pure. A color {r, g, b[, a]} -> "rrggbb" (lower case; alpha left out).
function Theme.colorToHex(c)
  local function byte(v) return math.min(255, math.max(0, math.floor((v or 0) * 255 + 0.5))) end
  return string.format("%02x%02x%02x", byte(c[1]), byte(c[2]), byte(c[3]))
end

-- Sets the r, g, b of Theme.colors[key] from "rrggbb", in place (every UI part
-- holding the table sees the new color; alpha kept). Returns the table, or
-- nil for an unknown key or bad hex.
function Theme.setColor(key, hex)
  local c = Theme.colors[key]
  local r, g, b = Theme.hexToRGB(hex)
  if type(c) ~= "table" or not r then return nil end
  c[1], c[2], c[3] = r, g, b
  return c
end

-- ---------------------------------------------------------------------------
-- Skins: the shape of the window border, the buttons and the lines, and the
-- sunken list box. They never change colors: every style is tinted with
-- Theme.colors.

-- The choices of each part, in option order.
Theme.skinParts = {
  border = { "round", "bevel", "thin" },
  buttons = { "bronze", "raised", "flat" },
  lines = { "gold", "groove", "plain", "dotted" },
}

-- Skins by id; Theme.skinOrder is the order of the choice list. Classic is
-- the default.
Theme.skins = {
  classic = { id = "classic", label = "Classic", border = "round", buttons = "bronze",
    lines = "gold", listBox = false },
  forge = { id = "forge", label = "Forge", border = "bevel", buttons = "raised",
    lines = "groove", listBox = true },
  slate = { id = "slate", label = "Slate", border = "thin", buttons = "flat",
    lines = "plain", listBox = false },
}
Theme.skinOrder = { "classic", "forge", "slate" }

-- How the styles shade the theme colors: the dark edge lines, the groove's
-- dark / light line, the raised buttons' light / dark edge, how far Plain
-- moves a line color toward grey and the panel, the sunken list fill.
Theme.skinScales = {
  edgeDark = 0.2, edgeLight = 1.7, grooveDark = 0.3, grooveLight = 2.0, grooveLightAlpha = 0.55,
  raisedLight = 3.5, raisedDark = 0.3, plainMix = 0.5, listBox = 0.5,
}

-- The active picks; the options write them with Theme.setStyle.
Theme.style = { border = "round", buttons = "bronze", lines = "gold", listBox = false }

function Theme.skin(id)
  return Theme.skins[id]
end

-- Stores one pick; false (nothing stored) for an unknown part or value.
function Theme.setStyle(part, value)
  if part == "listBox" then
    if type(value) ~= "boolean" then return false end
    Theme.style.listBox = value
    return true
  end
  local list = Theme.skinParts[part]
  if not list then return false end
  for _, v in ipairs(list) do
    if v == value then
      Theme.style[part] = value
      return true
    end
  end
  return false
end

-- The SetBackdrop table of a window: Round keeps the tooltip edge; the
-- other borders are drawn as lines (Theme.edgeRects), so the fill reaches
-- the frame's edge.
function Theme.backdropSpec(border)
  local S = Theme.sizes
  local bg, tileSize = Theme.textures.parchment, S.backdropTile
  if border == "round" then
    local inset = S.backdropInset
    return { bgFile = bg, edgeFile = Theme.textures.frameBorder, tile = true, tileSize = tileSize,
      edgeSize = S.backdropEdge, insets = { left = inset, right = inset, top = inset, bottom = inset } }
  end
  return { bgFile = bg, tile = true, tileSize = tileSize,
    insets = { left = 0, right = 0, top = 0, bottom = 0 } }
end

-- The line rectangles of a border: inset (px from the frame edge) and shade
-- (a factor on the border color). Round has none (the backdrop edge).
function Theme.edgeRects(border)
  local d, l = Theme.skinScales.edgeDark, Theme.skinScales.edgeLight
  if border == "thin" then return { { inset = 0, shade = d }, { inset = 1, shade = 1 } } end
  if border == "bevel" then
    return { { inset = 0, shade = d }, { inset = 1, shade = l }, { inset = 2, shade = 1 },
      { inset = 3, shade = 1 }, { inset = 4, shade = d } }
  end
  return {}
end

-- Pure. `a` moved toward `b` by t (0..1); alpha of `a`.
function Theme.mix(a, b, t)
  local function m(i) return a[i] + (b[i] - a[i]) * t end
  return { m(1), m(2), m(3), a[4] or 1 }
end

-- The colors of a styled line in `lines` style: the main line and, for
-- Groove, the light line under it. Plain takes the line color halfway to grey
-- (losing the gold) and then halfway to the panel. Alpha kept.
local GREY = { 0.5, 0.5, 0.5 }
function Theme.lineColors(lines, color, panel)
  local k = Theme.skinScales
  if lines == "groove" then
    return Theme.scaleColor(color, k.grooveDark), Theme.scaleColor(color, k.grooveLight)
  elseif lines == "plain" then
    return Theme.mix(Theme.mix(color, GREY, k.plainMix), panel, k.plainMix), nil
  end
  return color, nil
end

-- WCAG 2 contrast ratio (1..21) between two sRGB colors (components 0..1).
local function linear(c)
  if c <= 0.03928 then return c / 12.92 end
  return ((c + 0.055) / 1.055) ^ 2.4
end
local function luminance(r, g, b)
  return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
end
function Theme.contrast(r1, g1, b1, r2, g2, b2)
  local x, y = luminance(r1, g1, b1), luminance(r2, g2, b2)
  if x < y then x, y = y, x end
  return (x + 0.05) / (y + 0.05)
end

-- Text on a colored fill: `color` when it stands out enough
-- (Theme.MIN_TEXT_CONTRAST), else a near-black or white text, whichever
-- reads better on `fill`. `dim`: the dimmed variant (a disabled button).
Theme.MIN_TEXT_CONTRAST = 3
local DARK, LIGHT = { 0.08, 0.06, 0.04, 1 }, { 1, 1, 1, 1 }
local DARK_DIM, LIGHT_DIM = { 0.08, 0.06, 0.04, 0.55 }, { 1, 1, 1, 0.55 }
function Theme.readableOn(color, fill, dim)
  local r, g, b = fill[1], fill[2], fill[3]
  if Theme.contrast(color[1], color[2], color[3], r, g, b) >= Theme.MIN_TEXT_CONTRAST then return color end
  local dark = Theme.contrast(DARK[1], DARK[2], DARK[3], r, g, b) >= Theme.contrast(1, 1, 1, r, g, b)
  if dim then return dark and DARK_DIM or LIGHT_DIM end
  return dark and DARK or LIGHT
end

ns.Theme = Theme
