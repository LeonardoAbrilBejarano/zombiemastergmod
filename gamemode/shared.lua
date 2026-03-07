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
    START_RESOURCES     = 150,
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
    STARTING_MONEY      = 3000,
    KILL_REWARD         = 100,
}

-- Weapon definitions for loadout / buy menu
ZM_WEAPONS = {
    -- Melee
    { id = "weapon_crowbar",    name = "Crowbar",       category = "melee", price = 0 },

    -- EFT ARC9 Pistols
    { id = "arc9_eft_glock17",  name = "Glock 17",      category = "Pistols", price = 200, ammo = "Pistol", ammoCount = 72 },
    { id = "arc9_eft_m1911a1",  name = "M1911A1",       category = "Pistols", price = 300, ammo = "Pistol", ammoCount = 72 },
    { id = "arc9_eft_m9a3",     name = "M9A3",          category = "Pistols", price = 400, ammo = "Pistol", ammoCount = 72 },
    { id = "arc9_eft_deagle",   name = "Desert Eagle",  category = "Pistols", price = 650, ammo = "357",    ammoCount = 21 },
    
    -- Other
    { id = "weapon_smg1",       name = "SMG",           category = "SMGs",    price = 1000, ammo = "SMG1", ammoCount = 120 },
    { id = "weapon_shotgun",    name = "Shotgun",       category = "Heavy",   price = 1200, ammo = "Buckshot", ammoCount = 24 },
    { id = "weapon_ar2",        name = "Rifle",         category = "Rifles",  price = 2000, ammo = "AR2", ammoCount = 60 },
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
end
