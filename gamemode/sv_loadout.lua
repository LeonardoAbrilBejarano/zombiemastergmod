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
    
    -- Give default pistol
    local pistol = ply:Give("arc9_eft_pm")
    if IsValid(pistol) then
        ply:SetAmmo(0, pistol:GetPrimaryAmmoType())
    end

    -- Set health and armor
    ply:SetHealth(ZM_CONFIG.SURVIVOR_HP)
    ply:SetArmor(ZM_CONFIG.SURVIVOR_ARMOR)
end

-- Give a late-joining survivor a loadout
function ZM_GiveLateJoinLoadout(ply)
    ZM_GiveLoadout(ply)
end
