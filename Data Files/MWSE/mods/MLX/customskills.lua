-- MLX 0.1.15: Skills Module 2.1.1 permanent skill raises.
local M = {}
local key = "MLX_bookExperience_v1"
local ready = false
local function state()
    local p = tes3.player
    if not p or not tes3.mobilePlayer then return end
    return p, p.data[key]
end
local function baseline()
    local p, s = state()
    if not s then return end
    if not s.customSkillHigh then s.customSkillHigh = {}; p.modified = true end
    for id, data in pairs(p.data.otherSkills or {}) do
        if type(data) == "table" and type(data.value) == "number" then
            local n = math.floor(data.value)
            if s.customSkillHigh[id] == nil or n > s.customSkillHigh[id] then
                s.customSkillHigh[id] = n
                p.modified = true
            end
        end
    end
    ready = true
end
local function raised(e)
    if not ready then return end
    local p, s = state()
    if not s or not s.customSkillHigh or not e.skill then return end
    local skill = e.skill
    if skill.getOwner and skill:getOwner() ~= p then return end
    local id = skill.id
    local data = p.data.otherSkills and p.data.otherSkills[id]
    local delta = tonumber(e.numLevels)
    if not data or type(data.value) ~= "number" or not delta or delta <= 0 then return end
    local current = math.floor(data.value)
    local previous = math.floor(data.value - delta)
    local high = math.max(previous, s.customSkillHigh[id] or previous)
    local gained = math.max(0, current - high)
    if current > (s.customSkillHigh[id] or previous) then
        s.customSkillHigh[id] = current
        p.modified = true
    end
    if gained == 0 then return end
    local amount = 5 * gained
    s.xp = s.xp + amount
    p.modified = true
    require("MLX.notifications").earned(amount, "Skill: " .. (skill.name or id))
    mwse.log("[MLX custom skills] +%d XP: %s (%d -> %d); total=%d", amount, id, high, current, s.xp)
end
local function reset() ready = false end
local function safe(fn, e)
    local ok, err = pcall(fn, e)
    if not ok then mwse.log("[MLX custom skills] ERROR: %s", tostring(err)) end
end
function M.register()
    event.register("load", reset)
    event.register("loaded", reset)
    event.register("charGenFinished", reset)
    event.register("simulate", function() if not ready then safe(baseline) end end)
    -- The installed module emits this AFTER changing raw skill data, including
    -- exact numLevels. Do not also subscribe to SkillsModule:skillRaised.
    event.register("SkillsModule:LevelUp", function(e) safe(raised, e) end)
end
return M
