local ADDON, ns = ...

-- Reactive spells: on Forever the game never signals a proc, so the gold
-- pulse shows on these spells while they are usable and off cooldown
-- (Skin/Procs.lua). Pure: no WoW globals.
--
-- TO ADD A SPELL: add one line `{ id = <spell id>, name = "<English name>" }`
-- under the class (the class token as UnitClass returns it, e.g. "DRUID";
-- a new class is a new key). Any rank's id works: buttons match by the
-- spell's name, so every rank glows. `name` is only for reading the list
-- (and the tests); the game's own name is looked up from the id.
local Reactive = {}

Reactive.SPELLS = {
  WARRIOR = {
    { id = 7384, name = "Overpower" },       -- after the target dodges
    { id = 6572, name = "Revenge" },         -- after a block, dodge or parry
    { id = 5308, name = "Execute" },         -- target below 20% health
  },
  ROGUE = {
    { id = 14251, name = "Riposte" },        -- after a parry
  },
  HUNTER = {
    { id = 19306, name = "Counterattack" },  -- after a parry
    { id = 1495, name = "Mongoose Bite" },   -- after the target dodges
  },
  PALADIN = {
    { id = 24275, name = "Hammer of Wrath" }, -- target below 20% health
  },
}

-- The spell ids of a class token; {} for a class without reactive spells.
function Reactive.idsFor(classToken)
  local out = {}
  for i, entry in ipairs(Reactive.SPELLS[classToken or ""] or {}) do out[i] = entry.id end
  return out
end

-- Whether a reactive spell glows: true when usable and not on cooldown,
-- false when not usable or on cooldown, nil when usability is unknown
-- (a secret value: the glow keeps its last state). An unknown cooldown
-- (nil) counts as off cooldown.
function Reactive.isUp(usable, onCooldown)
  if usable == nil then return nil end
  return usable == true and onCooldown ~= true
end

ns.Reactive = Reactive
