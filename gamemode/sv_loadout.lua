--[[
    Zombie Master - Weapon Loadout System
    Server-side: distributes weapons to survivors at round start
]]

-- Weapon categories
local WEAPON_MELEE = "melee"
local WEAPON_SMALL = "small"
local WEAPON_LARGE = "large"

-- Give a random loadout to a survivor
function ZM_GiveLoadout(ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_SURVIVORS then return end

    ply:StripWeapons()

    -- Always give crowbar (melee backup)
    ply:Give("weapon_crowbar")

    -- Give a small weapon (pistol or revolver)
    local smallWeapons = {}
    for _, w in ipairs(ZM_WEAPONS) do
        if w.category == "small" then table.insert(smallWeapons, w) end
    end
    if #smallWeapons > 0 then
        local small = smallWeapons[math.random(#smallWeapons)]
        ply:Give(small.id)
        if small.ammo then
            ply:GiveAmmo(small.ammoCount or 50, small.ammo, true)
        end
    end

    -- 60% chance to also get a large weapon
    if math.random() < 0.6 then
        local largeWeapons = {}
        for _, w in ipairs(ZM_WEAPONS) do
            if w.category == "large" then table.insert(largeWeapons, w) end
        end
        if #largeWeapons > 0 then
            local large = largeWeapons[math.random(#largeWeapons)]
            ply:Give(large.id)
            if large.ammo then
                ply:GiveAmmo(large.ammoCount or 30, large.ammo, true)
            end
        end
    end

    -- Set health and armor
    ply:SetHealth(ZM_CONFIG.SURVIVOR_HP)
    ply:SetArmor(ZM_CONFIG.SURVIVOR_ARMOR)
end

-- Give a late-joining survivor a loadout
function ZM_GiveLateJoinLoadout(ply)
    ZM_GiveLoadout(ply)
end
