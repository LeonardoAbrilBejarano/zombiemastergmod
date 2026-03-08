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
    
    print("DEBUG info_manipulate KV parsed:", key, "->", value)

    if string.Left(lkey, 2) == "on" then
        self:StoreOutput(key, value)
        
        -- Fallback manual output handling because Source Engine sucks
        self.ManualOutputs = self.ManualOutputs or {}
        self.ManualOutputs[lkey] = self.ManualOutputs[lkey] or {}
        table.insert(self.ManualOutputs[lkey], value)
    end

    if lkey == "cost" then
        self:SetNWInt("Cost", tonumber(value) or 50)
    elseif lkey == "description" then
        self:SetNWString("Description", tostring(value))
    elseif lkey == "removeontrigger" then
        self:SetNWBool("RemoveOnTrigger", tobool(value))
    elseif lkey == "active" then
        self:SetNWBool("Active", tobool(value))
    elseif lkey == "targetname" then
        self:SetName(tostring(value))
    end
end

function ENT:AcceptInput(inputName, activator, caller, data)
    local linput = string.lower(inputName)
    
    if linput == "turnon" then
        self:SetNWBool("Active", true)
        return true
    elseif linput == "turnoff" then
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
    
    print("DEBUG info_manipulate Triggered! Firing outputs...")
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

function ENT:FireManualOutputs(eventName, activator)
    if not self.ManualOutputs or not self.ManualOutputs[eventName] then 
        PrintMessage(HUD_PRINTTALK, "DEBUG M-OUT: No outputs for event: " .. eventName)
        return 
    end
    
    for _, outStr in ipairs(self.ManualOutputs[eventName]) do
        PrintMessage(HUD_PRINTTALK, "DEBUG M-OUT: Proxying output: " .. outStr)
        
        -- Create a temporary C++ relay to execute the output natively
        -- This bypasses all issues with Lua ent:Fire on engine point entities finding
        local proxy = ents.Create("logic_relay")
        if IsValid(proxy) then
            proxy:SetPos(self:GetPos())
            proxy:SetKeyValue("spawnflags", "1") -- "Only trigger once"
            proxy:SetKeyValue("OnTrigger", outStr)
            proxy:Spawn()
            
            -- Fire the relay, letting C++ handle the output string exactly as the map intended
            proxy:Input("Trigger", activator, self, "")
            
            -- Remove it gracefully after it fires
            SafeRemoveEntityDelayed(proxy, 0.5)
        end
    end
end
