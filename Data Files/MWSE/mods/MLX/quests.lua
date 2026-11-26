-- MLX v0.1.11: journal completion, once per topic per save.
local M = {}
local key = "MLX_bookExperience_v1"
local rate = 100
local function complete(e)
    if not e.info or not e.topic or not e.info.isQuestFinished then return end
    if e.previousInfo and e.previousInfo.isQuestFinished then return end
    if type(e.index) ~= "number" or e.index <= 0 or e.index == e.previousIndex then return end
    local p = tes3.player
    if not p or not tes3.mobilePlayer then return end
    local s = p.data[key]
    if not s then return end
    local id = e.topic.id:lower()
    s.completedQuests = s.completedQuests or {}
    if s.completedQuests[id] then return end
    s.completedQuests[id] = true
    s.xp = s.xp + rate
    p.modified = true
    require("MLX.notifications").earned(rate, "Quest")
    mwse.log("[MLX quests] +%d XP: %s (index %d); total=%d", rate, id, e.index, s.xp)
end
function M.register()
    event.register("journal", function(e)
        local ok, err = pcall(complete, e)
        if not ok then mwse.log("[MLX quests] ERROR: %s", tostring(err)) end
    end)
end
return M
