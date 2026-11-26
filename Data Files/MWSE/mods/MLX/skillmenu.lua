-- MLX 0.2.1: post-native advancement allocation.
local M = {}
local groups = {
    { "Combat", {0,1,2,3,4,5,6,7,8} },
    { "Magic", {9,10,11,12,13,14,15,16,17} },
    { "Stealth", {18,19,20,21,22,23,24,25,26} },
}
local names = {"Block","Armorer","Medium Armor","Heavy Armor","Blunt Weapon","Long Blade","Axe","Spear","Athletics","Enchant","Destruction","Alteration","Illusion","Conjuration","Mysticism","Restoration","Alchemy","Unarmored","Security","Sneak","Acrobatics","Light Armor","Short Blade","Marksman","Mercantile","Speechcraft","Hand-to-Hand"}
local id = "MLX:SkillAllocation"
function M.open(level, pending, commit)
    if tes3ui.findMenu(id) then return end
    local base, allocation, labels = {}, {}, {}
    local capacity = 0
    for i = 0, 26 do
        local stat = tes3.mobilePlayer:getSkillStatistic(i)
        local value = assert(tonumber(stat.base), "Missing base skill " .. i)
        base[i] = math.floor(value)
        allocation[i] = 0
        capacity = capacity + math.max(0, 100 - base[i])
    end
    local budget = math.min(pending, capacity)
    local remaining = budget
    local menu = tes3ui.createMenu({id=id, fixedFrame=true, modal=true})
    menu.flowDirection = "top_to_bottom"
    menu.autoWidth = true
    menu.autoHeight = true
    local function close()
        menu:destroy()
        tes3ui.leaveMenuMode()
    end
    menu:createLabel({text=string.format("Level %d | Skill advancement",level)})
    menu:createLabel({text="Distribute your skill points"})
    local counter = menu:createLabel({text=""})
    local columns = menu:createBlock({})
    columns.flowDirection = "left_to_right"
    columns.autoWidth = true
    columns.autoHeight = true
    local function refresh()
        counter.text = string.format("Skill points remaining: %d / %d", remaining, budget)
        for i=0,26 do
            if labels[i] then labels[i].text = string.format("%d + %d = %d",base[i],allocation[i],base[i]+allocation[i]) end
        end
        menu:updateLayout()
    end
    local function change(i, delta)
        if delta > 0 and remaining > 0 and base[i]+allocation[i] < 100 then
            allocation[i]=allocation[i]+1; remaining=remaining-1
        elseif delta < 0 and allocation[i] > 0 then
            allocation[i]=allocation[i]-1; remaining=remaining+1
        end
        refresh()
    end
    for _, group in ipairs(groups) do
        local col = columns:createBlock({})
        col.flowDirection = "top_to_bottom"
        col.autoWidth = true; col.autoHeight = true
        col.paddingRight = 12
        col:createLabel({text=group[1]})
        for _, index in ipairs(group[2]) do
            local i = index
            local row = col:createBlock({})
            row.flowDirection = "left_to_right"
            row.autoWidth = true; row.autoHeight = true
            local name = row:createLabel({text=names[i+1]})
            name.width = 115
            local minus = row:createButton({text="-"})
            labels[i] = row:createLabel({text=""})
            labels[i].width = 100
            local plus = row:createButton({text="+"})
            minus:register(tes3.uiEvent.mouseClick,function() change(i,-1) end)
            plus:register(tes3.uiEvent.mouseClick,function() change(i,1) end)
        end
    end
    local buttons = menu:createBlock({})
    buttons.flowDirection="left_to_right"; buttons.autoWidth=true; buttons.autoHeight=true
    local reset=buttons:createButton({text="Reset"})
    reset:register(tes3.uiEvent.mouseClick,function()
        for i=0,26 do allocation[i]=0 end
        remaining=budget; refresh()
    end)
    local finish=buttons:createButton({text="Confirm allocation"})
    finish:register(tes3.uiEvent.mouseClick,function()
        if remaining ~= 0 then
            tes3.messageBox("MLX: Allocate all available points first.")
            return
        end
        local ok, err = pcall(commit, base, allocation, budget)
        if not ok then
            mwse.log("[MLX skills] Commit error: %s", tostring(err))
            tes3.messageBox("MLX: Allocation failed. See MWSE.log.")
            return
        end
        close()
        tes3.messageBox("MLX: Skill advancement complete!")
    end)
    refresh()
    tes3ui.enterMenuMode(id)
end
return M
