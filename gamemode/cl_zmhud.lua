--[[
    Zombie Master - ZM Overhead HUD
    Client-side: Resource display, zombie spawn buttons, power buttons, zombie selection
    This is the core RTS-style interface for the Zombie Master player
]]

local zm_panel = nil

-- ZM-specific click handling
hook.Add("HUDPaint", "ZM_OverheadHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM or ply.isPossessing then return end

    local w, h = ScrW(), ScrH()

    -- Draw ZM overlay
    ZM_DrawResourceBar(w, h)
    ZM_DrawPopulationBar(w, h)
    ZM_DrawPowerPanel(w, h)
    ZM_DrawZMInfo(w, h)
    ZM_DrawSelectedInfo(w, h)
    ZM_DrawCrosshair(w, h)
end)

-- Resource bar (top)
function ZM_DrawResourceBar(w, h)
    local barW = 300
    local barH = 30
    local x = w / 2 - barW / 2
    local y = 10

    -- Background
    draw.RoundedBox(6, x - 4, y - 4, barW + 8, barH + 8, Color(20, 20, 20, 220))

    -- Resource fill
    local frac = math.Clamp(ZM_LocalData.resources / ZM_CONFIG.MAX_RESOURCES, 0, 1)
    local resourceColor = Color(100, 200, 255)
    if ZM_LocalData.resources < 50 then
        resourceColor = Color(255, 100, 100)
    elseif ZM_LocalData.resources < 150 then
        resourceColor = Color(255, 200, 50)
    end

    draw.RoundedBox(4, x, y, barW * frac, barH, resourceColor)

    -- Text
    draw.SimpleText("Resources: " .. ZM_LocalData.resources .. " / " .. ZM_CONFIG.MAX_RESOURCES, "ZM_Medium", w / 2, y + barH / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Regen info
    draw.SimpleText("+" .. ZM_CONFIG.RESOURCE_REGEN .. "/s", "ZM_Small", x + barW + 15, y + barH / 2, Color(100, 200, 255, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

-- Population display
function ZM_DrawPopulationBar(w, h)
    local x = w / 2 - 150
    local y = 50

    draw.RoundedBox(6, x - 4, y - 4, 308, 28, Color(20, 20, 20, 220))

    local frac = math.Clamp(ZM_LocalData.population / ZM_LocalData.maxPop, 0, 1)
    local popColor = Color(180, 220, 80)
    if frac > 0.8 then popColor = Color(255, 100, 100) end

    draw.RoundedBox(4, x, y, 300 * frac, 20, popColor)

    draw.SimpleText("Pop: " .. ZM_LocalData.population .. " / " .. ZM_LocalData.maxPop, "ZM_Small", w / 2, y + 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- (Zombie Panel Removed; using Contextual Spawning on red spheres instead)

-- Power buttons (right panel)
function ZM_DrawPowerPanel(w, h)
    local panelW = 180
    local panelX = w - panelW - 10
    local btnH = 60
    local padding = 5

    -- build power list locally so we can compute height
    local powers = {
        { id = "physexplode", name = "Phys Explode",    cost = ZM_CONFIG.PHYSEXPLODE_COST,    color = Color(255, 140, 30), desc = "Delayed explosion" },
        { id = "spotcreate",  name = "Hidden Spawn",    cost = ZM_CONFIG.SPOTCREATE_COST,      color = Color(100, 200, 100), desc = "Spawn unseen zombie" },
        { id = "anywhere",    name = "Anywhere Spawn",  cost = ZM_CONFIG.ANYWHERE_SPAWN_COST, color = Color(150, 150, 255), desc = "Spawn shambler anywhere (ZM must be hidden & >200u away)" },
        { id = "possess",     name = "Possess Zombie",  cost = ZM_CONFIG.TRANSFORM_COST,     color = Color(200, 50, 200), desc = "Take control of a selected zombie (press Z to revert)" },
    }

    -- Compute panel height based on number of powers plus title area
    local panelH = 30 + (#powers * (btnH + padding)) + padding
    -- center the panel vertically on screen
    local panelY = h / 2 - panelH / 2

    -- Panel background
    draw.RoundedBox(8, panelX, panelY, panelW, panelH, Color(20, 20, 30, 220))

    -- Title
    draw.SimpleText("ZM POWERS", "ZM_Small", panelX + panelW / 2, panelY + 8, Color(255, 200, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local y = panelY + 30

    -- PhysExplode button
    local powers = {
        { id = "physexplode", name = "Phys Explode",    cost = ZM_CONFIG.PHYSEXPLODE_COST,    color = Color(255, 140, 30), desc = "Delayed explosion" },
        { id = "spotcreate",  name = "Hidden Spawn",    cost = ZM_CONFIG.SPOTCREATE_COST,      color = Color(100, 200, 100), desc = "Spawn unseen zombie" },
        { id = "anywhere",    name = "Anywhere Spawn",  cost = ZM_CONFIG.ANYWHERE_SPAWN_COST, color = Color(150, 150, 255), desc = "Spawn shambler anywhere (ZM must be hidden & >200u away)" },
        { id = "possess",     name = "Possess Zombie",  cost = ZM_CONFIG.TRANSFORM_COST,     color = Color(200, 50, 200), desc = "Take control of a selected zombie (press Z to revert)" },
    }

    for _, power in ipairs(powers) do
        local btnX = panelX + padding
        local btnW = panelW - padding * 2
        local canAfford = ZM_LocalData.resources >= power.cost
        local isSelected = (ZM_LocalData.currentPower == power.id)

        local btnColor = Color(40, 40, 50, 200)
        if isSelected then
            btnColor = Color(60, 40, 100, 250)
        elseif not canAfford then
            btnColor = Color(30, 30, 30, 180)
        end

        -- Mouse hover
        local mx, my = gui.MousePos()
        if mx >= btnX and mx <= btnX + btnW and my >= y and my <= y + btnH then
            if canAfford then
                btnColor = Color(60, 60, 80, 230)
            end
        end

        draw.RoundedBox(4, btnX, y, btnW, btnH, btnColor)

        local nameCol = canAfford and power.color or Color(100, 100, 100)
        draw.SimpleText(power.name, "ZM_Medium", btnX + 8, y + 4, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local costCol = canAfford and Color(200, 200, 200) or Color(255, 80, 80)
        draw.SimpleText("Cost: " .. power.cost, "ZM_Small", btnX + 8, y + 26, costCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(power.desc, "ZM_Small", btnX + 8, y + 42, Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        y = y + btnH + padding
    end
end

-- ZM info at top left
function ZM_DrawZMInfo(w, h)
    draw.RoundedBox(6, 10, 10, 160, 30, Color(200, 30, 30, 200))
    draw.SimpleText("★ ZOMBIE MASTER", "ZM_Medium", 90, 25, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local yObj = 50
    -- Round timer
    if ZM_LocalData.roundEndTime > 0 then
        local remaining = math.max(0, ZM_LocalData.roundEndTime - CurTime())
        local minutes = math.floor(remaining / 60)
        local seconds = math.floor(remaining % 60)
        draw.SimpleText(string.format("Time: %02d:%02d", minutes, seconds), "ZM_Small", 90, yObj, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        yObj = 70
    end
    
    -- Night Vision Button
    local mx, my = gui.MousePos()
    local nvHovered = (mx >= 10 and mx <= 170 and my >= yObj and my <= yObj + 20)
    local nvCol = ZM_LocalData.nightvision and Color(40, 120, 40, 200) or Color(60, 60, 60, 200)
    if nvHovered then
        nvCol = ZM_LocalData.nightvision and Color(60, 150, 60, 200) or Color(80, 80, 80, 200)
    end
    draw.RoundedBox(4, 10, yObj, 160, 20, nvCol)
    draw.SimpleText(ZM_LocalData.nightvision and "[N] Night Vision: ON" or "[N] Night Vision", "ZM_Small", 90, yObj + 4, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

-- Selected zombie info (bottom center)
function ZM_DrawSelectedInfo(w, h)
    local alive = 0
    if ZM_LocalData.selectedZombies then
        for _, npc in ipairs(ZM_LocalData.selectedZombies) do
            if IsValid(npc) and npc:IsNPC() and npc:Health() > 0 then
                alive = alive + 1
            end
        end
    end

    local panelW = 240
    local panelH = alive > 0 and 75 or 50
    local x = w / 2 - panelW / 2
    local y = h - 20 - panelH

    draw.RoundedBox(6, x, y, panelW, panelH, Color(20, 20, 30, 220))
    if alive > 0 then
        draw.SimpleText("Selected: " .. alive .. " zombie" .. (alive ~= 1 and "s" or ""), "ZM_Medium", w / 2, y + 10, Color(255, 200, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Draw Deselect All button text
        draw.RoundedBox(4, x + 10, y + 25, panelW - 20, 18, Color(60, 40, 40, 200))
        draw.SimpleText("Mid-Click to Deselect", "ZM_Small", w / 2, y + 27, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Draw AutoAttack button (Left-Click)
        local mx, my = gui.MousePos()
        local aaHovered = (mx >= x + 10 and mx <= x + panelW - 10 and my >= y + 48 and my <= y + 66)
        local btnCol = aaHovered and Color(150, 40, 40, 200) or Color(100, 40, 40, 200)
        draw.RoundedBox(4, x + 10, y + 48, panelW - 20, 18, btnCol)
        draw.SimpleText("Left-Click: Offensive Stance", "ZM_Small", w / 2, y + 50, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("No zombies selected", "ZM_Medium", w / 2, y + 15, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Draw Select All button background
        draw.RoundedBox(4, x + 10, y + 30, panelW - 20, 15, Color(40, 60, 40, 200))
        draw.SimpleText("Mid-Click to Select All", "ZM_Small", w / 2, y + 30, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end

-- Crosshair for ZM
function ZM_DrawCrosshair(w, h)
    -- User specifically requested to remove the central crosshair
end

-- Helper function to get world trace from mouse cursor
function ZM_GetCursorTrace(ply, optX, optY)
    local mx, my = optX, optY
    if not mx or not my then
        mx, my = gui.MousePos()
    end
    
    local aimVec = gui.ScreenToVector(mx, my)
    if not aimVec then aimVec = ply:GetAimVector() end
    
    return util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + (aimVec * 10000),
        filter = ply
    })
end

-- Track right-click camera dragging state
local zm_rightMouseHeld = false
local zm_rightMouseStartTime = 0
local zm_cameraRotating = false

-- Track left-click drag selection
local zm_isDragSelecting = false
local zm_dragStartX = 0
local zm_dragStartY = 0

-- Handle clicks on the top left panel (Night vision)
function ZM_HandleTopLeftClick(mx, my)
    local yObj = 50
    if ZM_LocalData.roundEndTime > 0 then yObj = 70 end
    
    if mx >= 10 and mx <= 170 and my >= yObj and my <= yObj + 20 then
        ZM_LocalData.nightvision = not ZM_LocalData.nightvision
        surface.PlaySound("buttons/lightswitch2.wav")
        return true
    end
    return false
end

-- Handle clicks on the bottom center panel
function ZM_HandleBottomPanelClick(mx, my)
    if not ZM_LocalData.selectedZombies or #ZM_LocalData.selectedZombies == 0 then return false end
    
    local panelW = 240
    local panelH = 75
    local x = ScrW() / 2 - panelW / 2
    local y = ScrH() - 20 - panelH

    -- Check auto attack button
    if mx >= x + 10 and mx <= x + panelW - 10 and my >= y + 48 and my <= y + 66 then
        net.Start("ZM_AutoAttack")
        net.SendToServer()
        return true
    end
    return false
end

-- ZM Mouse input handling (left-click only for GUI actions)
hook.Add("GUIMousePressed", "ZM_MousePress", function(mouseCode, aimVector)
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM or ply.isPossessing then return end

    if mouseCode == MOUSE_RIGHT then
        -- Cancel drag selection if starting a right-click action
        if zm_isDragSelecting then
            zm_isDragSelecting = false
        end
        
        zm_rightMouseHeld = true
        zm_rightMouseStartTime = RealTime()
        zm_cameraRotating = false
        
        if #ZM_LocalData.selectedZombies == 0 then
            zm_cameraRotating = true
            gui.EnableScreenClicker(false)
        end
        return
    end
    
    if mouseCode == MOUSE_MIDDLE then
        if #ZM_LocalData.selectedZombies > 0 then
            -- Deselect all
            ZM_LocalData.selectedZombies = {}
        else
            -- Select all
            for _, npc in ipairs(ents.GetAll()) do
                if IsValid(npc) and npc:IsNPC() and npc:Health() > 0 then
                    table.insert(ZM_LocalData.selectedZombies, npc)
                end
            end
            if #ZM_LocalData.selectedZombies > 0 then
                net.Start("ZM_SelectZombies")
                    net.WriteUInt(#ZM_LocalData.selectedZombies, 8)
                    for _, npc in ipairs(ZM_LocalData.selectedZombies) do
                        net.WriteEntity(npc)
                    end
                net.SendToServer()
            end
        end
        return
    end

    local mx, my = gui.MousePos()

    -- Check if clicking on top left panel buttons
    if ZM_HandleTopLeftClick(mx, my) then return end

    -- Check if clicking on power panel buttons
    if ZM_HandlePowerPanelClick(mx, my) then return end
    
    -- Check if clicking on bottom center panel buttons
    if ZM_HandleBottomPanelClick(mx, my) then return end

    if mouseCode == MOUSE_LEFT then
        if zm_rightMouseHeld then return end -- Block left clicks if right-click action is active
        
        if ZM_LocalData.currentPower then
            if ZM_LocalData.currentPower == "possess" then
                -- first try to pick the zombie under the cursor, falls back to selection
                local tr = ZM_GetCursorTrace(ply)
                local targetNpc = nil
                if IsValid(tr.Entity) and tr.Entity:IsNPC() then
                    targetNpc = tr.Entity
                elseif #ZM_LocalData.selectedZombies > 0 then
                    targetNpc = ZM_LocalData.selectedZombies[1]
                end

                if not IsValid(targetNpc) then
                    ZM_ShowNotification("No zombie targeted or selected!", Color(255,100,100))
                else
                    net.Start("ZM_UsePower")
                        net.WriteString("possess")
                        net.WriteEntity(targetNpc)
                    net.SendToServer()
                    ZM_LocalData.selectedZombies = {}
                    ZM_LocalData.currentPower = nil
                end
            else
                net.Start("ZM_UsePower")
                    net.WriteString(ZM_LocalData.currentPower)
                    -- Use power at target location
                    local tr = ZM_GetCursorTrace(ply)
                    if tr.Hit then
                        net.WriteVector(tr.HitPos)
                    else
                        net.WriteVector(Vector(0,0,0))
                    end
                net.SendToServer()
                ZM_LocalData.currentPower = nil
            end
        else
            -- Check if we clicked on a Spawn Point Sphere
            local aimVec = gui.ScreenToVector(mx, my)
            if not aimVec then aimVec = ply:GetAimVector() end
            
            local eyePos = ply:EyePos()
            local clickedSpawn = nil
            local clickedTrap = nil
            
            for _, ent in ipairs(ents.FindByClass("info_zombiespawn")) do
                if IsValid(ent) and ent:GetNWBool("Active", true) and not ent:GetNWBool("MapHidden", false) then
                    local hitPos = util.IntersectRayWithSphere(eyePos, aimVec, ent:GetPos(), 64)
                    if hitPos then
                        clickedSpawn = ent
                        break
                    end
                end
            end
            
            if IsValid(clickedSpawn) then
                ZM_OpenSpawnMenu(clickedSpawn)
                return
            end

            for _, ent in ipairs(ents.FindByClass("info_manipulate")) do
                if IsValid(ent) and ent:GetNWBool("Active", true) and not ent:GetNWBool("IsUsed", false) then
                    local hitPos = util.IntersectRayWithSphere(eyePos, aimVec, ent:GetPos(), 32)
                    if hitPos then
                        clickedTrap = ent
                        break
                    end
                end
            end

            if IsValid(clickedTrap) then
                net.Start("ZM_ActivateManipulate")
                    net.WriteEntity(clickedTrap)
                net.SendToServer()
                return
            end

            -- Check if clicking on empty space to start drag select
            zm_isDragSelecting = true
            zm_dragStartX = mx
            zm_dragStartY = my
        end
    end
end)

-- VGUI Context Menu for Spawn Points
local zm_spawnMenu = nil

function ZM_OpenSpawnMenu(spawnEnt)
    if IsValid(zm_spawnMenu) then zm_spawnMenu:Remove() end

    -- Base frame size and positioning
    local p = vgui.Create("DFrame")
    p:SetSize(350, 420)
    p:SetTitle("") -- Hide default title
    p:ShowCloseButton(false) -- Hide default close button
    -- Align to the left side of the screen, vertically centered (ScrH/2 - half window height)
    p:SetPos(30, ScrH() / 2 - 210)
    p:MakePopup()
    
    -- Custom DFrame Painting (matching the ZM Powers UI box)
    p.Paint = function(self, w, h)
        -- Main dark translucent background
        draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 30, 220))
        -- Header highlight
        draw.RoundedBoxEx(6, 0, 0, w, 35, Color(30, 30, 45, 240), true, true, false, false)
        
        -- Header text
        draw.SimpleText("ZM POWERS", "ZM_HUDSmall", w/2, 17, Color(255, 200, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Subheader (Spawn name)
        draw.SimpleText(spawnEnt:GetNWString("SpawnName", "Spawn Area"), "ZM_Small", w/2, 45, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Custom close button in top right
    local closeBtn = vgui.Create("DButton", p)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPos(p:GetWide() - 30, 5)
    closeBtn:SetText("X")
    closeBtn:SetTextColor(Color(200, 100, 100))
    closeBtn.Paint = function() end -- No background
    closeBtn.DoClick = function() p:Close() end

    local scroll = vgui.Create("DScrollPanel", p)
    -- Dock with margin to clear our custom header
    scroll:Dock(FILL)
    scroll:DockMargin(10, 50, 10, 10)

    for i, ztype in ipairs(ZM_ZOMBIE_TYPES) do
        local btn = scroll:Add("DButton")
        btn:SetText("") -- Clear default text, we draw our own
        btn:Dock(TOP)
        btn:DockMargin(0, 2, 0, 2)
        btn:SetTall(42)
        
        btn.Paint = function(self, w, h)
            local canAfford = (ZM_LocalData.resources or 0) >= ztype.cost and ((ZM_LocalData.population or 0) + ztype.popCost) <= (ZM_LocalData.maxPop or 50)
            
            -- Hover color state
            local bgCol = self:IsHovered() and Color(40, 40, 55, 240) or Color(30, 30, 45, 220)
            if not canAfford then
                bgCol = self:IsHovered() and Color(60, 30, 30, 240) or Color(40, 20, 20, 220)
            end
            
            draw.RoundedBox(4, 0, 0, w, h, bgCol)
            
            -- Name (centered, upper half)
            local nameCol = canAfford and Color(100, 255, 100) or Color(200, 100, 100)
            draw.SimpleText(ztype.name, "ZM_Medium", w / 2, 4, nameCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            
            -- Costs (centered, lower half)
            draw.SimpleText("Cost: " .. ztype.cost .. " / Pop: " .. ztype.popCost, "ZM_Small", w / 2, 23, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
        
        btn.DoClick = function()
            if (ZM_LocalData.resources or 0) >= ztype.cost and ((ZM_LocalData.population or 0) + ztype.popCost) <= (ZM_LocalData.maxPop or 50) then
                net.Start("ZM_SpawnZombie")
                    net.WriteString(ztype.id)
                    net.WriteUInt(spawnEnt:EntIndex(), 16)
                net.SendToServer()
            else
                surface.PlaySound("buttons/button10.wav")
            end
        end
    end
    zm_spawnMenu = p
end

-- Right-click: hold to rotate camera, quick-click to command zombies / deselect
local zm_wasZM = false
hook.Add("GUIMouseReleased", "ZM_MouseRelease", function(mouseCode, aimVector)
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM or ply.isPossessing then return end

    if mouseCode == MOUSE_LEFT and zm_isDragSelecting then
        zm_isDragSelecting = false
        local mx, my = gui.MousePos()
        
        -- If it's a very short drag, treat it as a click
        if math.abs(mx - zm_dragStartX) < 10 and math.abs(my - zm_dragStartY) < 10 then
            local tr = ZM_GetCursorTrace(ply, mx, my)
            if tr.Hit then
                ZM_TrySelectZombie(tr)
            else
                -- Clicked on empty space (no hit)
                ZM_LocalData.selectedZombies = {}
            end
            return
        end
        
        -- Otherwise it's a drag box selection
        local minX = math.min(mx, zm_dragStartX)
        local maxX = math.max(mx, zm_dragStartX)
        local minY = math.min(my, zm_dragStartY)
        local maxY = math.max(my, zm_dragStartY)
        
        -- If not holding ctrl, clear selection first (drag select overrides)
        if #ZM_LocalData.selectedZombies > 0 and not input.IsKeyDown(KEY_LCONTROL) then
            ZM_LocalData.selectedZombies = {}
        end
        
        local changed = false
        for _, npc in ipairs(ents.GetAll()) do
            if IsValid(npc) and npc:IsNPC() and npc:Health() > 0 then
                local screenPos = npc:GetPos():ToScreen()
                if screenPos.visible then
                    if screenPos.x >= minX and screenPos.x <= maxX and screenPos.y >= minY and screenPos.y <= maxY then
                        -- Check if already selected
                        local alreadySelectedIdx = nil
                        for i, v in ipairs(ZM_LocalData.selectedZombies) do
                            if v == npc then
                                alreadySelectedIdx = i
                                break
                            end
                        end
                        
                        -- If holding ctrl, toggle selection. If not holding ctrl, it always selects since we cleared the table above
                        if alreadySelectedIdx and input.IsKeyDown(KEY_LCONTROL) then
                            table.remove(ZM_LocalData.selectedZombies, alreadySelectedIdx)
                            changed = true
                        elseif not alreadySelectedIdx then
                            table.insert(ZM_LocalData.selectedZombies, npc)
                            changed = true
                        end
                    end
                end
            end
        end
        
        if changed or not input.IsKeyDown(KEY_LCONTROL) then
            -- We always send an update if ctrl wasn't held (to clear any existing selection) or if something actually changed
            net.Start("ZM_SelectZombies")
                net.WriteUInt(#ZM_LocalData.selectedZombies, 8)
                for _, npc in ipairs(ZM_LocalData.selectedZombies) do
                    net.WriteEntity(npc)
                end
            net.SendToServer()
        end
        return
    end

    if mouseCode == MOUSE_RIGHT and zm_rightMouseHeld then
        zm_rightMouseHeld = false
        
        if zm_cameraRotating then
            gui.EnableScreenClicker(true)
            zm_cameraRotating = false
        end

        local holdTime = RealTime() - zm_rightMouseStartTime
        if holdTime <= 0.15 and #ZM_LocalData.selectedZombies > 0 then
            local tr = ZM_GetCursorTrace(ply)
            
            if tr.Hit then
                net.Start("ZM_CommandZombies")
                    net.WriteVector(tr.HitPos)
                    net.WriteEntity(tr.Entity)
                    local validZombies = {}
                    for _, npc in ipairs(ZM_LocalData.selectedZombies) do
                        if IsValid(npc) then table.insert(validZombies, npc) end
                    end
                    net.WriteUInt(#validZombies, 8)
                    for _, npc in ipairs(validZombies) do
                        net.WriteEntity(npc)
                    end
                net.SendToServer()
            end
        elseif #ZM_LocalData.selectedZombies == 0 and holdTime <= 0.15 then
            -- Quick click with no zombies deselects power
            ZM_LocalData.currentPower = nil
            ZM_LocalData.spawnType = nil
        end
    end
end)

hook.Add("Think", "ZM_RightClickCamera", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local isZM = (ply:Team() == TEAM_ZM)
    
    if zm_wasZM and not isZM then
        gui.EnableScreenClicker(false)
        zm_rightMouseHeld = false
    end
    zm_wasZM = isZM

    if not isZM then return end

    local rightDown = input.IsMouseDown(MOUSE_RIGHT)

    if rightDown and #ZM_LocalData.selectedZombies > 0 and zm_rightMouseHeld then
        local holdTime = RealTime() - zm_rightMouseStartTime
        if holdTime > 0.15 and not zm_cameraRotating then
            zm_cameraRotating = true
            gui.EnableScreenClicker(false)
        end
    elseif not rightDown and zm_rightMouseHeld then
        -- Native fallback: if the mouse is physically released but we didn't catch it
        -- (because drawing contexts were disabled), we forcibly release it here.
        zm_rightMouseHeld = false
        if zm_cameraRotating then
            gui.EnableScreenClicker(true)
            zm_cameraRotating = false
        end
    end
end)

-- (Zombie spawn panel removed; replaced by contextual popup)

-- Handle clicks on power panel
function ZM_HandlePowerPanelClick(mx, my)
    local panelW = 180
    local btnH = 60
    local padding = 5

    -- replicate power list from draw routine so they stay in sync
    local powers = {
        { id = "physexplode" },
        { id = "spotcreate" },
        { id = "anywhere" },
        { id = "possess" },
    }

    -- compute vertical offset same as draw
    local panelH = 30 + (#powers * (btnH + padding)) + padding
    local panelX = ScrW() - panelW - 10
    local panelY = ScrH() / 2 - panelH / 2
    local y = panelY + 30

    for _, pinfo in ipairs(powers) do
        local powerId = pinfo.id
        local btnX = panelX + padding
        local btnW = panelW - padding * 2

        if mx >= btnX and mx <= btnX + btnW and my >= y and my <= y + btnH then
            if powerId == "possess" then
                -- if we already have a selected zombie, just use the power immediately
                if #ZM_LocalData.selectedZombies > 0 then
                    local npc = ZM_LocalData.selectedZombies[1]
                    if IsValid(npc) and (ZM_LocalData.resources or 0) >= ZM_CONFIG.TRANSFORM_COST then
                        net.Start("ZM_UsePower")
                            net.WriteString("possess")
                            net.WriteEntity(npc)
                        net.SendToServer()
                        ZM_LocalData.selectedZombies = {}
                        -- consume the power click but don't toggle state
                        return true
                    else
                        ZM_ShowNotification("Cannot possess: no resources or invalid target.", Color(255,100,100))
                        return true
                    end
                end
            end

            if ZM_LocalData.currentPower == powerId then
                ZM_LocalData.currentPower = nil -- Toggle off
            else
                ZM_LocalData.currentPower = powerId
                ZM_LocalData.spawnType = nil -- Deselect zombie spawn
            end
            return true
        end

        y = y + btnH + padding
    end

    return false
end

-- Try to select a zombie under the cursor
function ZM_TrySelectZombie(tr)
    local hitEnt = tr.Entity
    
    if IsValid(hitEnt) and hitEnt:IsNPC() then
        local alreadySelectedIdx = nil
        for i, v in ipairs(ZM_LocalData.selectedZombies) do
            if v == hitEnt then
                alreadySelectedIdx = i
                break
            end
        end
        
        if input.IsKeyDown(KEY_LCONTROL) then
            -- Holding Ctrl: Toggle specific zombie
            if alreadySelectedIdx then
                table.remove(ZM_LocalData.selectedZombies, alreadySelectedIdx)
            else
                table.insert(ZM_LocalData.selectedZombies, hitEnt)
            end
        else
            -- Not holding Ctrl: Select only this zombie (or do nothing if it's the only one selected)
            if alreadySelectedIdx and #ZM_LocalData.selectedZombies == 1 then
                -- It's the only one selected, do nothing
            else
                ZM_LocalData.selectedZombies = { hitEnt }
            end
        end

        net.Start("ZM_SelectZombies")
            net.WriteUInt(#ZM_LocalData.selectedZombies, 8)
            for _, npc in ipairs(ZM_LocalData.selectedZombies) do
                net.WriteEntity(npc)
            end
        net.SendToServer()
    else
        -- Click on empty space - deselect all
        if #ZM_LocalData.selectedZombies > 0 then
            ZM_LocalData.selectedZombies = {}
            net.Start("ZM_SelectZombies")
                net.WriteUInt(0, 8)
            net.SendToServer()
        end
    end
end

-- ZM keyboard shortcuts
hook.Add("PlayerBindPress", "ZM_Binds", function(ply, bind, pressed)
    if not pressed then return end
    if ply:Team() ~= TEAM_ZM or ply.isPossessing then return end

    -- Q for PhysExplode
    if bind == "lastinv" then
        if ZM_LocalData.currentPower == "physexplode" then
            ZM_LocalData.currentPower = nil
        else
            ZM_LocalData.currentPower = "physexplode"
            ZM_LocalData.spawnType = nil
        end
        return true
    end

    -- E for SpotCreate
    if bind == "+use" then
        if ZM_LocalData.currentPower == "spotcreate" then
            ZM_LocalData.currentPower = nil
        else
            ZM_LocalData.currentPower = "spotcreate"
            ZM_LocalData.spawnType = nil
        end
        return true
    end

    -- R for rally all
    if bind == "+reload" then
        local tr = ZM_GetCursorTrace(ply)
        if tr.Hit then
            net.Start("ZM_SetRally")
                net.WriteVector(tr.HitPos)
            net.SendToServer()
        end
        return true
    end

    -- 3 key (slot3) toggles the new anywhere-spawn power
    if bind == "slot3" then
        if ZM_LocalData.currentPower == "anywhere" then
            ZM_LocalData.currentPower = nil
        else
            ZM_LocalData.currentPower = "anywhere"
            ZM_LocalData.spawnType = nil
        end
        return true
    end

    -- Delete to remove selected zombie
    if bind == "impulse 100" then -- flashlight bind
        for _, npc in ipairs(ZM_LocalData.selectedZombies) do
            if IsValid(npc) then
                net.Start("ZM_DeleteZombie")
                    net.WriteEntity(npc)
                net.SendToServer()
            end
        end
        ZM_LocalData.selectedZombies = {}
        return true
    end

    -- N to toggle Night Vision (assuming they use a bind or we catch it)
    -- GMod natively binds 'N' to nothing usually, but +zoom is often used if there's no suit zoom.
    -- We can also catch the 'impulse 100' or other keys, but since GMod doesn't pass raw keys to PlayerBindPress unless bound,
    -- we'll rely on the UI button or if they bound a key to something generic.
    
    -- We'll add a 'Think' or 'ButtonPress' hook for the 'N' key specifically if we want a raw key.
    
    -- Escape to deselect everything
    if bind == "cancelselect" then
        ZM_LocalData.currentPower = nil
        ZM_LocalData.spawnType = nil
        ZM_LocalData.selectedZombies = {}
        return true
    end
end)

-- Show cursor for ZM (but not while right-clicking for camera rotation)
hook.Add("InputMouseApply", "ZM_ShowCursor", function(cmd, x, y, angle)
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM or ply.isPossessing then return end

    -- Don't re-enable cursor while right-click is held (camera rotation mode)
    if zm_rightMouseHeld then return end

    -- Enable cursor
    if not vgui.CursorVisible() then
        gui.EnableScreenClicker(true)
    end
end)



-- Draw selected zombie highlights in the world
hook.Add("PostDrawOpaqueRenderables", "ZM_HighlightZombies", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM or ply.isPossessing then return end

    -- Draw halos on selected zombies
    local selected = {}
    for _, npc in ipairs(ZM_LocalData.selectedZombies) do
        if IsValid(npc) then
            table.insert(selected, npc)
        end
    end

    if #selected > 0 then
        halo.Add(selected, Color(255, 200, 50), 2, 2, 1)
    end

    -- Draw halos on ALL owned zombies (faint green)
    local allZombies = {}
    for _, npc in ipairs(ents.GetAll()) do
        if IsValid(npc) and npc:IsNPC() then
            table.insert(allZombies, npc)
        end
    end

    if #allZombies > 0 then
        halo.Add(allZombies, Color(100, 200, 100, 50), 1, 1, 1)
    end
end)
-- Possession revert key (Z)
local zm_zWasDown = false
hook.Add("Think", "ZM_PossessRevertKey", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply.isPossessing then return end

    local isDown = input.IsKeyDown(KEY_Z)
    if isDown and not zm_zWasDown then
        net.Start("ZM_RevertPossess")
        net.SendToServer()
    end
    zm_zWasDown = isDown
end)
-- Night Vision input check (N Key)
local zm_nKeyWasDown = false
hook.Add("Think", "ZM_NightVisionKey", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM or ply.isPossessing then return end
    
    local isDown = input.IsKeyDown(KEY_N)
    if isDown and not zm_nKeyWasDown then
        ZM_LocalData.nightvision = not ZM_LocalData.nightvision
        surface.PlaySound("buttons/lightswitch2.wav")
    end
    zm_nKeyWasDown = isDown
end)

-- Night Vision post-processing
hook.Add("RenderScreenspaceEffects", "ZM_NightVisionEffect", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM or ply.isPossessing then return end
    if not ZM_LocalData.nightvision then return end

    local colorMod = {
        ["$pp_colour_addr"]         = 0,
        ["$pp_colour_addg"]         = 0.05,
        ["$pp_colour_addb"]         = 0,
        ["$pp_colour_brightness"]   = 0.1,
        ["$pp_colour_contrast"]     = 1.4,
        ["$pp_colour_colour"]       = 0.4,
        ["$pp_colour_mulr"]         = 0,
        ["$pp_colour_mulg"]         = 0.8,
        ["$pp_colour_mulb"]         = 0
    }
    
    DrawColorModify(colorMod)
    DrawBloom(0.5, 1.2, 5, 5, 1, 1, 0, 0.5, 0)
    -- Add a faint green vignette or overlay if you want, but ColorModify + Bloom usually looks good for NVG.
end)

-- Draw drag selection box
hook.Add("HUDPaint", "ZM_DrawDragSelect", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM or ply.isPossessing then return end

    if zm_isDragSelecting then
        local mx, my = gui.MousePos()
        
        local minX = math.min(mx, zm_dragStartX)
        local maxX = math.max(mx, zm_dragStartX)
        local minY = math.min(my, zm_dragStartY)
        local maxY = math.max(my, zm_dragStartY)
        
        local w = maxX - minX
        local h = maxY - minY
        
        if w > 5 or h > 5 then
            surface.SetDrawColor(255, 30, 30, 5)
            surface.DrawRect(minX, minY, w, h)
            
            surface.SetDrawColor(255, 30, 30, 120)
            surface.DrawOutlinedRect(minX, minY, w, h)
        end
    end
end)
