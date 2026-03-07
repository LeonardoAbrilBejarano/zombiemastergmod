--[[
    Zombie Master - Zombie Type Definitions
    Shared between client and server
]]

ZM_ZOMBIE_TYPES = {
    {
        id          = "shambler",
        name        = "Shambler",
        npcClass    = "npc_zombie",
        cost        = 10,
        popCost     = 1,
        description = "Slow but sturdy undead. Cheap and numerous.",
        color       = Color(120, 180, 80),
        icon        = "icon16/user.png",
    },
    {
        id          = "banshee",
        name        = "Banshee",
        npcClass    = "npc_fastzombie",
        cost        = 30,
        popCost     = 2,
        description = "Fast and agile. Can climb walls and leap at survivors.",
        color       = Color(200, 60, 60),
        icon        = "icon16/lightning.png",
    },
    {
        id          = "hulk",
        name        = "Hulk",
        npcClass    = "npc_poisonzombie",
        cost        = 75,
        popCost     = 4,
        description = "Massive and tough. Throws poison headcrabs.",
        color       = Color(100, 60, 160),
        icon        = "icon16/shield.png",
    },
    {
        id          = "drifter",
        name        = "Drifter",
        npcClass    = "npc_headcrab_black",
        cost        = 15,
        popCost     = 1,
        description = "Small and sneaky. Good for scouting.",
        color       = Color(60, 140, 200),
        icon        = "icon16/bug.png",
    },
    {
        id          = "immolator",
        name        = "Immolator",
        npcClass    = "npc_zombie",  -- We'll use a regular zombie with fire effect
        cost        = 50,
        popCost     = 3,
        description = "Burns everything around it. Dangerous in close quarters.",
        color       = Color(255, 140, 30),
        icon        = "icon16/fire.png",
        isImmolator = true,  -- Special flag for fire effects
    },
}

-- Lookup table by ID
ZM_ZOMBIE_BY_ID = {}
for _, ztype in ipairs(ZM_ZOMBIE_TYPES) do
    ZM_ZOMBIE_BY_ID[ztype.id] = ztype
end

-- Get cost for a zombie type
function ZM_GetZombieCost(typeId)
    local ztype = ZM_ZOMBIE_BY_ID[typeId]
    if not ztype then return 999, 999 end
    return ztype.cost, ztype.popCost
end

-- Get zombie type by index (1-based)
function ZM_GetZombieTypeByIndex(index)
    return ZM_ZOMBIE_TYPES[index]
end

-- Get total number of zombie types
function ZM_GetZombieTypeCount()
    return #ZM_ZOMBIE_TYPES
end
