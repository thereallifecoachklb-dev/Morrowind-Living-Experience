-- MLX 0.1.14: faction promotions only, per-character high-water marks.
local M = {}
local key = "MLX_bookExperience_v1"
local function scan()
    local p = tes3.player
    if not p or not tes3.mobilePlayer or not p.object then return end
    local s = p.data[key]
    if not s then return end
    local baseline = not s.factionHigh
    local high = s.factionHigh or {}
    local current = {}
    for faction in tes3.iterateObjects(tes3.objectType.faction) do
        if faction.playerJoined and not faction.playerExpelled then
            local rank = tonumber(faction.playerRank)
            if rank and rank >= 0 and rank <= 9 then
                current[faction.id:lower()] = { rank = math.floor(rank), name = faction.name or faction.id }
            end
        end
    end
    s.factionHigh = high
    if baseline then p.modified = true end
    for id, entry in pairs(current) do
        local old = high[id]
        local rank = entry.rank
        if old == nil then
            -- First observed membership never earns XP, including direct high-rank entry.
            high[id] = rank
            p.modified = true
            mwse.log("[MLX faction] Baseline: %s rank %d", entry.name, rank)
        elseif rank > old then
            local amount = 0
            for r = old + 1, rank do amount = amount + 50 * r end
            high[id] = rank
            s.xp = s.xp + amount
            p.modified = true
            require("MLX.notifications").earned(amount, "Faction: " .. entry.name)
            mwse.log("[MLX faction] +%d XP: %s rank %d -> %d; total=%d", amount, entry.name, old, rank, s.xp)
        end
    end
end
local lastError
local function safe()
    local ok, err = pcall(scan)
    if not ok then
        if lastError ~= tostring(err) then
            lastError = tostring(err)
            mwse.log("[MLX faction] ERROR: %s", lastError)
        end
    else lastError = nil end
end
function M.register()
    local last = -10
    event.register("simulate", function()
        local now = os.clock()
        if now - last >= 0.5 then last = now; safe() end
    end)
    event.register("loaded", function() last = -10; safe() end)
    event.register("save", safe)
end
return M
