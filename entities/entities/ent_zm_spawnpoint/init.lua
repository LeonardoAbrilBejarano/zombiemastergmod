--[[
    Zombie Master - Zombie Spawn Point Entity
    Map entity: ZM can spawn zombies from these points
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_combine/headcrabcannister01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:DrawShadow(false)
    
    -- Network variables
    self:SetNWBool("Active", true)
    self:SetNWString("SpawnName", "Zombie Spawn")

    -- Spawn queue
    self.spawnQueue = {}
    self.isSpawning = false
end

function ENT:Reset()
    self.spawnQueue = {}
    self.isSpawning = false
    self:SetNWBool("Active", true)
end

function ENT:QueueZombie(typeId)
    if #self.spawnQueue >= (ZM_CONFIG and ZM_CONFIG.SPAWN_QUEUE_SIZE or 10) then
        return false
    end
    table.insert(self.spawnQueue, typeId)

    if not self.isSpawning then
        self:StartSpawning()
    end

    return true
end

function ENT:StartSpawning()
    if self.isSpawning then return end
    self.isSpawning = true
    self:SpawnThink()
end

function ENT:SpawnThink()
    if #self.spawnQueue <= 0 then
        self.isSpawning = false
        return
    end

    if not self:GetNWBool("Active", true) then
        self.isSpawning = false
        return
    end

    local typeId = table.remove(self.spawnQueue, 1)
    local zm = ZM_GetZMPlayer and ZM_GetZMPlayer() or nil

    if IsValid(zm) then
        local ztype = ZM_ZOMBIE_BY_ID[typeId]
        if ztype then
            -- Find valid spawn position near this entity
            local spawnPos = self:FindValidSpawnPoint()
            if spawnPos then
                local npc = ZM_SpawnZombie(zm, ztype, spawnPos)
                if npc then
                    npc:SetOwner(self)
                end
            end
        end
    end

    -- Schedule next spawn
    timer.Simple(ZM_CONFIG and ZM_CONFIG.SPAWN_DELAY or 0.75, function()
        if IsValid(self) then
            self:SpawnThink()
        end
    end)
end

function ENT:FindValidSpawnPoint()
    local hoverOrigin = self:GetPos()
    
    -- First, project the center point straight down to the absolute floor
    local centerDownTr = util.TraceLine({
        start = hoverOrigin + Vector(0,0,10),
        endpos = hoverOrigin - Vector(0,0,500),
        mask = MASK_SOLID_BRUSHONLY
    })
    
    local floorOrigin = centerDownTr.Hit and centerDownTr.HitPos or hoverOrigin
    
    local offsets = {0, 40, 80, 120, 160}
    
    for _, r in ipairs(offsets) do
        local points = (r == 0) and 1 or 8
        local startAngle = math.random(0, 359)
        local step = 360 / points
        
        for deg = 0, 359, step do
            local rad = math.rad(startAngle + deg)
            -- Calculate test position on the horizontal plane of the FLOOR
            local testPos = floorOrigin + Vector(math.cos(rad) * r, math.sin(rad) * r, 0)
            
            local isValid = true
            
            -- Prevent spawning inside or behind walls by checking line of sight
            -- We trace from slightly above the floor to avoid tiny bumps
            if r > 0 then
                local wallTr = util.TraceLine({
                    start = floorOrigin + Vector(0,0,20),
                    endpos = testPos + Vector(0,0,20),
                    mask = MASK_SOLID_BRUSHONLY
                })
                if wallTr.Hit then
                    isValid = false
                end
            end
            
            if isValid then
                -- Must use BRUSHONLY for the downward trace to ignore NPC heads and prevent vertical stacking
                -- Trace from slightly higher in case of stairs/ramps
                local downTr = util.TraceLine({
                    start = testPos + Vector(0,0,50),
                    endpos = testPos - Vector(0,0,200),
                    mask = MASK_SOLID_BRUSHONLY
                })
                
                local finalPos = downTr.Hit and downTr.HitPos or testPos
                
                -- Check if an NPC can physically fit in this exact spot
                -- endpos MUST be the same as start, or very close, otherwise it's a sweep trace that hits ceilings
                local hullTr = util.TraceHull({
                    start = finalPos + Vector(0,0,2),
                    endpos = finalPos + Vector(0,0,3),
                    mins = Vector(-16, -16, 0),
                    maxs = Vector(16, 16, 70),
                    mask = MASK_NPCSOLID
                })
                
                if not hullTr.Hit then
                    return finalPos + Vector(0,0,2) -- Return with slight Z bump to prevent stuck-in-floor
                end
            end
        end
    end

    -- Absolute fallback
    return floorOrigin + Vector(0, 0, 10)
end

function ENT:Think()
    -- Nothing needed for now
end

function ENT:OnRemove()
    self.spawnQueue = {}
end
