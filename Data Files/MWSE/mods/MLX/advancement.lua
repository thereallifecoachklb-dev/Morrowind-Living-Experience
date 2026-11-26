-- MLX 0.2.2: native advancement followed by skill allocation.
local M = {}
local key = "MLX_bookExperience_v1"
local shown = false
local opening = false
local startedLevel
local oldTotal
local oldProgress
local oldMultipliers = {}
local lastError
local lastState
function M.requirement(level)
    return math.floor(1500 + 250 * level ^ 1.35 + 0.5)
end
local function state()
    local p = tes3.player
    if not p or not tes3.mobilePlayer or not p.object then return end
    local level = tonumber(p.object.level)
    local s = p.data[key]
    if not level or level < 1 or not s or type(s.xp) ~= "number" then return end
    return p, s, math.floor(level)
end
-- Called immediately after each existing module credits an award.
function M.capAward(amount)
    local p, s, level = state()
    if not p then return amount end
    local need = M.requirement(level)
    local before = s.xp - amount
    local credited = math.max(0, math.min(amount, need - before))
    if s.xp > need then s.xp = need; p.modified = true end
    return credited
end
function M.pending()
    local p, s = state()
    return p and (tonumber(s.pendingSkillPoints) or 0) or 0
end
function M.nativeActive() return opening end
local function restore()
    if oldTotal then tes3.findGMST(tes3.gmst.iLevelupTotal).value = oldTotal end
    for i, value in pairs(oldMultipliers) do
        tes3.findGMST(tes3.gmst[string.format("iLevelUp%02dMult", i)]).value = value
    end
    oldMultipliers = {}
    oldTotal = nil
    if tes3.mobilePlayer then tes3.mobilePlayer.levelUpProgress = 0 end
    opening = false
