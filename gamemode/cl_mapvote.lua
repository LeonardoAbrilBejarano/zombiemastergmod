--[[
    Zombie Master - Map Vote System
    Client-side: UI for voting maps
]]

local mapVotePanel = nil
local activeMaps = {}
local currentVotes = {}
local voteEndTime = 0

net.Receive("ZM_OpenMapVote", function()
    activeMaps = net.ReadTable()
    currentVotes = net.ReadTable()
    voteEndTime = net.ReadFloat()
    ZM_OpenMapVoteMenu()
end)

net.Receive("ZM_MapVoteUpdate", function()
    currentVotes = net.ReadTable()
    if IsValid(mapVotePanel) then
        -- Refresh the counts without recreating everything if needed,
        -- but for simplicity we can just wait for the button Paint functions to draw the updated counts
    end
end)

net.Receive("ZM_MapVoteTimer", function()
    voteEndTime = net.ReadFloat()
end)

function ZM_OpenMapVoteMenu()
    if IsValid(mapVotePanel) then mapVotePanel:Remove() end

    local w, h = ScrW(), ScrH()
    local panelW, panelH = 500, 100 + (#activeMaps * 80)

    mapVotePanel = vgui.Create("DFrame")
    mapVotePanel:SetSize(panelW, panelH)
    mapVotePanel:SetPos(w / 2 - panelW / 2, h / 2 - panelH / 2)
    mapVotePanel:SetTitle("")
    mapVotePanel:SetDraggable(false)
    mapVotePanel:ShowCloseButton(true)
    mapVotePanel:MakePopup()

    mapVotePanel.Paint = function(self, pw, ph)
        draw.RoundedBox(12, 0, 0, pw, ph, Color(15, 15, 25, 240))
        draw.RoundedBox(12, 2, 2, pw - 4, ph - 4, Color(25, 25, 40, 240))

        draw.SimpleText("MAP VOTING", "ZM_Title", pw / 2, 20, Color(100, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("Select a map to play next", "ZM_Medium", pw / 2, 55, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        surface.SetDrawColor(100, 200, 255, 150)
        surface.DrawRect(40, 82, pw - 80, 2)
    end

    local startY = 100
    for i, mapName in ipairs(activeMaps) do
        local btnMap = vgui.Create("DButton", mapVotePanel)
        btnMap:SetSize(panelW - 60, 60)
        btnMap:SetPos(30, startY + ((i - 1) * 70))
        btnMap:SetText("")
        
        btnMap.Paint = function(self, bw, bh)
            -- Check if I voted for this
            local myVote = LocalPlayer() and currentVotes[LocalPlayer()] == mapName
            
            local col = self:IsHovered() and Color(60, 80, 100, 220) or Color(40, 50, 60, 200)
            if myVote then
                col = Color(50, 120, 50, 200)
            end
            
            draw.RoundedBox(8, 0, 0, bw, bh, col)

            draw.SimpleText(mapName, "ZM_Large", 20, bh / 2, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            -- Count votes
            local mapVoteCount = 0
            for ply, vote in pairs(currentVotes) do
                if vote == mapName then mapVoteCount = mapVoteCount + 1 end
            end
            
            draw.SimpleText(mapVoteCount .. " Votes", "ZM_Medium", bw - 20, bh / 2, Color(150, 200, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        
        btnMap.DoClick = function()
            net.Start("ZM_VoteMap")
                net.WriteUInt(i, 8)
            net.SendToServer()
        end
    end
end

-- Override F2 to open map voting
hook.Add("PlayerBindPress", "ZM_MapVoteBind", function(ply, bind, pressed)
    if not pressed then return end
    if bind == "gm_showteam" then -- F2
        net.Start("ZM_OpenMapVote")
        net.SendToServer()
        return true
    end
    
    -- Block standard team select bind if needed, though they had gm_showhelp (F1) for that in cl_teamselect.lua
end)

-- Draw timer on HUD
hook.Add("HUDPaint", "ZM_MapVoteHUD", function()
    if voteEndTime > 0 then
        local remaining = math.max(0, voteEndTime - CurTime())
        if remaining > 0 then
            surface.SetFont("ZM_Title")
            local text = "Map Vote: " .. math.ceil(remaining) .. "s"
            local tw, th = surface.GetTextSize(text)
            
            local x = ScrW() / 2 - tw / 2
            local y = 20
            
            draw.RoundedBox(8, x - 10, y - 5, tw + 20, th + 10, Color(0, 0, 0, 200))
            draw.SimpleText(text, "ZM_Title", ScrW() / 2, y, Color(255, 200, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        else
            voteEndTime = 0
        end
    end
end)
