--[[
    Zombie Master - Manipulate (Trap) Entity
    Client-side: draw the manipulate (visible only to ZM)
]]

include("shared.lua")

function ENT:Draw()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Only visible to ZM
    if ply:Team() ~= TEAM_ZM then return end

    self:DrawModel()

    -- Draw label above
    local pos = self:GetPos() + Vector(0, 0, 40)
    local ang = (LocalPlayer():GetPos() - pos):Angle()
    ang:RotateAroundAxis(ang:Right(), -90)
    ang:RotateAroundAxis(ang:Up(), 180)

    cam.Start3D2D(pos, ang, 0.12)
        local active = self:GetNWBool("Active", true)
        local desc = self:GetNWString("Description", "Trap")
        local cost = self:GetNWInt("Cost", 0)

        local bgColor = active and Color(30, 30, 100, 200) or Color(60, 30, 30, 200)
        draw.RoundedBox(8, -250, -40, 500, 80, bgColor)

        draw.SimpleText("⚡ " .. desc, "ZM_Large", 0, -12, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Cost: " .. cost, "ZM_Small", 0, 15, active and Color(200, 200, 255) or Color(150, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
