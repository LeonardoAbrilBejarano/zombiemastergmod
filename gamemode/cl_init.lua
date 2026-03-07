--[[
    Zombie Master Gamemode - Client Init
    Client-side only
]]

include("shared.lua")
include("cl_hud.lua")
include("cl_zmhud.lua")
include("cl_teamselect.lua")
include("cl_scoreboard.lua")
include("cl_objectives.lua")
include("cl_buymenu.lua")

--[[---------------------------------------------------------
    Initialize Client Systems
-----------------------------------------------------------]]
function GM:Initialize()
    -- Initialize HUD elements if needed
end


-- Local state
ZM_LocalData = {
    resources   = 0,
    population  = 0,
    maxPop      = 50,
    roundState  = ROUND_WAITING,
    roundEndTime = 0,
    selectedZombies = {},
    currentPower = nil,  -- "physexplode", "spotcreate", or nil
    spawnType = nil,      -- zombie type ID to spawn, or nil
}

-- Receive round state updates
net.Receive("ZM_RoundState", function()
    ZM_LocalData.roundState = net.ReadUInt(4)
end)

-- Receive resource updates
net.Receive("ZM_UpdateResources", function()
    ZM_LocalData.resources = net.ReadInt(16)
end)

-- Receive population updates
net.Receive("ZM_UpdatePopulation", function()
    ZM_LocalData.population = net.ReadInt(16)
    ZM_LocalData.maxPop = net.ReadInt(16)
end)

-- Receive round timer
net.Receive("ZM_RoundTimer", function()
    ZM_LocalData.roundEndTime = net.ReadFloat()
end)

-- Receive notifications
net.Receive("ZM_Notification", function()
    local msg = net.ReadString()
    local col = net.ReadColor()
    ZM_ShowNotification(msg, col)
end)

-- Notification system
local notifications = {}

function ZM_ShowNotification(msg, col)
    table.insert(notifications, {
        text = msg,
        color = col or Color(255, 255, 255),
        time = CurTime(),
        alpha = 255,
    })

    -- Keep max 5 notifications
    while #notifications > 5 do
        table.remove(notifications, 1)
    end
end

-- Draw notifications on screen
hook.Add("HUDPaint", "ZM_Notifications", function()
    local y = ScrH() * 0.25
    local now = CurTime()

    for i = #notifications, 1, -1 do
        local notif = notifications[i]
        local age = now - notif.time
        if age > 5 then
            table.remove(notifications, i)
        else
            local alpha = 255
            if age > 3 then
                alpha = 255 * (1 - (age - 3) / 2)
            end

            local col = Color(notif.color.r, notif.color.g, notif.color.b, alpha)
            local bgCol = Color(0, 0, 0, alpha * 0.6)

            surface.SetFont("ZM_NotifFont")
            local tw, th = surface.GetTextSize(notif.text)
            local x = ScrW() / 2 - tw / 2

            draw.RoundedBox(4, x - 10, y - 2, tw + 20, th + 4, bgCol)
            draw.SimpleText(notif.text, "ZM_NotifFont", ScrW() / 2, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

            y = y + th + 8
        end
    end
end)

-- Create fonts
surface.CreateFont("ZM_Title", {
    font = "Arial",
    size = 32,
    weight = 800,
})

surface.CreateFont("ZM_Large", {
    font = "Arial",
    size = 24,
    weight = 700,
})

surface.CreateFont("ZM_Medium", {
    font = "Arial",
    size = 18,
    weight = 600,
})

surface.CreateFont("ZM_Small", {
    font = "Arial",
    size = 14,
    weight = 500,
})

surface.CreateFont("ZM_NotifFont", {
    font = "Arial",
    size = 20,
    weight = 600,
})

surface.CreateFont("ZM_HUDLarge", {
    font = "Arial",
    size = 28,
    weight = 800,
})

surface.CreateFont("ZM_HUDSmall", {
    font = "Arial",
    size = 16,
    weight = 600,
})
