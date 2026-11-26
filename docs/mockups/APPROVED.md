# Approved mockups

Copied from AnotherHUD's `docs/mockups/` (approved there on 2026-11-21; the
action bars moved to AnotherBars on 2026-11-25). Pages 4 and 5 are kept as
they were approved; page 5 also shows the class resource bar, which stays in
AnotherHUD.

The art the player approved, per mockup page in this folder. Open a page via a
local web server from this folder (for example `python -m http.server`), as
the pages load `kit.js`, `kit.css` and `units.js`. Colors and skin rules come
from AnotherLedger's `Theme.lua` (`Theme.colors`, `Theme.edgeRects`,
`Theme.skinScales`); every part is drawn in all four skins (Classic, Forge,
Slate, Gilded) and tinted with the theme colors.

Shared rules (all mockups):

- **Panel**: `panelTint` (0.15, 0.10, 0.06) fill; border = the skin's
  `edgeRects` lines in `panelBorder` (0.55, 0.42, 0.24) shades (Classic: the
  soft round tooltip edge, ~4 px; Forge bevel 5 px; Slate thin 2 px; Gilded
  6 px plus 10 px corner studs).
- **Ring** (portrait and round badges): the same border lines bent into a
  circle, outside in; Gilded adds four 9 px studs at 45 / 135 / 225 / 315 deg.
- **Dividers** (between health and power, beside a cast icon): the skin's
  Lines pick in `goldLine` (gold / groove / plain / dotted).
- **Texts**: game font (FRIZQT) with outline; level numbers in `gold`.

## 4. Action buttons and proc glow (`4-buttons.html`)

- Edge variant: **A, skin border**: the frames' border lines around the icon
  (Classic soft round 3 px with 4 px corner radius, Forge bevel 5 px, Slate
  2 px, Gilded 6 px plus 7 px corner studs), `panelTint` behind. Icon cropped
  to fill the inside.
- Buttons pick shading inside the edge: Bronze = 1 px dark line
  (`panelBorder` x 0.3) plus a faint warm top light; Raised = 1 px light
  top / left (`panelBorder` x 1.9) and dark bottom / right (x 0.25); Flat =
  nothing.
- States: hover = edge lines in `goldLine` plus a 16% warm overlay; pressed =
  icon at 70% brightness; active / toggled = 2 px `gold` inner edge with a
  soft gold inner glow; empty slot = panel at 75% with a dark inner shadow.
- Tints: out of range red (0.8, 0.1, 0.1) multiplied on the icon and the
  hotkey in red; no mana blue (0.5, 0.5, 1); unusable grey (desaturated,
  ~55% brightness). Cooldown: 72% black swipe, time centered in `gold` 15 pt.
- Texts (at 40 px): hotkey top right 10 pt white; count / charges bottom
  right 12 pt; macro name bottom center 9 pt cream (0.93, 0.87, 0.72).
- Proc glow: **1, Gold pulse**: a halo 5 px outside the button (2 px
  `goldLine` line, 10 px outer glow at 75%, 8 px inner glow at 60%) that
  breathes between 55% and 100% opacity and 100-106% size, 1.1 s per cycle.

## 5. Totem bar (`5-resources.html`, totem part)

- Totem bar: **as shown**. Four 32 px slots, 4 px apart, in the approved
  action button look (skin border); time left in `gold` 11 pt at the bottom of
  the icon; a 3 px `goldLine` bar under each slot that drains with the time
  left; an empty slot is a faint panel (50%) with a dim 1 px edge.
