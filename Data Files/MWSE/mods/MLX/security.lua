-- MLX: reward confirmed native lockpick and probe results, once per reference.
local M = {}
local generation = 0
local function attempt(e, trap)
    if not tes3.player or not tes3.mobilePlayer or e.block then return end
    if (trap and e.disarmer or e.picker) ~= tes3.mobilePlayer then return end
    local ref, node = e.reference, e.lockData
    if not ref or not node or not ref.supportsLuaData then return end
    if trap then
        if not e.trapPresent or not node.trap then return end
    elseif not e.lockPresent or not node.locked then return end
    local amount = trap and 10 or 5 * math.min(5, math.max(1, math.ceil((tonumber(node.level) or 1) / 20)))
    local field = trap and 'MLX_trapRewarded_v1' or 'MLX_lockRewarded_v1'
    if ref.data[field] then return end
    local handle = tes3.makeSafeObjectHandle(ref)
    local epoch = generation
    timer.delayOneFrame(function()
        local ok, err = pcall(function()
            if epoch ~= generation or not tes3.player or not handle:valid() then return end
            local target = handle:getObject()
            if not target or not target.supportsLuaData or target.data[field] then return end
            local current = target.lockNode
            if current and (trap and current.trap or not trap and current.locked) then return end
            local p = tes3.player
            local s = p.data.MLX_bookExperience_v1
            if not s then require('MLX.core').scan(); s = p.data.MLX_bookExperience_v1 end
            if not s then return end
            target.data[field] = true
            target.modified = true
            s.xp = s.xp + amount
            p.modified = true
            local label = trap and 'Trap disarming' or 'Lockpicking'
            require('MLX.notifications').earned(amount, label)
            mwse.log('[MLX security] +%d XP (%s); total=%d', amount, label, s.xp)
        end)
        if not ok then mwse.log('[MLX security] confirmation ERROR: %s', tostring(err)) end
    end)
end
function M.register()
    event.register('load', function() generation = generation + 1 end)
    for _, name in ipairs({'lockPick', 'trapDisarm'}) do
        local trap = name == 'trapDisarm'
        event.register(name, function(e)
            local ok, err = pcall(attempt, e, trap)
            if not ok then mwse.log('[MLX security] attempt ERROR: %s', tostring(err)) end
        end, {priority = -1000})
    end
    mwse.log('[MLX] v0.1.21 Security XP registered')
end
return M
