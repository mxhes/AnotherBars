local ADDON, ns = ...

-- The approved proc glow (APPROVED.md §4, gold pulse): a halo 5 px outside
-- the button: a 2 px goldLine line with a 10 px outer and an 8 px inner soft
-- glow, breathing between 55% and 100% opacity and 100-106% size, 1.1 s per
-- cycle. Our own frame on top of the button; Blizzard's spell alert is set to
-- alpha 0 while ours shows.
ns.Skin = ns.Skin or {}
local Glow = {}
Glow.__index = Glow

function Glow.attach(button, level)
  local T, D = ns.Theme, ns.Skin.Draw
  local g = T.button.glow
  local frame = CreateFrame("Frame", nil, button)
  local pad = g.out + g.outer
  frame:SetPoint("TOPLEFT", button, "TOPLEFT", -pad, pad)
  frame:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", pad, -pad)
  frame:SetFrameLevel(level or 1)
  local c = T.colors.goldLine
  local outer = D.strips(frame, "BACKGROUND")
  D.placeStrips(outer, frame, 0, g.outer, c, g.outerAlpha, false)
  local line = D.rect(frame, "BORDER")
  D.placeRect(line, frame, g.outer, g.line)
  D.tintAll(line, c)
  local inner = D.strips(frame, "BACKGROUND", 1)
  D.placeStrips(inner, frame, g.outer + g.line, g.inner, c, g.innerAlpha, true)

  -- UNVERIFIED (check in client): Alpha / Scale animations with BOUNCE.
  local group = frame:CreateAnimationGroup()
  group:SetLooping("BOUNCE")
  local alpha = group:CreateAnimation("Alpha")
  alpha:SetFromAlpha(g.alphaLow)
  alpha:SetToAlpha(g.alphaHigh)
  alpha:SetDuration(g.period / 2)
  local scale = group:CreateAnimation("Scale")
  scale:SetScaleFrom(1, 1)
  scale:SetScaleTo(g.scaleHigh, g.scaleHigh)
  scale:SetOrigin("CENTER", 0, 0)
  scale:SetDuration(g.period / 2)
  frame:Hide()
  return setmetatable({ frame = frame, group = group, button = button }, Glow)
end

function Glow:show()
  local alert = ns.Skin.Blizzard.spellAlert(self.button)
  if alert then alert:SetAlpha(0) end
  if self.on then return end
  self.on = true
  self.frame:Show()
  self.group:Play()
end

function Glow:hide()
  if not self.on then return end
  self.on = false
  self.group:Stop()
  self.frame:Hide()
end

ns.Skin.Glow = Glow
