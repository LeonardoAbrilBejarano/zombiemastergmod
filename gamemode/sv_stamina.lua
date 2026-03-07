--[[
    Zombie Master - Stamina System
    Server-side: drain and regenerate stamina for Survivors
]]

util.AddNetworkString("ZM_UpdateStamina")

local STAMINA_MAX = 100
local STAMINA_DRAIN_RATE = 15 -- per second sprinting
local STAMINA_REGEN_RATE = 10 -- per second resting
local STAMINA_JUMP_COST = 10

local JUMP_COOLDOWN = 1

hook.Add("PlayerTick", "ZM_StaminaSystem", function(ply, mv)
    if not IsValid(ply) or ply:Team() ~= TEAM_SURVIVORS or not ply:Alive() then return end
    
    local currentStamina = ply:GetNWFloat("ZM_Stamina", STAMINA_MAX)
    local isMoving = mv:GetVelocity():Length2D() > 10
    local isSprinting = ply:KeyDown(IN_SPEED) and isMoving and ply:IsOnGround()
    
    local nextTickStamina = currentStamina

    if isSprinting then
        nextTickStamina = math.max(0, currentStamina - (STAMINA_DRAIN_RATE * engine.TickInterval()))
    else
        nextTickStamina = math.min(STAMINA_MAX, currentStamina + (STAMINA_REGEN_RATE * engine.TickInterval()))
    end
    
    if currentStamina ~= nextTickStamina then
        ply:SetNWFloat("ZM_Stamina", nextTickStamina)
    end
end)

hook.Add("SetupMove", "ZM_StaminaMovement", function(ply, mv, cmd)
    if not IsValid(ply) or ply:Team() ~= TEAM_SURVIVORS or not ply:Alive() then return end
    
    local currentStamina = ply:GetNWFloat("ZM_Stamina", STAMINA_MAX)
    
    -- If out of stamina, force run speed to walk speed
    if currentStamina <= 0 then
        mv:SetMaxClientSpeed(100) -- enforce 100 walk speed max
        mv:SetMaxSpeed(100)
    end
    
    -- Jump cost
    if mv:KeyPressed(IN_JUMP) and ply:IsOnGround() then
        if currentStamina >= STAMINA_JUMP_COST then
            ply:SetNWFloat("ZM_Stamina", currentStamina - STAMINA_JUMP_COST)
        else
            -- Block jump if they don't have enough stamina
            local buttons = mv:GetButtons()
            mv:SetButtons(bit.band(buttons, bit.bnot(IN_JUMP)))
        end
    end
end)
