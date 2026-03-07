--[[
    Zombie Master - Manipulate (Trap) Entity
    Server-side: activatable trap system for the ZM
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_lab/reciever01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:SetColor(Color(100, 100, 255, 150))
    self:DrawShadow(false)

    -- Network variables
    self:SetNWBool("Active", true)
    self:SetNWString("Description", "Trap")
    self:SetNWInt("Cost", 50)
    self:SetNWBool("RemoveOnTrigger", false)
end

function ENT:SetupManipulate(description, cost, removeOnTrigger)
    self:SetNWString("Description", description or "Trap")
    self:SetNWInt("Cost", cost or 50)
    self:SetNWBool("RemoveOnTrigger", removeOnTrigger or false)
end

function ENT:Trigger(activator)
    if not self:GetNWBool("Active", true) then return end

    -- Fire outputs (for map I/O compatibility)
    self:Fire("OnPressed", "", 0, activator, self)

    -- Create an effect at the manipulate location
    local effectData = EffectData()
    effectData:SetOrigin(self:GetPos())
    effectData:SetMagnitude(3)
    effectData:SetScale(2)
    util.Effect("Sparks", effectData)

    -- Sound
    self:EmitSound("buttons/button3.wav", 75, 100, 0.8)

    -- Remove if configured
    if self:GetNWBool("RemoveOnTrigger", false) then
        self:Remove()
    else
        -- Disable temporarily
        self:SetNWBool("Active", false)
        timer.Simple(30, function()
            if IsValid(self) then
                self:SetNWBool("Active", true)
            end
        end)
    end
end

function ENT:ToggleActive()
    self:SetNWBool("Active", not self:GetNWBool("Active", true))
end

function ENT:Think()
    -- Could add auto-trigger logic here (like CZombieManipulateTrigger)
end
