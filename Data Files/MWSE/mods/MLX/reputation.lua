-- MLX 0.1.13: general reputation high-water mark, persisted per character.
local M = {}
local key = "MLX_bookExperience_v1"
local function scan()
    local p = tes3.player
    if not p or not tes3.mobilePlayer or not p.object then return end
    local s = p.data[key]
    if not s then return end
    local rep = tonumber(p.object.reputation)
    if not rep then return end
    rep = math.floor(rep)
    if s.reputationHigh == nil then
        s.reputationHigh = rep
        p.modified = true
        mwse.log("[MLX reputation] Baseline: %d", rep)
        return
    end
    if rep <= s.reputationHigh then return end
    local delta = rep - s.reputationHigh
    local rate = delta * 50
    s.reputationHigh = rep
    s.xp = s.xp + rate
    p.modified = true
    require("MLX.notifications").earned(rate, "Reputation")
    mwse.log("[MLX reputation] +%d XP for %d new reputation; total=%d", rate, delta, s.xp)
end
local lastError
local function safe()
    local ok, err = pcall(scan)
    if not ok then
        if lastError ~= tostring(err) then mwse.log("[MLX reputation] ERROR: %s", tostring(err)); lastError = tostring(err) end
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
