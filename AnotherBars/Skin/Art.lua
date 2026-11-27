local ADDON, ns = ...

-- "Hide Blizzard art": the regions listed per bar in Core/Art.lua go to
-- alpha 0 (out of combat), and back to the alpha they had when shown again.
-- The alpha we found lives in our own weak table, never on Blizzard's
-- frames. Missing names and pools are skipped.
ns.Skin = ns.Skin or {}
local SkinArt = {}

local saved = setmetatable({}, { __mode = "k" }) -- [region] = alpha before we hid it

-- The object at a dot path under `root` ("EndCaps", "A.B"), or nil.
local function resolve(root, path)
  local obj = root
  for part in string.gmatch(path, "[^%.]+") do
    if type(obj) ~= "table" then return nil end
    obj = obj[part]
  end
  if type(obj) == "table" and type(obj.SetAlpha) == "function" then return obj end
  return nil
end

-- The bar's art objects: listed regions, then the active objects of its
-- listed pools.
-- UNVERIFIED (check in client): the region names in Core/Art.lua and the
-- pools' EnumerateActive.
local function objects(barId, frame)
  local out = {}
  for _, path in ipairs(ns.Art.regionsFor(barId)) do
    local obj = resolve(frame, path)
    if obj then out[#out + 1] = obj end
  end
  for _, key in ipairs(ns.Art.poolsFor(barId)) do
    local pool = frame[key]
    if type(pool) == "table" and type(pool.EnumerateActive) == "function" then
      for obj in pool:EnumerateActive() do
        if type(obj) == "table" and type(obj.SetAlpha) == "function" then out[#out + 1] = obj end
      end
    end
  end
  return out
end

local function hide(obj)
  if saved[obj] == nil then saved[obj] = obj:GetAlpha() end
  obj:SetAlpha(0)
end

local function show(obj)
  local a = saved[obj]
  if a == nil then return end
  saved[obj] = nil
  obj:SetAlpha(a)
end

-- Hides (hide = true) or shows the bar's art, out of combat.
function SkinArt.apply(barId, hideArt)
  local bar = ns.Bars.get(barId)
  if not bar then return end
  ns.Combat.after("art:" .. barId, function()
    local frame = rawget(_G, bar.frame)
    if type(frame) ~= "table" then return end
    for _, obj in ipairs(objects(barId, frame)) do
      if hideArt then hide(obj) else show(obj) end
    end
  end)
end

ns.Skin.Art = SkinArt
