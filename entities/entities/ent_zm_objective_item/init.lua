AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/items/car_battery01.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
    self:SetUseType(SIMPLE_USE)
    self:SetTrigger(true)

    self:SetNWString("ItemName", "Item")
    self:SetNWInt("ObjIndex", 0)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if activator:Team() ~= TEAM_SURVIVORS then return end

    -- Notify the objective system
    if ZM_OnObjectiveItemPickup then
        ZM_OnObjectiveItemPickup(activator, self)
    end
end

function ENT:Touch(ent)
    if not IsValid(ent) or not ent:IsPlayer() then return end
    if ent:Team() ~= TEAM_SURVIVORS then return end

    -- Auto-pickup on touch
    if ZM_OnObjectiveItemPickup then
        ZM_OnObjectiveItemPickup(ent, self)
    end
end
