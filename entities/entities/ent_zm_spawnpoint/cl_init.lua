--[[
    Zombie Master - Zombie Spawn Point Entity
    Client-side: draw the spawn point (visible only to ZM)
]]

include("shared.lua")

local matGlow = Material("sprites/light_glow02_add")

function ENT:Initialize()
    -- Set render bounds so it doesn't get culled if we look away from its origin
    self:SetRenderBounds(Vector(-64, -64, -64), Vector(64, 64, 64))
end

function ENT:DrawTranslucent()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Only visible to ZM
    if ply:Team() ~= TEAM_ZM then return end

    local active = self:GetNWBool("Active", true)
    if not active then return end

    local pos = self:GetPos()

    -- We do NOT call self:DrawModel() here because we want the canister to be invisible.
    -- The server sets the color to Alpha 0, so it physically transmits without rendering its mesh.

    -- Draw glowing inner orb
    local pulse = math.abs(math.sin(CurTime() * 3)) * 50 + 200
    render.SetMaterial(matGlow)
    render.DrawSprite(pos + Vector(0,0,10), 64, 64, Color(255, 50, 50, pulse))
    
    -- Draw outer aura
    local slowPulse = math.abs(math.sin(CurTime() * 1.5)) * 30 + 100
    render.DrawSprite(pos + Vector(0,0,10), 180, 180, Color(255, 0, 0, slowPulse))
end

-- Override default Draw to ensure it evaluates translucent drawing instead of opaque
function ENT:Draw()
    self:DrawTranslucent()
end
