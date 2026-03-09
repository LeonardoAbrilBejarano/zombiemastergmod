--[[
    Zombie Master - ZM Powers
    Server-side: PhysExplode and SpotCreate powers
]]

-- Handle power usage from client
net.Receive("ZM_UsePower", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end
    if ZM_GetRoundState() ~= ROUND_ACTIVE then return end
    if ply.isPossessing then return end -- cannot use other powers while possessing

    local powerType = net.ReadString()

    -- possession uses an entity argument instead of a position
    if powerType == "possess" then
        local npc = net.ReadEntity()
        ZM_Power_Possess(ply, npc)
        return
    end

    local targetPos = net.ReadVector()

    if powerType == "physexplode" then
        ZM_Power_PhysExplode(ply, targetPos)
    elseif powerType == "spotcreate" then
        ZM_Power_SpotCreate(ply, targetPos)
    elseif powerType == "anywhere" then
        ZM_Power_AnywhereSpawn(ply, targetPos)
    end
end)

--[[
    PhysExplode - Delayed physics explosion
    Based on CDelayedPhysExplosion from zm_powers_concom.cpp
    Cost: 400 resources
    Delay: 7.4 seconds with buildup effects
]]
function ZM_Power_PhysExplode(ply, location)
    if not location or not isvector(location) then
        ZM_Notify(ply, "Invalid location!", Color(255, 100, 100))
        return
    end

    local cost = ZM_CONFIG.PHYSEXPLODE_COST
    if not ZM_DeductResources(ply, cost) then
        ZM_Notify(ply, "Not enough resources! Need " .. cost, Color(255, 100, 100))
        return
    end

    local delay = ZM_CONFIG.PHYSEXPLODE_DELAY
    local radius = ZM_CONFIG.PHYSEXPLODE_RADIUS

    -- Create buildup effects (sparks)
    local effectData = EffectData()
    effectData:SetOrigin(location)
    effectData:SetMagnitude(5)
    effectData:SetScale(3)
    util.Effect("Sparks", effectData)

    -- Buildup sound
    sound.Play("ambient/energy/weld1.wav", location, 75, 100, 0.8)

    -- Periodic spark effects during delay
    local sparkTimer = "ZM_PhysExpSparks_" .. CurTime()
    local sparkCount = 0
    timer.Create(sparkTimer, 0.5, math.floor(delay / 0.5), function()
        sparkCount = sparkCount + 1
        local ed = EffectData()
        ed:SetOrigin(location + VectorRand() * 10)
        ed:SetMagnitude(sparkCount)
        ed:SetScale(2)
        util.Effect("Sparks", ed)
    end)

    -- Delayed explosion
    timer.Simple(delay, function()
        timer.Remove(sparkTimer)

        -- Boom sound
        sound.Play("ambient/explosions/explode_4.wav", location, 100, 100, 1.0)

        -- Force nearby players to drop held objects
        for _, target in ipairs(ents.FindInSphere(location, ZM_CONFIG.PHYSEXPLODE_FORCE_DROP_RADIUS)) do
            if IsValid(target) and target:IsPlayer() and target:Team() == TEAM_SURVIVORS then
                target:DropObject()
                -- Disorient player (shake screen)
                util.ScreenShake(target:GetPos(), 10, 5, 2, 500)
            end
        end

        -- Physics explosion - push objects away
        local phys_radius = radius
        for _, ent in ipairs(ents.FindInSphere(location, phys_radius)) do
            if IsValid(ent) then
                local phys = ent:GetPhysicsObject()
                if IsValid(phys) and ent:GetClass() ~= "player" then
                    local dir = (ent:GetPos() - location):GetNormalized()
                    local dist = ent:GetPos():Distance(location)
                    local force = (1 - dist / phys_radius) * 50000
                    phys:ApplyForceCenter(dir * force + Vector(0, 0, force * 0.3))
                    phys:Wake()
                end

                -- Screen shake for players
                if ent:IsPlayer() then
                    util.ScreenShake(ent:GetPos(), 15, 8, 3, 300)
                end
            end
        end

        -- Explosion visual effect
        local explodeEffect = EffectData()
        explodeEffect:SetOrigin(location)
        explodeEffect:SetMagnitude(8)
        explodeEffect:SetScale(4)
        util.Effect("Explosion", explodeEffect)

        -- More sparks
        local sparkEffect = EffectData()
        sparkEffect:SetOrigin(location)
        sparkEffect:SetMagnitude(10)
        sparkEffect:SetScale(5)
        util.Effect("Sparks", sparkEffect)
    end)

    ZM_Notify(ply, "Explosion created! Detonating in " .. delay .. " seconds.", Color(255, 200, 50))
end

