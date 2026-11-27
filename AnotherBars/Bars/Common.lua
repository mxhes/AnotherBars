local ADDON, ns = ...

-- One module per Blizzard bar (ns.Bars): the Look and Text settings on the
-- bar's own Edit Mode panel, and the approved skin on each of its buttons.
-- Client calls only inside create / apply.
ns.BarModules = ns.BarModules or {}
local Common = {}

local KEYS = { "shading", "hotkey", "macro", "count", "fontSize" }

Common.defaults = { shading = "Skin", hotkey = true, macro = true, count = true, fontSize = 10,
  hideArt = true, ownPadding = true, padding = 2, fadeAlpha = 100, fadeMouseover = true }

-- tooltips: per-bar replacements { [key] = text }.
local function settings(tooltips)
  tooltips = tooltips or {}
  local function tip(key, text) return tooltips[key] or text end
  return {
    { section = "Look", controls = {
      { key = "shading", type = "dropdown", label = "Button shading", values = { "Skin", "Bronze", "Raised", "Flat" },
        tooltip = "Inner shading of the buttons; Skin follows the skin's pick" },
      { key = "hideArt", type = "checkbox", label = "Hide Blizzard art",
        tooltip = tip("hideArt", "Hides the bar's end caps, background and dividers") },
      { key = "ownPadding", type = "checkbox", label = "Own padding",
        tooltip = tip("ownPadding", "Uses the padding below instead of Blizzard's") },
      { key = "padding", type = "slider", label = "Padding", min = 0, max = 10, step = 1,
        tooltip = tip("padding", "Space between buttons; 0 joins the bar into one frame") },
    } },
    { section = "Text", controls = {
      { key = "hotkey", type = "checkbox", label = "Show hotkey", tooltip = "The key bound to each button" },
      { key = "macro", type = "checkbox", label = "Show macro name", tooltip = "The name of a macro on a button" },
      { key = "count", type = "checkbox", label = "Show count", tooltip = "Item counts and spell charges" },
      { key = "fontSize", type = "slider", label = "Font size", min = 6, max = 16, step = 1,
        tooltip = "Size of the hotkey; the other texts follow" },
    } },
    { section = "Fading", controls = {
      { key = "fadeAlpha", type = "slider", label = "Opacity out of combat", min = 0, max = 100, step = 5,
        tooltip = "How visible the bar is out of combat; 100 never fades" },
      { key = "fadeMouseover", type = "checkbox", label = "Full on mouse-over",
        tooltip = "Shows the bar fully while the mouse is over it" },
    } },
  }
end

-- The bar's current skin opts.
function Common.opts(id)
  local out = {}
  for _, k in ipairs(KEYS) do out[k] = ns.Options.get(id, k) end
  out.framed = ns.Look.framed(ns.Options.get(id, "ownPadding") == true, ns.Options.get(id, "padding"))
  return out
end

-- The bar's existing buttons, in order.
function Common.buttons(id)
  local bar = ns.Bars.get(id)
  local list = {}
  for i = 1, bar.count do
    local b = rawget(_G, bar.button .. i)
    if b then list[#list + 1] = b end
  end
  return list
end

local created = {} -- [id] = true once the bar's module is created, in order
local createdOrder = {}
local events

-- Blizzard's art (Skin/Art.lua) and our padding on the bar
-- (Core/Layout.lua): Blizzard's anchors back when own padding is off. Re-run after each Blizzard layout, a shown button,
-- PLAYER_ENTERING_WORLD / EDIT_MODE_LAYOUTS_UPDATED and a skin change.
function Common.layout(id)
  local O = ns.Options
  -- Blizzard makes the main bar's dividers on layout: hide them again.
  if ns.Skin and ns.Skin.Art then ns.Skin.Art.apply(id, O.get(id, "hideArt") == true) end
  local Layout = ns.Layout
  if not (Layout and ns.Grid) then return end
  local own, padding = O.get(id, "ownPadding") == true, O.get(id, "padding") or 0
  if own then
    local edge = ns.Look.edgeWidth(ns.Look.skin().border)
    Layout.repack(id, ns.Grid.spacing(padding, edge))
  else
    Layout.reset(id)
  end
  -- after the repack (queued in that order): padding 0's one bar frame
  if ns.Skin and ns.Skin.BarFrame then ns.Skin.BarFrame.apply(id, ns.Look.framed(own, padding)) end
end

function Common.layoutAll()
  for _, id in ipairs(createdOrder) do Common.layout(id) end
end

-- UNVERIFIED (check in client): EDIT_MODE_LAYOUTS_UPDATED on Forever. The
-- main bar's buttons only sit right after Blizzard's Edit Mode layout is in.
local function ensureEvents()
  if events then return end
  events = CreateFrame("Frame")
  for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "EDIT_MODE_LAYOUTS_UPDATED" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  events:SetScript("OnEvent", function() Common.layoutAll() end)
end

local function startLayout(id)
  if not created[id] then
    created[id] = true
    createdOrder[#createdOrder + 1] = id
    ensureEvents()
    if ns.Layout then
      ns.Layout.watch(id, function() Common.layout(id) end)
      ns.Layout.onShowRepack(id, function() Common.layout(id) end)
    end
  end
  Common.layout(id)
end

-- The bar's fade opts (Skin/Fade.lua).
function Common.fadeOpts(id)
  return { fadeAlpha = ns.Options.get(id, "fadeAlpha"), fadeMouseover = ns.Options.get(id, "fadeMouseover") }
end

-- Alpha is allowed in combat: no Combat.after.
local function fade(id)
  if ns.Skin and ns.Skin.Fade then ns.Skin.Fade.apply(id, Common.fadeOpts(id)) end
end

local function skinAll(spec)
  local opts = Common.opts(spec.id)
  for _, b in ipairs(Common.buttons(spec.id)) do ns.Skin.Button.skin(b, opts) end
end

-- Defines the module of bar `id`. `extra(spec)` runs after the buttons are
-- skinned on create (the pet bar's autocast badge). overrides: { defaults =
-- { [key] = value }, tooltips = { [key] = text } } for this bar.
function Common.define(id, extra, overrides)
  overrides = overrides or {}
  local bar = ns.Bars.get(id)
  local defaults = {}
  for k, v in pairs(Common.defaults) do defaults[k] = v end
  for k, v in pairs(overrides.defaults or {}) do defaults[k] = v end
  return ns.Modules.define{
    id = id,
    label = bar.label,
    kind = "bar",
    system = { index = bar.system },
    blizzard = { bar.frame },
    defaults = defaults,
    settings = settings(overrides.tooltips),
    create = function(spec)
      skinAll(spec)
      spec.frame = rawget(_G, bar.frame) or true
      if extra then extra(spec) end
      startLayout(id)
      fade(id)
    end,
    apply = function(spec)
      skinAll(spec)
      Common.layout(id)
      fade(id)
    end,
  }
end

ns.BarModules.Common = Common
