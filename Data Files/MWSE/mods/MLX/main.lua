-- MLX: inventory marker, XP tracking, advancement and MCM entry point.
local id = "mlx_experience_marker_v2"
local oldId = "mlx_experience_marker_v1"
local lastCheck = -10
local lastCount = nil
local lastError = nil
local function log(s) mwse.log("[MLX marker] %s", s) end
local function count(item)
    return tes3.getItemCount({ reference = tes3.player, item = item })
end
local function ensure()
    if not tes3.player or not tes3.mobilePlayer then return end
    local obj = tes3.getObject(id)
    if not obj then
        local base = assert(tes3.getObject("misc_dwrv_gear00"), "Missing vanilla Rusty Dwemer Cog")
        obj = assert(base:createCopy({ id = id, addToObjectList = true, sourceless = false }), "Copy failed")
        obj.name = "Experience"
        obj.weight = 0
        obj.value = 0
        log("Created " .. obj.id .. "; icon=" .. tostring(obj.icon) .. "; carriable=" .. tostring(obj.isCarriable))
    end
    local before = count(obj)
    if before == 0 then
        local added = tes3.addItem({ reference = tes3.player, item = obj, count = 1, playSound = false, showMessage = false, updateGUI = true })
        local after = count(obj)
        log("Insertion: before=" .. tostring(before) .. "; addItem returned=" .. tostring(added) .. "; after=" .. tostring(after))
        if after > 0 then tes3ui.forcePlayerInventoryUpdate() end
    end
    local current = count(obj)
    if current > 1 then
        tes3.removeItem({ reference = tes3.player, item = obj, count = current - 1, playSound = false, showMessage = false, updateGUI = true })
        tes3ui.forcePlayerInventoryUpdate()
        current = count(obj)
        log("Duplicate repair; remaining markers=" .. tostring(current))
    end
    if current ~= lastCount then
        log("Verified inventory count=" .. tostring(current))
        lastCount = current
    end
    -- Only clean up the obsolete marker after the replacement is present.
    if current > 0 then
        local old = tes3.getObject(oldId)
        if old then
            local n = count(old)
            if n > 0 then
                tes3.removeItem({ reference = tes3.player, item = old, count = n, playSound = false })
                tes3ui.forcePlayerInventoryUpdate()
                log("Removed obsolete test marker")
            end
        end
    end
end
local function check()
    local ok, err = pcall(ensure)
    if not ok then
        if tostring(err) ~= lastError then log("ERROR: " .. tostring(err)); lastError = tostring(err) end
    else lastError = nil end
end
local function reset()
    lastCheck = -10
    lastCount = nil
    lastError = nil
end
-- Simulation only runs outside menus. Recheck after starting inventory transfers.
event.register("simulate", function()
    local now = os.clock()
    if now - lastCheck < 1 then return end
    lastCheck = now
    check()
end)
event.register("loaded", reset)
event.register("charGenFinished", reset)
event.register("uiActivated", function(e)
    if not tes3.player or not tes3.mobilePlayer then return end
    local ok, err = pcall(function()
        local obj = tes3.getObject(id)
        log("Inventory opened; marker count=" .. tostring(obj and count(obj) or 0))
    end)
    if not ok then log("Inventory diagnostic error: " .. tostring(err)) end
end, { filter = "MenuInventory" })
log("v0.1.3 marker-only initialized")


-- MLX 0.1.5: isolated acquisition polling, no changes to marker code.
local books = require("MLX.core")
local combat = require("MLX.combat")
local combatError
local lastBookCheck = -10
local bookError
local function scanBooks()
    local ok, err = pcall(books.scan)
    if not ok then
        if bookError ~= tostring(err) then log("Book ERROR: " .. tostring(err)); bookError = tostring(err) end
    else bookError = nil end
    local combatOK, combatErr = pcall(combat.scan)
    if not combatOK then
        if combatError ~= tostring(combatErr) then log("Combat ERROR: " .. tostring(combatErr)); combatError = tostring(combatErr) end
    else combatError = nil end
end
event.register("simulate", function()
    local now = os.clock()
    if now - lastBookCheck < 0.5 then return end
    lastBookCheck = now
    scanBooks()
end)
event.register("loaded", function() lastBookCheck = -10 end)
event.register("charGenFinished", function() lastBookCheck = -10 end)
event.register("save", scanBooks)

