-- MLX v0.1.19: reward successful native potion brewing.
local M = {}
local key = "MLX_bookExperience_v1"
local rate = 15
local function brewed(e)
    if not e.object or not tes3.player or not tes3.mobilePlayer then return end
    local p = tes3.player
    local s = p.data[key]
    if not s then
        require("MLX.core").scan()
        s = p.data[key]
    end
    if not s then return end
    s.xp = s.xp + rate
    p.modified = true
    require("MLX.notifications").earned(rate, "Alchemy")
    mwse.log("[MLX alchemy] +%d XP: %s; total=%d", rate, tostring(e.object.name), s.xp)
end
function M.register()
    event.register("potionBrewed", function(e)
        local ok, err = pcall(brewed, e)
        if not ok then mwse.log("[MLX alchemy] ERROR: %s", tostring(err)) end
    end)
    mwse.log("[MLX] v0.1.19 Alchemy XP registered")
end
return M
