-- MLX: reward confirmed native pickpocket transfers.
local M = {}
local generation = 0
local function attempt(e)
    local p = tes3.player
    if not p or not tes3.mobilePlayer or not e.item or not e.reference then return end
    local item = e.item
    local ref = e.reference
    if ref == p then return end
    local n = tonumber(e.count) or 0
    if n < 1 then return end
    local before = tes3.getItemCount({reference=p, item=item})
    local victimBefore = tes3.getItemCount({reference=ref, item=item})
    local handle = tes3.makeSafeObjectHandle(ref)
    local epoch = generation
    timer.delayOneFrame(function()
        local ok, err = pcall(function()
            if epoch ~= generation or not tes3.player or not handle:valid() then return end
            local target = handle:getObject()
            local player = tes3.player
            local after = tes3.getItemCount({reference=player, item=item})
            local victimAfter = tes3.getItemCount({reference=target, item=item})
            if after <= before or victimAfter >= victimBefore then return end
            local s = player.data.MLX_bookExperience_v1
            if not s then require('MLX.core').scan(); s = player.data.MLX_bookExperience_v1 end
            if not s then return end
            s.xp = s.xp + 5
            player.modified = true
            require('MLX.notifications').earned(5, 'Pickpocketing')
            mwse.log('[MLX pickpocket] +5 XP; total=%d', s.xp)
        end)
        if not ok then mwse.log('[MLX pickpocket] confirmation ERROR: %s', tostring(err)) end
    end)
end
function M.register()
    event.register('load', function() generation = generation + 1 end)
    event.register('pickpocket', function(e)
        local ok, err = pcall(attempt, e)
        if not ok then mwse.log('[MLX pickpocket] attempt ERROR: %s', tostring(err)) end
    end, {priority=-1000})
    mwse.log('[MLX] v0.1.22 Pickpocket XP registered')
end
return M