-- MLX 0.1.5: live XP tooltip.
local lastTooltipResult
local function experienceTooltip(e)
    if not e.object or not e.object.id or e.object.id:lower() ~= id then return end
    if not e.tooltip or not tes3.player or not tes3.player.object then return end
    local ok, err = pcall(function()
        local level = tonumber(tes3.player.object.level)
        if not level or level < 1 then error("Player level unavailable") end
        level = math.floor(level)
        local need = require("MLX.advancement").requirement(level)
        scanBooks()
        local xp = math.min(books.xp(), need)
        local lines = {
            string.format("Level: %d", level),
            string.format("Experience: %d / %d XP", xp, need),
            string.format("XP remaining: %d", math.max(0, need - xp)),
            string.format("Progress: %.1f%%", math.min(100, 100 * xp / need)),
        }
        local pending = require("MLX.advancement").pending()
        if pending > 0 then lines[#lines + 1] = string.format("Unspent skill points: %d", pending) end
        if xp >= need then lines[#lines + 1] = "Ready to Advance!" end
        local block = e.tooltip:createBlock({ id = "MLX:ExperienceTooltip" })
        block.flowDirection = "top_to_bottom"
        block.autoHeight = true
        block.autoWidth = true
        for _, line in ipairs(lines) do
            block:createLabel({ text = line })
        end
        e.tooltip:updateLayout()
        local result = string.format("Tooltip displayed: level=%d XP=%d/%d", level, xp, need)
        if result ~= lastTooltipResult then log(result); lastTooltipResult = result end
    end)
    if not ok then
        local result = "Tooltip ERROR: " .. tostring(err)
        if result ~= lastTooltipResult then log(result); lastTooltipResult = result end
    end
end
event.register("uiObjectTooltip", experienceTooltip)
log("v0.1.7 book, scroll and combat XP initialized")

require("MLX.ingredients").register()
mwse.log("[MLX] v0.1.8 ingredient discovery initialized")

require("MLX.exploration").register()
mwse.log("[MLX] v0.1.9 exploration initialized")

require("MLX.quests").register()
mwse.log("[MLX] v0.1.11 quest completion initialized; combat rate reduced")

require("MLX.notifications")
mwse.log("[MLX] v0.1.12 queued source-labelled notifications initialized")

require("MLX.reputation").register()
mwse.log("[MLX] v0.1.13 reputation initialized")

require("MLX.factions").register()
mwse.log("[MLX] v0.1.14 faction promotion XP initialized")

require("MLX.customskills").register()
mwse.log("[MLX] v0.1.15 Skills Module permanent skill XP initialized")

require("MLX.crafting").register()
mwse.log("[MLX] v0.1.16 optional Morrowind Crafting XP initialized")

require("MLX.artifacts").register()
mwse.log("[MLX] v0.1.17 artifact XP initialized")

require("MLX.progression").register()

require("MLX.alchemy").register()

require("MLX.armorer").register()

require("MLX.security").register()

require("MLX.pickpocket").register()

require("MLX.enchanting").register()

require("MLX.advancement").register()

-- MCM only: no changes to advancement or save data.
local function registerMLXConfig()
    local template = mwse.mcm.createTemplate({name="Morrowind Living Experience (MLX)"})
    template:register()
    local page = template:createSideBarPage({label="Advancement", inGameOnly=false})
    page.sidebar:createInfo({text="Morrowind Living Experience\nVersion 0.9.0 Beta\nExperience-based character advancement."})
    page:createInfo({label="Character advancement", text="Earn XP through living and adventuring. Custom and legacy crafting skills award 5 XP per permanent whole skill point. First-time eligible ingredient consumption awards 1 XP. Select three attributes and allocate 25 skill points at each level. Press F9 during gameplay to reopen pending allocation."})
    page:createInfo({label="Experience", text="Hover over the Experience inventory marker for progress and pending points."})
    mwse.log("[MLX] v0.9.0 Beta MCM sidebar registered")
end
event.register("modConfigReady", function()
    local ok, err = pcall(registerMLXConfig)
    if not ok then mwse.log("[MLX] MCM ERROR: %s", tostring(err)) end
end)
