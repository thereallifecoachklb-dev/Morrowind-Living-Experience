-- MLX v0.1.20: experience for successful native equipment repairs.
local M = {}
local key = "MLX_bookExperience_v1"
local rate = 5
local function repaired(e)
    if not tes3.player or not tes3.mobilePlayer or not e.item then return end
    if e.repairer ~= tes3.mobilePlayer then return end
    if type(e.roll) ~= "number" or type(e.chance) ~= "number" or e.roll >= e.chance then return end
    if type(e.repairAmount) ~= "number" or e.repairAmount <= 0 then return end
    local p = tes3.player
    local s = p.data[key]
    if not s then
        require("MLX.core").scan()
        s = p.data[key]
    end
    if not s then return end
    s.xp = s.xp + rate
    p.modified = true
    require("MLX.notifications").earned(rate, "Armorer")
    mwse.log("[MLX armorer] +%d XP: %s; total=%d", rate, tostring(e.item.name), s.xp)
end
function M.register()
    event.register("repair", function(e)
        local ok, err = pcall(repaired, e)
        if not ok then mwse.log("[MLX armorer] ERROR: %s", tostring(err)) end
    end, { priority = -1000 })
    mwse.log("[MLX] v0.1.20 Armorer XP registered")
end
return M
