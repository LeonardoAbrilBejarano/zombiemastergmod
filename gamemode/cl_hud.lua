--[[
    Zombie Master - Survivor HUD
    Client-side: health, ammo, round info for survivors
]]

-- Hide default HUD elements
local hideHUD = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudAmmo"] = true,
    ["CHudSecondaryAmmo"] = true,
    ["CHudDamageIndicator"] = true,
}

hook.Add("HUDShouldDraw", "ZM_HideDefaultHUD", function(name)
    if hideHUD[name] then return false end
end)

-- Draw survivor HUD
hook.Add("HUDPaint", "ZM_SurvivorHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    if ply:Team() == TEAM_ZM then return end -- ZM has its own HUD
    if ply:Team() ~= TEAM_SURVIVORS then return end

    local w, h = ScrW(), ScrH()

    -- Health bar
    ZM_DrawHealthBar(ply, w, h)

    -- Ammo display
    ZM_DrawAmmo(ply, w, h)

    -- Round info
    ZM_DrawRoundInfo(w, h)
end)

-- Health bar
function ZM_DrawHealthBar(ply, w, h)
    local barW = 250
    local barH = 24
    local x = 20
    local y = h - 60

    -- Background
    draw.RoundedBox(4, x - 2, y - 2, barW + 4, barH + 4, Color(0, 0, 0, 180))

    -- Health bar
    local hp = math.Clamp(ply:Health() / ply:GetMaxHealth(), 0, 1)
    local hpColor
    if hp > 0.5 then
        hpColor = Color(60, 200, 60)
    elseif hp > 0.25 then
        hpColor = Color(220, 180, 30)
    else
        hpColor = Color(220, 50, 30)
    end

    draw.RoundedBox(2, x, y, barW * hp, barH, hpColor)

    -- Health text
    draw.SimpleText(ply:Health() .. " HP", "ZM_HUDSmall", x + barW / 2, y + barH / 2, Color(255, 255, 255, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Armor bar (if any)
    local armor = ply:Armor()
    if armor > 0 then
        y = y - 20
        local armorBarH = 12
        draw.RoundedBox(4, x - 2, y - 2, barW + 4, armorBarH + 4, Color(0, 0, 0, 180))

        local armorFrac = math.Clamp(armor / 100, 0, 1)
        draw.RoundedBox(2, x, y, barW * armorFrac, armorBarH, Color(50, 120, 220))
        draw.SimpleText(armor .. " Armor", "ZM_Small", x + barW / 2, y + armorBarH / 2, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- Ammo display
function ZM_DrawAmmo(ply, w, h)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end

    local clip = wep:Clip1()
    local reserve = ply:GetAmmoCount(wep:GetPrimaryAmmoType())

    if clip < 0 then return end -- Melee weapon

    local x = w - 200
    local y = h - 60

    -- Background
    draw.RoundedBox(4, x - 2, y - 2, 180, 44, Color(0, 0, 0, 180))

    -- Clip ammo
    draw.SimpleText(clip, "ZM_HUDLarge", x + 10, y + 6, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Separator
    draw.SimpleText("/", "ZM_HUDSmall", x + 70, y + 14, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- Reserve ammo
    draw.SimpleText(reserve, "ZM_Medium", x + 90, y + 12, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

-- Round info
function ZM_DrawRoundInfo(w, h)
    local state = ZM_LocalData.roundState
    local stateText = ""
    local stateColor = Color(255, 255, 255)

    if state == ROUND_WAITING then
        stateText = "WAITING FOR PLAYERS"
        stateColor = Color(255, 220, 50)
    elseif state == ROUND_ACTIVE then
        stateText = "ROUND IN PROGRESS"
        stateColor = Color(60, 200, 60)
    elseif state == ROUND_POST then
        stateText = "ROUND OVER"
        stateColor = Color(200, 100, 100)
    end

    -- Round state text at top center
    draw.SimpleText(stateText, "ZM_Medium", w / 2, 10, stateColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- Round timer
    if state == ROUND_ACTIVE and ZM_LocalData.roundEndTime > 0 then
        local remaining = math.max(0, ZM_LocalData.roundEndTime - CurTime())
        local minutes = math.floor(remaining / 60)
        local seconds = math.floor(remaining % 60)
        local timerText = string.format("%02d:%02d", minutes, seconds)

        local timerColor = Color(255, 255, 255)
        if remaining < 60 then
            timerColor = Color(255, 80, 80)
        end

        draw.SimpleText(timerText, "ZM_HUDLarge", w / 2, 32, timerColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    -- Team info
    local survivorCount = 0
    local aliveSurvivors = 0
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SURVIVORS then
            survivorCount = survivorCount + 1
            if ply:Alive() then
                aliveSurvivors = aliveSurvivors + 1
            end
        end
    end

    if state == ROUND_ACTIVE then
        draw.SimpleText("Survivors: " .. aliveSurvivors .. "/" .. survivorCount, "ZM_Small", w / 2, 62, Color(60, 200, 60, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end
