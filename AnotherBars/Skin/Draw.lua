local ADDON, ns = ...

-- Drawing helpers for our own overlay frames: tinted line textures, 1 px
-- line rectangles (adapted from AnotherHUD Units/Parts/Panel.lua) and soft
-- gradient strips along a rectangle's sides. Only ever called on frames and
-- textures we created.
ns.Skin = ns.Skin or {}
local Draw = {}

function Draw.tint(tex, c, alpha)
  tex:SetVertexColor(c[1], c[2], c[3], alpha or c[4] or 1)
end

-- A plain white tile texture on `frame` (tinted by the caller).
function Draw.tile(frame, layer, sub)
  local t = frame:CreateTexture(nil, layer or "ARTWORK", nil, sub)
  t:SetTexture(ns.Theme.textures.line)
  return t
end

-- `tex` covering `rel` minus `inset` px on every side.
function Draw.inset(tex, rel, inset)
  tex:ClearAllPoints()
  tex:SetPoint("TOPLEFT", rel, "TOPLEFT", inset, -inset)
  tex:SetPoint("BOTTOMRIGHT", rel, "BOTTOMRIGHT", -inset, inset)
end

-- Four line textures { top, bottom, left, right }.
function Draw.rect(frame, layer, sub)
  local r = {}
  for i = 1, 4 do r[i] = Draw.tile(frame, layer, sub) end
  return r
end

-- Places a rect `inset` px inside `rel`, `thick` px wide.
function Draw.placeRect(r, rel, inset, thick)
  local o, w = inset, thick or 1
  for _, t in ipairs(r) do t:ClearAllPoints() end
  local top, bottom, left, right = r[1], r[2], r[3], r[4]
  top:SetPoint("TOPLEFT", rel, "TOPLEFT", o, -o); top:SetPoint("TOPRIGHT", rel, "TOPRIGHT", -o, -o)
  top:SetHeight(w)
  bottom:SetPoint("BOTTOMLEFT", rel, "BOTTOMLEFT", o, o); bottom:SetPoint("BOTTOMRIGHT", rel, "BOTTOMRIGHT", -o, o)
  bottom:SetHeight(w)
  left:SetPoint("TOPLEFT", rel, "TOPLEFT", o, -o); left:SetPoint("BOTTOMLEFT", rel, "BOTTOMLEFT", o, o)
  left:SetWidth(w)
  right:SetPoint("TOPRIGHT", rel, "TOPRIGHT", -o, -o); right:SetPoint("BOTTOMRIGHT", rel, "BOTTOMRIGHT", -o, o)
  right:SetWidth(w)
end

function Draw.tintAll(list, c, alpha)
  for _, t in ipairs(list) do Draw.tint(t, c, alpha) end
end

function Draw.showAll(list, shown)
  for _, t in ipairs(list) do
    if shown then t:Show() else t:Hide() end
  end
end

-- A color fading from `alpha` (at `strong`) to 0 across `tex`.
-- UNVERIFIED (check in client): Texture:SetGradient with CreateColor values.
local function gradient(tex, orientation, c, alpha, strongAtMax)
  local mk = rawget(_G, "CreateColor")
  if type(mk) ~= "function" or type(tex.SetGradient) ~= "function" then
    Draw.tint(tex, c, alpha * 0.5)
    return
  end
  tex:SetVertexColor(1, 1, 1, 1)
  local on, off = mk(c[1], c[2], c[3], alpha), mk(c[1], c[2], c[3], 0)
  if strongAtMax then tex:SetGradient(orientation, off, on) else tex:SetGradient(orientation, on, off) end
end

-- Four gradient strips { top, bottom, left, right }, `size` px wide, `inset`
-- px inside `rel`; strongest at the outer side when `strongOutside`, else at
-- the inner side.
function Draw.strips(frame, layer, sub)
  return Draw.rect(frame, layer, sub)
end

function Draw.placeStrips(s, rel, inset, size, c, alpha, strongOutside)
  Draw.placeRect(s, rel, inset, size)
  local o = strongOutside and true or false
  -- VERTICAL runs bottom (min) to top (max); HORIZONTAL left (min) to right (max).
  gradient(s[1], "VERTICAL", c, alpha, o)
  gradient(s[2], "VERTICAL", c, alpha, not o)
  gradient(s[3], "HORIZONTAL", c, alpha, not o)
  gradient(s[4], "HORIZONTAL", c, alpha, o)
end

ns.Skin.Draw = Draw
