--[[
    Zombie Master - Mission / Objective System
    Server-side: handles mission flow, objectives, pickup items, and win conditions

    Missions are defined as sequences of objectives. When all objectives in a
    mission are completed, survivors win the round.
    
    Each objective can have:
      - description: text shown to survivors
      - type: "pickup" (find and deliver items), "interact" (use an entity), 
              "survive" (survive for X seconds), "reach" (reach a zone)
      - onComplete: callback when objective is completed
]]

-- Active mission state
ZM_Mission = {
    active      = false,
    missionId   = nil,
    objectives  = {},   -- list of objective tables
    current     = 1,    -- index of current objective
    items       = {},   -- spawned mission entities
    zones       = {},   -- trigger zones
}

-- All mission definitions
ZM_MISSIONS = {}

-- ============================================================
-- MISSION 1: GAS FEVER (inspired by zm_gasfever)
-- Find batteries → Power the elevator → Call for rescue on the radio
-- ============================================================
ZM_MISSIONS["gasfever"] = {
    name = "Gas Fever",
    description = "Find batteries to restore power, then call for rescue!",
    icon = "icon16/lightning.png",
    objectives = {
        {
            id = "find_batteries",
            description = "Find 2 batteries scattered around the area",
            type = "pickup",
            itemClass = "ent_zm_objective_item",
            itemModel = "models/items/car_battery01.mdl",
            itemName = "Battery",
            requiredCount = 2,
            collected = 0,
            spawnOffset = {Vector(500, 300, 20), Vector(-600, -400, 20)},
        },
        {
            id = "power_elevator",
            description = "Bring the batteries to the generator to restore power",
            type = "interact",
            interactModel = "models/props_vehicles/generatortrailer01.mdl",
            interactName = "Generator",
            interactPrompt = "Press E to install batteries",
            spawnOffset = Vector(0, 200, 20),
        },
        {
            id = "call_radio",
            description = "Use the radio to call for rescue!",
            type = "interact",
            interactModel = "models/props_lab/monitor02.mdl",
            interactName = "Radio",
            interactPrompt = "Press E to call for help",
            spawnOffset = Vector(100, 200, 45),
        },
        {
            id = "survive_rescue",
            description = "Survive until rescue arrives! (60 seconds)",
            type = "survive",
            surviveTime = 60,
        },
    },
}

-- ============================================================
-- MISSION 2: DARK WOODS (inspired by zm_woodsdark)
-- Find the cabin → Collect firewood → Light signal fire → Reach extraction
-- ============================================================
ZM_MISSIONS["darkwoods"] = {
    name = "Dark Woods",
    description = "Navigate the darkness and signal for rescue!",
    icon = "icon16/weather_moon.png",
    objectives = {
        {
            id = "find_flares",
            description = "Find 3 flares to light the way",
            type = "pickup",
            itemClass = "ent_zm_objective_item",
            itemModel = "models/items/flare.mdl",
            itemName = "Flare",
            requiredCount = 3,
            collected = 0,
            spawnOffset = {Vector(800, 100, 20), Vector(-300, 600, 20), Vector(200, -700, 20)},
        },
        {
            id = "find_radio_parts",
            description = "Find the radio transmitter parts (2 needed)",
            type = "pickup",
            itemClass = "ent_zm_objective_item",
            itemModel = "models/props_lab/reciever01a.mdl",
            itemName = "Radio Part",
            requiredCount = 2,
            collected = 0,
            spawnOffset = {Vector(-500, 200, 20), Vector(600, -300, 20)},
        },
        {
            id = "build_radio",
            description = "Build the emergency radio at the tower",
            type = "interact",
            interactModel = "models/props_wasteland/prison_lamp001c.mdl",
            interactName = "Radio Tower",
            interactPrompt = "Press E to assemble radio",
            spawnOffset = Vector(0, -400, 20),
        },
        {
            id = "wait_rescue",
            description = "Hold position until the helicopter arrives! (45 seconds)",
            type = "survive",
            surviveTime = 45,
        },
    },
}

