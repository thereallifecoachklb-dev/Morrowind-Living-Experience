-- MLX 0.1.7: use the engine's player kill counters, not all actor deaths.
local M = {}
local key = "MLX_bookExperience_v1"
local function snapshot()
    local counts, actors = {}, {}
    for actor, count in pairs(tes3.getKillCounts()) do
        local obj = actor
        if type(actor) == "string" then obj = tes3.getObject(actor) end
        local id = type(actor) == "string" and actor or (obj and obj.id)
        if id and type(count) == "number" and count > 0 then
            id = id:lower()
            counts[id] = math.floor(count)
            actors[id] = obj
        end
    end
    return counts, actors
end
function M.scan()
    local p = tes3.player
    if not p or not tes3.mobilePlayer or not p.object then return end
    local s = p.data[key]
    if not s then return end -- acquisition module initializes the shared ledger
    local counts, actors = snapshot()
    if not s.combatCounts then
        s.combatCounts = counts
        p.modified = true
        mwse.log("[MLX combat] Initialized; previous kills excluded")
        return
    end
    for id, count in pairs(counts) do
        local previous = s.combatCounts[id] or 0
        if count > previous then
            local obj = actors[id]
            local level = math.max(1, math.floor(tonumber(obj and obj.level) or 1))
            local rate = 5 * level
            local delta = count - previous
            local award = delta * rate
            s.xp = s.xp + award
            s.combatCounts[id] = count
            p.modified = true
            require("MLX.notifications").earned(award, "Combat")
            mwse.log("[MLX combat] +%d XP: %s x%d (base level %d); total=%d", award, id, delta, level, s.xp)
        end
    end
end
return M
