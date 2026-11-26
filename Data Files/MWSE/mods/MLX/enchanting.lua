-- MLX v0.1.23: successful self-enchantment and confirmed manual recharge.
local M = {}
local baseline, generation, pending = nil, 0, false
local function award(amount, label)
    local p = tes3.player
    if not p or not tes3.mobilePlayer then return end
    local s = p.data.MLX_bookExperience_v1
    if not s then require('MLX.core').scan(); s = p.data.MLX_bookExperience_v1 end
    if not s then return end
    s.xp = s.xp + amount
    p.modified = true
    require('MLX.notifications').earned(amount, label)
    mwse.log('[MLX enchant] +%d XP (%s); total=%d', amount, label, s.xp)
end
local function snapshot()
    if not tes3.player or not tes3.mobilePlayer then return nil end
    local result = { souls = 0, items = {} }
    for _, stack in pairs(tes3.player.object.inventory) do
        local obj = stack.object
        if obj and stack.count > 0 then
            if obj.objectType == tes3.objectType.miscItem then
                for _, data in pairs(stack.variables or {}) do
                    if data.soul then result.souls = result.souls + 1 end
                end
            elseif obj.objectType == tes3.objectType.weapon or obj.objectType == tes3.objectType.armor or obj.objectType == tes3.objectType.clothing then
                local ench = obj.enchantment
                if ench and (ench.castType == tes3.enchantmentType.onUse or ench.castType == tes3.enchantmentType.onStrike) then
                    local max = ench.maxCharge
                    local deficit = 0
                    for _, data in pairs(stack.variables or {}) do
                        local charge = tonumber(data.charge)
                        if charge and charge >= 0 then deficit = deficit + math.max(0, max - charge) end
                    end
                    result.items[obj.id] = { count = stack.count, deficit = deficit }
                end
            end
        end
    end
    return result
end
local function guarded(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then mwse.log('[MLX enchant] ERROR: %s', tostring(err)) end
end
local function check(before)
    local after = snapshot()
    baseline = after
    if not before or not after or after.souls >= before.souls then return end
    for id, old in pairs(before.items) do
        local new = after.items[id]
        if new and new.count == old.count and old.deficit - new.deficit > 0.001 then
            award(5, 'Recharging')
            return
        end
    end
    mwse.log('[MLX enchant] Soul consumed without confirmed recharge')
end
function M.register()
    event.register('load', function() generation = generation + 1; baseline = nil; pending = false end)
    event.register('enchantedItemCreated', function(e)
        guarded(function()
            if not e.object or not tes3.player or not tes3.mobilePlayer then return end
            if e.enchanterReference == tes3.player or e.enchanter == tes3.mobilePlayer then
                award(25, 'Enchanting')
            end
        end)
    end)
    -- The native selector opens before a soul gem is applied. Capture the state there.
    event.register('uiActivated', function()
        guarded(function() if not pending then baseline = snapshot() end end)
    end, {filter = 'MenuInventorySelect'})
    -- Observe the native skill exercise without unblocking the progression module.
    event.register('exerciseSkill', function(e)
        if e.skill ~= tes3.skill.enchant or not baseline or pending then return end
        if not tes3ui.findMenu('MenuInventorySelect') then return end
        local before, epoch = baseline, generation
        pending = true
        timer.delayOneFrame(function()
            if epoch ~= generation then return end
            pending = false
            guarded(check, before)
        end)
    end, {priority = 1000})
    event.register('simulate', function() if not pending then baseline = nil end end)
    mwse.log('[MLX] v0.1.23 Enchanting and recharge XP registered')
end
return M
