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
        
        
        local searchClasses = {
            "\"classname\" \"npc_maker\"",
            "\"classname\" \"npc_zombie_maker\"",
            "\"classname\" \"npc_template_maker\""
        }
        
        local restoredCount = 0
        
        for _, searchStr in ipairs(searchClasses) do
            local startIdx = 1
            while true do
                startIdx = string.find(bspData, searchStr, startIdx, true)
                if not startIdx then break end
                
                local blockStart = string.find(string.reverse(string.sub(bspData, 1, startIdx)), "{", 1, true)
                blockStart = blockStart and (startIdx - blockStart) or (startIdx - 300)
                local blockEnd = string.find(bspData, "}", startIdx, true) or (startIdx + 500)
                
                local block = string.sub(bspData, blockStart, blockEnd)
                
                -- Extract properties
                local name = string.match(block, "\"targetname\"%s+\"([^\"]+)\"")
                local ox, oy, oz = string.match(block, "\"origin\"%s+\"([%-%d%.]+)%s+([%-%d%.]+)%s+([%-%d%.]+)\"")
                local ax, ay, az = string.match(block, "\"angles\"%s+\"([%-%d%.]+)%s+([%-%d%.]+)%s+([%-%d%.]+)\"")
                local npcType = string.match(block, "\"NPCType\"%s+\"([^\"]+)\"") or ""
                
                if name and ox and oy and oz then
                    local pos = Vector(tonumber(ox), tonumber(oy), tonumber(oz))
                    local ang = Angle(tonumber(ax) or 0, tonumber(ay) or 0, tonumber(az) or 0)
                    
                    local zmTypeId = "shambler"
                    if npcType == "npc_fastzombie" then zmTypeId = "banshee"
                    elseif npcType == "npc_poisonzombie" then zmTypeId = "hulk"
                    elseif npcType == "npc_headcrab_black" or npcType == "npc_headcrab_fast" then zmTypeId = "drifter"
                    elseif npcType == "npc_zombie" then zmTypeId = "shambler"
                    end
                    
                    local maxCount = string.match(block, "\"MaxNPCCount\"%s+\"([%d]+)\"") or "1"
                    
                    local exists = false
                    for _, ent in ipairs(ents.FindByName(name)) do
                        if IsValid(ent) and ent:GetClass() == "info_zombiespawn" then 
                            ent:Remove() 
                        end
                    end
                    
                    local sp = ents.Create("info_zombiespawn")
                        if IsValid(sp) then
                            sp:SetPos(pos)
                            sp:SetAngles(ang)
                            sp:SetName(name)
                            sp:SetKeyValue("rallyname", string.match(block, "\"NPCTargetname\"%s+\"([^\"]+)\"") or "")
                            sp:SetKeyValue("map_zombietype", zmTypeId)
                            sp:SetKeyValue("map_maxcount", maxCount)
                            sp:SetKeyValue("map_hidden", "1")
                            sp:Spawn()
                            
                            restoredCount = restoredCount + 1
                        end
                end
                
                startIdx = blockEnd
            end
        end
        
    -- print("====== ZM MAP RESTORER: Restored " .. restoredCount .. " makers! ======")
end

function ZM_TestMaker()
    print("====== BSP ENTITY DUMP 3 ======")
    local mapname = game.GetMap() 
    local bspData = file.Read("maps/" .. mapname .. ".bsp", "GAME")
    if not bspData then return print("No BSP") end
    
    local searchStr = "\"targetname\" \"crane_lift_relay\""
    local startIdx = 1
    local count = 0
    while count < 5 do
        startIdx = string.find(bspData, searchStr, startIdx, true)
        if not startIdx then break end
        
        local blockStart = string.find(string.reverse(string.sub(bspData, 1, startIdx)), "{", 1, true)
        blockStart = blockStart and (startIdx - blockStart) or (startIdx - 500)
        local blockEnd = string.find(bspData, "}", startIdx, true) or (startIdx + 500)
        
        local block = string.sub(bspData, blockStart, blockEnd)
        local name = string.match(block, "\"targetname\"%s+\"([^\"]+)\"") or "UNNAMED_TRAP"
        
        print("--- RELAY: " .. name .. " ---")
        print(block)
        print("-------------------")
        
        startIdx = blockEnd
        count = count + 1
    end
    print("====== END BSP ENTITY DUMP 3 ======")
end