-- ============================================================
-- MISSION 3: DOCKS OF SHAME (inspired by zm_docksofshame)
-- Find fuel cans → Fuel the boat → Start engine → Escape
-- ============================================================
ZM_MISSIONS["docks"] = {
    name = "Docks of Shame",
    description = "Fuel the escape boat and get out alive!",
    icon = "icon16/anchor.png",
    objectives = {
        {
            id = "find_fuel",
            description = "Find 3 fuel cans around the docks",
            type = "pickup",
            itemClass = "ent_zm_objective_item",
            itemModel = "models/props_junk/gascan001a.mdl",
            itemName = "Fuel Can",
            requiredCount = 3,
            collected = 0,
            spawnOffset = {Vector(400, 500, 20), Vector(-400, 300, 20), Vector(100, -600, 20)},
        },
        {
            id = "fuel_boat",
            description = "Bring the fuel to the boat engine",
            type = "interact",
            interactModel = "models/props_vehicles/apc001.mdl",
            interactName = "Boat Engine",
            interactPrompt = "Press E to fuel the boat",
            spawnOffset = Vector(0, 600, 20),
        },
        {
            id = "find_keys",
            description = "Find the ignition key",
            type = "pickup",
            itemClass = "ent_zm_objective_item",
            itemModel = "models/props_junk/garbage_metalcan001a.mdl",
            itemName = "Ignition Key",
            requiredCount = 1,
            collected = 0,
            spawnOffset = {Vector(-700, -200, 20)},
        },
        {
            id = "start_engine",
            description = "Start the boat engine and escape!",
            type = "interact",
            interactModel = "models/props_combine/breenConsole.mdl",
            interactName = "Boat Controls",
            interactPrompt = "Press E to start engine",
            spawnOffset = Vector(50, 600, 20),
        },
    },
}

-- ============================================================
-- MISSION 4: SUBWAY ESCAPE (inspired by zm_subway)
-- Restore power → Open gates → Reach the train → Escape
-- ============================================================
ZM_MISSIONS["subway"] = {
    name = "Subway Escape",
    description = "Restore power to the subway and catch the last train!",
    icon = "icon16/arrow_right.png",
    objectives = {
        {
            id = "find_fuses",
            description = "Find 2 fuse boxes to restore power",
            type = "pickup",
            itemClass = "ent_zm_objective_item",
            itemModel = "models/props_lab/reciever01b.mdl",
            itemName = "Fuse Box",
            requiredCount = 2,
            collected = 0,
            spawnOffset = {Vector(300, -500, 20), Vector(-500, 400, 20)},
        },
        {
            id = "restore_power",
            description = "Install fuses at the power station",
            type = "interact",
            interactModel = "models/props_combine/combine_interface001.mdl",
            interactName = "Power Station",
            interactPrompt = "Press E to install fuses",
            spawnOffset = Vector(-200, 0, 20),
        },
        {
            id = "open_gate",
            description = "Open the security gate",
            type = "interact",
            interactModel = "models/props_combine/combine_lock01.mdl",
            interactName = "Security Gate",
            interactPrompt = "Press E to open gate",
            spawnOffset = Vector(200, 300, 20),
        },
        {
            id = "reach_train",
            description = "Reach the train platform!",
            type = "reach",
            reachRadius = 150,
            spawnOffset = Vector(0, 800, 20),
        },
    },
}

-- ============================================================
-- MISSION 5: CUSTOM BATTERY SURVIVAL
-- Specifically designed for the downloaded workshop map
-- ============================================================
ZM_MISSIONS["custom_battery_survival"] = {
    name = "Power Restoration",
    description = "Find the 3 hidden batteries, deliver them to the spawn, and survive for 3 minutes!",
    icon = "icon16/lightning.png",
    objectives = {
        {
            id = "find_batteries",
            description = "Find 3 batteries scattered around the map",
            type = "pickup",
            itemClass = "ent_zm_objective_item",
            itemModel = "models/items/car_battery01.mdl",
            itemName = "Battery",
            requiredCount = 3,
            collected = 0,
            -- EDIT THESE VECTORS TO YOUR EXACT COORDINATES WITH THE getpos COMMAND
            absoluteSpawnPos = {
                Vector(-903.963684, -342.429047, 202.516098),
                Vector(-1219.185059, -2682.500000, 492.031250),
                Vector(4957.332520, 1190.500977, 448.031250)
            },
        },
        {
            id = "deliver_batteries",
            description = "Bring the batteries back to the generator at spawn",
            type = "interact",
            interactModel = "models/props_vehicles/generatortrailer01.mdl",
            interactName = "Generator",
            interactPrompt = "Press E to install batteries",
            -- EDIT THIS VECTOR TO YOUR EXACT SPAWN/DELIVERY COORDINATE WITH THE getpos COMMAND
            absoluteSpawnPos = Vector(3456.766113, -1844.450684, 384.031250),
        },
        {
            id = "survive_3_mins",
            description = "Defend the area for 3 minutes! (180 seconds)",
            type = "survive",
            surviveTime = 180,
        },
    },
    -- Spawn points for survivors in this specific mission
    playerSpawns = {
        Vector(3456.766113, -1844.450684, 384.031250),
    }
}

