--[[
    Zombie Master - Objectives HUD
    Client-side: shows current mission objectives to survivors and ZM
]]

-- Local objective state
ZM_ObjData = {
    missionName = "",
    objectives = {},
    current = 1,
    surviveEnd = 0,
}

-- Receive objective updates
net.Receive("ZM_ObjectiveUpdate", function()
    ZM_ObjData.missionName = net.ReadString()
    local count = net.ReadUInt(4)
    local current = net.ReadUInt(4)
    ZM_ObjData.current = current
    ZM_ObjData.objectives = {}

    for i = 1, count do
        local obj = {
            description = net.ReadString(),
            completed = net.ReadBool(),
            type = net.ReadString(),
        }
        if obj.type == "pickup" then
            obj.collected = net.ReadUInt(8)
            obj.required = net.ReadUInt(8)
        end
        if obj.type == "survive" then
            ZM_ObjData.surviveEnd = net.ReadFloat()
        end
        table.insert(ZM_ObjData.objectives, obj)
    end
end)

-- Draw objective panel
hook.Add("HUDPaint", "ZM_ObjectivesHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if #ZM_ObjData.objectives == 0 then return end

    local w, h = ScrW(), ScrH()

    -- Panel position (right side for survivors, top-center for ZM)
    local panelW = 280
    local panelX, panelY

    if ply:Team() == TEAM_ZM then
        panelX = w / 2 - panelW / 2
        panelY = 85
    else
        panelX = w - panelW - 15
        panelY = 80
    end

    -- Count lines needed
    local lineHeight = 22
    local headerHeight = 35
    local totalLines = #ZM_ObjData.objectives
    local panelH = headerHeight + totalLines * lineHeight + 15

    -- Check for survive timer
    local surviveRemaining = 0
    local hasSurvive = false
    for i, obj in ipairs(ZM_ObjData.objectives) do
        if obj.type == "survive" and i == ZM_ObjData.current and not obj.completed then
            hasSurvive = true
            surviveRemaining = math.max(0, ZM_ObjData.surviveEnd - CurTime())
            panelH = panelH + 25
        end
    end

    -- Background
    draw.RoundedBox(8, panelX, panelY, panelW, panelH, Color(10, 10, 20, 200))

    -- Mission title
    draw.SimpleText("📋 " .. ZM_ObjData.missionName, "ZM_Medium", panelX + panelW / 2, panelY + 8, Color(255, 220, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- Separator
    surface.SetDrawColor(255, 220, 50, 80)
    surface.DrawRect(panelX + 10, panelY + 30, panelW - 20, 1)

    -- Objectives list
    local y = panelY + headerHeight

    for i, obj in ipairs(ZM_ObjData.objectives) do
        local isCurrent = (i == ZM_ObjData.current)
        local prefix, textColor

        if obj.completed then
            prefix = "✓ "
            textColor = Color(80, 180, 80, 180)
        elseif isCurrent then
            prefix = "► "
            textColor = Color(255, 255, 255)
        else
            prefix = "○ "
            textColor = Color(120, 120, 120, 150)
        end

        -- Objective text
        local text = prefix .. obj.description
        if obj.type == "pickup" and isCurrent and not obj.completed then
            text = prefix .. obj.description
            -- Show collection progress
            local progress = " [" .. (obj.collected or 0) .. "/" .. (obj.required or 1) .. "]"
            draw.SimpleText(text, "ZM_Small", panelX + 10, y, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            local tw = surface.GetTextSize(text)
            draw.SimpleText(progress, "ZM_Small", panelX + 10 + tw, y, Color(255, 200, 50), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        else
            draw.SimpleText(text, "ZM_Small", panelX + 10, y, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        y = y + lineHeight

        -- Survive timer
        if obj.type == "survive" and isCurrent and not obj.completed and hasSurvive then
            local seconds = math.floor(surviveRemaining)
            local timerText = "⏱ Time remaining: " .. seconds .. "s"
            local timerColor = seconds > 15 and Color(100, 200, 255) or Color(255, 80, 80)

            -- Timer bar
            local barW = panelW - 20
            local barH = 14
            local frac = math.Clamp(surviveRemaining / (ZM_ObjData.surviveEnd - (ZM_ObjData.surviveEnd - surviveRemaining) + surviveRemaining), 0, 1)

            draw.RoundedBox(2, panelX + 10, y, barW, barH, Color(30, 30, 30))
            draw.RoundedBox(2, panelX + 10, y, barW * frac, barH, timerColor)
            draw.SimpleText(timerText, "ZM_Small", panelX + panelW / 2, y, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

            y = y + 22
        end
    end
end)
