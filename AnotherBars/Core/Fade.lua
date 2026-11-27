local ADDON, ns = ...

-- Pure. Fading (Skin/Fade.lua): the alpha a bar wants and how fast it gets
-- there. Bars are full in combat, while Edit Mode is open and (when the bar
-- wants it) while the mouse is over them; otherwise at the bar's opacity.
local Fade = {}

-- Seconds from faded to full (IN) and from full to faded (OUT).
Fade.IN = 0.2
Fade.OUT = 0.5

-- Whether a bar fades at all: an opacity below 100 (%).
function Fade.active(fadeAlpha)
  return type(fadeAlpha) == "number" and fadeAlpha < 100
end

-- opts = { fadeAlpha (0-100), fadeMouseover }, st = { combat, editMode, mouse }.
function Fade.target(opts, st)
  if st.combat or st.editMode or (st.mouse and opts.fadeMouseover) then return 1 end
  local a = (opts.fadeAlpha or 100) / 100
  if a < 0 then return 0 end
  if a > 1 then return 1 end
  return a
end

-- `current` moved toward `target` after `dt` seconds, never past it.
function Fade.step(current, target, dt)
  if current < target then
    return math.min(target, current + dt / Fade.IN)
  elseif current > target then
    return math.max(target, current - dt / Fade.OUT)
  end
  return current
end

ns.Fade = Fade
