--[[
    Zombie Master Gamemode - Server Init
    Server-side only
]]

-- Send client files
AddCSLuaFile("shared.lua")
AddCSLuaFile("sh_zombietypes.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_zmhud.lua")
AddCSLuaFile("cl_teamselect.lua")
AddCSLuaFile("cl_scoreboard.lua")
AddCSLuaFile("cl_objectives.lua")

-- Load shared
include("shared.lua")

-- Load server-side systems
include("sv_round.lua")
include("sv_zm.lua")
include("sv_powers.lua")
include("sv_loadout.lua")
include("sv_objectives.lua")

--[[---------------------------------------------------------
    Gamemode Initialization
-----------------------------------------------------------]]
function GM:Initialize()
    print("=============================================")
    print("   ZOMBIE MASTER GAMEMODE LOADED")
    print("   The dead shall serve...")
    print("=============================================")

    -- Set up teams
    team.SetUp(TEAM_SURVIVORS, "Survivors", Color(60, 180, 60))
    team.SetUp(TEAM_ZM, "Zombie Master", Color(200, 30, 30))
    team.SetUp(TEAM_SPECTATOR, "Spectators", Color(150, 150, 150))
end

--[[---------------------------------------------------------
    Player Initial Spawn
-----------------------------------------------------------]]
function GM:PlayerInitialSpawn(ply)
    -- Start as unassigned, show team selection
    ply:SetTeam(TEAM_UNASSIGNED)
    ply.zmVolunteer = false
    ply.wasZMLastRound = false

    timer.Simple(1, function()
        if not IsValid(ply) then return end
        -- Open team selection menu
        net.Start("ZM_TeamSelect")
        net.Send(ply)
    end)
end

--[[---------------------------------------------------------
    Player Spawn
-----------------------------------------------------------]]
function GM:PlayerSpawn(ply)
    if ply:Team() == TEAM_ZM then
        -- ZM is set up separately
        return
    end

    if ply:Team() ~= TEAM_SURVIVORS then
        -- Spectator or unassigned
        ply:StripWeapons()
        ply:Spectate(OBS_MODE_ROAMING)
        return
    end

    ply:UnSpectate()

    -- Survivor setup
    ply:SetModel("models/player/group01/male_0" .. math.random(1, 9) .. ".mdl")
    ply:SetupHands()

    -- Give weapons
    ZM_GiveLoadout(ply)

    -- Set speed
    ply:SetWalkSpeed(200)
    ply:SetRunSpeed(300)
end

--[[---------------------------------------------------------
    Player Death
-----------------------------------------------------------]]
function GM:PlayerDeath(ply, inflictor, attacker)
    if ply:Team() == TEAM_ZM then
        -- ZM can't really die, but just in case
        return
    end

    ply.NextSpawnTime = CurTime() + 999 -- Don't respawn automatically during active round

    if ZM_GetRoundState() == ROUND_ACTIVE then
        ZM_NotifyAll(ply:Nick() .. " has been killed!", Color(255, 100, 100))

        -- Check round end
        timer.Simple(0.5, function()
            ZM_CheckRoundEnd()
        end)
    end
end

function GM:PlayerDeathThink(ply)
    -- Only allow respawn during waiting/post round or as spectator
    if ZM_GetRoundState() ~= ROUND_ACTIVE then
        if ply:KeyPressed(IN_ATTACK) or ply:KeyPressed(IN_JUMP) then
            ply:Spawn()
        end
    else
        -- During active round, dead survivors spectate
        if ply:Team() == TEAM_SURVIVORS then
            ply:Spectate(OBS_MODE_ROAMING)
        end
    end
end

--[[---------------------------------------------------------
    Player Loadout (suppress default)
-----------------------------------------------------------]]
function GM:PlayerLoadout(ply)
    -- Handled in PlayerSpawn
end

--[[---------------------------------------------------------
    Player Model (suppress default)
-----------------------------------------------------------]]
function GM:PlayerSetModel(ply)
    -- Handled in PlayerSpawn
end

--[[---------------------------------------------------------
    Disable sandbox features
-----------------------------------------------------------]]
function GM:PlayerSpawnSENT(ply, class) return false end
function GM:PlayerSpawnSWEP(ply, class) return false end
function GM:PlayerSpawnNPC(ply) return false end
function GM:PlayerSpawnVehicle(ply) return false end
function GM:PlayerSpawnProp(ply) return false end
function GM:PlayerSpawnEffect(ply) return false end
function GM:PlayerSpawnRagdoll(ply) return false end

