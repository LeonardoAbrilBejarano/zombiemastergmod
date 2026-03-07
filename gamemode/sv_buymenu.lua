--[[
    Zombie Master - Server Side Buy Menu System
    Handles purchasing weapons and networking money
]]

-- Give money on kill
hook.Add("OnNPCKilled", "ZM_Economy_KillReward", function(npc, attacker, inflictor)
    if IsValid(attacker) and attacker:IsPlayer() and attacker:Team() == TEAM_SURVIVORS then
        -- Optional: specific reward per zombie type, but for now just general reward
        local current = attacker:GetNWInt("ZM_Money", 0)
        attacker:SetNWInt("ZM_Money", current + ZM_CONFIG.KILL_REWARD)
        
        -- Flash on client
        net.Start("ZM_Notification")
            net.WriteString("+$" .. ZM_CONFIG.KILL_REWARD)
            net.WriteColor(Color(100, 255, 100))
        net.Send(attacker)
    end
end)

-- Process buy requests from the client
net.Receive("ZM_BuyItem", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_SURVIVORS then return end
    if not ply:Alive() then return end

    local weaponId = net.ReadString()
    local isAmmoOnly = net.ReadBool()
    
    local weaponData = nil
    for _, w in ipairs(ZM_WEAPONS) do
        if w.id == weaponId then
            weaponData = w
            break
        end
    end
    
    if not weaponData then return end
    
    local price = weaponData.price or 0
    if isAmmoOnly then
        price = math.Round(price * 0.25) -- Ammo costs 25% of weapon price
    end
    
    local currentMoney = ply:GetNWInt("ZM_Money", 0)
    
    if currentMoney >= price then
        -- Deduct money
        ply:SetNWInt("ZM_Money", currentMoney - price)
        
        if isAmmoOnly then
            if weaponData.ammo then
                ply:GiveAmmo(weaponData.ammoCount or 30, weaponData.ammo, false)
                ZM_Notify(ply, "Purchased ammo for $" .. price, Color(100, 255, 100))
            end
        else
            if ply:HasWeapon(weaponId) then
                ZM_Notify(ply, "You already have this weapon!", Color(255, 100, 100))
                -- Refund
                ply:SetNWInt("ZM_Money", currentMoney)
            else
                local wepTbl = weapons.Get(weaponId) or weapons.GetStored(weaponId)
                local newSlot = wepTbl and wepTbl.Slot or 2 -- Assume primary if unknown
                local isMelee = (weaponData.category == "Cuerpo a cuerpo")
                
                if not isMelee then
                    -- Strip existing weapon in the same slot
                    for _, wep in ipairs(ply:GetWeapons()) do
                        local wClass = wep:GetClass()
                        if wClass ~= "weapon_crowbar" and wClass ~= "weapon_physcannon" then
                            local oldWepTbl = weapons.Get(wClass) or weapons.GetStored(wClass)
                            local oldSlot = oldWepTbl and oldWepTbl.Slot or 2
                            
                            -- Slot <= 1 means pistol, Slot >= 2 means primary rifle/shotgun etc
                            if (newSlot <= 1 and oldSlot <= 1) or (newSlot > 1 and oldSlot > 1) then
                                ply:StripWeapon(wClass)
                            end
                        end
                    end
                end
                
                local newWep = ply:Give(weaponId)
                if IsValid(newWep) then
                    ply:SetAmmo(0, newWep:GetPrimaryAmmoType())
                end
                
                ZM_Notify(ply, "Purchased " .. weaponData.name .. " for $" .. price, Color(100, 255, 100))
            end
        end
    else
        ZM_Notify(ply, "Not enough money! Need $" .. price, Color(255, 100, 100))
    end
end)

-- Hook F3 (ShowSpare1) to open the buy menu
hook.Add("ShowSpare1", "ZM_OpenBuyMenu_F3", function(ply)
    if IsValid(ply) and ply:Team() == TEAM_SURVIVORS then
        ply:ConCommand("zm_buymenu")
    end
end)
