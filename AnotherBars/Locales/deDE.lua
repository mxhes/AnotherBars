local ADDON, ns = ...

-- German texts. The key is the English text (see Core/Locale.lua); a missing
-- entry shows the English text. Each module adds its entries here.
ns.Locale.register("deDE", {
  -- Shared section names of the bar panels
  ["Look"] = "Aussehen",
  ["Text"] = "Text",
  ["Fading"] = "Ausblenden",
  ["Type /reload to apply"] = "Mit /reload übernehmen",

  -- Bars (Core/Bars.lua)
  ["Action Bar 1"] = "Aktionsleiste 1",
  ["Action Bar 2"] = "Aktionsleiste 2",
  ["Action Bar 3"] = "Aktionsleiste 3",
  ["Action Bar 4"] = "Aktionsleiste 4",
  ["Action Bar 5"] = "Aktionsleiste 5",
  ["Action Bar 6"] = "Aktionsleiste 6",
  ["Action Bar 7"] = "Aktionsleiste 7",
  ["Action Bar 8"] = "Aktionsleiste 8",
  ["Stance Bar"] = "Haltungsleiste",
  ["Pet Bar"] = "Begleiterleiste",

  -- Look and Text settings (Bars/Common.lua)
  ["Button shading"] = "Schattierung",
  ["Inner shading of the buttons; Skin follows the skin's pick"] = "Innere Schattierung der Knöpfe; Skin folgt der Wahl des Skins",
  ["Skin"] = "Skin",
  ["Bronze"] = "Bronze",
  ["Raised"] = "Erhaben",
  ["Flat"] = "Flach",
  ["Show hotkey"] = "Tastenkürzel zeigen",
  ["The key bound to each button"] = "Die Taste, die auf jedem Knopf liegt",
  ["Show macro name"] = "Makroname zeigen",
  ["The name of a macro on a button"] = "Der Name eines Makros auf einem Knopf",
  ["Show count"] = "Anzahl zeigen",
  ["Item counts and spell charges"] = "Gegenstandsanzahl und Zauberaufladungen",
  ["Font size"] = "Schriftgröße",
  ["Size of the hotkey; the other texts follow"] = "Größe des Tastenkürzels; die anderen Texte folgen",

  -- Settings window (UI/Settings.lua)
  ["Settings"] = "Einstellungen",
  ["Border and decoration style of all bars"] = "Rahmen und Verzierung aller Leisten",
  ["Turns this bar's look on or off"] = "Schaltet das Aussehen dieser Leiste ein oder aus",
})
