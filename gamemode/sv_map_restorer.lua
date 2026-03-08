--[[
    Zombie Master - Map Entity Restorer
    Garry's Mod automatically deletes Half-Life 2 NPC spawners (npc_template_maker, npc_zombie_maker) 
    in multiplayer. Zombie Master maps heavily rely on these to spawn zombies from traps.
    This script intercepts the map loading process to replace or preserve them.
]]

-- We can't stop GMod from deleting them internally during map load, 
-- but we CAN read the BSP data (like we did in the dumper) and manually spawn
-- our own info_zombiespawn entities in their exact places with their exact names!

function ZM_RunMapRestorer()
    local mapname = game.GetMap() 
        local bspData = file.Read("maps/" .. mapname .. ".bsp", "GAME")
        if not bspData then bspData = file.Read("maps/" .. mapname .. ".bsp", "MOD") end
        if not bspData then bspData = file.Read("maps/" .. mapname .. ".bsp", "DOWNLOAD") end
        if not bspData then
            local files = file.Find("maps/" .. mapname .. "*", "GAME")
            if #files > 0 then bspData = file.Read("maps/" .. files[1], "GAME") end
        end

        if not bspData then return end
        
        print("====== ZM MAP RESTORER: Scanning for purged HL2 Makers ======")
        
        local searchStr = "\"classname\" \"npc_zombie_maker\""
        local startIdx = 1
        local restoredCount = 0
        
        while true do
            startIdx = string.find(bspData, searchStr, startIdx, true)
            if not startIdx then break end
            
            local blockStart = string.find(string.reverse(string.sub(bspData, 1, startIdx)), "{", 1, true)
            blockStart = blockStart and (startIdx - blockStart) or (startIdx - 300)
            local blockEnd = string.find(bspData, "}", startIdx, true) or (startIdx + 300)
            
            local block = string.sub(bspData, blockStart, blockEnd)
            
            -- Extract Name
            local name = string.match(block, "\"targetname\"%s+\"([^\"]+)\"")
            -- Extract Origin
            local ox, oy, oz = string.match(block, "\"origin\"%s+\"([%-%d%.]+)%s+([%-%d%.]+)%s+([%-%d%.]+)\"")
            -- Extract Angles
            local ax, ay, az = string.match(block, "\"angles\"%s+\"([%-%d%.]+)%s+([%-%d%.]+)%s+([%-%d%.]+)\"")
            
            if name and ox and oy and oz then
                local pos = Vector(tonumber(ox), tonumber(oy), tonumber(oz))
                local ang = Angle(tonumber(ax) or 0, tonumber(ay) or 0, tonumber(az) or 0)
                
                -- Check if it already exists (unlikely, but safe)
                local exists = false
                for _, ent in ipairs(ents.FindByName(name)) do
                    if IsValid(ent) then exists = true break end
                end
                
                if not exists then
                    -- Create our own spawn point as a replacement!
                    local sp = ents.Create("info_zombiespawn")
                    if IsValid(sp) then
                        sp:SetPos(pos)
                        sp:SetAngles(ang)
                        sp:SetName(name)
                        sp:SetKeyValue("rallyname", string.match(block, "\"NPCTargetname\"%s+\"([^\"]+)\"") or "")
                        sp:Spawn()
                        
                        -- Hide them from the ZM until triggered? No, ZM spawns are normally visible.
                        -- But since these are triggered by traps, maybe we shouldn't draw the red sphere?
                        -- For now, keep it visible so we know our restorer worked.
                        restoredCount = restoredCount + 1
                        print("RESTORED purged maker: " .. name .. " at " .. tostring(pos))
                    end
                end
            end
            
            startIdx = blockEnd
        end
        
    
    print("====== ZM MAP RESTORER: Restored " .. restoredCount .. " makers! ======")
end