-- ============================================================
-- MISSION SYSTEM FUNCTIONS
-- ============================================================
-- MAP-SPECIFIC ZOMBIE SPAWN POINTS
-- ============================================================
ZM_MAP_SPAWNPOINTS = {
    -- Format: mapname = { {pos = Vector, ang = Angle}, ... }
    ["docksofthedead"] = {
        { pos = Vector(1176.053589, -673.838074, 102.290039), ang = Angle(-5.466962, 174.335938, -0.000128) },
        { pos = Vector(2693.938232, -1791.397095, -382.266174), ang = Angle(12.921293, -2.519963, -0.000128) },
        { pos = Vector(-1414.554443, -878.577576, -204.162659), ang = Angle(5.632240, -75.962540, -0.000128) },
        { pos = Vector(-2179.603271, -2218.307861, 377.505676), ang = Angle(-3.589503, -62.212814, -0.000128) },
        { pos = Vector(-377.814606, 451.109985, 26.200813), ang = Angle(-3.307843, 179.870636, -0.000128) },
        { pos = Vector(1827.108887, -256.268127, 172.322830), ang = Angle(-3.423649, 177.468369, 0.000000) }
    }
}

-- Generate pre-defined ZM Spawn Points for the map
function ZM_SpawnMapSpawnPoints()
    local theMap = string.lower(game.GetMap())
    
    -- Cleanup strictly the procedural spawn points first to prevent dupes
    for _, ent in ipairs(ents.FindByClass("ent_zm_spawnpoint")) do
        if IsValid(ent) then ent:Remove() end
    end
    
    -- Fuzzy match the map name (e.g. zm_docksofthedead matches docksofthedead)
    local matchedSpawns = nil
    for mapKey, spawnList in pairs(ZM_MAP_SPAWNPOINTS) do
        if string.find(theMap, mapKey, 1, true) then
            matchedSpawns = spawnList
            break
        end
    end
    
    if matchedSpawns then
        local count = 0
        for i, spawnData in ipairs(matchedSpawns) do
            local sp = ents.Create("ent_zm_spawnpoint")
            if IsValid(sp) then
                -- Add +15 to Z so they don't clip into the floor
                sp:SetPos(spawnData.pos + Vector(0, 0, 15))
                sp:SetAngles(spawnData.ang)
                sp:SetNWString("SpawnName", "Spawn Area " .. i)
                sp:Spawn()
                sp:Activate()
                count = count + 1
            end
        end
        print("DEBUG ZM_SpawnMapSpawnPoints: Spawned " .. count .. " ZM spawn points for map " .. theMap)
        
        -- Force a sync to the ZM player so they see the new red spheres immediately
        local zmPly = ZM_GetZMPlayer and ZM_GetZMPlayer() or nil
        if IsValid(zmPly) then
            ZM_SyncSpawnPointsToClient(zmPly)
        end
    else
        print("DEBUG ZM_SpawnMapSpawnPoints: No predefined ZM spawn points found for map", theMap)
    end
end

-- Spawn them natively as soon as the map logic finishes loading
hook.Add("InitPostEntity", "ZM_LoadMapSpawns", function()
    timer.Simple(1, function()
        ZM_SpawnMapSpawnPoints()
    end)
end)

