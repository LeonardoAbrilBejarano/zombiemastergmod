include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local locked = self:GetNWBool("Locked", false)
    local used = self:GetNWBool("Used", false)

    -- Draw floating label
    local pos = self:GetPos() + Vector(0, 0, 40)
    local dist = ply:GetPos():Distance(self:GetPos())
    if dist > 600 then return end -- Only show label nearby

    local ang = (ply:GetPos() - pos):Angle()
    ang:RotateAroundAxis(ang:Right(), -90)
    ang:RotateAroundAxis(ang:Up(), 180)

    local scale = math.Clamp(0.12 - (dist / 8000), 0.06, 0.12)

    cam.Start3D2D(pos, ang, scale)
        local name = self:GetNWString("InteractName", "Objective")
        local prompt = self:GetNWString("Prompt", "Press E")

        if used then
            draw.RoundedBox(6, -200, -30, 400, 60, Color(40, 100, 40, 200))
            draw.SimpleText("✓ " .. name, "ZM_Large", 0, -8, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Completed", "ZM_Small", 0, 16, Color(180, 220, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif locked then
            draw.RoundedBox(6, -200, -30, 400, 60, Color(60, 40, 40, 180))
            draw.SimpleText("🔒 " .. name, "ZM_Large", 0, -8, Color(150, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Locked", "ZM_Small", 0, 16, Color(150, 120, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.RoundedBox(6, -200, -30, 400, 60, Color(30, 60, 120, 220))
            draw.SimpleText("⚡ " .. name, "ZM_Large", 0, -8, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(prompt, "ZM_Small", 0, 16, Color(200, 220, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end

-- Glow effect for unlocked interact points
function ENT:Think()
    if self:GetNWBool("Locked", false) or self:GetNWBool("Used", false) then return end

    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.pos = self:GetPos() + Vector(0, 0, 20)
        dlight.r = 50
        dlight.g = 120
        dlight.b = 255
        dlight.brightness = 3
        dlight.Decay = 1000
        dlight.Size = 150
        dlight.DieTime = CurTime() + 0.5
    end
end