--[[---------------------------------------------------------
    Weapon pickup control
-----------------------------------------------------------]]
function GM:PlayerCanPickupWeapon(ply, weapon)
    if ply:Team() == TEAM_ZM then return false end
    return true
end

--[[---------------------------------------------------------
    Fall damage
-----------------------------------------------------------]]
function GM:GetFallDamage(ply, speed)
    return speed / 8 -- Moderate fall damage
end

--[[---------------------------------------------------------
    Game Description
-----------------------------------------------------------]]
function GM:GetGameDescription()
    return "Zombie Master"
end

--[[---------------------------------------------------------
    Handle team joining from client
-----------------------------------------------------------]]
net.Receive("ZM_JoinTeam", function(len, ply)
    if not IsValid(ply) then return end

    local teamId = net.ReadUInt(4)

    if teamId == TEAM_SURVIVORS then
        ply:SetTeam(TEAM_SURVIVORS)
        ZM_Notify(ply, "You have joined the Survivors!", Color(60, 180, 60))

        if ZM_GetRoundState() == ROUND_ACTIVE then
            ply:Spawn()
            ZM_GiveLateJoinLoadout(ply)
        elseif ZM_GetRoundState() == ROUND_WAITING then
            ply:Spawn()
            ZM_CheckRoundStart()
        end

    elseif teamId == TEAM_ZM then
        -- Direct ZM join (for testing or single-player)
        -- Remove existing ZM if any
        local existingZM = ZM_GetZMPlayer()
        if IsValid(existingZM) and existingZM ~= ply then
            existingZM:SetTeam(TEAM_SURVIVORS)
            existingZM:Spawn()
            ZM_Notify(existingZM, "You have been replaced as Zombie Master!", Color(255, 100, 100))
        end

        ply:SetTeam(TEAM_ZM)
        ZM_SetupZMPlayer(ply)
        ZM_Notify(ply, "You are now the Zombie Master!", Color(255, 60, 60))

        -- Auto-start round if not active
        if ZM_GetRoundState() ~= ROUND_ACTIVE then
            ZM_SetRoundState(ROUND_ACTIVE)
            local roundTimer = CurTime() + ZM_CONFIG.ROUND_TIME
            net.Start("ZM_RoundTimer")
                net.WriteFloat(roundTimer)
            net.Broadcast()

            -- Start resource regen
            timer.Create("ZM_ResourceRegen", ZM_CONFIG.RESOURCE_REGEN_RATE, 0, function()
                if ZM_GetRoundState() ~= ROUND_ACTIVE then return end
                local zm = ZM_GetZMPlayer()
                if not IsValid(zm) then return end
                ZM_AddResources(zm, ZM_CONFIG.RESOURCE_REGEN)
            end)

            ZM_NotifyAll("Round started! " .. ply:Nick() .. " is the Zombie Master!", Color(255, 60, 60))

            -- Start a random mission
            timer.Simple(2, function()
                ZM_StartMission(nil)
            end)
        end

    elseif teamId == TEAM_SPECTATOR then
        ply:SetTeam(TEAM_SPECTATOR)
        ply:Spectate(OBS_MODE_ROAMING)
        ZM_Notify(ply, "You are now spectating.", Color(150, 150, 150))
    end
end)

--[[---------------------------------------------------------
    Player disconnect handling
-----------------------------------------------------------]]
function GM:PlayerDisconnected(ply)
    if ply:Team() == TEAM_ZM and ZM_GetRoundState() == ROUND_ACTIVE then
        -- ZM left, end round
        timer.Simple(0.5, function()
            ZM_CheckRoundEnd()
        end)
    end
end

--[[---------------------------------------------------------
    NPC relationships - make zombies attack survivors
-----------------------------------------------------------]]
hook.Add("OnEntityCreated", "ZM_NPCRelationships", function(ent)
    if IsValid(ent) and ent:IsNPC() then
        timer.Simple(0, function()
            if IsValid(ent) then
                ent:AddRelationship("player D_HT 99")
            end
        end)
    end
end)

--[[---------------------------------------------------------
    Prevent friendly fire between survivors
-----------------------------------------------------------]]
function GM:PlayerShouldTakeDamage(ply, attacker)
    if IsValid(attacker) and attacker:IsPlayer() then
        if ply:Team() == TEAM_SURVIVORS and attacker:Team() == TEAM_SURVIVORS then
            return false -- No friendly fire
        end
        if ply:Team() == TEAM_ZM then
            return false -- ZM is invulnerable
        end
    end
    return true
end
