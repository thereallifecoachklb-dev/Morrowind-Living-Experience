-- MLX v0.1.17: curated artifact registry, independent of ordinary enchanted equipment.
local M = {}
local key = "MLX_bookExperience_v1"
local artifacts = {
    ["amulet of shadows"] = { "amulet of shadows", 100 },
    ["artifact_bittercup_01"] = { "artifact_bittercup_01", 500 },
    ["azura_star_unique"] = { "azura_star_unique", 500 },
    ["bipolar blade"] = { "bipolar blade", 100 },
    ["bloodworm_helm_unique"] = { "bloodworm_helm_unique", 250 },
    ["bm_hunterspear_unique"] = { "bm_hunterspear_unique", 500 },
    ["bm_mace_aevar_uni"] = { "bm_mace_aevar_uni", 100 },
    ["bm_ring_hircine"] = { "bm_ring_hircine", 500 },
    ["bonebiter_bow_unique"] = { "bonebiter_bow_unique", 100 },
    ["boots of blinding speed[unique]"] = { "boots of blinding speed[unique]", 100 },
    ["boots_apostle_unique"] = { "boots_apostle_unique", 100 },
    ["claymore_chrysamere_unique"] = { "claymore_chrysamere_unique", 250 },
    ["claymore_iceblade_unique"] = { "claymore_iceblade_unique", 250 },
    ["cuirass_savior_unique"] = { "cuirass_savior_unique", 500 },
    ["daedric_crescent_unique"] = { "daedric_crescent_unique", 500 },
    ["daedric_helm_clavicusvile"] = { "daedric_helm_clavicusvile", 500 },
    ["daedric_scourge_unique"] = { "daedric_scourge_unique", 500 },
    ["dagger_fang_unique"] = { "dagger_fang_unique", 250 },
    ["dragonbone_cuirass_unique"] = { "dragonbone_cuirass_unique", 250 },
    ["dwarven_hammer_volendrung"] = { "dwarven_hammer_volendrung", 500 },
    ["ebon_plate_cuirass_unique"] = { "ebon_plate_cuirass_unique", 500 },
    ["ebony_bow_auriel"] = { "ebony_bow_auriel", 250 },
    ["ebony_shield_auriel"] = { "ebony_shield_auriel", 250 },
    ["gauntlet_fists_l_unique"] = { "gauntlet_fists_l_unique", 250 },
    ["gauntlet_fists_r_unique"] = { "gauntlet_fists_r_unique", 250 },
    ["helm_bearclaw_unique"] = { "helm_bearclaw_unique", 250 },
    ["katana_goldbrand_unique"] = { "katana_goldbrand_unique", 500 },
    ["keening"] = { "keening", 250 },
    ["longbow_shadows_unique"] = { "longbow_shadows_unique", 250 },
    ["longsword_umbra_unique"] = { "longsword_umbra_unique", 500 },
    ["lords_cuirass_unique"] = { "lords_cuirass_unique", 250 },
    ["mace of molag bal_unique"] = { "mace of molag bal_unique", 500 },
    ["mace of slurring"] = { "mace of slurring", 100 },
    ["mehrunes'_razor_unique"] = { "mehrunes'_razor_unique", 500 },
    ["misc_wraithguard_no_equip"] = { "wraithguard", 250 },
    ["necromancers_amulet_uniq"] = { "necromancers_amulet_uniq", 250 },
    ["nerevarblade_01"] = { "nerevarblade_01", 250 },
    ["nerevarblade_01_flame"] = { "nerevarblade_01", 250 },
    ["ring of azura"] = { "ring of azura", 500 },
    ["ring_dahrkmezalf_uniq"] = { "ring_dahrkmezalf_uniq", 100 },
    ["ring_denstagmer_unique"] = { "ring_denstagmer_unique", 100 },
    ["ring_equity_uniq"] = { "ring_equity_uniq", 100 },
    ["ring_khajiit_unique"] = { "ring_khajiit_unique", 500 },
    ["ring_mentor_unique"] = { "ring_mentor_unique", 100 },
    ["ring_phynaster_unique"] = { "ring_phynaster_unique", 250 },
    ["ring_surrounding_unique"] = { "ring_surrounding_unique", 100 },
    ["ring_vampiric_unique"] = { "ring_vampiric_unique", 250 },
    ["ring_warlock_unique"] = { "ring_warlock_unique", 250 },
    ["ring_wind_unique"] = { "ring_wind_unique", 100 },
    ["spear_mercy_unique"] = { "spear_mercy_unique", 500 },
    ["spell_breaker_unique"] = { "spell_breaker_unique", 500 },
    ["staff_hasedoki_unique"] = { "staff_hasedoki_unique", 250 },
    ["staff_magnus_unique"] = { "staff_magnus_unique", 250 },
    ["staff_of_llevule"] = { "staff_of_llevule", 100 },
    ["steel spear snow prince"] = { "steel spear snow prince", 100 },
    ["stendar_hammer_unique"] = { "stendar_hammer_unique", 250 },
    ["sunder"] = { "sunder", 250 },
    ["sword of almalexia"] = { "sword of almalexia", 250 },
    ["towershield_eleidon_unique"] = { "towershield_eleidon_unique", 250 },
    ["warhammer_crusher_unique"] = { "warhammer_crusher_unique", 250 },
    ["wraithguard"] = { "wraithguard", 250 },
    ["wraithguard_jury_rig"] = { "wraithguard", 250 },
}
-- Optional extension for other mods; aliases may share a discovery key.
function M.add(id, rate, canonical)
    assert(type(id)=="string" and type(rate)=="number" and rate>0 and rate==math.floor(rate))
    artifacts[id:lower()] = { (canonical or id):lower(), rate }
end
function M.scan()
    local p = tes3.player
    if not p or not tes3.mobilePlayer or not p.object then return end
    local s = p.data[key]
    if not s then return end
    local baseline = not s.artifactsSeen
    s.artifactsSeen = s.artifactsSeen or {}
    if baseline then p.modified = true end
    for _, stack in pairs(p.object.inventory) do
        local obj = stack.object
        local entry = obj and obj.id and artifacts[obj.id:lower()]
        if stack.count > 0 and entry and not s.artifactsSeen[entry[1]] then
            s.artifactsSeen[entry[1]] = true
            p.modified = true
            if not baseline then
                s.xp = s.xp + entry[2]
                require("MLX.notifications").earned(entry[2], "Artifact: " .. (obj.name or obj.id))
                mwse.log("[MLX artifacts] +%d XP: %s; total=%d", entry[2], obj.id, s.xp)
            end
        end
    end
end
local lastError
local function safe()
    local ok, err = pcall(M.scan)
    if not ok then
        if lastError ~= tostring(err) then mwse.log("[MLX artifacts] ERROR: %s", tostring(err)); lastError = tostring(err) end
    else lastError = nil end
end
function M.register()
    local last = -10
    event.register("simulate", function()
        local now = os.clock()
        if now-last >= 0.5 then last=now; safe() end
    end)
    event.register("loaded", function() last=-10 end)
    event.register("charGenFinished", function() last=-10 end)
    event.register("save", safe)
end
return M
