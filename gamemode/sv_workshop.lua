--[[
    Zombie Master - Workshop & Downloads
    Forces clients to download server dependencies
]]

if not SERVER then return end

-- EFT Collection Assets (Option B: Individual Addons)
-- Base & Shared
resource.AddWorkshop("2910505837") -- ARC9 Weapon Base
resource.AddWorkshop("2917343547") -- [ARC9] Escape from Tarkov SHARED

-- EFT Weapons
resource.AddWorkshop("2919110631") -- [ARC9] EFT Pistols
resource.AddWorkshop("2917344450") -- [ARC9] EFT Submachine Guns
resource.AddWorkshop("2922999549") -- [ARC9] EFT Shotguns
resource.AddWorkshop("2962829818") -- [ARC9] EFT Assault Rifles
resource.AddWorkshop("2924902340") -- [ARC9] EFT Sniper Rifles
resource.AddWorkshop("2976665920") -- [ARC9] EFT Marksman Rifles
resource.AddWorkshop("2950907061") -- [ARC9] EFT Machine Guns
resource.AddWorkshop("3010049092") -- [ARC9] EFT Explosives
resource.AddWorkshop("3012983285") -- [ARC9] EFT Melee Pack

-- Extras
resource.AddWorkshop("3432143677") -- [ARC9] EFT Special Useless Items
resource.AddWorkshop("2925285789") -- [ARC9] EFT Slickers Attachment
resource.AddWorkshop("2965318829") -- [ARC9] EFT Extras
resource.AddWorkshop("3653148203") -- [ARC9] WTT CZ Scorpion EVO 3


-- Tu addon de texturas, modelos y sonidos de Zombie Master
-- https://steamcommunity.com/sharedfiles/filedetails/?id=3681277326
resource.AddWorkshop("3681277326")

-- Set server to allow client downloads if not set
RunConsoleCommand("sv_allowdownload", "0")
RunConsoleCommand("sv_allowupload", "1")


