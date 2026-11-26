local ADDON, ns = ...

-- One module per Blizzard bar (ns.Bars): the Look and Text settings on the
-- bar's own Edit Mode panel, and the approved skin on each of its buttons.
-- Client calls only inside create / apply.
ns.BarModules = ns.BarModules or {}
local Common = {}

local KEYS = { "shading", "hotkey", "macro", "count", "fontSize" }

Common.defaults = { shading = "Skin", hotkey = true, macro = true, count = true, fontSize = 10 }

local function settings()
  return {
    { section = "Look", controls = {
      { key = "shading", type = "dropdown", label = "Button shading", values = { "Skin", "Bronze", "Raised", "Flat" },
        tooltip = "Inner shading of the buttons; Skin follows the skin's pick" },
    } },
    { section = "Text", controls = {
      { key = "hotkey", type = "checkbox", label = "Show hotkey", tooltip = "The key bound to each button" },
      { key = "macro", type = "checkbox", label = "Show macro name", tooltip = "The name of a macro on a button" },
      { key = "count", type = "checkbox", label = "Show count", tooltip = "Item counts and spell charges" },
      { key = "fontSize", type = "slider", label = "Font size", min = 6, max = 16, step = 1,
        tooltip = "Size of the hotkey; the other texts follow" },
    } },
  }
end

-- The bar's current skin opts.
function Common.opts(id)
  local out = {}
  for _, k in ipairs(KEYS) do out[k] = ns.Options.get(id, k) end
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

local function skinAll(spec)
  local opts = Common.opts(spec.id)
  for _, b in ipairs(Common.buttons(spec.id)) do ns.Skin.Button.skin(b, opts) end
end

-- Defines the module of bar `id`. `extra(spec)` runs after the buttons are
-- skinned on create (the pet bar's autocast badge).
function Common.define(id, extra)
  local bar = ns.Bars.get(id)
  local defaults = {}
  for k, v in pairs(Common.defaults) do defaults[k] = v end
  return ns.Modules.define{
    id = id,
    label = bar.label,
    kind = "bar",
    system = { index = bar.system },
    blizzard = { bar.frame },
    defaults = defaults,
    settings = settings(),
    create = function(spec)
      skinAll(spec)
      spec.frame = rawget(_G, bar.frame) or true
      if extra then extra(spec) end
    end,
    apply = function(spec)
      skinAll(spec)
    end,
  }
end

ns.BarModules.Common = Common
