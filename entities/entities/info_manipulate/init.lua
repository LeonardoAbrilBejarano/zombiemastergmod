--[[
    Zombie Master - Manipulate (Trap) Entity
    Server-side: activatable trap system for the ZM
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    -- Use a tiny invisible block model just to have a valid entity position for the engine
    self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:DrawShadow(false)
    -- Do NOT use SetNoDraw(true) here, or ENT:Draw() won't run on the client!

    -- Network variables
    self:SetNWBool("Active", true)
    self:SetNWString("Description", "Trap")
    self:SetNWInt("Cost", 50)
    self:SetNWBool("RemoveOnTrigger", false)
end

-- Hook into native mapping system parameters
function ENT:KeyValue(key, value)
    local lkey = string.lower(key)
    
    if string.Left(lkey, 2) == "on" then
        self:StoreOutput(key, value)
    end

    if lkey == "cost" then
        self:SetNWInt("Cost", tonumber(value) or 50)
    elseif lkey == "description" then
        self:SetNWString("Description", tostring(value))
    elseif lkey == "removeontrigger" then
        self:SetNWBool("RemoveOnTrigger", tobool(value))
    elseif lkey == "active" then
        self:SetNWBool("Active", tobool(value))
    end
end

function ENT:SetupManipulate(description, cost, removeOnTrigger)
    self:SetNWString("Description", description or "Trap")
    self:SetNWInt("Cost", cost or 50)
    self:SetNWBool("RemoveOnTrigger", removeOnTrigger or false)
end

function ENT:Trigger(activator)
    if not self:GetNWBool("Active", true) then return end
    
    -- Fire outputs
    self:TriggerOutput("OnPressed", activator)
    self:TriggerOutput("OnTrigger", activator)

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
