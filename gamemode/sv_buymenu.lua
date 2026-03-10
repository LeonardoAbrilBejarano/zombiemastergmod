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

-- helper to convert ammo type names to numeric IDs
local function normalizeAmmoType(at)
    if type(at) == "string" then
        -- game.GetAmmoID returns 0 for unknown names
        return game.GetAmmoID(at)
    else
        return at or 0
    end
end

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
                local amt = weaponData.ammoCount or 30
                ply:GiveAmmo(amt, weaponData.ammo, false)
                -- clamp after giving in case the player already had excess
                local at = normalizeAmmoType(weaponData.ammo)
                local clip = getClipSizeFor(ply, at)
                if clip and clip > 0 then
                    local cur = ply:GetAmmoCount(at)
                    local maxRes = clip * 2
                    if cur > maxRes then
                        ply:SetAmmo(maxRes, at)
                    end
                end
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

-- ===== Ammo capacity enforcement utilities =====

local function ammoName(ammoType)
    if type(ammoType) == "number" then
        return game.GetAmmoName(ammoType)
    else
        return tostring(ammoType)
    end
end

local function getClipSizeFor(ply, ammoType)
    -- returns the clip size for the first weapon on the player that uses the
    -- given ammo type (numeric ID). 0 means "no weapon uses this ammo", which
    -- callers treat as no cap.  This never returns nil so arithmetic is safe.
    if not IsValid(ply) then return 0 end
    ammoType = normalizeAmmoType(ammoType)
    if ammoType <= 0 then return 0 end
    for _, wep in ipairs(ply:GetWeapons()) do
        if IsValid(wep) then
            if wep:GetPrimaryAmmoType() == ammoType then
                return wep:GetMaxClip1() or 0
            end
            if wep:GetSecondaryAmmoType() == ammoType then
                return wep:GetMaxClip2() or 0
            end
        end
    end
    return 0
end

