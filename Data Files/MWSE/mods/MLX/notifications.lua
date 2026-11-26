-- MLX 0.1.12: queue messages until normal gameplay resumes.
local M = {}
local queue = {}
local cooldown = 0
function M.earned(amount, source)
    amount = require("MLX.advancement").capAward(amount)
    if amount <= 0 then return end
    queue[#queue + 1] = {amount = amount, source = source or "Experience"}
end
local function reset()
    queue = {}
    cooldown = 0
end
event.register("load", reset)
event.register("charGenFinished", reset)
event.register("simulate", function(e)
    if not tes3.player or not tes3.mobilePlayer or tes3ui.menuMode() then return end
    cooldown = math.max(0, cooldown - (e.delta or 0))
    if cooldown > 0 or #queue == 0 then return end
    local entry = table.remove(queue, 1)
    local ok, err = pcall(tes3.messageBox, {
        message = string.format("XP earned: +%d (%s)", entry.amount, entry.source),
        showInDialog = false,
        duration = 2,
    })
    if not ok then mwse.log("[MLX notifications] ERROR: %s", tostring(err)) end
    cooldown = 2.1
end)
return M
