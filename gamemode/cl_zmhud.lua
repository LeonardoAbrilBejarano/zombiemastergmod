--[[
    Zombie Master - ZM Overhead HUD
    Client-side: Resource display, zombie spawn buttons, power buttons, zombie selection
    This is the core RTS-style interface for the Zombie Master player
]]

local zm_panel = nil

-- ZM-specific click handling
hook.Add("HUDPaint", "ZM_OverheadHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end

    local w, h = ScrW(), ScrH()

    -- Draw ZM overlay
    ZM_DrawResourceBar(w, h)
    ZM_DrawPopulationBar(w, h)
    ZM_DrawZombiePanel(w, h)
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

-- Zombie spawn buttons (left panel)
function ZM_DrawZombiePanel(w, h)
    local panelX = 10
    local panelY = h / 2 - 160
    local panelW = 180
    local btnH = 50
    local padding = 5

    -- Panel background
    local totalH = #ZM_ZOMBIE_TYPES * (btnH + padding) + 40
    draw.RoundedBox(8, panelX, panelY, panelW, totalH, Color(20, 20, 30, 220))

    -- Title
    draw.SimpleText("SPAWN ZOMBIES", "ZM_Small", panelX + panelW / 2, panelY + 8, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local y = panelY + 30

    for i, ztype in ipairs(ZM_ZOMBIE_TYPES) do
        local btnX = panelX + padding
        local btnW = panelW - padding * 2

        -- Button color (highlight if selected)
        local btnColor = Color(40, 40, 50, 200)
        local isSelected = (ZM_LocalData.spawnType == ztype.id)
        local canAfford = ZM_LocalData.resources >= ztype.cost
        local canPop = (ZM_LocalData.population + ztype.popCost) <= ZM_LocalData.maxPop

        if isSelected then
            btnColor = Color(100, 40, 40, 250)
        elseif not canAfford or not canPop then
            btnColor = Color(30, 30, 30, 180)
        end

        -- Mouse hover detection
        local mx, my = gui.MousePos()
        if mx >= btnX and mx <= btnX + btnW and my >= y and my <= y + btnH then
            if canAfford and canPop then
                btnColor = Color(60, 60, 80, 230)
                if isSelected then
                    btnColor = Color(120, 50, 50, 250)
                end
            end
        end

        draw.RoundedBox(4, btnX, y, btnW, btnH, btnColor)

        -- Zombie name
        local nameColor = canAfford and canPop and ztype.color or Color(100, 100, 100)
        draw.SimpleText(ztype.name, "ZM_Medium", btnX + 8, y + 4, nameColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        -- Cost
        local costColor = canAfford and Color(200, 200, 200) or Color(255, 80, 80)
        draw.SimpleText("Cost: " .. ztype.cost .. "  Pop: " .. ztype.popCost, "ZM_Small", btnX + 8, y + 28, costColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        y = y + btnH + padding
    end
end

-- Power buttons (right panel)
function ZM_DrawPowerPanel(w, h)
    local panelW = 180
    local panelX = w - panelW - 10
    local panelY = h / 2 - 100
    local btnH = 60
    local padding = 5

    -- Panel background
    draw.RoundedBox(8, panelX, panelY, panelW, 180, Color(20, 20, 30, 220))

    -- Title
    draw.SimpleText("ZM POWERS", "ZM_Small", panelX + panelW / 2, panelY + 8, Color(255, 200, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local y = panelY + 30

    -- PhysExplode button
    local powers = {
        { id = "physexplode", name = "Phys Explode",  cost = ZM_CONFIG.PHYSEXPLODE_COST, color = Color(255, 140, 30), desc = "Delayed explosion" },
        { id = "spotcreate",  name = "Hidden Spawn",  cost = ZM_CONFIG.SPOTCREATE_COST,  color = Color(100, 200, 100), desc = "Spawn unseen zombie" },
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

    -- Round timer
    if ZM_LocalData.roundEndTime > 0 then
        local remaining = math.max(0, ZM_LocalData.roundEndTime - CurTime())
        local minutes = math.floor(remaining / 60)
        local seconds = math.floor(remaining % 60)
        draw.SimpleText(string.format("Time: %02d:%02d", minutes, seconds), "ZM_Small", 90, 50, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end

-- Selected zombie info (bottom center)
function ZM_DrawSelectedInfo(w, h)
    if #ZM_LocalData.selectedZombies == 0 then return end

    local count = #ZM_LocalData.selectedZombies
    local alive = 0
    for _, npc in ipairs(ZM_LocalData.selectedZombies) do
        if IsValid(npc) and npc:IsNPC() and npc:Health() > 0 then
            alive = alive + 1
        end
    end

    local panelW = 200
    local x = w / 2 - panelW / 2
    local y = h - 100

    draw.RoundedBox(6, x, y, panelW, 40, Color(20, 20, 30, 220))
    draw.SimpleText("Selected: " .. alive .. " zombie" .. (alive ~= 1 and "s" or ""), "ZM_Medium", w / 2, y + 20, Color(255, 200, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Crosshair for ZM
function ZM_DrawCrosshair(w, h)
    local cx, cy = w / 2, h / 2
    local size = 12
    local col = Color(255, 50, 50, 180)

    if ZM_LocalData.currentPower == "physexplode" then
        col = Color(255, 140, 30, 200)
        size = 16
    elseif ZM_LocalData.currentPower == "spotcreate" then
        col = Color(100, 200, 100, 200)
        size = 16
    elseif ZM_LocalData.spawnType then
        col = Color(255, 255, 100, 200)
        size = 14
    end

    surface.SetDrawColor(col)
    surface.DrawLine(cx - size, cy, cx + size, cy)
    surface.DrawLine(cx, cy - size, cx, cy + size)

    -- Circle
    local segments = 16
    for i = 0, segments - 1 do
        local a1 = (i / segments) * math.pi * 2
        local a2 = ((i + 1) / segments) * math.pi * 2
        surface.DrawLine(
            cx + math.cos(a1) * size * 1.5,
            cy + math.sin(a1) * size * 1.5,
            cx + math.cos(a2) * size * 1.5,
            cy + math.sin(a2) * size * 1.5
        )
    end
end

-- Helper function to get world trace from mouse cursor
function ZM_GetCursorTrace(ply)
    local mx, my = gui.MousePos()
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
local zm_rightMouseMoved = false

-- ZM Mouse input handling (left-click only for GUI actions)
hook.Add("GUIMousePressed", "ZM_MousePress", function(mouseCode, aimVector)
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end

    local mx, my = gui.MousePos()

    -- Check if clicking on zombie panel buttons
    if ZM_HandleZombiePanelClick(mx, my) then return end
    if ZM_HandlePowerPanelClick(mx, my) then return end

    -- World click (spawn zombie, use power, or select zombie)
    local tr = ZM_GetCursorTrace(ply)
    if not tr.Hit then return end

    if mouseCode == MOUSE_LEFT then
        if ZM_LocalData.currentPower then
            -- Use power at target location
            net.Start("ZM_UsePower")
                net.WriteString(ZM_LocalData.currentPower)
                net.WriteVector(tr.HitPos)
            net.SendToServer()
            ZM_LocalData.currentPower = nil
        elseif ZM_LocalData.spawnType then
            -- Spawn zombie at target location
            net.Start("ZM_SpawnZombie")
                net.WriteString(ZM_LocalData.spawnType)
                net.WriteVector(tr.HitPos)
            net.SendToServer()
            -- Keep spawn type selected for rapid spawning
        else
            -- Try to select a zombie under cursor
            ZM_TrySelectZombie(tr)
        end
    end
end)

-- Right-click: hold to rotate camera, quick-click to command zombies / deselect
local zm_wasZM = false
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

    if rightDown and not zm_rightMouseHeld then
        -- Right mouse just pressed
        zm_rightMouseHeld = true
        zm_rightMouseStartTime = RealTime()
        zm_rightMouseMoved = false
        -- Disable cursor so mouse controls camera rotation
        gui.EnableScreenClicker(false)
    elseif rightDown and zm_rightMouseHeld then
        -- Still holding right mouse - check if we've moved enough to count as drag
        if (RealTime() - zm_rightMouseStartTime) > 0.15 then
            zm_rightMouseMoved = true
        end
    elseif not rightDown and zm_rightMouseHeld then
        -- Right mouse just released
        zm_rightMouseHeld = false
        -- Re-enable cursor for ZM GUI
        gui.EnableScreenClicker(true)

        -- If it was a quick click (not a drag), perform command action
        if not zm_rightMouseMoved then
            local tr = ZM_GetCursorTrace(ply)
            if tr.Hit then
                if #ZM_LocalData.selectedZombies > 0 then
                    -- Command selected zombies to move
                    net.Start("ZM_CommandZombies")
                        net.WriteVector(tr.HitPos)
                        local validZombies = {}
                        for _, npc in ipairs(ZM_LocalData.selectedZombies) do
                            if IsValid(npc) then table.insert(validZombies, npc) end
                        end
                        net.WriteUInt(#validZombies, 8)
                        for _, npc in ipairs(validZombies) do
                            net.WriteEntity(npc)
                        end
                    net.SendToServer()
                else
                    -- Deselect power/spawn type
                    ZM_LocalData.currentPower = nil
                    ZM_LocalData.spawnType = nil
                end
            end
        end
    end
end)

-- Handle clicks on zombie spawn panel
function ZM_HandleZombiePanelClick(mx, my)
    local panelX = 10
    local panelY = ScrH() / 2 - 160
    local panelW = 180
    local btnH = 50
    local padding = 5

    local y = panelY + 30

    for i, ztype in ipairs(ZM_ZOMBIE_TYPES) do
        local btnX = panelX + padding
        local btnW = panelW - padding * 2

        if mx >= btnX and mx <= btnX + btnW and my >= y and my <= y + btnH then
            if ZM_LocalData.spawnType == ztype.id then
                ZM_LocalData.spawnType = nil -- Toggle off
            else
                ZM_LocalData.spawnType = ztype.id
                ZM_LocalData.currentPower = nil -- Deselect power
            end
            return true
        end

        y = y + btnH + padding
    end

    return false
end

-- Handle clicks on power panel
function ZM_HandlePowerPanelClick(mx, my)
    local panelW = 180
    local panelX = ScrW() - panelW - 10
    local panelY = ScrH() / 2 - 100
    local btnH = 60
    local padding = 5

    local y = panelY + 30

    local powers = {"physexplode", "spotcreate"}

    for _, powerId in ipairs(powers) do
        local btnX = panelX + padding
        local btnW = panelW - padding * 2

        if mx >= btnX and mx <= btnX + btnW and my >= y and my <= y + btnH then
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
        -- Add to selection (or replace if not holding ctrl)
        if not input.IsKeyDown(KEY_LCONTROL) then
            ZM_LocalData.selectedZombies = {}
        end
        table.insert(ZM_LocalData.selectedZombies, hitEnt)

        net.Start("ZM_SelectZombies")
            net.WriteUInt(#ZM_LocalData.selectedZombies, 8)
            for _, npc in ipairs(ZM_LocalData.selectedZombies) do
                net.WriteEntity(npc)
            end
        net.SendToServer()
    else
        -- Click on empty space - deselect all
        ZM_LocalData.selectedZombies = {}
    end
end

-- ZM keyboard shortcuts
hook.Add("PlayerBindPress", "ZM_Binds", function(ply, bind, pressed)
    if not pressed then return end
    if ply:Team() ~= TEAM_ZM then return end

    -- Number keys 1-5 for zombie types
    for i = 1, 5 do
        if bind == "slot" .. i then
            local ztype = ZM_ZOMBIE_TYPES[i]
            if ztype then
                if ZM_LocalData.spawnType == ztype.id then
                    ZM_LocalData.spawnType = nil
                else
                    ZM_LocalData.spawnType = ztype.id
                    ZM_LocalData.currentPower = nil
                end
            end
            return true
        end
    end

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
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end

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
    if not IsValid(ply) or ply:Team() ~= TEAM_ZM then return end

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
