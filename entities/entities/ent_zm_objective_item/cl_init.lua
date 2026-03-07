include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    -- Draw floating label
    local pos = self:GetPos() + Vector(0, 0, 30)
    local ang = (LocalPlayer():GetPos() - pos):Angle()
    ang:RotateAroundAxis(ang:Right(), -90)
    ang:RotateAroundAxis(ang:Up(), 180)

    cam.Start3D2D(pos, ang, 0.1)
        local name = self:GetNWString("ItemName", "Item")
        draw.RoundedBox(6, -150, -20, 300, 40, Color(200, 150, 0, 200))
        draw.SimpleText("★ " .. name, "ZM_Large", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

-- Glow effect
function ENT:Think()
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.pos = self:GetPos() + Vector(0, 0, 10)
        dlight.r = 255
        dlight.g = 200
        dlight.b = 50
        dlight.brightness = 3
        dlight.Decay = 1000
        dlight.Size = 128
        dlight.DieTime = CurTime() + 0.5
    end
end
