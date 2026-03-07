--[[
    Zombie Master - Map Vote System
    Server-side: logic for tracking votes, timers, and changing map
]]

util.AddNetworkString("ZM_OpenMapVote")
util.AddNetworkString("ZM_VoteMap")
util.AddNetworkString("ZM_MapVoteTimer")
util.AddNetworkString("ZM_MapVoteUpdate")

ZM_MapVote = ZM_MapVote or {}
ZM_MapVote.Active = false
ZM_MapVote.EndTime = 0
ZM_MapVote.Votes = {} -- Player = MapName
ZM_MapVote.Maps = {
    "zm_docksoftthedead",
    "hns_mallparking_short"
}
ZM_MapVote.DURATION = 60 -- seconds

-- Let client request to open map vote menu
net.Receive("ZM_OpenMapVote", function(len, ply)
    ZM_SendMapVote(ply)
end)

function ZM_SendMapVote(ply)
    net.Start("ZM_OpenMapVote")
        net.WriteTable(ZM_MapVote.Maps)
        net.WriteTable(ZM_MapVote.Votes)
        if ZM_MapVote.Active then
            net.WriteFloat(ZM_MapVote.EndTime)
        else
            net.WriteFloat(0)
        end
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

-- Handle vote
net.Receive("ZM_VoteMap", function(len, ply)
    local mapIndex = net.ReadUInt(8)
    local mapName = ZM_MapVote.Maps[mapIndex]
    
    if not mapName then return end

    ZM_MapVote.Votes[ply] = mapName
    
    ZM_NotifyAll(ply:Nick() .. " voted for " .. mapName, Color(100, 200, 255))
    
    -- Tell clients about the updated vote counts
    net.Start("ZM_MapVoteUpdate")
        net.WriteTable(ZM_MapVote.Votes)
    net.Broadcast()

    ZM_CheckMapVotes()
end)

function ZM_CheckMapVotes()
    local totalPlayers = #player.GetAll()
    if totalPlayers == 0 then return end
    
    local totalVotes = 0
    for ply, mapName in pairs(ZM_MapVote.Votes) do
        if IsValid(ply) then
            totalVotes = totalVotes + 1
        else
            ZM_MapVote.Votes[ply] = nil -- cleanup disconnected players
        end
    end
    
    local threshold = math.ceil(totalPlayers / 2)
    
    if totalVotes >= threshold and not ZM_MapVote.Active then
        ZM_StartMapVoteTimer()
    end
end

function ZM_StartMapVoteTimer()
    if ZM_MapVote.Active then return end
    
    ZM_MapVote.Active = true
    ZM_MapVote.EndTime = CurTime() + ZM_MapVote.DURATION
    
    ZM_NotifyAll("Map vote threshold reached! Map changes in " .. ZM_MapVote.DURATION .. " seconds.", Color(255, 200, 50))
    
    net.Start("ZM_MapVoteTimer")
        net.WriteFloat(ZM_MapVote.EndTime)
    net.Broadcast()
    
    timer.Create("ZM_MapVoteEndTimer", ZM_MapVote.DURATION, 1, function()
        ZM_EndMapVote()
    end)
end

function ZM_EndMapVote()
    ZM_MapVote.Active = false
    
    local mapCounts = {}
    for _, map in ipairs(ZM_MapVote.Maps) do
        mapCounts[map] = 0
    end
    
    for ply, mapName in pairs(ZM_MapVote.Votes) do
        if IsValid(ply) and mapCounts[mapName] ~= nil then
            mapCounts[mapName] = mapCounts[mapName] + 1
        end
    end
    
    local bestMap = ZM_MapVote.Maps[1]
    local bestVotes = -1
    
    for mapName, votes in pairs(mapCounts) do
        if votes > bestVotes then
            bestVotes = votes
            bestMap = mapName
        end
    end
    
    ZM_NotifyAll("Vote ended! Changing map to " .. bestMap .. "...", Color(50, 255, 50))
    
    timer.Simple(3, function()
        RunConsoleCommand("changelevel", bestMap)
    end)
end

-- Cleanup votes on disconnect
hook.Add("PlayerDisconnected", "ZM_MapVoteCleanup", function(ply)
    if ZM_MapVote.Votes[ply] then
        ZM_MapVote.Votes[ply] = nil
        net.Start("ZM_MapVoteUpdate")
            net.WriteTable(ZM_MapVote.Votes)
        net.Broadcast()
        ZM_CheckMapVotes()
    end
end)
