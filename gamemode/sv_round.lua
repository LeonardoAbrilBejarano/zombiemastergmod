--[[
    Zombie Master - Round System
    Server-side round state machine
]]

local roundState = ROUND_WAITING
local roundTimer = 0
local roundHadZM = false
local zmVolunteers = {}

-- Get current round state
function ZM_GetRoundState()
    return roundState
end

-- Set round state and notify all clients
function ZM_SetRoundState(state)
    roundState = state
    net.Start("ZM_RoundState")
        net.WriteUInt(state, 4)
    net.Broadcast()
end

-- Notify a player
function ZM_Notify(ply, msg, col)
    col = col or Color(255, 255, 255)
    net.Start("ZM_Notification")
        net.WriteString(msg)
        net.WriteColor(col)
    net.Send(ply)
end

-- Notify all players
function ZM_NotifyAll(msg, col)
    col = col or Color(255, 255, 255)
    net.Start("ZM_Notification")
        net.WriteString(msg)
        net.WriteColor(col)
    net.Broadcast()
end

-- Count players on a team
function ZM_CountTeam(teamId)
    local count = 0
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == teamId then count = count + 1 end
    end
    return count
end

-- Get ZM player
function ZM_GetZMPlayer()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_ZM then return ply end
    end
    return nil
end

