-- MLX 0.1.8: first confirmed ingredient consumption.
local M = {}
local key = "MLX_bookExperience_v1"
local function eligible(p)
    local class = p.object.class
    if not class then return false end
    for _, skill in ipairs(class.majorSkills) do
        if skill == tes3.skill.alchemy then return false end
    end
    for _, skill in ipairs(class.minorSkills) do
        if skill == tes3.skill.alchemy then return false end
    end
    return true
end
local function onEquip(e)
    local p = tes3.player
    local item = e.item
    if not p or e.reference ~= p or not item or item.objectType ~= tes3.objectType.ingredient or e.block then return end
    if not eligible(p) then return end
    local s = p.data[key]
    if not s then return end
    local id = item.id
    local lower = id:lower()
    if s.ingredientsSeen and s.ingredientsSeen[lower] then return end
    local before = tes3.getItemCount({reference=p, item=item})
    if before <= 0 then return end
    -- Equip is pre-consumption. Confirm actual loss on the next real frame,
    -- including when inventory remains open. Never remove or alter the item.
    timer.delayOneFrame(function()
        local ok, err = pcall(function()
            local player = tes3.player
            if not player or player.data[key] ~= s or not eligible(player) then return end
            local obj = tes3.getObject(id)
            if not obj then return end
            local after = tes3.getItemCount({reference=player, item=obj})
            if after >= before then return end
            s.ingredientsSeen = s.ingredientsSeen or {}
            if s.ingredientsSeen[lower] then return end
            s.ingredientsSeen[lower] = true
            s.xp = s.xp + 1
            player.modified = true
            require("MLX.notifications").earned(1, "Ingredient")
            mwse.log("[MLX ingredients] +1 XP: %s (%s); total=%d", obj.name or id, id, s.xp)
        end)
        if not ok then mwse.log("[MLX ingredients] Confirmation ERROR: %s", tostring(err)) end
    end, timer.real)
end
function M.register()
    event.register("equip", function(e)
        local ok, err = pcall(onEquip, e)
        if not ok then mwse.log("[MLX ingredients] Equip ERROR: %s", tostring(err)) end
    end, {priority=1000})
end
return M
