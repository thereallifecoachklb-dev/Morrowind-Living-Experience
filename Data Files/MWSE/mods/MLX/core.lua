-- MLX 0.1.6: persistent book and magical scroll acquisition ledger.
local M = {}
local key = "MLX_bookExperience_v1"
local bookRate, scrollRate = 25, 15
function M.xp()
    local p = tes3.player
    local s = p and p.data[key]
    return s and s.xp or 0
end
function M.scan()
    local p = tes3.player
    if not p or not tes3.mobilePlayer or not p.object then return end
    local books = {}
    for _, stack in pairs(p.object.inventory) do
        local obj = stack.object
        if stack.count > 0 and obj and obj.objectType == tes3.objectType.book
            then
            local rate
            if obj.type == tes3.bookType.book then
                rate = bookRate
            elseif obj.type == tes3.bookType.scroll and obj.enchantment then
                rate = scrollRate
            end
            if rate then books[obj.id:lower()] = { name = obj.name or obj.id, rate = rate } end
        end
    end
    local s = p.data[key]
    local baseline = not s
    if baseline then
        s = { xp = 0, seen = {} }
        p.data[key] = s
        p.modified = true
        mwse.log("[MLX books] Ledger initialized; existing books excluded")
    end
    local scrollBaseline = not s.scrollsInitialized
    for id, entry in pairs(books) do
        if not s.seen[id] then
            s.seen[id] = true
            if not baseline and not (scrollBaseline and entry.rate == scrollRate) then
                s.xp = s.xp + entry.rate
                require("MLX.notifications").earned(entry.rate, entry.rate == scrollRate and "Scroll" or "Book")
                mwse.log("[MLX books] +%d XP: %s (%s); total=%d", entry.rate, entry.name, id, s.xp)
            end
            p.modified = true
        end
    end
    if scrollBaseline then
        s.scrollsInitialized = true
        p.modified = true
        mwse.log("[MLX books] Scroll tracking initialized; existing scrolls excluded")
    end
end
return M
