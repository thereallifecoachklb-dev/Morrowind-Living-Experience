-- MLX 0.1.9: first visits, shared per-character XP ledger.
local M = {}
local key = "MLX_bookExperience_v1"
local function clean(s)
    return tostring(s or ""):lower():match("^%s*(.-)%s*$")
end
local function contains(s, word) return s:find(word, 1, true) ~= nil end
local function classify(cell)
    local name = clean(cell.isInterior and cell.name or cell.displayName)
    local root = name:match("^([^,]+)") or name
    if not cell.isInterior then
        local region = cell.region
        local regionName = clean(region and region.name)
        if cell.hasMapMarker and name ~= "" and name ~= regionName then
            if contains(name,"ruin") or contains(name,"daedric") or contains(name,"shrine") then
                return "site:"..root, 50, "named ruin or shrine"
            end
            return "site:"..root, 25, "named exterior location"
        end
        return string.format("wild:%d:%d",cell.gridX,cell.gridY), 5, "wilderness cell"
    end
    if name == "" then return end
    -- Exclude ordinary settlement interiors and residential/service names.
    if contains(name,"house") or contains(name,"manor") or contains(name,"shop") or contains(name,"guild") or contains(name,"quarters") or contains(name,"yurt") or contains(name,"shack") or name:match("%f[%a]inn%f[%A]") or contains(name,"tavern") or contains(name,"temple") or contains(name,"office") or contains(name,"shipwreck") or contains(name,":") then return end
    if contains(root,"ancestral tomb") or contains(root," catacomb") then return "site:"..root,25,"tomb" end
    if contains(name,"dwemer") or contains(root,"ruin") or root:match("^m[zch]") or root:match("^nchu") then return "site:"..root,50,"ruin" end
    if contains(name,"daedric") or contains(name,"shrine") then return "site:"..root,50,"shrine" end
    if contains(root,"mine") or contains(root,"cave") or contains(root,"grotto") or contains(root,"cavern") or contains(root,"caverns") or contains(root,"egg mine") then return "site:"..root,25,"cave or mine" end
    -- Many vanilla caves have only a single proper name (e.g. Addamasartus).
    if name == root and root:match("^[%a][%a%-]+$") then return "site:"..root,25,"unqualified interior (cave candidate)" end
end
local function scan()
    local p = tes3.player
    if not p or not tes3.mobilePlayer or not p.object then return end
    local s = p.data[key]
    if not s then return end
    local cell = tes3.getPlayerCell()
    if not cell then return end
    local id, rate, category = classify(cell)
    if not s.explorationSeen then
        s.explorationSeen = {}
        if id then s.explorationSeen[id] = true end
        p.modified = true
        mwse.log("[MLX exploration] Initialized; current location excluded: %s", tostring(id))
        return
    end
    if not id or s.explorationSeen[id] then return end
    s.explorationSeen[id] = true
    s.xp = s.xp + rate
    p.modified = true
    require("MLX.notifications").earned(rate, "Exploration")
    mwse.log("[MLX exploration] +%d XP: %s (%s; %s); total=%d",rate,tostring(cell.displayName),category,id,s.xp)
end
local lastError
local function safe()
    local ok,err = pcall(scan)
    if not ok then
        if lastError ~= tostring(err) then mwse.log("[MLX exploration] ERROR: %s",tostring(err)); lastError=tostring(err) end
    else lastError=nil end
end
function M.register()
    local last = -10
    event.register("simulate", function()
        local now = os.clock()
        if now - last >= 0.5 then last = now; safe() end
    end)
    event.register("loaded", function() last = -10 end)
    event.register("cellChanged", safe)
    event.register("save", safe)
end
return M
