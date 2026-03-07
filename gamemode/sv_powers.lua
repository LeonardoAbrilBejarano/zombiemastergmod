--[[
    Zombie Master - ZM Powers
    Server-side: PhysExplode and SpotCreate powers
]]

-- Handle power usage from client
net.Receive("ZM_UsePower", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end
    if ZM_GetRoundState() ~= ROUND_ACTIVE then return end

    local powerType = net.ReadString()
    local targetPos = net.ReadVector()

    if powerType == "physexplode" then
        ZM_Power_PhysExplode(ply, targetPos)
    elseif powerType == "spotcreate" then
        ZM_Power_SpotCreate(ply, targetPos)
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
