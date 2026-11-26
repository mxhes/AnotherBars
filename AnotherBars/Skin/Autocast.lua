local ADDON, ns = ...

-- The approved pet autocast badge (APPROVED.md §7): an 11 px round badge in
-- the icon's top-left inside corner, the skin's ring lines (a stack of
-- tinted discs as AnotherHUD's Units/Parts/Ring.lua, no studs) around a
-- panelTint fill. Autocast on: a 4 px gold dot with a soft goldLine glow,
-- breathing 70-100% over 1.4 s. Can autocast but off: the empty badge.
-- Can't autocast: no badge. Blizzard's autocast art goes to alpha 0.
ns.Skin = ns.Skin or {}
local Autocast = {}

local badges = setmetatable({}, { __mode = "k" }) -- [button] = badge
local order = {}

local function shades(border)
  local T = ns.Theme
  if border == "round" then return T.ringRoundShades end
  local list = {}
  for i, r in ipairs(T.edgeRects(border)) do list[i] = r.shade end
  return list
end

local function disc(frame, layer, sub)
  local t = frame:CreateTexture(nil, layer, nil, sub)
  t:SetTexture(ns.Theme.textures.disc)
  return t
end

local function place(tex, frame, x, y, dia)
  tex:ClearAllPoints()
  tex:SetPoint("CENTER", frame, "TOPLEFT", x, -y)
  tex:SetSize(dia, dia)
end

local function layout(badge)
  local T, D = ns.Theme, ns.Skin.Draw
  local B = T.button.badge
  local skin = ns.Look.skin()
  local list = shades(skin.border)
  local e = ns.Look.edgeWidth(skin.border)
  local frame = badge.frame
  local cx, cy = e + B.size / 2, e + B.size / 2
  badge.shown = {}
  for i, k in ipairs(list) do
    local t = badge.lines[i]
    if not t then t = disc(frame, "ARTWORK", math.min(i, 7)); badge.lines[i] = t end
    place(t, frame, cx, cy, B.size - 2 * (i - 1))
    D.tint(t, T.scaleColor(T.colors.panelBorder, k))
    t:Show()
    badge.shown[i] = t
  end
  for i = #list + 1, #badge.lines do badge.lines[i]:Hide() end
  local fill = B.size - 2 * #list
  if fill > 0 then
    place(badge.fill, frame, cx, cy, fill)
    D.tint(badge.fill, T.colors.panelTint)
    badge.fill:Show()
  else
    badge.fill:Hide()
  end
  place(badge.halo, frame, cx, cy, B.dot + 3)
  D.tint(badge.halo, T.colors.goldLine, 0.6)
  place(badge.dot, frame, cx, cy, B.dot)
  D.tint(badge.dot, T.colors.gold)
end

-- Adds the badge to a pet button (`front`: our front frame of the button).
function Autocast.attach(b, front)
  if badges[b] then return badges[b] end
  local B = ns.Theme.button.badge
  local frame = CreateFrame("Frame", nil, front or b)
  frame:SetAllPoints(front or b)
  local level = (front and front.GetFrameLevel and front:GetFrameLevel()) or 1
  frame:SetFrameLevel(level + 1)
  local badge = { frame = frame, lines = {}, playing = false }
  badge.fill = disc(frame, "OVERLAY", 0)
  badge.halo = disc(frame, "OVERLAY", 1)
  badge.dot = disc(frame, "OVERLAY", 2)
  -- UNVERIFIED (check in client): Alpha animation with BOUNCE.
  local group = frame:CreateAnimationGroup()
  group:SetLooping("BOUNCE")
  local a = group:CreateAnimation("Alpha")
  a:SetFromAlpha(B.alphaLow)
  a:SetToAlpha(B.alphaHigh)
  a:SetDuration(B.period / 2)
  a:SetTarget(badge.dot)
  badge.group = group
  for _, t in ipairs(ns.Skin.Blizzard.regions(b).autocast) do t:SetAlpha(0) end
  layout(badge)
  frame:Hide()
  badge.dot:Hide(); badge.halo:Hide()
  if not badges[b] then order[#order + 1] = b end
  badges[b] = badge
  return badge
end

-- allowed / enabled from GetPetActionInfo; a secret (plain nil) changes nothing.
function Autocast.set(b, allowed, enabled)
  local badge = badges[b]
  if not badge then return end
  local a = ns.Util.plain(allowed)
  if a == nil then return end
  if not a then badge.frame:Hide(); return end
  badge.frame:Show()
  local on = ns.Util.plain(enabled)
  if on == nil then return end
  if on then
    badge.dot:Show(); badge.halo:Show()
    if not badge.playing then badge.group:Play(); badge.playing = true end
  else
    badge.dot:Hide(); badge.halo:Hide()
    if badge.playing then badge.group:Stop(); badge.playing = false end
  end
end

-- Every badge again for the current skin.
function Autocast.relayoutAll()
  for _, b in ipairs(order) do
    if badges[b] then layout(badges[b]) end
  end
end

ns.Skin.Autocast = Autocast