--[[
    SpotCreate - Hidden zombie spawn
    Based on ZM_Power_SpotCreate from zm_powers_concom.cpp
    Cost: 100 resources
    Spawns a shambler at a location not visible to any survivor
]]
function ZM_Power_SpotCreate(ply, location)
    if not location or not isvector(location) then
        ZM_Notify(ply, "Invalid location!", Color(255, 100, 100))
        return
    end

    local cost = ZM_CONFIG.SPOTCREATE_COST

    -- Check resources
    if (ply.zmResources or 0) < cost then
        ZM_Notify(ply, "Not enough resources! Need " .. cost, Color(255, 100, 100))
        return
    end

    -- Trace down to find the floor
    local trFloor = util.TraceHull({
        start = location + Vector(0, 0, 25),
        endpos = location - Vector(0, 0, 25),
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 72),
        mask = MASK_NPCSOLID,
    })

    if trFloor.Fraction == 1.0 then
        ZM_Notify(ply, "The zombie does not fit in that location!", Color(255, 100, 100))
        return
    end

    location = trFloor.HitPos

    -- Check line of sight from all survivors
    local headTarget = location + Vector(0, 0, 64)
    for _, survivor in ipairs(player.GetAll()) do
        if IsValid(survivor) and survivor:Team() == TEAM_SURVIVORS and survivor:Alive() then
            local eyePos = survivor:EyePos()

            -- Check at feet level
            local trFeet = util.TraceLine({
                start = location,
                endpos = eyePos,
                mask = MASK_OPAQUE,
            })

            if trFeet.Fraction == 1.0 then
                ZM_Notify(ply, "One of the survivors can see this location!", Color(255, 100, 100))
                return
            end

            -- Check at head level
            local trHead = util.TraceLine({
                start = headTarget,
                endpos = eyePos,
                mask = MASK_OPAQUE,
            })

            if trHead.Fraction == 1.0 then
                ZM_Notify(ply, "One of the survivors can see this location!", Color(255, 100, 100))
                return
            end
        end
    end

    -- Check if the zombie fits
    local trCheck = util.TraceHull({
        start = location,
        endpos = location + Vector(0, 0, 1),
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 72),
        mask = MASK_NPCSOLID,
    })

    if trCheck.Hit then
        ZM_Notify(ply, "The zombie does not fit in that location!", Color(255, 100, 100))
        return
    end

    -- Check population cap
    local shambler = ZM_ZOMBIE_BY_ID["shambler"]
    if (ply.zmPopulation or 0) + shambler.popCost > (ply.zmMaxPop or ZM_CONFIG.MAX_ZOMBIES) then
        ZM_Notify(ply, "Population limit reached!", Color(255, 100, 100))
        return
    end

    -- Spawn the hidden zombie
    local npc = ZM_SpawnZombie(ply, shambler, location)
    if npc then
        ZM_DeductResources(ply, cost)
        ZM_RecalcPopulation(ply)
        ZM_Notify(ply, "Hidden zombie spawned.", Color(100, 255, 100))
    end
end


--[[
    AnywhereSpawn - shambler can be placed anywhere (ignore target LOS) as
    long as the ZM himself is not currently visible to survivors and is far
    enough away.  This is a more expensive alternative to spot-create and is
    activated via the new "Anywhere Spawn" power.
]]
function ZM_Power_AnywhereSpawn(ply, location)
    if not location or not isvector(location) then
        ZM_Notify(ply, "Invalid location!", Color(255, 100, 100))
        return
    end

    local cost = ZM_CONFIG.ANYWHERE_SPAWN_COST
    -- Check resources but don't deduct until after we verify the spawn succeeded
    if (ply.zmResources or 0) < cost then
        ZM_Notify(ply, "Not enough resources! Need " .. cost, Color(255, 100, 100))
        return
    end

    -- Trace down to find the floor and ensure the zombie fits
    local trFloor = util.TraceHull({
        start = location + Vector(0, 0, 25),
        endpos = location - Vector(0, 0, 25),
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 72),
        mask = MASK_NPCSOLID,
    })

    if trFloor.Fraction == 1.0 then
        ZM_Notify(ply, "The zombie does not fit in that location!", Color(255, 100, 100))
        return
    end

    location = trFloor.HitPos

    -- Ensure no survivor can see the ZM or is within 200 units
    for _, survivor in ipairs(player.GetAll()) do
        if IsValid(survivor) and survivor:Team() == TEAM_SURVIVORS and survivor:Alive() then
            if survivor:GetPos():Distance(ply:GetPos()) < 200 then
                ZM_Notify(ply, "You must be at least 200 units away from all survivors!", Color(255, 100, 100))
                return
            end

            local tr = util.TraceLine({
                start = survivor:EyePos(),
                endpos = ply:GetPos(),
                mask = MASK_OPAQUE,
            })
            if tr.Fraction == 1.0 then
                ZM_Notify(ply, "A survivor can see your position!", Color(255, 100, 100))
                return
            end
        end
    end

    -- Population cap check
    local shambler = ZM_ZOMBIE_BY_ID["shambler"]
    if (ply.zmPopulation or 0) + shambler.popCost > (ply.zmMaxPop or ZM_CONFIG.MAX_ZOMBIES) then
        ZM_Notify(ply, "Population limit reached!", Color(255, 100, 100))
        return
    end

    -- Spawn it
    local npc = ZM_SpawnZombie(ply, shambler, location)
    if npc then
        ZM_DeductResources(ply, cost)
        ZM_RecalcPopulation(ply)
        ZM_Notify(ply, "Anywhere shambler spawned.", Color(100, 255, 100))
    end
