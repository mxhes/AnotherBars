# AnotherBars

Blizzard's action bars in the look of the "Another" UI suite (AnotherLedger,
AnotherHUD) for WoW Forever: Action Bars 1-8, the Stance bar and the Pet bar,
with tighter spacing, Blizzard's bar artwork hidden and settings in
Blizzard's Edit Mode. A totem bar follows later.

In development. What works so far:

- **The look.** Every button on Action Bars 1-8, the Stance bar and the Pet
  bar wears the suite's frame: the skin's border around the icon, the
  button shading, and the suite's hover, pressed, active and empty-slot
  looks. Out of range, out of mana and unusable spells are tinted, the
  cooldown time shows in gold. Reactive spells (such as Overpower,
  Revenge, Execute, Riposte or Hammer of Wrath) pulse in gold while you can
  use them. Pet abilities that can cast on their own show a small round
  badge: a gold dot while autocast is on, empty while it is off.
- **Edit Mode.** Open Edit Mode and click a bar. Below Blizzard's own
  settings you find:
  - **Look**: Button shading (Skin, Bronze, Raised or Flat; Skin follows
    the chosen skin).
  - **Text**: show or hide the hotkey, the macro name and the count, and
    the font size.
  - **Settings**: opens the AnotherBars settings.
- **Settings** (`/abars`, or the Settings button in Edit Mode): the skin
  for all bars (Classic, Forge, Slate) and which bars wear the
  look. Turning a bar off brings Blizzard's look back after a `/reload`.
- `/abars version` prints the version.

The design is in `docs/superpowers/specs/`.
