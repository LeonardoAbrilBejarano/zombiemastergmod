--[[
    Zombie Master Gamemode - Shared Init
    Loaded on both client and server
]]

GM.Name     = "Zombie Master"
GM.Author   = "Custom"
GM.Email    = ""
GM.Website  = ""
GM.TeamBased = true

-- Team constants
TEAM_SURVIVORS  = 2
TEAM_ZM         = 3

-- Round states
ROUND_WAITING   = 0
ROUND_ACTIVE    = 1
ROUND_POST      = 2

-- Load shared systems
include("sh_zombietypes.lua")

-- Shared configuration
ZM_CONFIG = {
    -- Resource system
    START_RESOURCES     = 999,
    MAX_RESOURCES       = 999,
    RESOURCE_REGEN      = 3,        -- Resources gained per tick
    RESOURCE_REGEN_RATE = 1,        -- Seconds between regen ticks

    -- Population
    MAX_ZOMBIES         = 50,       -- Maximum zombie population
    BANSHEE_LIMIT       = 5,        -- Max banshees = players * this value

    -- Spawn
    SPAWN_DELAY         = 0.75,     -- Seconds between zombie spawns from a single point
    SPAWN_QUEUE_SIZE    = 10,       -- Max queue size per spawn point

    -- Powers
    PHYSEXPLODE_COST    = 400,
    PHYSEXPLODE_DELAY   = 7.4,      -- Seconds before explosion
    PHYSEXPLODE_RADIUS  = 222,
    PHYSEXPLODE_FORCE_DROP_RADIUS = 128,

    SPOTCREATE_COST     = 100,

    -- Round
    ROUND_WAIT_TIME     = 15,       -- Seconds to wait for players
    ROUND_POST_TIME     = 10,       -- Seconds after round end before next
    MIN_PLAYERS         = 1,        -- Minimum players to start (1 for testing)
    ROUND_TIME          = 600,      -- Max round time (10 min)

    -- Loadout
    SURVIVOR_HP         = 100,
    SURVIVOR_ARMOR      = 50,
    ZM_MOVE_SPEED       = 800,      -- ZM overhead camera speed
    -- Economy
    STARTING_MONEY      = 16000,
    KILL_REWARD         = 100,
}

-- Weapon definitions for loadout / buy menu
ZM_WEAPONS = {
    -- Melee
    { id = "weapon_crowbar",    name = "Crowbar",       category = "melee", price = 0 },

    -- EFT ARC9 Pistols
    { id = "arc9_eft_glock17",  name = "Glock 17",      category = "Pistolas", price = 200, ammo = "Pistol", ammoCount = 72 },
    { id = "arc9_eft_m1911a1",  name = "M1911A1",       category = "Pistolas", price = 300, ammo = "Pistol", ammoCount = 72 },
    { id = "arc9_eft_m9a3",     name = "M9A3",          category = "Pistolas", price = 400, ammo = "Pistol", ammoCount = 72 },
    { id = "arc9_eft_deagle",   name = "Desert Eagle",  category = "Pistolas", price = 650, ammo = "357",    ammoCount = 21 },
    
    -- Other
    { id = "weapon_smg1",       name = "SMG",           category = "Subfusiles",    price = 1000, ammo = "SMG1", ammoCount = 120 },
    { id = "weapon_shotgun",    name = "Shotgun",       category = "Escopetas",   price = 1200, ammo = "Buckshot", ammoCount = 24 },
    { id = "weapon_ar2",        name = "Rifle",         category = "Fusiles de asalto",  price = 2000, ammo = "AR2", ammoCount = 60 },
}

-- Network strings (registered on server)
if SERVER then
    util.AddNetworkString("ZM_TeamSelect")
    util.AddNetworkString("ZM_JoinTeam")
    util.AddNetworkString("ZM_RoundState")
    util.AddNetworkString("ZM_UpdateResources")
    util.AddNetworkString("ZM_UpdatePopulation")
    util.AddNetworkString("ZM_SpawnZombie")
    util.AddNetworkString("ZM_CommandZombies")
    util.AddNetworkString("ZM_UsePower")
    util.AddNetworkString("ZM_Notification")
    util.AddNetworkString("ZM_ActivateManipulate")
    util.AddNetworkString("ZM_SyncManipulates")
    util.AddNetworkString("ZM_SyncSpawnPoints")
    util.AddNetworkString("ZM_SelectZombies")
    util.AddNetworkString("ZM_SetRally")
    util.AddNetworkString("ZM_DeleteZombie")
    util.AddNetworkString("ZM_RoundTimer")
    util.AddNetworkString("ZM_VolunteerZM")
    util.AddNetworkString("ZM_OpenSpawnMenu")
    util.AddNetworkString("ZM_ObjectiveUpdate")
    util.AddNetworkString("ZM_BuyItem")
    util.AddNetworkString("ZM_AutoAttack")