-- clamp reserves on spawn/respawn just in case
hook.Add("PlayerSpawn", "ZM_ClampAmmoOnSpawn", function(ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_SURVIVORS then return end
    for _, wep in ipairs(ply:GetWeapons()) do
        if IsValid(wep) then
            local at = wep:GetPrimaryAmmoType()
            if at then
                local clip = getClipSizeFor(ply, at)
                if clip and clip > 0 then
                    local cur = ply:GetAmmoCount(at)
                    local maxRes = clip * 2
                    if cur > maxRes then
                        ply:SetAmmo(maxRes, at)
                    end
                end
            end
        end
    end
end)

-- also clamp when the player is given a weapon mid-round (e.g. bought)
hook.Add("PlayerGiveSWEP","ZM_ClampAmmoOnEquip",function(ply,class)
    if not IsValid(ply) or ply:Team() ~= TEAM_SURVIVORS then return end
    local wep = ply:GetWeapon(class)
    if not IsValid(wep) then return end
    local at = wep:GetPrimaryAmmoType()
    if at then
        local clip = getClipSizeFor(ply, at)
        if clip and clip > 0 then
            local cur = ply:GetAmmoCount(at)
            local maxRes = clip * 2
            if cur > maxRes then
                ply:SetAmmo(maxRes, at)
            end
        end
    end
end)

-- PlayerCanPickup hooks as additional prevention
hook.Add("PlayerCanPickupAmmo", "ZM_AmmoCapPickup", function(ply, ammoType, amount)
    if not IsValid(ply) or ply:Team() ~= TEAM_SURVIVORS then return end
    local clip = getClipSizeFor(ply, ammoType)
    if not clip or clip <= 0 then
        -- no weapon uses this ammo, no cap enforced
        return
    end
    local current = ply:GetAmmoCount(ammoType)
    local maxRes = clip * 2
    if current >= maxRes then
        ply.ZM_LastDeniedAmmo = {pos = ply:GetEyeTrace().HitPos, type = ammoType, amt = amount, time = CurTime()}
        return false
    end
    -- if excess would push us over, allow but let GiveAmmo trim it
end)

hook.Add("PlayerCanPickupItem", "ZM_AmmoEntityCap", function(ply, ent)
    if not IsValid(ply) or ply:Team() ~= TEAM_SURVIVORS or not IsValid(ent) then return end
    local cls = ent:GetClass()
    if string.find(cls:lower(), "ammo") then
        -- some non-ammo entities have "ammo" in their class name; only
        -- query GetAmmoType() when the method actually exists and is a
        -- function to avoid nil-value calls.
        local ammoType = ent.AmmoType
        if not ammoType and ent.GetAmmoType and type(ent.GetAmmoType) == "function" then
            ammoType = ent:GetAmmoType()
        end
        ammoType = ammoType or 0

        local clip = getClipSizeFor(ply, ammoType)
        if not clip or clip <= 0 then
            -- no weapon uses this ammo type; don't interfere
            return
        end
        local current = ply:GetAmmoCount(ammoType)
        local maxRes = clip * 2
        if current >= maxRes then
            return false
        end
    end
end)

-- global GiveAmmo/SetAmmo overrides to intercept any script or pickup
do
    local playerMeta = FindMetaTable("Player")
    if playerMeta and not playerMeta.ZM_GiveAmmoPatched then
        playerMeta.ZM_GiveAmmoPatched = true
        local realGA = playerMeta.GiveAmmo
        function playerMeta:GiveAmmo(amount, ammoType, hidePopup)
            if amount <= 0 then return 0 end
            local clip = getClipSizeFor(self, ammoType)
            if not clip or clip <= 0 then
                -- unknown ammo type; just forward to original
                return realGA(self, amount, ammoType, hidePopup)
            end
            local current = self:GetAmmoCount(ammoType)
            local maxRes = clip * 2
            -- clamp downward if somehow we're already over max
            if current > maxRes then
                -- use original SetAmmo to avoid recursion
                realSA(self, maxRes, ammoType)
                current = maxRes
            end
            if current >= maxRes then
                ZM_Notify(self, "Reserve full (" .. maxRes .. ")", Color(255,100,100))
                local tr = self:GetEyeTrace()
                self.ZM_LastDeniedAmmo = {pos = tr.HitPos, type = ammoType, amt = amount, time = CurTime()}
                return 0
            end
            if current + amount > maxRes then
                amount = maxRes - current
            end
            return realGA(self, amount, ammoType, hidePopup)
        end
    end

    if playerMeta and not playerMeta.ZM_SetAmmoPatched then
        playerMeta.ZM_SetAmmoPatched = true
        local realSA = playerMeta.SetAmmo
        function playerMeta:SetAmmo(amount, ammoType)
            if amount <= 0 then return realSA(self, amount, ammoType) end
            local clip = getClipSizeFor(self, ammoType)
            if not clip or clip <= 0 then
                return realSA(self, amount, ammoType)
            end
            local current = self:GetAmmoCount(ammoType)
            local maxRes = clip * 2
            if current > maxRes then
                realSA(self, maxRes, ammoType)
                current = maxRes
            end
            if current >= maxRes then
                ZM_Notify(self, "Reserve full (" .. maxRes .. ")", Color(255,100,100))
                local tr = self:GetEyeTrace()
                self.ZM_LastDeniedAmmo = {pos = tr.HitPos, type = ammoType, amt = amount, time = CurTime()}
                return 0
            end
            if current + amount > maxRes then
                amount = maxRes - current
            end
            return realSA(self, amount, ammoType)
        end
    end
end

-- take control of ammo entity touches
local function overrideTouch(self, activator)
    if not IsValid(activator) or not activator:IsPlayer() or activator:Team() ~= TEAM_SURVIVORS then
        if self.ZM_OriginalTouch then
            self:ZM_OriginalTouch(activator)
        end
        return
    end

    -- determine ammo type/amount safely
    local ammoType = self.AmmoType or (self.GetAmmoType and self:GetAmmoType()) or 0
    local amount = self.AmmoAmount or (self.GetAmmoAmount and self:GetAmmoAmount()) or 0

    local clip = getClipSizeFor(activator, ammoType)
    if not clip or clip <= 0 then
        -- no appropriate weapon; use original behaviour
        if self.ZM_OriginalTouch then
            self:ZM_OriginalTouch(activator)
        end
        return
    end

    local current = activator:GetAmmoCount(ammoType)
    local maxRes = clip * 2

    if current >= maxRes then
        -- already full: respawn crate if recently denied
        local data = activator.ZM_LastDeniedAmmo
        if data and data.type == ammoType and data.time + 1 > CurTime() then
            timer.Simple(0, function()
                if IsValid(self) then
                    local new = ents.Create(self:GetClass())
                    if IsValid(new) then
                        new:SetPos(self:GetPos())
                        new:Spawn()
                    end
                end
            end)
        end
        return
    end

    -- compute how much we can give without overflowing
    local giveAmt = amount
    if current + amount > maxRes then
        giveAmt = maxRes - current
    end

    if giveAmt > 0 then
        activator:GiveAmmo(giveAmt, ammoType)
    end

    -- remove the crate ourselves to avoid originalTouch giving more
    if IsValid(self) then
        self:Remove()
    end
end

local function PatchAmmoEnt(ent)
    if not IsValid(ent) or ent.ZMHooked then return end
    if not ent:GetClass():lower():find("ammo") then return end

    ent.ZMHooked = true
    ent.ZM_OriginalTouch = ent.Touch
    ent.Touch = overrideTouch
end

local function PatchAmmoClass(cls)
    local stored = scripted_ents.GetStored(cls)
    if stored and stored.t and not stored.t.ZM_ClassPatched and stored.t.Touch then
        stored.t.ZM_ClassPatched = true
        stored.t.ZM_OriginalTouch = stored.t.Touch
        stored.t.Touch = function(self, activator)
            overrideTouch(self, activator)
        end
    end
end

-- patch existing ammo classes on startup
for _, v in pairs(scripted_ents.GetList()) do
    if v.t and v.t.ClassName and string.find(v.t.ClassName:lower(), "ammo") then
        PatchAmmoClass(v.t.ClassName)
    end
end

-- ensure future ammo entities are hooked
hook.Add("OnEntityCreated", "ZM_PatchAmmoTouch", function(ent)
    if IsValid(ent) then
        PatchAmmoEnt(ent)
    end
end)

-- periodic enforcement as a safety net
hook.Add("Think", "ZM_EnforceAmmoCap", function()
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or ply:Team() ~= TEAM_SURVIVORS then
            -- skip invalid/non-survivor players
        else
            for _, wep in ipairs(ply:GetWeapons()) do
                if IsValid(wep) then
                    local at = wep:GetPrimaryAmmoType()
                    if at then
                        local clip = getClipSizeFor(ply, at)
                        if clip and clip > 0 then
                            local cur = ply:GetAmmoCount(at)
                            local maxRes = clip * 2
                            if cur > maxRes then
                                ply:SetAmmo(maxRes, at)
                            end
                        end
                    end
                end
            end
        end
    end
end)