end
local function check()
    local p, s, level = state()
    if not p then return end
    local summary = string.format("level=%d XP=%d pending=%d", level, s.xp, M.pending())
    if summary ~= lastState then
        mwse.log("[MLX advancement] State: %s", summary)
        lastState = summary
    end
    if opening then
        if level > startedLevel and not tes3ui.menuMode() then
            restore()
            s.xp = 0
            s.pendingSkillPoints = 25
            p.modified = true
            shown = true
            mwse.log("[MLX advancement] Native level confirmed: %d -> %d; XP reset; 25 skill points pending", startedLevel, level)
        end
        return
    end
    if s.pendingSkillPoints and s.pendingSkillPoints > 0 then
        if tes3ui.menuMode() or tes3ui.findMenu("MLX:SkillAllocation") then return end
        local pending = s.pendingSkillPoints
        require("MLX.skillmenu").open(level, pending, function(base, allocation, budget)
            assert(tes3.player == p and p.data[key] == s and s.pendingSkillPoints == pending, "Advancement state changed")
            local sum, capacity = 0, 0
            for i = 0, 26 do
                local current = tes3.mobilePlayer:getSkillStatistic(i).base
                assert(current == base[i], "Skill changed during allocation: " .. i)
                local n = allocation[i]
                assert(type(n) == "number" and n >= 0 and n == math.floor(n), "Invalid allocation")
                assert(n <= math.max(0, 100 - current), "Skill cap exceeded")
                sum = sum + n
                capacity = capacity + math.max(0, 100 - current)
            end
            assert(sum == budget and budget == math.min(pending, capacity), "Invalid point total")
            local changed, snapshots = {}, {}
            local ok, err = pcall(function()
                for i = 0, 26 do
                    if allocation[i] > 0 then
                        local stat = tes3.mobilePlayer:getSkillStatistic(i)
                        local oldCurrent = tonumber(stat.currentRaw)
                        assert(oldCurrent, "Missing current skill " .. i)
                        snapshots[i] = {base = stat.base, current = oldCurrent}
                        changed[#changed + 1] = i
                        local targetBase = base[i] + allocation[i]
                        local targetCurrent = oldCurrent + allocation[i]
                        tes3.modStatistic({ reference = tes3.mobilePlayer, skill = i, value = allocation[i] })
                        local after = tes3.mobilePlayer:getSkillStatistic(i)
                        mwse.log("[MLX skills] Write check %d: base=%s expected=%s current=%s expected=%s", i, tostring(after.base), tostring(targetBase), tostring(after.currentRaw), tostring(targetCurrent))
                        assert(math.abs(after.base - targetBase) < 0.001 and math.abs(after.currentRaw - targetCurrent) < 0.001, "Skill write failed: " .. i)
                        mwse.log("[MLX skills] %s: base %s -> %s; current %s -> %s", tes3.getSkillName(i), tostring(base[i]), tostring(after.base), tostring(oldCurrent), tostring(after.currentRaw))
                    end
                end
            end)
            if not ok then
                for _, i in ipairs(changed) do
                    local restored, failure = pcall(function()
                        local st = tes3.mobilePlayer:getSkillStatistic(i)
                        tes3.modStatistic({reference = tes3.mobilePlayer, skill = i, base = snapshots[i].base - st.base})
                        st = tes3.mobilePlayer:getSkillStatistic(i)
                        tes3.modStatistic({reference = tes3.mobilePlayer, skill = i, current = snapshots[i].current - st.currentRaw})
                        st = tes3.mobilePlayer:getSkillStatistic(i)
                        assert(math.abs(st.base - snapshots[i].base) < 0.001 and math.abs(st.currentRaw - snapshots[i].current) < 0.001, "Rollback verification failed: " .. i)
                    end)
                    if not restored then mwse.log("[MLX skills] Rollback error: %s", tostring(failure)) end
                end
                error(err)
            end
            s.pendingSkillPoints = 0
            s.mlxVerifiedAllocationLevel = level
            p.modified = true
            mwse.log("[MLX skills] Committed %d points at level %d", sum, level)
        end)
        return
    end
    local need = M.requirement(level)
    if s.xp > need then s.xp = need; p.modified = true end
    if s.xp < need then shown = false; return end
    if shown or tes3ui.menuMode() then return end
    shown = true
    startedLevel = level
    opening = true
    local ok, err = pcall(function()
        local total = assert(tes3.findGMST(tes3.gmst.iLevelupTotal))
        oldTotal = total.value
        oldProgress = tes3.mobilePlayer.levelUpProgress
        for i = 1, 10 do
            local g = assert(tes3.findGMST(tes3.gmst[string.format("iLevelUp%02dMult", i)]))
            oldMultipliers[i] = g.value
            g.value = 1
        end
        total.value = 10
        tes3.mobilePlayer.levelUpProgress = 10
        assert(tes3.runLegacyScript({command = "EnableLevelUpMenu"}), "Native level-up command failed")
    end)
    if not ok then restore(); error(err) end
    mwse.log("[MLX advancement] Native level-up requested at level %d", level)
end
function M.register()
    mwse.log("[MLX advancement] v0.9.0 public beta registered")
    event.register("keyDown", function()
        if tes3ui.menuMode() then return end
        local p, s, level = state()
        if not p then return end
        mwse.log("[MLX recovery] F9: level=%d pending=%d XP=%d", level, M.pending(), s.xp)
        if M.pending() > 0 then
            local ok, err = pcall(check)
            if not ok then mwse.log("[MLX recovery] Open error: %s", tostring(err)) end
        else
            tes3.messageBox("MLX: No pending points recorded.")
        end
    end, {filter=67})
    event.register("load", function()
        if opening then restore() end
        shown = false; lastError = nil; lastState = nil
    end)
    event.register("charGenFinished", function() shown = false end)
    event.register("simulated", function()
        local ok, err = pcall(check)
        if not ok and tostring(err) ~= lastError then
            lastError = tostring(err)
            mwse.log("[MLX advancement] ERROR: %s", lastError)
        end
    end)
end
return M
