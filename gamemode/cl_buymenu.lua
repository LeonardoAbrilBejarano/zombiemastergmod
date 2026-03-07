--[[
    Zombie Master - Client Side Buy Menu UI
]]

local plyBuyMenu = nil
local frameW, frameH = 800, 600

function ZM_OpenBuyMenu()
    if IsValid(plyBuyMenu) then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:Team() ~= TEAM_SURVIVORS then return end
    if not ply:Alive() then return end

    plyBuyMenu = vgui.Create("DFrame")
    plyBuyMenu:SetSize(frameW, frameH)
    plyBuyMenu:Center()
    plyBuyMenu:SetTitle("")
    plyBuyMenu:MakePopup()
    plyBuyMenu:ShowCloseButton(false)
    
    plyBuyMenu.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 35, 240))
        draw.RoundedBoxEx(8, 0, 0, w, 50, Color(45, 45, 50, 255), true, true, false, false)
        
        draw.SimpleText("SURVIVOR ARMORY", "Trebuchet24", 20, 25, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        local money = LocalPlayer():GetNWInt("ZM_Money", 0)
        draw.SimpleText("$" .. money, "Trebuchet24", w - 20, 25, Color(100, 255, 100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    
    local closeBtn = vgui.Create("DButton", plyBuyMenu)
    closeBtn:SetSize(40, 40)
    closeBtn:SetPos(frameW - 50, 5)
    closeBtn:SetText("X")
    closeBtn:SetFont("Trebuchet24")
    closeBtn:SetTextColor(Color(255, 100, 100))
    closeBtn.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(255, 100, 100, 50))
        end
    end
    closeBtn.DoClick = function()
        plyBuyMenu:Close()
    end
    
    -- Split into categories
    local categories = {}
    for _, w in ipairs(ZM_WEAPONS) do
        if w.price and w.price > 0 then
            categories[w.category] = categories[w.category] or {}
            table.insert(categories[w.category], w)
        end
    end
    
    local catPanel = vgui.Create("DPanel", plyBuyMenu)
    catPanel:SetSize(200, frameH - 70)
    catPanel:SetPos(20, 60)
    catPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 25, 200))
    end
    
    local itemsPanel = vgui.Create("DScrollPanel", plyBuyMenu)
    itemsPanel:SetSize(frameW - 250, frameH - 70)
    itemsPanel:SetPos(230, 60)
    
    local function populateItems(catName)
        itemsPanel:Clear()
        
        if not categories[catName] then return end
        
        local yPos = 0
        for _, w in ipairs(categories[catName]) do
            local itemCard = itemsPanel:Add("DPanel")
            itemCard:SetSize(itemsPanel:GetWide() - 20, 80)
            itemCard:SetPos(0, yPos)
            itemCard.weaponData = w
            
            itemCard.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 45, 200))
                
                local canAfford = LocalPlayer():GetNWInt("ZM_Money", 0) >= self.weaponData.price
                local col = canAfford and Color(255, 255, 255) or Color(150, 150, 150)
                local priceCol = canAfford and Color(100, 255, 100) or Color(255, 100, 100)
                
                draw.SimpleText(self.weaponData.name, "Trebuchet24", 15, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText("$" .. self.weaponData.price, "Trebuchet24", w - 150, h / 2, priceCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            
            local buyWeaponBtn = vgui.Create("DButton", itemCard)
            buyWeaponBtn:SetSize(100, 30)
            buyWeaponBtn:SetPos(itemCard:GetWide() - 110, 10)
            buyWeaponBtn:SetText("BUY WEAPON")
            buyWeaponBtn:SetTextColor(Color(255,255,255))
            buyWeaponBtn.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(60, 180, 60) or Color(40, 140, 40))
            end
            buyWeaponBtn.DoClick = function()
                net.Start("ZM_BuyItem")
                    net.WriteString(w.id)
                    net.WriteBool(false) -- not ammo only
                net.SendToServer()
                -- Don't close immediately so they can buy ammo
            end
            
            if w.ammo then
                local ammoPrice = math.Round(w.price * 0.25)
                local buyAmmoBtn = vgui.Create("DButton", itemCard)
                buyAmmoBtn:SetSize(100, 30)
                buyAmmoBtn:SetPos(itemCard:GetWide() - 110, 45)
                buyAmmoBtn:SetText("BUY AMMO ($" .. ammoPrice .. ")")
                buyAmmoBtn:SetTextColor(Color(255,255,255))
                buyAmmoBtn.Paint = function(self, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(60, 100, 180) or Color(40, 80, 140))
                end
                buyAmmoBtn.DoClick = function()
                    net.Start("ZM_BuyItem")
                        net.WriteString(w.id)
                        net.WriteBool(true) -- ammo only
                    net.SendToServer()
                end
            end
            
            yPos = yPos + 85
        end
    end
    
    local yPos = 10
    
    local sortedCats = {}
    for catName, _ in pairs(categories) do
        table.insert(sortedCats, catName)
    end
    table.sort(sortedCats)
    
    local firstCat = nil
    for _, catName in ipairs(sortedCats) do
        if not firstCat then firstCat = catName end
        
        local catBtn = vgui.Create("DButton", catPanel)
        catBtn:SetSize(180, 40)
        catBtn:SetPos(10, yPos)
        catBtn:SetText(catName)
        catBtn:SetFont("Trebuchet24")
        catBtn:SetTextColor(Color(200, 200, 200))
        catBtn.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(60, 60, 70) or Color(40, 40, 45))
        end
        catBtn.DoClick = function()
            populateItems(catName)
        end
        
        yPos = yPos + 45
    end
    
    if firstCat then
        populateItems(firstCat)
    end
end

-- Create the custom console command
concommand.Add("zm_buymenu", function(ply, cmd, args)
    ZM_OpenBuyMenu()
end)

-- Bind "B" key for buy menu intercepting normal game loop hooks isn't robust,
-- Better to hook PlayerBindPress
hook.Add("PlayerBindPress", "ZM_BuyMenuBind", function(ply, bind, pressed)
    if not pressed then return end
    if bind:find("gm_showspare1") then -- F3
        RunConsoleCommand("zm_buymenu")
        return true
    elseif bind:find("slot") or bind:find("menu") then
        -- You could optionally map standard B key if needed,
        -- but many users type B in chat etc.
        -- Often better to use F3 or bind "b" "zm_buymenu" in console explicitly.
    end
end)
