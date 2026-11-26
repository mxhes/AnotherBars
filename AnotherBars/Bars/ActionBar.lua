local ADDON, ns = ...

-- Action Bars 1-8 (ns.Bars), one module each (Bars/Common.lua).
for i = 1, 8 do
  ns.BarModules.Common.define("bar" .. i)
end