-- Start a mission (called at round start)
function ZM_StartMission(missionId)
    -- Clean up previous mission & spawn pints FIRST
    ZM_CleanupMission()

    local theMap = string.lower(game.GetMap())
    print("DEBUG ZM_StartMission MAP NAME CHECK:", theMap)
    
    -- Make sure map spawns exist or refresh them
    ZM_SpawnMapSpawnPoints()
    
    -- Disable custom missions on specific maps that have their own integrated missions
    if string.find(theMap, "docksofthedead", 1, true) then
        ZM_NotifyAll("Playing on official ZM map: Custom objectives disabled.", Color(150, 150, 150))
        -- Don't clean up mission here since we just spawned ZM points; the cleanup should happen before.
        -- Wait, actually we DO need to cleanup old custom objectives if any existed.
        return
    end

    -- OVERRIDE: Check if we are playing on the specific map
    -- EDIT "zm_mapname" TO THE NAME OF THE WORKSHOP MAP YOU DOWNLOADED
    if game.GetMap() == "hns_mallparking_short" then
        missionId = "custom_battery_survival"
    end

    local missionDef = ZM_MISSIONS[missionId]
    if not missionDef then
        -- Pick a random mission
        local keys = table.GetKeys(ZM_MISSIONS)
        missionId = keys[math.random(#keys)]
        missionDef = ZM_MISSIONS[missionId]
    end

    -- Find a good base position (center of player spawns)
    local basePos = Vector(0, 0, 0)
    local spawns = ents.FindByClass("info_player_start")
    if #spawns > 0 then
        local total = Vector(0, 0, 0)
        for _, sp in ipairs(spawns) do
            total = total + sp:GetPos()
        end
        basePos = total / #spawns
    end

    -- Initialize mission state
    ZM_Mission.active = true
    ZM_Mission.missionId = missionId
    ZM_Mission.current = 1
    ZM_Mission.items = {}
    ZM_Mission.zones = {}

    -- Deep copy objectives so we can modify collected counts etc.
    ZM_Mission.objectives = {}
    for i, obj in ipairs(missionDef.objectives) do
        ZM_Mission.objectives[i] = table.Copy(obj)
        ZM_Mission.objectives[i].completed = false
        if obj.type == "pickup" then
            ZM_Mission.objectives[i].collected = 0
        end
    end

    -- Spawn entities for ALL objectives (but only current one is active)
    for i, obj in ipairs(ZM_Mission.objectives) do
        ZM_SpawnObjectiveEntities(obj, basePos, i)
    end

    -- Notify everyone
    ZM_NotifyAll("Mission: " .. missionDef.name, Color(255, 220, 50))
    ZM_NotifyAll(missionDef.description, Color(200, 200, 200))

    -- Sync to clients
    ZM_SyncObjectives()
end

-- Spawn entities for an objective
function ZM_SpawnObjectiveEntities(obj, basePos, objIndex)
    if obj.type == "pickup" then
        -- Spawn collectible items
        local offsets = obj.spawnOffset or {}
        local absPosList = obj.absoluteSpawnPos or {}
        local count = math.max(#offsets, #absPosList)

        for j = 1, count do
            local spawnPos
            if absPosList[j] then
                spawnPos = absPosList[j]
            elseif offsets[j] then
                spawnPos = basePos + offsets[j]
            end
            
            if not spawnPos then continue end

            -- Only trace down for relative offsets, not absolute getpos vectors
            if not absPosList[j] then
                local tr = util.TraceLine({
                    start = spawnPos + Vector(0, 0, 200),
                    endpos = spawnPos - Vector(0, 0, 500),
                    mask = MASK_SOLID_BRUSHONLY,
                })
                if tr.Hit then
                    spawnPos = tr.HitPos + Vector(0, 0, 10)
                end
            end

            local item = ents.Create("ent_zm_objective_item")
            if IsValid(item) then
                item:SetPos(spawnPos)
                item:SetModel(obj.itemModel or "models/items/car_battery01.mdl")
                item:SetNWString("ItemName", obj.itemName or "Item")
                item:SetNWInt("ObjIndex", objIndex)
                item:Spawn()
                item:Activate()

                -- Glow effect
                item:SetMaterial("models/debug/debugwhite")
                item:SetColor(Color(255, 255, 100))

                table.insert(ZM_Mission.items, item)
            end
        end
    elseif obj.type == "interact" then
        -- Spawn interaction point
        local spawnPos = obj.absoluteSpawnPos or (basePos + (obj.spawnOffset or Vector(0, 0, 20)))

        if not obj.absoluteSpawnPos then
            local tr = util.TraceLine({
                start = spawnPos + Vector(0, 0, 200),
                endpos = spawnPos - Vector(0, 0, 500),
                mask = MASK_SOLID_BRUSHONLY,
            })
            if tr.Hit then
                spawnPos = tr.HitPos + Vector(0, 0, 5)
            end
        end

        local interact = ents.Create("ent_zm_objective_interact")
        if IsValid(interact) then
            interact:SetPos(spawnPos)
            interact:SetModel(obj.interactModel or "models/props_lab/monitor02.mdl")
            interact:SetNWString("InteractName", obj.interactName or "Objective")
            interact:SetNWString("Prompt", obj.interactPrompt or "Press E to interact")
            interact:SetNWInt("ObjIndex", objIndex)
            interact:SetNWBool("Locked", objIndex ~= 1) -- Lock future objectives
            interact:Spawn()
            interact:Activate()

            table.insert(ZM_Mission.items, interact)
        end
    elseif obj.type == "reach" then
        -- Spawn a reach zone marker
        local spawnPos = obj.absoluteSpawnPos or (basePos + (obj.spawnOffset or Vector(0, 0, 20)))

        if not obj.absoluteSpawnPos then
            local tr = util.TraceLine({
                start = spawnPos + Vector(0, 0, 200),
                endpos = spawnPos - Vector(0, 0, 500),
                mask = MASK_SOLID_BRUSHONLY,
            })
            if tr.Hit then
                spawnPos = tr.HitPos + Vector(0, 0, 5)
            end
        end

        local zone = ents.Create("ent_zm_objective_interact")
        if IsValid(zone) then
            zone:SetPos(spawnPos)
            zone:SetModel("models/props_combine/breenGlobe.mdl")
            zone:SetNWString("InteractName", "Extraction Point")
            zone:SetNWString("Prompt", "Press E to escape!")
            zone:SetNWInt("ObjIndex", objIndex)
            zone:SetNWBool("Locked", objIndex ~= 1)
            zone:Spawn()
            zone:Activate()

            table.insert(ZM_Mission.items, zone)
        end
    end
    -- "survive" type doesn't spawn entities, it's timer-based
end

-- Handle item pickup
function ZM_OnObjectiveItemPickup(ply, itemEnt)
    if not ZM_Mission.active then return end

    local objIndex = itemEnt:GetNWInt("ObjIndex", 0)
    local obj = ZM_Mission.objectives[objIndex]
    if not obj or obj.completed then return end
    if obj.type ~= "pickup" then return end
    if objIndex ~= ZM_Mission.current then return end

    obj.collected = (obj.collected or 0) + 1

    local itemName = itemEnt:GetNWString("ItemName", "Item")
    ZM_NotifyAll(ply:Nick() .. " found a " .. itemName .. "! (" .. obj.collected .. "/" .. obj.requiredCount .. ")", Color(100, 255, 100))

    -- Remove the item
    itemEnt:Remove()

    -- Check if all items collected
    if obj.collected >= obj.requiredCount then
        ZM_CompleteObjective(objIndex)
    else
        ZM_SyncObjectives()
    end
end

-- Handle interaction
function ZM_OnObjectiveInteract(ply, interactEnt)
    if not ZM_Mission.active then return end

    local objIndex = interactEnt:GetNWInt("ObjIndex", 0)
    if objIndex ~= ZM_Mission.current then
        ZM_Notify(ply, "Complete the current objective first!", Color(255, 100, 100))
        return
    end

    local obj = ZM_Mission.objectives[objIndex]
    if not obj or obj.completed then return end

    ZM_CompleteObjective(objIndex)
end

-- Complete an objective and move to next
function ZM_CompleteObjective(objIndex)
    local obj = ZM_Mission.objectives[objIndex]
    if not obj then return end

    obj.completed = true

    ZM_NotifyAll("✓ Objective complete: " .. obj.description, Color(100, 255, 100))

    -- Play completion sound
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:EmitSound("buttons/button9.wav", 60, 120, 0.6)
        end
    end

    -- Advance to next objective
    ZM_Mission.current = ZM_Mission.current + 1

    if ZM_Mission.current > #ZM_Mission.objectives then
        -- All objectives done! Survivors win!
        ZM_EndRound(false, "All objectives completed!")
        return
    end

    local nextObj = ZM_Mission.objectives[ZM_Mission.current]

    -- Unlock next objective's interactables
    for _, ent in ipairs(ZM_Mission.items) do
        if IsValid(ent) and ent:GetNWInt("ObjIndex", 0) == ZM_Mission.current then
            ent:SetNWBool("Locked", false)
        end
    end

    -- Handle survive-type objective
    if nextObj.type == "survive" then
        ZM_NotifyAll("⏱ " .. nextObj.description, Color(255, 220, 50))
        local surviveTime = nextObj.surviveTime or 60

        timer.Create("ZM_SurviveTimer", surviveTime, 1, function()
            if ZM_Mission.active and ZM_Mission.current == ZM_Mission.current then
                ZM_CompleteObjective(ZM_Mission.current)
            end
        end)

        -- Countdown notifications
        timer.Create("ZM_SurviveCountdown", 10, math.floor(surviveTime / 10), function()
            if not ZM_Mission.active then timer.Remove("ZM_SurviveCountdown") return end
            local remaining = math.max(0, surviveTime - (CurTime() - (ZM_Mission.surviveStart or CurTime())))
        end)

        ZM_Mission.surviveStart = CurTime()
        ZM_Mission.surviveEnd = CurTime() + surviveTime
    else
        ZM_NotifyAll("► Next: " .. nextObj.description, Color(255, 220, 50))
    end

    ZM_SyncObjectives()
end

-- Sync objectives to all clients
function ZM_SyncObjectives()
    if not ZM_Mission.active then
        net.Start("ZM_ObjectiveUpdate")
            net.WriteString("")
            net.WriteUInt(0, 4)
            net.WriteUInt(0, 4)
        net.Broadcast()
        return
    end

    local missionDef = ZM_MISSIONS[ZM_Mission.missionId]
    if not missionDef then return end

    net.Start("ZM_ObjectiveUpdate")
        net.WriteString(missionDef.name)
        net.WriteUInt(#ZM_Mission.objectives, 4)
        net.WriteUInt(ZM_Mission.current, 4)
        for i, obj in ipairs(ZM_Mission.objectives) do
            net.WriteString(obj.description)
            net.WriteBool(obj.completed)
            net.WriteString(obj.type)
            if obj.type == "pickup" then
                net.WriteUInt(obj.collected or 0, 8)
                net.WriteUInt(obj.requiredCount or 1, 8)
            end
            if obj.type == "survive" then
                net.WriteFloat(ZM_Mission.surviveEnd or 0)
            end
        end
    net.Broadcast()
end

-- Clean up all mission entities
function ZM_CleanupMission()
    ZM_Mission.active = false

    for _, ent in ipairs(ents.FindByClass("ent_zm_objective_*")) do
        if IsValid(ent) then ent:Remove() end
    end
    
    -- Remove procedural spawn points
    for _, ent in ipairs(ents.FindByClass("ent_zm_spawnpoint")) do
        if IsValid(ent) then ent:Remove() end
    end
    
    ZM_Mission.items = {}

    timer.Remove("ZM_SurviveTimer")
    timer.Remove("ZM_SurviveCountdown")
    
    ZM_SyncObjectives()
end

-- Console command to set mission
concommand.Add("zm_setmission", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local missionId = args[1]
    if missionId and ZM_MISSIONS[missionId] then
        ZM_StartMission(missionId)
        ZM_NotifyAll("Mission changed to: " .. ZM_MISSIONS[missionId].name, Color(255, 220, 50))
    else
        local list = table.concat(table.GetKeys(ZM_MISSIONS), ", ")
        if IsValid(ply) then
            ZM_Notify(ply, "Available missions: " .. list, Color(200, 200, 200))
        else
            print("Available missions: " .. list)
        end
    end
end)
