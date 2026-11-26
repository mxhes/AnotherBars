local ADDON, ns = ...

-- The approved action button look (docs/mockups/APPROVED.md §4) on a
-- Blizzard button. Once per button, out of combat, we add our own frames,
-- parented to the button:
--   back  (level - 1): the panel fill (Classic: the round tooltip edge too)
--   cooldown          : Blizzard's, moved to level + 1 and restyled
--   front (level + 2): edge lines, shading, active / hover / pressed / empty
--                      overlays, Gilded studs
--   text  (level + 3): Blizzard's hotkey / count / macro name, re-parented
--   glow  (level + 4): the proc glow (Skin/Glow.lua)
-- Blizzard's own border, highlight, pushed, checked and flash textures go to
-- alpha 0. Hooks (Skin/Blizzard.lua) only show / hide / tint our regions and
-- tint the icon; their client values pass Util.plain first (secret -> skip).
-- Per-button data lives in `state`, never on the button.
ns.Skin = ns.Skin or {}
local Button = {}

local state = setmetatable({}, { __mode = "k" })
local skinned = {} -- buttons in skin order (relayoutAll)
local wiredGlobal = false

local function T() return ns.Theme end
local function D() return ns.Skin.Draw end

local CORNERS = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }
local STUD_OFFSET = { TOPLEFT = { 1, -1 }, TOPRIGHT = { -1, -1 }, BOTTOMLEFT = { 1, 1 }, BOTTOMRIGHT = { -1, 1 } }

function Button.state(b)
  return state[b]
end

-- The gold cooldown font object of a size (created once).
-- UNVERIFIED (check in client): CreateFont and Cooldown:SetCountdownFont.
local function cooldownFont(size)
  local name = "AnotherBarsCooldown" .. size
  if not rawget(_G, name) and type(rawget(_G, "CreateFont")) == "function" then
    local f = CreateFont(name)
    f:SetFont(T().fonts.file, size, "OUTLINE")
    local g = T().colors.gold
    f:SetTextColor(g[1], g[2], g[3], 1)
  end
  return name
end

-- State flags -> our overlays.
local function paintEdges(st)
  local border = st.border
  local edges = ns.Look.edges(border, st.hover)
  if border == "round" then
    local c = st.hover and T().colors.goldLine or T().colors.panelBorder
    st.back:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    return
  end
  for i, e in ipairs(edges) do D().tintAll(st.rects[i], e.color) end
end

local function showState(st)
  D().showAll(st.active, st.checked)
  D().showAll(st.activeGlow, st.checked)
  if st.hover then st.hoverFill:Show() else st.hoverFill:Hide() end
  if st.pressed then st.pressedFill:Show() else st.pressedFill:Hide() end
  if st.isEmpty then st.empty:Show() else st.empty:Hide() end
  D().showAll(st.emptyShadow, st.isEmpty)
end

local function tintIcon(b, st)
  local icon = st.regions.icon
  if not icon then return end
  local usable, noMana = true, false
  local action = b.action
  local isUsable = rawget(_G, "IsUsableAction")
  if type(action) == "number" and type(isUsable) == "function" then
    local u, m = isUsable(action)
    usable, noMana = ns.Util.plain(u), ns.Util.plain(m)
  end
  local tint = ns.Look.iconTint(st.inRange, usable, noMana)
  if not tint then return end
  icon:SetVertexColor(tint[1], tint[2], tint[3])
  if icon.SetDesaturated then icon:SetDesaturated(tint.desaturate and true or false) end
end

local function onUpdate(b)
  local st = state[b]
  if not st then return end
  local icon = st.regions.icon
  local shown = icon and ns.Util.plain(icon:IsShown())
  if shown ~= nil then st.isEmpty = not shown end
  showState(st)
  tintIcon(b, st)
end

local function onRange(b, inRange, checksRange)
  local st = state[b]
  if not st then return end
  local checks, r = ns.Util.plain(checksRange), ns.Util.plain(inRange)
  if checks == false then st.inRange = true
  elseif checks == nil or r == nil then st.inRange = nil
  else st.inRange = r and true or false end
  tintIcon(b, st)
end

local function onChecked(b, checked)
  local st = state[b]
  local v = ns.Util.plain(checked)
  if not st or v == nil then return end
  st.checked = v and true or false
  showState(st)
end

local function onPressed(b, pressed)
  local st = state[b]
  if not st then return end
  st.pressed = pressed and true or false
  showState(st)
end

local function onHover(b, over)
  local st = state[b]
  if not st then return end
  st.hover = over and true or false
  paintEdges(st)
  showState(st)
end

local function onAlertShow(b)
  local st = state[b]
  if st and st.glow then st.glow:show() end
end

local function onAlertHide(b)
  local st = state[b]
  if st and st.glow then st.glow:hide() end
