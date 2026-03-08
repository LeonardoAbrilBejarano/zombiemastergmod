--[[
    Zombie Master - ZM Player Logic
    Server-side: handles ZM's overhead camera, resources, population, zombie commands
]]

-- Set up a player as the Zombie Master
function ZM_SetupZMPlayer(ply)
    ply:SetTeam(TEAM_ZM)
    ply:StripWeapons()
    ply:SetHealth(1)
    ply:GodEnable()

    -- Overhead camera mode
    ply:SetMoveType(MOVETYPE_NOCLIP)
    ply:SetNoTarget(true)
    ply:SetRenderMode(RENDERMODE_NONE)   -- Invisible
    ply:SetColor(Color(255, 255, 255, 0))
    ply:DrawShadow(false)
    ply:SetNoDraw(true)
    ply:SetNotSolid(true)

    -- Move to a high position above map center
    local mapCenter = Vector(0, 0, 0)
    -- Try to find the map center from spawn points
    local spawns = ents.FindByClass("info_player_start")
    if #spawns > 0 then
        local total = Vector(0, 0, 0)
        for _, sp in ipairs(spawns) do
            total = total + sp:GetPos()
        end
        mapCenter = total / #spawns
    end
    ply:SetPos(mapCenter + Vector(0, 0, 500))
    ply:SetAngles(Angle(89, 0, 0)) -- Look straight down

    -- Initialize ZM data
    ply.zmResources     = ZM_CONFIG.START_RESOURCES
    ply.zmPopulation    = 0
    ply.zmMaxPop        = ZM_CONFIG.MAX_ZOMBIES
    ply.zmSelectedZombies = {}
    ply.zmSpawnPoints   = {}

    -- Sync initial data
    ZM_SyncResources(ply)
    ZM_SyncPopulation(ply)
    ZM_SyncSpawnPointsToClient(ply)
    ZM_SyncManipulatesToClient(ply)
end

-- Add resources to the ZM
function ZM_AddResources(ply, amount)
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end
    ply.zmResources = math.min((ply.zmResources or 0) + amount, ZM_CONFIG.MAX_RESOURCES)
    ply:PrintMessage(HUD_PRINTCONSOLE, "ZM_AddResources TICK: " .. amount .. " New total: " .. ply.zmResources)
    ZM_SyncResources(ply)
end

-- Deduct resources from the ZM
function ZM_DeductResources(ply, amount)
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return false end
    if (ply.zmResources or 0) < amount then return false end
    ply.zmResources = ply.zmResources - amount
    ZM_SyncResources(ply)
    return true
end

-- Sync resource count to client
function ZM_SyncResources(ply)
    if not IsValid(ply) then return end
    net.Start("ZM_UpdateResources")
        net.WriteInt(ply.zmResources or 0, 16)
    net.Send(ply)
end

