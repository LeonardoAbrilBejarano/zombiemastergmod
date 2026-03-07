AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_lab/monitor02.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetUseType(SIMPLE_USE)

    self:SetNWString("InteractName", "Objective")
    self:SetNWString("Prompt", "Press E to interact")
    self:SetNWInt("ObjIndex", 0)
    self:SetNWBool("Locked", false)
    self:SetNWBool("Used", false)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if activator:Team() ~= TEAM_SURVIVORS then return end
    if self:GetNWBool("Locked", false) then
        if ZM_Notify then
            ZM_Notify(activator, "Complete the current objective first!", Color(255, 100, 100))
        end
        return
    end
    if self:GetNWBool("Used", false) then return end

    self:SetNWBool("Used", true)

    -- Sound effect
    self:EmitSound("buttons/button9.wav", 75, 100, 0.8)

    -- Spark effect
    local ed = EffectData()
    ed:SetOrigin(self:GetPos() + Vector(0, 0, 20))
    ed:SetMagnitude(3)
    util.Effect("Sparks", ed)

    -- Notify the objective system
    if ZM_OnObjectiveInteract then
        ZM_OnObjectiveInteract(activator, self)
    end
end