-- Select the Zombie Master
function ZM_SelectZM()
    local eligible_players = 0
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() ~= TEAM_SPECTATOR and ply:Team() ~= TEAM_UNASSIGNED then
            eligible_players = eligible_players + 1
        end
    end

    -- If there's less than 2 players, allow them to play solo as Survivor without forcing ZM
    if eligible_players < 2 then
        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() == TEAM_ZM then return ply end
        end
        return nil
    end

    local candidates = {}

    -- Check volunteers first
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SURVIVORS or ply:Team() == TEAM_UNASSIGNED then
            if ply.zmVolunteer then
                table.insert(candidates, ply)
            end
        end
    end

    -- If no volunteers, pick from all eligible players
    if #candidates == 0 then
        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() == TEAM_SURVIVORS or ply:Team() == TEAM_UNASSIGNED then
                -- Prefer players who haven't been ZM recently
                if not ply.wasZMLastRound then
                    table.insert(candidates, ply)
                end
            end
        end
    end

    -- Absolute fallback
    if #candidates == 0 then
        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() ~= TEAM_SPECTATOR then
                table.insert(candidates, ply)
            end
        end
    end

    if #candidates == 0 then return nil end

    return candidates[math.random(#candidates)]
end

-- Start a new round
function ZM_StartRound()
    -- Remove all NPCs from previous round
    for _, npc in ipairs(ents.FindByClass("npc_*")) do
        if IsValid(npc) then npc:Remove() end
    end

    -- Reset all spawn points
    ZM_ResetSpawnPoints()

    -- Select ZM
    local zmPlayer = ZM_SelectZM()
    
    local activePlayers = 0
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() ~= TEAM_SPECTATOR and ply:Team() ~= TEAM_UNASSIGNED then
            activePlayers = activePlayers + 1
        end
    end
    
    if activePlayers == 0 then
        ZM_NotifyAll("Not enough players to start a round!", Color(255, 100, 100))
        return
    end

    -- Mark previous ZM
    for _, ply in ipairs(player.GetAll()) do
        ply.wasZMLastRound = (ply:Team() == TEAM_ZM)
    end

    -- Assign teams
    for _, ply in ipairs(player.GetAll()) do
        if ply == zmPlayer then
            ply:SetTeam(TEAM_ZM)
            ZM_SetupZMPlayer(ply)
        elseif ply:Team() ~= TEAM_SPECTATOR then
            ply:SetTeam(TEAM_SURVIVORS)
            ply:Spawn()
        end
    end

    -- Start round
    ZM_SetRoundState(ROUND_ACTIVE)
    roundTimer = CurTime() + ZM_CONFIG.ROUND_TIME

    -- Broadcast round timer
    net.Start("ZM_RoundTimer")
        net.WriteFloat(roundTimer)
    net.Broadcast()

    if IsValid(zmPlayer) then
        roundHadZM = true
        ZM_NotifyAll("Round started! " .. zmPlayer:Nick() .. " is the Zombie Master!", Color(255, 60, 60))
        
        -- Start resource regeneration
        timer.Create("ZM_ResourceRegen", ZM_CONFIG.RESOURCE_REGEN_RATE, 0, function()
            if ZM_GetRoundState() ~= ROUND_ACTIVE then return end
            local zm = ZM_GetZMPlayer()
            if not IsValid(zm) then return end
            ZM_AddResources(zm, ZM_CONFIG.RESOURCE_REGEN)
        end)
    else
        roundHadZM = false
        ZM_NotifyAll("Round started! No Zombie Master present, survive against the horde!", Color(60, 255, 60))
    end

    -- Start a random mission
    timer.Simple(2, function()
        ZM_StartMission(nil) -- nil = random mission
    end)
end

-- End the round
function ZM_EndRound(zmWins, reason)
    if ZM_GetRoundState() ~= ROUND_ACTIVE then return end

    ZM_SetRoundState(ROUND_POST)
    timer.Remove("ZM_ResourceRegen")

    -- Clean up mission entities
    ZM_CleanupMission()

    if zmWins then
        ZM_NotifyAll("The Zombie Master wins! " .. (reason or "All survivors are dead!"), Color(255, 60, 60))
        -- Give ZM score
        local zm = ZM_GetZMPlayer()
        if IsValid(zm) then
            zm:AddFrags(50)
        end
    else
        ZM_NotifyAll("The survivors have prevailed! " .. (reason or ""), Color(60, 255, 60))
        -- Give survivors score
        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() == TEAM_SURVIVORS and ply:Alive() then
                ply:AddFrags(50)
            end
        end
    end

    -- Schedule next round
    timer.Simple(ZM_CONFIG.ROUND_POST_TIME, function()
        ZM_SetRoundState(ROUND_WAITING)
        ZM_CheckRoundStart()
    end)
end

-- Check if we should start a round (enough players)
function ZM_CheckRoundStart()
    if ZM_GetRoundState() ~= ROUND_WAITING then return end

    local totalPlayers = 0
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() ~= TEAM_SPECTATOR then
            totalPlayers = totalPlayers + 1
        end
    end

    if totalPlayers >= ZM_CONFIG.MIN_PLAYERS then
        ZM_NotifyAll("Round starting in " .. ZM_CONFIG.ROUND_WAIT_TIME .. " seconds!", Color(255, 220, 50))
        timer.Create("ZM_RoundCountdown", ZM_CONFIG.ROUND_WAIT_TIME, 1, function()
            if ZM_GetRoundState() == ROUND_WAITING then
                ZM_StartRound()
            end
        end)
    end
end

-- Check for round end conditions
function ZM_CheckRoundEnd()
    if ZM_GetRoundState() ~= ROUND_ACTIVE then return end

    -- Check if ZM disconnected
    local zm = ZM_GetZMPlayer()
    if not IsValid(zm) and roundHadZM then
        ZM_EndRound(false, "The Zombie Master has left!")
        return
    end

    -- Check if all survivors are dead
    local aliveSurvivors = 0
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SURVIVORS and ply:Alive() then
            aliveSurvivors = aliveSurvivors + 1
        end
    end

    if aliveSurvivors == 0 and ZM_CountTeam(TEAM_SURVIVORS) > 0 then
        ZM_EndRound(true, "All survivors are dead!")
        return
    end

    -- Check round time
    if CurTime() > roundTimer then
        ZM_EndRound(true, "Time has run out!")
        return
    end
end

-- Periodic round check
timer.Create("ZM_RoundCheck", 1, 0, function()
    ZM_CheckRoundEnd()
end)

-- Volunteer to be ZM
net.Receive("ZM_VolunteerZM", function(len, ply)
    if not IsValid(ply) then return end
    ply.zmVolunteer = not ply.zmVolunteer
    if ply.zmVolunteer then
        ZM_Notify(ply, "You have volunteered to be the Zombie Master!", Color(255, 200, 50))
    else
        ZM_Notify(ply, "You are no longer volunteering as Zombie Master.", Color(200, 200, 200))
    end
end)
