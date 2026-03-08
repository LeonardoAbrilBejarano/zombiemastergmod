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

    -- Network variables if not set by map
    if self.kvActive == nil then self:SetNWBool("Active", true) end
    if not self.kvDesc then self:SetNWString("Description", "Trap") end
    if not self.kvCost then self:SetNWInt("Cost", 50) end
    if self.kvRemove == nil then self:SetNWBool("RemoveOnTrigger", false) end
    self:SetNWBool("IsUsed", false)
end

-- Hook into native mapping system parameters
function ENT:KeyValue(key, value)
    local lkey = string.lower(key)

    if string.Left(lkey, 2) == "on" then
        self:StoreOutput(key, value)
        
        -- Fallback manual output handling because Source Engine sucks
        self.ManualOutputs = self.ManualOutputs or {}
        self.ManualOutputs[lkey] = self.ManualOutputs[lkey] or {}
        table.insert(self.ManualOutputs[lkey], value)
    end

    if lkey == "cost" then
        self:SetNWInt("Cost", tonumber(value) or 50)
        self.kvCost = true
    elseif lkey == "description" then
        self:SetNWString("Description", tostring(value))
        self.kvDesc = true
    elseif lkey == "removeontrigger" then
        self:SetNWBool("RemoveOnTrigger", tobool(value))
        self.kvRemove = true
    elseif lkey == "startdisabled" then
        self:SetNWBool("Active", value == "0" and true or false)
        self.kvActive = true
    elseif lkey == "active" then
        self:SetNWBool("Active", tobool(value))
        self.kvActive = true
    elseif lkey == "targetname" then
        self:SetName(tostring(value))
    end
end

function ENT:AcceptInput(inputName, activator, caller, data)
    local linput = string.lower(inputName)
    
    if linput == "turnon" or linput == "enable" then
        self:SetNWBool("Active", true)
        return true
    elseif linput == "turnoff" or linput == "disable" then
        self:SetNWBool("Active", false)
        return true
    elseif linput == "toggle" then
        self:SetNWBool("Active", not self:GetNWBool("Active", true))
        return true
    end
    
    return false
end

function ENT:SetupManipulate(description, cost, removeOnTrigger)
    self:SetNWString("Description", description or "Trap")
    self:SetNWInt("Cost", cost or 50)
    self:SetNWBool("RemoveOnTrigger", removeOnTrigger or false)
end

function ENT:Trigger(activator)
    if not self:GetNWBool("Active", true) then return end
    if self:GetNWBool("IsUsed", false) then return end
    
    -- Prevent double-triggering wallet drains within 1 second
    if self.NextTriggerTime and CurTime() < self.NextTriggerTime then return end
    self.NextTriggerTime = CurTime() + 1
    
    -- Fire native outputs (may silently fail if engine lacks datadesc)
    self:TriggerOutput("OnPressed", activator)
    self:TriggerOutput("OnTrigger", activator)

    -- Fire manual Lua outputs (bulletproof fallback)
    self:FireManualOutputs("onpressed", activator)
    self:FireManualOutputs("ontrigger", activator)

    -- Create an effect at the manipulate location
    local effectData = EffectData()
    effectData:SetOrigin(self:GetPos())
    effectData:SetMagnitude(3)
    effectData:SetScale(2)
    util.Effect("Sparks", effectData)

    -- Sound
    self:EmitSound("buttons/button3.wav", 75, 100, 0.8)

    -- Only become permanently disabled if the map author specifically configured it to be single-use
    if self:GetNWBool("RemoveOnTrigger", false) then
        self:SetNWBool("IsUsed", true)
    end
end

function ENT:ResetTrap()
    self:SetNWBool("IsUsed", false)
end

function ENT:ToggleActive()
    self:SetNWBool("Active", not self:GetNWBool("Active", true))
end

function ENT:Think()
    -- Could add auto-trigger logic here (like CZombieManipulateTrigger)
end

function ENT:FireManualOutputs(eventName, activator)
    if not self.ManualOutputs or not self.ManualOutputs[eventName] then 
        return 
    end
    
    for _, outStr in ipairs(self.ManualOutputs[eventName]) do
        local parts = string.Explode(",", outStr)
        if #parts >= 5 then
            local target = parts[1]
            local input = parts[2]
            local delay = tonumber(parts[#parts - 1]) or 0
            
            local paramParts = {}
            for i = 3, #parts - 2 do
                table.insert(paramParts, parts[i])
            end
            local param = table.concat(paramParts, ",")
            
            local targets = {}
            if target == "!activator" then
                if IsValid(activator) then table.insert(targets, activator) end
            elseif target == "!self" then
                table.insert(targets, self)
            elseif target == "!player" then
                for _, p in ipairs(player.GetAll()) do table.insert(targets, p) end
            else
                local isWildcard = string.EndsWith(target, "*")
                if not isWildcard then
                    for _, ent in ipairs(ents.FindByName(target)) do
                        table.insert(targets, ent)
                    end
                else
                    local baseName = string.sub(target, 1, #target - 1)
                    for _, ent in ipairs(ents.GetAll()) do
                        local name = ent:GetName()
                        if name and string.StartWith(name, baseName) then
                            table.insert(targets, ent)
                        end
                    end
                end
            end
            
            for _, ent in ipairs(targets) do
                if IsValid(ent) then
                    ent:Fire(input, param, delay, activator, self)
                end
            end
        end
    end
end
