-- MLX 0.1.18: native skill progression control, independent of XP awards.
local M = {}
local lastError
local function enforce()
    if not tes3.mobilePlayer then return end
    if require("MLX.advancement").nativeActive() then return end
    local ok, err = pcall(function()
        -- Suppress natural level readiness, including progress already in a save.
        -- The threshold is temporary; MLX will replace the level-up path later.
        local total = assert(tes3.findGMST(tes3.gmst.iLevelupTotal))
        local major = assert(tes3.findGMST(tes3.gmst.iLevelupMajorMult))
        local minor = assert(tes3.findGMST(tes3.gmst.iLevelupMinorMult))
        total.value = 1000
        major.value = 0
        minor.value = 0
        if tes3.mobilePlayer.levelUpProgress ~= 0 then
            tes3.mobilePlayer.levelUpProgress = 0
        end
    end)
    if not ok then
        if lastError ~= tostring(err) then mwse.log("[MLX progression] ERROR: %s", tostring(err)) end
        lastError = tostring(err)
    else lastError = nil end
end
function M.register()
    event.register("exerciseSkill", function(e)
        if tes3.mobilePlayer and type(e.skill) == "number" and e.skill >= 0 and e.skill < 27 then
            e.block = true
        end
    end, { priority = -1000 })
    event.register("loaded", enforce)
    event.register("charGenFinished", enforce)
    event.register("simulate", enforce)
    event.register("skillRaised", function(e)
        mwse.log("[MLX progression] Skill %s raised to %s; source=%s", tostring(e.skill), tostring(e.level), tostring(e.source))
        enforce()
    end)
    event.register("save", enforce)
    mwse.log("[MLX] v0.1.18 vanilla progression control registered")
end
return M
