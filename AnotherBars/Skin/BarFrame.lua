local ADDON, ns = ...

-- Padding 0 (APPROVED.md §6, variant C): one skin panel wraps the whole
-- bar, and 1 px dividers in the skin's Lines pick sit between the icons.
-- Our own frame, parented to Blizzard's bar frame (hides with it) and
-- anchored by its four edges to the outermost buttons of the last repack
-- (Core/Layout.lua); the bar frame itself is never sized. Out of combat.
ns.Skin = ns.Skin or {}
local BarFrame = {}

local bars = {} -- [barId] = { frame, rects = { rect, ... }, lines = { tex, ... } }

function BarFrame.state(barId)
  return bars[barId]
end

local function create(parent)
  local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  local st = { frame = frame, rects = {}, lines = {} }
  st.fill = ns.Skin.Draw.tile(frame, "BACKGROUND")
  return st
end

-- Panel fill and the skin's border: Classic the round tooltip edge, the
-- other skins their edge lines in panelBorder shades.
local function paintPanel(st, border)
  local Th, Dr = ns.Theme, ns.Skin.Draw
  local panel = Th.colors.panelTint
  local frame = st.frame
  local rects = {}
  if border == "round" then
    local inset = 2
    frame:SetBackdrop({ bgFile = Th.textures.parchment, edgeFile = Th.textures.frameBorder, tile = true,
      tileSize = Th.sizes.backdropTile, edgeSize = Th.button.barRoundEdgeSize,
      insets = { left = inset, right = inset, top = inset, bottom = inset } })
    if frame.SetBackdropColor then frame:SetBackdropColor(panel[1], panel[2], panel[3], 1) end
    local pb = Th.colors.panelBorder
    if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(pb[1], pb[2], pb[3], 1) end
    st.fill:Hide()
  else
    frame:SetBackdrop(nil)
    Dr.inset(st.fill, frame, 0)
    Dr.tint(st.fill, panel, 1)
    st.fill:Show()
    rects = ns.Look.edges(border, false)
  end
  for i, e in ipairs(rects) do
    if not st.rects[i] then st.rects[i] = Dr.rect(frame, "BORDER") end
    Dr.placeRect(st.rects[i], frame, e.inset, 1)
    Dr.tintAll(st.rects[i], e.color)
    Dr.showAll(st.rects[i], true)
  end
  for i = #rects + 1, #st.rects do Dr.showAll(st.rects[i], false) end
end

-- The 1 px line between buttons i and its neighbour, in the gap between
-- their icons (each icon is inset by `e`).
local function placeLine(t, b, axis, e)
  t:ClearAllPoints()
  if axis == "v" then
    t:SetPoint("TOPLEFT", b, "TOPRIGHT", -e, -e)
    t:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -e + 1, e)
  else
    t:SetPoint("TOPLEFT", b, "BOTTOMLEFT", e, e)
    t:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -e, e - 1)
  end
end

local function paintLines(st, skin, cells, buttons, e)
  local Th, Dr = ns.Theme, ns.Skin.Draw
  local color = Th.lineColors(skin.lines, Th.colors.goldLine, Th.colors.panelTint)
  local pairsList = ns.Grid.dividers(cells)
  for n, p in ipairs(pairsList) do
    local t = st.lines[n]
    if not t then
      t = st.frame:CreateTexture(nil, "ARTWORK")
      st.lines[n] = t
    end
    -- UNVERIFIED (check in client): the dotted texture at 1 px.
    t:SetTexture(skin.lines == "dotted" and Th.textures.skinDotted or Th.textures.line)
    placeLine(t, buttons[p[1]], p[3], e)
    Dr.tint(t, color)
    t:Show()
  end
  for n = #pairsList + 1, #st.lines do st.lines[n]:Hide() end
end

-- Shows (on) or hides the bar's frame, out of combat. Runs after the
-- bar's repack (same queue, later key), so the cells are the new ones.
function BarFrame.apply(barId, on)
  local bar = ns.Bars.get(barId)
  if not bar then return end
  ns.Combat.after("barframe:" .. barId, function()
    local st = bars[barId]
    if not on then
      if st then st.frame:Hide() end
      return
    end
    local cells, buttons = ns.Layout.cells(barId)
    local edges = ns.Layout.edges(barId)
    local parent = ns.Bars.frame(barId)
    if not (cells and buttons and edges and parent) then
      if st then st.frame:Hide() end
      return
    end
    if not st then
      st = create(parent)
      bars[barId] = st
    end
    local frame = st.frame
    local first = buttons[1]
    local level = (first.GetFrameLevel and first:GetFrameLevel()) or 2
    frame:SetFrameLevel(math.max(0, level - 2))
    frame:ClearAllPoints()
    frame:SetPoint("LEFT", edges.left, "LEFT", 0, 0)
    frame:SetPoint("RIGHT", edges.right, "RIGHT", 0, 0)
    frame:SetPoint("TOP", edges.top, "TOP", 0, 0)
    frame:SetPoint("BOTTOM", edges.bottom, "BOTTOM", 0, 0)
    local skin = ns.Look.skin()
    local e = ns.Look.edgeWidth(skin.border)
    paintPanel(st, skin.border)
    paintLines(st, skin, cells, buttons, e)
    frame:Show()
  end)
end

ns.Skin.BarFrame = BarFrame
