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
    
    -- Crucial: Render mode needs to support transparency, and color must be 0 auth to hide it from humans
    -- Client script (cl_init.lua) will override drawing for the ZM player using Sprites
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:SetColor(Color(255, 255, 255, 0))
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
    local pos = self:GetPos()
    local attempts = 25

    for i = 1, attempts do
        local testPos = pos + Vector(
            math.random(-128, 128),
            math.random(-128, 128),
            0
        )

        local tr = util.TraceHull({
            start = testPos + Vector(0, 0, 10),
            endpos = testPos + Vector(0, 0, 1),
            mins = Vector(-16, -16, 0),
            maxs = Vector(16, 16, 72),
            mask = MASK_NPCSOLID,
        })

        if not tr.Hit then
            return testPos
        end
    end

    -- Fallback to entity position
    return pos + Vector(0, 0, 10)
end

function ENT:Think()
    -- Nothing needed for now
end

function ENT:OnRemove()
    self.spawnQueue = {}
end
