--[[
    Zombie Master - Team Selection Menu
    Client-side: lets players choose Survivors, volunteer for ZM, or Spectate
]]

local teamSelectPanel = nil

-- Open team selection
net.Receive("ZM_TeamSelect", function()
    ZM_OpenTeamSelect()
end)

function ZM_OpenTeamSelect()
    if IsValid(teamSelectPanel) then teamSelectPanel:Remove() end

    local w, h = ScrW(), ScrH()
    local panelW, panelH = 500, 400

    teamSelectPanel = vgui.Create("DFrame")
    teamSelectPanel:SetSize(panelW, panelH)
    teamSelectPanel:SetPos(w / 2 - panelW / 2, h / 2 - panelH / 2)
    teamSelectPanel:SetTitle("")
    teamSelectPanel:SetDraggable(false)
    teamSelectPanel:ShowCloseButton(false)
    teamSelectPanel:MakePopup()

    teamSelectPanel.Paint = function(self, pw, ph)
        -- Dark background with border
        draw.RoundedBox(12, 0, 0, pw, ph, Color(15, 15, 25, 240))
        draw.RoundedBox(12, 2, 2, pw - 4, ph - 4, Color(25, 25, 40, 240))

        -- Title
        draw.SimpleText("ZOMBIE MASTER", "ZM_Title", pw / 2, 20, Color(200, 30, 30), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("Choose Your Role", "ZM_Medium", pw / 2, 55, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Decorative line
        surface.SetDrawColor(200, 30, 30, 150)
        surface.DrawRect(40, 82, pw - 80, 2)
    end

    -- Survivors button
    local btnSurvivor = vgui.Create("DButton", teamSelectPanel)
    btnSurvivor:SetSize(panelW - 60, 70)
    btnSurvivor:SetPos(30, 100)
    btnSurvivor:SetText("")
    btnSurvivor.Paint = function(self, bw, bh)
        local col = self:IsHovered() and Color(40, 120, 40, 220) or Color(30, 80, 30, 200)
        draw.RoundedBox(8, 0, 0, bw, bh, col)

        draw.SimpleText("☠ JOIN SURVIVORS", "ZM_Large", bw / 2, 14, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("Fight for your life against the zombie horde!", "ZM_Small", bw / 2, 44, Color(180, 220, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    btnSurvivor.DoClick = function()
        net.Start("ZM_JoinTeam")
            net.WriteUInt(TEAM_SURVIVORS, 4)
        net.SendToServer()
        teamSelectPanel:Remove()
    end

    -- Play as ZM button
    local btnZM = vgui.Create("DButton", teamSelectPanel)
    btnZM:SetSize(panelW - 60, 70)
    btnZM:SetPos(30, 185)
    btnZM:SetText("")
    btnZM.Paint = function(self, bw, bh)
        local col = self:IsHovered() and Color(140, 30, 30, 220) or Color(100, 20, 20, 200)
        draw.RoundedBox(8, 0, 0, bw, bh, col)

        draw.SimpleText("★ PLAY AS ZOMBIE MASTER", "ZM_Large", bw / 2, 14, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("Command the undead from above!", "ZM_Small", bw / 2, 44, Color(220, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    btnZM.DoClick = function()
        net.Start("ZM_JoinTeam")
            net.WriteUInt(TEAM_ZM, 4)
        net.SendToServer()
        teamSelectPanel:Remove()
    end

    -- Spectate button
    local btnSpec = vgui.Create("DButton", teamSelectPanel)
    btnSpec:SetSize(panelW - 60, 50)
    btnSpec:SetPos(30, 270)
    btnSpec:SetText("")
    btnSpec.Paint = function(self, bw, bh)
        local col = self:IsHovered() and Color(60, 60, 80, 220) or Color(40, 40, 60, 200)
        draw.RoundedBox(8, 0, 0, bw, bh, col)
        draw.SimpleText("SPECTATE", "ZM_Medium", bw / 2, bh / 2, Color(150, 150, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnSpec.DoClick = function()
        net.Start("ZM_JoinTeam")
            net.WriteUInt(TEAM_SPECTATOR, 4)
        net.SendToServer()
        teamSelectPanel:Remove()
    end

    -- Player counts
    local infoLabel = vgui.Create("DLabel", teamSelectPanel)
    infoLabel:SetPos(30, 340)
    infoLabel:SetSize(panelW - 60, 40)
    infoLabel:SetText("")
    infoLabel.Paint = function(self, lw, lh)
        local survivors = 0
        local spectators = 0
        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() == TEAM_SURVIVORS then survivors = survivors + 1
            elseif ply:Team() == TEAM_SPECTATOR then spectators = spectators + 1 end
        end

        draw.SimpleText("Survivors: " .. survivors .. "  |  Spectators: " .. spectators .. "  |  Players: " .. #player.GetAll(), "ZM_Small", lw / 2, lh / 2, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- F1 to reopen team select
hook.Add("PlayerBindPress", "ZM_TeamSelectBind", function(ply, bind, pressed)
    if not pressed then return end
    if bind == "gm_showhelp" then
        ZM_OpenTeamSelect()
        return true
    end
end)
