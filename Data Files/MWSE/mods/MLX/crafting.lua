-- MLX 0.1.16: optional legacy Morrowind Crafting integration.
local M = {}
local key = "MLX_bookExperience_v1"
local skills = {
    {"mc_cooking", "Cooking"}, {"mc_crafting", "Crafting"},
    {"mc_woodworking", "Woodworking"}, {"mc_sewing", "Sewing"},
    {"mc_fletching", "Fletching"}, {"mc_mining", "Mining"},
    {"mc_smithing", "Smithing"},
}
local function scan()
    local p = tes3.player
    if not p or not tes3.mobilePlayer or not p.object then return end
    local s = p.data[key]
    if not s then return end
    for _, skill in ipairs(skills) do
        local id, name = skill[1], skill[2]
        local value = tonumber(tes3.getGlobal(id))
        -- Zero is the uninitialized default in the Crafting ESP.
        if value and value >= 1 then
            local level = math.floor(value)
            if not s.craftingHigh then s.craftingHigh = {} end
            local high = s.craftingHigh[id]
            if high == nil then
                s.craftingHigh[id] = level
                p.modified = true
                mwse.log("[MLX crafting] %s baseline: %d", name, level)
            elseif level > high then
                local xp = (level - high) * 5
                s.craftingHigh[id] = level
                s.xp = s.xp + xp
                p.modified = true
                require("MLX.notifications").earned(xp, "Crafting: " .. name)
                mwse.log("[MLX crafting] +%d XP: %s %d -> %d; total=%d", xp, name, high, level, s.xp)
            end
        end
    end
end
local lastError
local function safe()
    local ok, err = pcall(scan)
    if not ok then
        if lastError ~= tostring(err) then mwse.log("[MLX crafting] ERROR: %s", tostring(err)); lastError = tostring(err) end
    else lastError = nil end
end
function M.register()
    local last = -10
    event.register("simulate", function()
        local now = os.clock()
        if now - last >= 0.5 then last = now; safe() end
    end)
    event.register("loaded", function() last = -10 end)
    event.register("charGenFinished", function() last = -10 end)
    event.register("save", safe)
end
return M
