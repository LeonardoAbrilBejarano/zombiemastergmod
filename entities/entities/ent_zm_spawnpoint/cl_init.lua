--[[
    Zombie Master - Zombie Spawn Point Entity
    Client-side: draw the spawn point (visible only to ZM)
]]

include("shared.lua")

function ENT:Draw()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Only visible to ZM
    if ply:Team() ~= TEAM_ZM then return end

    self:DrawModel()

    -- Draw label above
    local pos = self:GetPos() + Vector(0, 0, 60)
    local ang = (LocalPlayer():GetPos() - pos):Angle()
    ang:RotateAroundAxis(ang:Right(), -90)
    ang:RotateAroundAxis(ang:Up(), 180)

    cam.Start3D2D(pos, ang, 0.15)
        local active = self:GetNWBool("Active", true)
        local bgColor = active and Color(20, 80, 20, 200) or Color(80, 20, 20, 200)
        draw.RoundedBox(8, -200, -30, 400, 60, bgColor)

        local text = active and "ZOMBIE SPAWN" or "INACTIVE"
        draw.SimpleText(text, "ZM_Large", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