end

--[[---------------------------------------------------------
    Dynamic ARC9 EFT Weapon Loader
    Automatically scans installed weapons and adds EFT weapons
    to the Survivor Buy Menu (F3) with calculated prices.
-----------------------------------------------------------]]
hook.Add("InitPostEntity", "ZM_LoadEFTWeapons", function()
    local allWeapons = weapons.GetList()
    local addedCount = 0

    for _, wep in ipairs(allWeapons) do
        local class = wep.ClassName

        -- Only process EFT ARC9 weapons
        if class and string.match(class, "^arc9_eft_") then
            -- Avoid adding existing weapons manually defined above
            local alreadyExists = false
            for _, existing in ipairs(ZM_WEAPONS) do
                if existing.id == class then
                    alreadyExists = true
                    break
                end
            end

            if not alreadyExists then
                local name = wep.PrintName or class
                local wepCategory = wep.Category or ""
                local subCategory = wep.SubCategory or ""
                
                local shopCat = "Other"
                local price = 1000
                local ammo = "SMG1"
                local ammoCount = 60

                local catLower = string.lower(wepCategory .. " " .. subCategory .. " " .. class)
                
                -- Determine shop category, price, and ammo type based on the SWEP Category
                if string.find(catLower, "pistol") or string.find(catLower, "pistola") then
                    shopCat = "Pistolas"
                    price = 400
                    ammo = "Pistol"
                    ammoCount = 72
                elseif string.find(catLower, "smg") or string.find(catLower, "submachine") or string.find(catLower, "subfusil") then
                    shopCat = "Subfusiles"
                    price = 1000
                    ammo = "SMG1"
                    ammoCount = 120
                elseif string.find(catLower, "shotgun") or string.find(catLower, "escopeta") then
                    shopCat = "Escopetas"
                    price = 1200
                    ammo = "Buckshot"
                    ammoCount = 24
                elseif string.find(catLower, "sniper") or string.find(catLower, "marksman") or string.find(catLower, "francotirador") or string.find(catLower, "tirador") then
                    shopCat = "Fusiles de francotirador & Fusiles de tirador designado"
                    price = 2500
                    ammo = "357" -- Default strong ammo for snipers
                    ammoCount = 20
                elseif string.find(catLower, "carbine") or string.find(catLower, "carabina") then
                    shopCat = "Carabinas de asalto"
                    price = 1500
                    ammo = "AR2"
                    ammoCount = 60
                elseif string.find(catLower, "assault") or string.find(catLower, "asalto") or string.find(catLower, "rifle") then
                    shopCat = "Fusiles de asalto"
                    price = 1800
                    ammo = "AR2"
                    ammoCount = 90
                elseif string.find(catLower, "machine gun") or string.find(catLower, "lmg") or string.find(catLower, "ametralladora") then
                    shopCat = "Ametralladoras Ligeras"
                    price = 3000
                    ammo = "AR2"
                    ammoCount = 200
                elseif string.find(catLower, "explosive") or string.find(catLower, "grenade") or string.find(catLower, "granada") then
                    shopCat = "Granadas & Lanzagranadas"
                    price = 800
                    ammo = "Grenade"
                    ammoCount = 1
                elseif string.find(catLower, "melee") or string.find(catLower, "cuerpo") then
                    shopCat = "Cuerpo a cuerpo"
                    price = 500
                else
                    shopCat = (subCategory ~= "") and subCategory or "Otros"
                end

                -- Add to global ZM weapons table
                table.insert(ZM_WEAPONS, {
                    id = class,
                    name = name,
                    category = shopCat,
                    price = price,
                    ammo = ammo,
                    ammoCount = ammoCount
                })
                addedCount = addedCount + 1
            end
        end
    end
    print("[ZM] Dynamically loaded " .. addedCount .. " EFT weapons into the Buy Menu.")
end)