end


--[[
    Possess - turn the Zombie Master into one of his selected zombies.
    The zombie entity is removed and the player adopts its model/position.
    When the player dies while possessing, they revert back to overhead ZM.
]]
function ZM_Power_Possess(ply, npc)
    if not IsValid(npc) or not npc:IsNPC() then
        ZM_Notify(ply, "No valid zombie selected!", Color(255, 100, 100))
        return
    end
    if npc.zmOwner ~= ply then
        ZM_Notify(ply, "You can only possess your own zombies!", Color(255, 100, 100))
        return
    end

    local cost = ZM_CONFIG.TRANSFORM_COST
    if (ply.zmResources or 0) < cost then
        ZM_Notify(ply, "Not enough resources! Need " .. cost, Color(255, 100, 100))
        return
    end

    -- capture NPC details and then delete it; we'll respawn later
    local pos = npc:GetPos()
    print("[ZM] possess npc pos", pos)
    local model = npc:GetModel()
    local health = npc:Health()
    local ztypeId = npc.zmType

    -- determine hull dimensions now in case the entity loses methods later
    local hullmins, hullmaxs = Vector(-16,-16,0), Vector(16,16,72)
    if npc.GetHullMins then
        hullmins = npc:GetHullMins() or hullmins
        hullmaxs = npc:GetHullMaxs() or hullmaxs
    end
    -- debug: print hull sizes so we can see what's being used
    print("[ZM] possess hullmins", hullmins, "hullmaxs", hullmaxs)

    -- remove the NPC completely to avoid collision oddities
    npc:Remove()

    -- store data for respawn/revert
    ply.possessedNPCdata = {
        ztype = ztypeId,
        model = model,
        health = health,
        hullmins = hullmins,
        hullmaxs = hullmaxs,
    }

    ZM_RecalcPopulation(ply)

    -- mark player as controlling a zombie
    ply.isPossessing = true

    -- make player visible and reset ZM state
    ply:SetRenderMode(RENDERMODE_NORMAL)
    ply:SetColor(Color(255,255,255,255))
    ply:DrawShadow(true)
    ply:GodDisable()
    ply:SetMoveType(MOVETYPE_WALK)

    -- teleport and change appearance; initial position is NPC origin
    ply:SetPos(pos)

    ply:SetModel(model or "models/zombie/classic.mdl")
    ply:SetHealth(health)
    ply:SetMaxHealth(health)

    -- adjust collision hull to match the zombie BEFORE moving further
    local mins, maxs = hullmins, hullmaxs
    ply:SetHull(mins, maxs)
    ply:SetHullDuck(mins * 0.5, maxs * 0.5)

    -- perform a hull trace downward so the player doesn't spawn half‑buried
    local startpos = ply:GetPos() + Vector(0,0,50)
    local tr = util.TraceHull({
        start = startpos,
        endpos = startpos - Vector(0,0,150),
        mins = mins,
        maxs = maxs,
        mask = MASK_PLAYERSOLID,
        filter = ply
    })
    if tr.Hit then
        -- nudge the result up slightly; trace returns a point on the floor, which can
        -- leave part of the hull intersecting the world and trigger a fall-through.
        local finalpos = tr.HitPos + Vector(0,0,1)
        ply:SetPos(finalpos)
    else
        ply:DropToFloor() -- fallback if trace fails
    end

    -- make absolutely sure we end up on the ground in case the trace was dubious
    ply:DropToFloor()

    -- slow the player down to zombie pace and prevent noclip
    ply:SetWalkSpeed(120)
    ply:SetRunSpeed(120)

    -- strip any survivor gear and give them a basic melee weapon so they have
    -- something visible to swing while possessing
    ply:StripWeapons()
    ply:Give("weapon_crowbar")

    ZM_DeductResources(ply, cost)
    ZM_Notify(ply, "You possess a zombie! Press Z to return or die to automatically revert.", Color(200, 50, 200))
end


-- Handle possession revert request from client
util.AddNetworkString("ZM_RevertPossess")
net.Receive("ZM_RevertPossess", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end
    if not ply.isPossessing then return end

    -- respawn the zombie using stored data
    if ply.possessedNPCdata then
        local data = ply.possessedNPCdata
        local ztype = ZM_ZOMBIE_BY_ID[data.ztype]
        if ztype then
            local newnpc = ZM_SpawnZombie(ply, ztype, ply:GetPos())
            if IsValid(newnpc) then
                newnpc:SetModel(data.model)
                newnpc:SetHealth(data.health)
                newnpc:SetMaxHealth(data.health)
            end
        end
        ply.possessedNPCdata = nil
        ZM_RecalcPopulation(ply)
    end

    -- reset player back to ZM form
    ply.isPossessing = false
    ply:StripWeapons()
    ply:ResetHull()
    ply:SetTeam(TEAM_ZM)
    ZM_SetupZMPlayer(ply)
    ply:Spawn()
end)