end

-- Our frames and textures of one button (created once).
local function build(b)
  local regions = ns.Skin.Blizzard.regions(b)
  -- UNVERIFIED (check in client): a child frame one level below its parent
  -- draws under the parent's icon.
  local back = CreateFrame("Frame", nil, b, "BackdropTemplate")
  back:SetAllPoints(b)
  local front = CreateFrame("Frame", nil, b)
  front:SetAllPoints(b)
  local text = CreateFrame("Frame", nil, b)
  text:SetAllPoints(b)
  local st = { regions = regions, back = back, front = front, text = text, rects = {}, studs = {},
    inRange = true, checked = false, hover = false, pressed = false, isEmpty = false }
  st.fill = D().tile(back, "BACKGROUND")
  st.shade = D().rect(front, "ARTWORK")
  st.topLight = D().tile(front, "ARTWORK", 1)
  st.empty = D().tile(front, "BACKGROUND")
  st.emptyShadow = D().strips(front, "BACKGROUND", 1)
  st.active = D().rect(front, "OVERLAY")
  st.activeGlow = D().strips(front, "ARTWORK", 2)
  st.pressedFill = D().tile(front, "ARTWORK", 3)
  st.hoverFill = D().tile(front, "ARTWORK", 4)
  for _, corner in ipairs(CORNERS) do
    local s = front:CreateTexture(nil, "OVERLAY", nil, 1)
    s:SetTexture(T().textures.skinStud)
    st.studs[#st.studs + 1] = s
    st.studCorner = st.studCorner or {}
    st.studCorner[s] = corner
  end
  st.glow = ns.Skin.Glow.attach(b)
  return st
end

local function wire(b)
  local B = ns.Skin.Blizzard
  B.onUpdate(b, onUpdate)
  B.onChecked(b, onChecked)
  B.onPressed(b, onPressed)
  B.onHover(b, onHover)
  if not wiredGlobal then
    wiredGlobal = true
    B.onRange(onRange)
    B.onAlert(onAlertShow, onAlertHide)
  end
end

local function placeText(fs, parent, point, x, y, size, color, shown)
  if not fs then return end
  fs:SetParent(parent)
  fs:SetFont(T().fonts.file, size, "OUTLINE")
  if color then fs:SetTextColor(color[1], color[2], color[3], color[4] or 1) end
  fs:ClearAllPoints()
  fs:SetPoint(point, parent, point, x, y)
  fs:SetAlpha(shown and 1 or 0)
end

-- Places and tints everything for the current skin and the bar's opts.
local function layout(b, st, opts)
  local Th, Dr = T(), D()
  local B = Th.button
  local skin = ns.Look.skin()
  local border = skin.border
  local e = ns.Look.edgeWidth(border)
  st.border = border
  local level = (b.GetFrameLevel and b:GetFrameLevel()) or 1
  st.back:SetFrameLevel(math.max(0, level - 1))
  st.front:SetFrameLevel(level + 2)
  st.text:SetFrameLevel(level + 3)
  st.glow.frame:SetFrameLevel(level + 4)

  for _, t in ipairs(st.regions.hide) do t:SetAlpha(0) end
  for _, t in ipairs(st.regions.autocast) do t:SetAlpha(0) end

  -- back: the fill, and for Classic the round tooltip edge
  local panel = Th.colors.panelTint
  if border == "round" then
    local inset = 2
    st.back:SetBackdrop({ bgFile = Th.textures.parchment, edgeFile = Th.textures.frameBorder, tile = true,
      tileSize = Th.sizes.backdropTile, edgeSize = B.roundEdgeSize,
      insets = { left = inset, right = inset, top = inset, bottom = inset } })
    st.back:SetBackdropColor(panel[1], panel[2], panel[3], 1)
    st.fill:Hide()
  else
    st.back:SetBackdrop(nil)
    Dr.inset(st.fill, st.back, 0)
    Dr.tint(st.fill, panel)
    st.fill:Show()
  end

  -- edge lines (not for round)
  local rects = border == "round" and {} or Th.edgeRects(border)
  for i, r in ipairs(rects) do
    if not st.rects[i] then st.rects[i] = Dr.rect(st.front, "BORDER") end
    Dr.placeRect(st.rects[i], st.front, r.inset, 1)
    Dr.showAll(st.rects[i], true)
  end
  for i = #rects + 1, #st.rects do Dr.showAll(st.rects[i], false) end
  paintEdges(st)

  -- studs (Gilded)
  local studs = Th.edgeStuds(border)
  for _, s in ipairs(st.studs) do
    local corner = st.studCorner[s]
    local off = STUD_OFFSET[corner]
    s:ClearAllPoints()
    s:SetSize(B.studSize, B.studSize)
    s:SetPoint("CENTER", st.front, corner, off[1], off[2])
    Dr.tint(s, Th.colors.panelBorder)
    if studs then s:Show() else s:Hide() end
  end

  -- icon and cooldown inside the edge
  local icon = st.regions.icon
  if icon then
    Dr.inset(icon, b, e)
    local c = B.iconCrop
    icon:SetTexCoord(c, 1 - c, c, 1 - c)
    if st.regions.mask and icon.RemoveMaskTexture then pcall(icon.RemoveMaskTexture, icon, st.regions.mask) end
  end
  local sizes = ns.Look.fontSizes(opts.fontSize)
  local cd = st.regions.cooldown
  if cd then
    cd:ClearAllPoints()
    cd:SetPoint("TOPLEFT", b, "TOPLEFT", e, -e)
    cd:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -e, e)
    cd:SetFrameLevel(level + 1)
    if cd.SetSwipeColor then cd:SetSwipeColor(0, 0, 0, B.swipeAlpha) end
    if cd.SetDrawEdge then cd:SetDrawEdge(false) end
    if cd.SetCountdownFont then cd:SetCountdownFont(cooldownFont(sizes.cooldown)) end
  end

  -- shading inside the edge (Buttons pick)
  local shading = ns.Look.shading(opts.shading, skin)
  local pb = Th.colors.panelBorder
  Dr.placeRect(st.shade, st.front, e, 1)
  st.topLight:Hide()
  if shading == "bronze" then
    Dr.tintAll(st.shade, Th.scaleColor(pb, 0.3), 0.85)
    Dr.showAll(st.shade, true)
    st.topLight:ClearAllPoints()
    st.topLight:SetPoint("TOPLEFT", st.front, "TOPLEFT", e + 1, -(e + 1))
    st.topLight:SetPoint("TOPRIGHT", st.front, "TOPRIGHT", -(e + 1), -(e + 1))
    st.topLight:SetHeight(8)
    Dr.tint(st.topLight, { 1, 0.86, 0.63 }, 0.18)
    st.topLight:Show()
  elseif shading == "raised" then
    local light, dark = Th.scaleColor(pb, 1.9), Th.scaleColor(pb, 0.25)
    Dr.tint(st.shade[1], light, 0.8); Dr.tint(st.shade[3], light, 0.8)
    Dr.tint(st.shade[2], dark, 0.9); Dr.tint(st.shade[4], dark, 0.9)
    Dr.showAll(st.shade, true)
  else
    Dr.showAll(st.shade, false)
  end

  -- state overlays inside the edge
  Dr.placeRect(st.active, st.front, e, B.activeEdge)
  Dr.tintAll(st.active, Th.colors.gold)
  Dr.placeStrips(st.activeGlow, st.front, e + B.activeEdge, B.activeGlow, Th.colors.gold, B.activeGlowAlpha, true)
  Dr.inset(st.hoverFill, st.front, e)
  Dr.tint(st.hoverFill, B.hover)
  Dr.inset(st.pressedFill, st.front, e)
  Dr.tint(st.pressedFill, B.pressed)
  Dr.inset(st.empty, st.front, e)
  Dr.tint(st.empty, panel, B.emptyAlpha)
  Dr.placeStrips(st.emptyShadow, st.front, e, B.emptyShadowSize, B.emptyShadow, B.emptyShadow[4], true)

  -- texts
  local r = st.regions
  placeText(r.hotkey, st.text, "TOPRIGHT", -(e + 1), -e, sizes.hotkey, nil, opts.hotkey ~= false)
  placeText(r.count, st.text, "BOTTOMRIGHT", -(e + 1), e - 1, sizes.count, nil, opts.count ~= false)
  placeText(r.name, st.text, "BOTTOM", 0, e, sizes.macro, B.macroColor, opts.macro ~= false)
  if r.name and r.name.SetJustifyH then r.name:SetJustifyH("CENTER") end

  onUpdate(b)
end

-- Skins `b` with the bar's opts { shading, hotkey, count, macro, fontSize };
-- again with new opts it only relayouts. Waits for combat to end.
function Button.skin(b, opts)
  if type(b) ~= "table" then return end
  opts = opts or {}
  local key = "skin:" .. tostring(b.GetName and b:GetName() or b)
  ns.Combat.after(key, function()
    local st = state[b]
    if not st then
      st = build(b)
      state[b] = st
      skinned[#skinned + 1] = b
      wire(b)
    end
    st.opts = opts
    layout(b, st, opts)
  end)
end

-- Every skinned button again with its last opts (after a skin change).
function Button.relayoutAll()
  for _, b in ipairs(skinned) do
    local st = state[b]
    if st then Button.skin(b, st.opts) end
  end
end

ns.Skin.Button = Button