-- Recalculate population
function ZM_RecalcPopulation(ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end

    local pop = 0
    for _, npc in ipairs(ents.GetAll()) do
        if IsValid(npc) and npc:IsNPC() and npc.zmOwner == ply then
            local ztype = npc.zmType
            if ztype then
                local _, popCost = ZM_GetZombieCost(ztype)
                pop = pop + popCost
            else
                pop = pop + 1
            end
        end
    end

    ply.zmPopulation = pop
    ZM_SyncPopulation(ply)
end

-- Sync population to client
function ZM_SyncPopulation(ply)
    if not IsValid(ply) then return end
    net.Start("ZM_UpdatePopulation")
        net.WriteInt(ply.zmPopulation or 0, 16)
        net.WriteInt(ply.zmMaxPop or ZM_CONFIG.MAX_ZOMBIES, 16)
    net.Send(ply)
end

-- Sync spawn points to the ZM client
function ZM_SyncSpawnPointsToClient(ply)
    if not IsValid(ply) then return end

    local spawnPoints = ents.FindByClass("info_zombiespawn")
    net.Start("ZM_SyncSpawnPoints")
        net.WriteUInt(#spawnPoints, 8)
        for _, sp in ipairs(spawnPoints) do
            net.WriteEntity(sp)
            net.WriteVector(sp:GetPos())
            net.WriteBool(sp:GetNWBool("Active", true))
        end
    net.Send(ply)
end

-- Sync manipulates to the ZM client
function ZM_SyncManipulatesToClient(ply)
    if not IsValid(ply) then return end

    local manips = ents.FindByClass("info_manipulate")
    net.Start("ZM_SyncManipulates")
        net.WriteUInt(#manips, 8)
        for _, m in ipairs(manips) do
            net.WriteEntity(m)
            net.WriteVector(m:GetPos())
            net.WriteString(m:GetNWString("Description", "Trap"))
            net.WriteInt(m:GetNWInt("Cost", 0), 16)
            net.WriteBool(m:GetNWBool("Active", true))
        end
    net.Send(ply)
end

-- Handle zombie spawning request from ZM client
net.Receive("ZM_SpawnZombie", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end
    if ZM_GetRoundState() ~= ROUND_ACTIVE then return end

    local typeId = net.ReadString()
    local spawnEntIndex = net.ReadUInt(16)

    local spawner = Entity(spawnEntIndex)
    if not IsValid(spawner) or spawner:GetClass() ~= "info_zombiespawn" or not spawner:GetNWBool("Active", true) then
        ZM_Notify(ply, "Invalid or inactive spawn point!", Color(255, 100, 100))
        return
    end

    local ztype = ZM_ZOMBIE_BY_ID[typeId]
    if not ztype then
        ZM_Notify(ply, "Invalid zombie type!", Color(255, 100, 100))
        return
    end

    -- Check resources
    if (ply.zmResources or 0) < ztype.cost then
        ZM_Notify(ply, "Not enough resources! Need " .. ztype.cost, Color(255, 100, 100))
        return
    end

    -- Check population
    if (ply.zmPopulation or 0) + ztype.popCost > (ply.zmMaxPop or ZM_CONFIG.MAX_ZOMBIES) then
        ZM_Notify(ply, "Population limit reached!", Color(255, 100, 100))
        return
    end

    -- Check banshee limit
    if typeId == "banshee" and ZM_OverBansheeLimit() then
        ZM_Notify(ply, "Maximum number of banshees reached!", Color(255, 100, 100))
        return
    end

    -- Queue the zombie in the spawn point
    if spawner.QueueZombie and spawner:QueueZombie(typeId) then
        -- Deduct resources immediately when queued
        ZM_DeductResources(ply, ztype.cost)
        
        -- Artificially bump population to prevent over-queueing
        -- We won't fully recalculate here because it might un-sync, but we can just add to the var
        ply.zmPopulation = (ply.zmPopulation or 0) + ztype.popCost
        ZM_SyncPopulation(ply)
    else
        ZM_Notify(ply, "Spawn point queue is full!", Color(255, 100, 100))
    end
end)

-- Spawn a zombie NPC
function ZM_SpawnZombie(zmPlayer, ztype, pos)
    local npc = ents.Create(ztype.npcClass)
    if not IsValid(npc) then return nil end

    npc:SetPos(pos)
    npc:SetAngles(Angle(0, math.random(0, 360), 0))
    npc:Spawn()
    npc:Activate()

    -- Mark as belonging to ZM
    npc.zmOwner = zmPlayer
    npc.zmType = ztype.id

    -- Immolator special: ignite continuously
    if ztype.isImmolator then
        npc:Ignite(9999, 50)
        -- Make it do fire damage to nearby players
        timer.Create("ZM_Immolator_" .. npc:EntIndex(), 1, 0, function()
            if not IsValid(npc) or not npc:Alive() then
                timer.Remove("ZM_Immolator_" .. npc:EntIndex())
                return
            end
            for _, ent in ipairs(ents.FindInSphere(npc:GetPos(), 80)) do
                if IsValid(ent) and ent:IsPlayer() and ent:Team() == TEAM_SURVIVORS and ent:Alive() then
                    local dmg = DamageInfo()
                    dmg:SetDamage(5)
                    dmg:SetDamageType(DMG_BURN)
                    dmg:SetAttacker(npc)
                    dmg:SetInflictor(npc)
                    ent:TakeDamageInfo(dmg)
                end
            end
        end)
    end

    -- Set enemy relationships (attack survivors)
    npc:AddRelationship("player D_HT 99")

    -- Track NPC death for population recalc
    hook.Add("OnNPCKilled", "ZM_NPCDeath_" .. npc:EntIndex(), function(killed, attacker, inflictor)
        if killed == npc then
            hook.Remove("OnNPCKilled", "ZM_NPCDeath_" .. npc:EntIndex())
            if ztype.isImmolator then
                timer.Remove("ZM_Immolator_" .. npc:EntIndex())
            end
            timer.Simple(0.1, function()
                if IsValid(zmPlayer) then
                    ZM_RecalcPopulation(zmPlayer)
                end
            end)
        end
    end)

    return npc
end

-- Check banshee limit
function ZM_OverBansheeLimit()
    local limit = ZM_CONFIG.BANSHEE_LIMIT
    if limit <= 0 then return false end

    local survivorCount = ZM_CountTeam(TEAM_SURVIVORS)
    local maxBanshees = math.max(5, math.ceil(limit * survivorCount))

    local currentBanshees = 0
    for _, npc in ipairs(ents.GetAll()) do
        if IsValid(npc) and npc:IsNPC() and npc.zmType == "banshee" then
            currentBanshees = currentBanshees + 1
        end
    end

    return currentBanshees >= maxBanshees
end

-- Handle zombie command (move to position)
net.Receive("ZM_CommandZombies", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end

    local targetPos = net.ReadVector()
    local targetEnt = net.ReadEntity()
    local numZombies = net.ReadUInt(8)

    for i = 1, numZombies do
        local npc = net.ReadEntity()
        if IsValid(npc) and npc:IsNPC() and npc.zmOwner == ply then
            npc.zmAutoAttack = false -- Explicit command cancels auto-attack
            if IsValid(targetEnt) and targetEnt:IsPlayer() and targetEnt:Team() == TEAM_SURVIVORS and targetEnt:Alive() then
                -- Set the NPC's enemy to the clicked survivor
                npc:SetLastPosition(targetPos)
                npc:SetTarget(targetEnt)
                npc:SetEnemy(targetEnt)
                npc:UpdateEnemyMemory(targetEnt, targetPos)
                npc:SetSchedule(SCHED_TARGET_CHASE)
            else
                -- Generic walk to position
                npc:SetLastPosition(targetPos)
                npc:SetSchedule(SCHED_FORCED_GO_RUN)
            end
        end
    end
end)

-- Handle zombie selection
net.Receive("ZM_SelectZombies", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end

    local numZombies = net.ReadUInt(8)
    ply.zmSelectedZombies = {}

    for i = 1, numZombies do
        local npc = net.ReadEntity()
        if IsValid(npc) and npc:IsNPC() and npc.zmOwner == ply then
            table.insert(ply.zmSelectedZombies, npc)
        end
    end
end)

-- Handle Auto-Attack command
net.Receive("ZM_AutoAttack", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end

    local count = 0
    for _, npc in ipairs(ply.zmSelectedZombies or {}) do
        if IsValid(npc) and npc:IsNPC() and npc:Health() > 0 then
            npc.zmAutoAttack = true
            npc:SetSchedule(SCHED_TARGET_CHASE)
            count = count + 1
        end
    end
    
    if count > 0 then
        ZM_Notify(ply, count .. " zombies in Offensive Stance (Auto-Attack)!", Color(255, 100, 100))
    end
end)

-- Auto-Attack AI Loop
hook.Add("Think", "ZM_AutoAttackAI", function()
    if not ZM_NextAITick then ZM_NextAITick = 0 end
    if CurTime() < ZM_NextAITick then return end
    ZM_NextAITick = CurTime() + 1 -- Update targets every second
    
    local survivors = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SURVIVORS and ply:Alive() then
            table.insert(survivors, ply)
        end
    end
    
    if #survivors == 0 then return end

    for _, npc in ipairs(ents.GetAll()) do
        if IsValid(npc) and npc:IsNPC() and npc.zmOwner and npc.zmAutoAttack and npc:Health() > 0 then
            -- Find closest survivor
            local closest = nil
            local minDist = math.huge
            local pos = npc:GetPos()

            local enemy = npc:GetEnemy()
            if not IsValid(enemy) or not enemy:Alive() then
                for _, s in ipairs(survivors) do
                    local d = pos:DistToSqr(s:GetPos())
                    if d < minDist then
                        minDist = d
                        closest = s
                    end
                end
                
                if closest then
                    npc:SetTarget(closest)
                    npc:SetEnemy(closest)
                    npc:UpdateEnemyMemory(closest, closest:GetPos())
                    npc:SetSchedule(SCHED_TARGET_CHASE)
                end
            else
                -- If they already have an enemy, ensure they keep knowing its position to not lose aggro
                npc:UpdateEnemyMemory(enemy, enemy:GetPos())
            end
        end
    end
end)

-- Handle rally point setting
net.Receive("ZM_SetRally", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end

    local pos = net.ReadVector()

    -- Move all owned zombies to rally point
    for _, npc in ipairs(ents.GetAll()) do
        if IsValid(npc) and npc:IsNPC() and npc.zmOwner == ply then
            npc:SetLastPosition(pos)
            npc:SetSchedule(SCHED_FORCED_GO_RUN)
        end
    end

    ZM_Notify(ply, "Rally point set!", Color(100, 255, 100))
end)

-- Handle delete zombie command
net.Receive("ZM_DeleteZombie", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end

    local npc = net.ReadEntity()
    if IsValid(npc) and npc:IsNPC() and npc.zmOwner == ply then
        npc:Remove()
        timer.Simple(0.1, function()
            if IsValid(ply) then
                ZM_RecalcPopulation(ply)
            end
        end)
    end
end)

-- Handle manipulate activation from ZM
net.Receive("ZM_ActivateManipulate", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end
    if ZM_GetRoundState() ~= ROUND_ACTIVE then return end

    local manip = net.ReadEntity()
    if not IsValid(manip) or manip:GetClass() ~= "info_manipulate" then return end

    local cost = manip:GetNWInt("Cost", 0)
    if not ZM_DeductResources(ply, cost) then
        ZM_Notify(ply, "Not enough resources! Need " .. cost, Color(255, 100, 100))
        return
    end

    -- Trigger the manipulate
    if manip.Trigger then
        manip:Trigger(ply)
    end

    ZM_Notify(ply, "Trap activated!", Color(255, 200, 50))
end)

-- Reset spawn points between rounds
function ZM_ResetSpawnPoints()
    for _, sp in ipairs(ents.FindByClass("info_zombiespawn")) do
        if IsValid(sp) and sp.Reset then
            sp:Reset()
        end
    end
end

-- ZM movement speed override
hook.Add("Move", "ZM_Movement", function(ply, mv)
    if ply:Team() == TEAM_ZM then
        -- Faster movement for overhead camera
        mv:SetMaxClientSpeed(ZM_CONFIG.ZM_MOVE_SPEED)
        mv:SetMaxSpeed(ZM_CONFIG.ZM_MOVE_SPEED)
    end
end)
