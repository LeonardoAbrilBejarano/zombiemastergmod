--[[
    Zombie Master - Custom Scoreboard
    Client-side: shows survivors, ZM, and spectators with status
]]

local scoreboardPanel = nil

function GM:ScoreboardShow()
    if IsValid(scoreboardPanel) then scoreboardPanel:Remove() end

    local w, h = ScrW(), ScrH()
    local panelW, panelH = 600, 500

    scoreboardPanel = vgui.Create("DFrame")
    scoreboardPanel:SetSize(panelW, panelH)
    scoreboardPanel:SetPos(w / 2 - panelW / 2, h / 2 - panelH / 2)
    scoreboardPanel:SetTitle("")
    scoreboardPanel:SetDraggable(false)
    scoreboardPanel:ShowCloseButton(false)
    scoreboardPanel:MakePopup()

    scoreboardPanel.Paint = function(self, pw, ph)
        draw.RoundedBox(12, 0, 0, pw, ph, Color(15, 15, 25, 240))
        draw.RoundedBox(12, 2, 2, pw - 4, ph - 4, Color(25, 25, 40, 230))

        -- Title
        draw.SimpleText("ZOMBIE MASTER", "ZM_Title", pw / 2, 15, Color(200, 30, 30), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Round state
        local stateText = "WAITING"
        local stateCol = Color(255, 220, 50)
        if ZM_LocalData.roundState == ROUND_ACTIVE then
            stateText = "ROUND IN PROGRESS"
            stateCol = Color(60, 200, 60)
        elseif ZM_LocalData.roundState == ROUND_POST then
            stateText = "ROUND OVER"
            stateCol = Color(200, 100, 100)
        end
        draw.SimpleText(stateText, "ZM_Small", pw / 2, 50, stateCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    -- Create a scrollable list
    local scrollPanel = vgui.Create("DScrollPanel", scoreboardPanel)
    scrollPanel:SetPos(15, 75)
    scrollPanel:SetSize(panelW - 30, panelH - 90)

    -- Zombie Master header
    local zmHeader = vgui.Create("DPanel", scrollPanel)
    zmHeader:SetSize(panelW - 40, 30)
    zmHeader:Dock(TOP)
    zmHeader:DockMargin(0, 5, 0, 0)
    zmHeader.Paint = function(self, pw, ph)
        draw.RoundedBox(4, 0, 0, pw, ph, Color(120, 20, 20, 200))
        draw.SimpleText("★ ZOMBIE MASTER", "ZM_Medium", 10, ph / 2, Color(255, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Score", "ZM_Small", pw - 60, ph / 2, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- ZM players
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_ZM then
            ZM_AddPlayerRow(scrollPanel, ply, Color(80, 20, 20, 180))
        end
    end

    -- Survivors header
    local survHeader = vgui.Create("DPanel", scrollPanel)
    survHeader:SetSize(panelW - 40, 30)
    survHeader:Dock(TOP)
    survHeader:DockMargin(0, 10, 0, 0)
    survHeader.Paint = function(self, pw, ph)
        draw.RoundedBox(4, 0, 0, pw, ph, Color(20, 80, 20, 200))
        draw.SimpleText("SURVIVORS", "ZM_Medium", 10, ph / 2, Color(200, 255, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Status", "ZM_Small", pw - 130, ph / 2, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Score", "ZM_Small", pw - 60, ph / 2, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Survivor players
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SURVIVORS then
            ZM_AddPlayerRow(scrollPanel, ply, Color(20, 50, 20, 180))
        end
    end

    -- Spectators header
    local specHeader = vgui.Create("DPanel", scrollPanel)
    specHeader:SetSize(panelW - 40, 25)
    specHeader:Dock(TOP)
    specHeader:DockMargin(0, 10, 0, 0)
    specHeader.Paint = function(self, pw, ph)
        draw.RoundedBox(4, 0, 0, pw, ph, Color(40, 40, 60, 200))
        draw.SimpleText("SPECTATORS", "ZM_Small", 10, ph / 2, Color(150, 150, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR or ply:Team() == TEAM_UNASSIGNED then
            ZM_AddPlayerRow(scrollPanel, ply, Color(30, 30, 40, 150))
        end
    end
end

function ZM_AddPlayerRow(parent, ply, bgColor)
    local row = vgui.Create("DPanel", parent)
    row:SetSize(parent:GetWide() - 10, 32)
    row:Dock(TOP)
    row:DockMargin(5, 2, 5, 0)

    row.Paint = function(self, pw, ph)
        draw.RoundedBox(4, 0, 0, pw, ph, bgColor)

        -- Player name
        local nameCol = Color(255, 255, 255)
        if not ply:Alive() and ply:Team() == TEAM_SURVIVORS then
            nameCol = Color(150, 80, 80)
        end
        draw.SimpleText(ply:Nick(), "ZM_Medium", 40, ph / 2, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Status
        if ply:Team() == TEAM_SURVIVORS then
            local statusText = ply:Alive() and "ALIVE" or "DEAD"
            local statusCol = ply:Alive() and Color(100, 255, 100) or Color(255, 80, 80)
            draw.SimpleText(statusText, "ZM_Small", pw - 130, ph / 2, statusCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif ply:Team() == TEAM_ZM then
            draw.SimpleText("COMMANDING", "ZM_Small", pw - 130, ph / 2, Color(255, 200, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Score
        draw.SimpleText(ply:Frags(), "ZM_Small", pw - 60, ph / 2, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Ping
        draw.SimpleText(ply:Ping() .. "ms", "ZM_Small", pw - 15, ph / 2, Color(120, 120, 120), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    -- Avatar
    local avatar = vgui.Create("AvatarImage", row)
    avatar:SetSize(24, 24)
    avatar:SetPos(6, 4)
    avatar:SetPlayer(ply, 32)
end

function GM:ScoreboardHide()
    if IsValid(scoreboardPanel) then
        scoreboardPanel:Remove()
        scoreboardPanel = nil
    end
end
