if not IsAddOnLoaded("Blizzard_InspectUI") then
    LoadAddOn("Blizzard_InspectUI")
end

local Test = true
local fontPath = "Fonts\\FRIZQT__.TTF"  -- Standard WoW font
local fontSize = 11  -- Adjust the font size as needed
local globalScale = 1.7

local itemTypeInfo = {
    ["INVTYPE_RELIC"] = {0.3164, false},
    ["INVTYPE_TRINKET"] = {0.5625, false},
    ["INVTYPE_2HWEAPON"] = {2.000, true},
    ["INVTYPE_WEAPONMAINHAND"] = {1.0000, true},
    ["INVTYPE_WEAPONOFFHAND"] = {1.0000, true},
    ["INVTYPE_RANGED"] = {0.3164, true},
    ["INVTYPE_THROWN"] = {0.3164, false},
    ["INVTYPE_RANGEDRIGHT"] = {0.3164, false},
    ["INVTYPE_SHIELD"] = {1.0000, true},
    ["INVTYPE_WEAPON"] = {1.0000, true},
    ["INVTYPE_HOLDABLE"] = {1.0000, false},
    ["INVTYPE_HEAD"] = {1.0000, true},
    ["INVTYPE_NECK"] = {0.5625, false},
    ["INVTYPE_SHOULDER"] = {0.7500, true},
    ["INVTYPE_CHEST"] = {1.0000, true},
    ["INVTYPE_ROBE"] = {1.0000, true},
    ["INVTYPE_WAIST"] = {0.7500, false},
    ["INVTYPE_LEGS"] = {1.0000, true},
    ["INVTYPE_FEET"] = {0.75, true},
    ["INVTYPE_WRIST"] = {0.5625, true},
    ["INVTYPE_HAND"] = {0.7500, true},
    ["INVTYPE_FINGER"] = {0.5625, false},
    ["INVTYPE_CLOAK"] = {0.5625, true},
    ["INVTYPE_BODY"] = {0, false},
    ["INVTYPE_TABARD"] = {0, false},
}


local rarityModifiers = {
    -- Assuming rarity is a number from 1 (common) to 5 (legendary)
    [0] = 2.25,  -- Poor
    [1] = 2.0,  -- Common
    [2] = 2,  -- Uncommon
    [3] = 1.8,  -- Rare
    [4] = 1.6,  -- Epic
    [5] = 1.4,  -- Legendary
}

local enchantmentModifier = 1.05  -- 5% increase for enchanted items


-- Character Window
local scoreFrame = CreateFrame("Frame", "GearScoreDisplay", CharacterFrame)
scoreFrame:SetSize(100, 30)
scoreFrame:SetPoint("BOTTOMLEFT", CharacterFrame, "BOTTOMLEFT", 70, 230)

scoreFrame.text = scoreFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
scoreFrame.text:SetFont(fontPath, fontSize)
scoreFrame.text:SetTextColor(1, 1, 1)
scoreFrame.text:SetPoint("LEFT", scoreFrame, "LEFT", 0, 0)

scoreFrame.avgItemLevelText = scoreFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
scoreFrame.avgItemLevelText:SetFont(fontPath, fontSize)
scoreFrame.avgItemLevelText:SetTextColor(1, 1, 1)
scoreFrame.avgItemLevelText:SetPoint("BOTTOMRIGHT", scoreFrame, "RIGHT", 115, 0)



-- Inspect Window   
local inspectScoreFrame = CreateFrame("Frame", "InspectGearScoreDisplay", InspectFrame)
inspectScoreFrame:SetSize(100, 30)
inspectScoreFrame:SetPoint("BOTTOMLEFT", InspectFrame, "BOTTOMLEFT", 55, 110)

inspectScoreFrame.text = inspectScoreFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
inspectScoreFrame.text:SetFont(fontPath, fontSize)
inspectScoreFrame.text:SetTextColor(1, 1, 1)
inspectScoreFrame.text:SetPoint("LEFT", inspectScoreFrame, "LEFT", 15, 30)

inspectScoreFrame.avgItemLevelText = inspectScoreFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
inspectScoreFrame.avgItemLevelText:SetFont(fontPath, fontSize)
inspectScoreFrame.avgItemLevelText:SetTextColor(1, 1, 1)
inspectScoreFrame.avgItemLevelText:SetPoint("BOTTOMRIGHT", inspectScoreFrame, "RIGHT", 140, 20)




local function GetEnchantIDFromItemLink(itemLink)
    local enchantID = itemLink:match("item:%d+:(%d+)")
    return tonumber(enchantID)  -- Convert to number, will be nil if no enchantment
end


--Calculates the score of a single individual item
local function CalculateItemScore(itemLink)
    if not itemLink then return 0 end
    local _, _, itemRarity, itemLevel, _, _, _, _, itemEquipLoc, _, _, _, _, _ = GetItemInfo(itemLink)
    local slotModifier = itemTypeInfo[itemEquipLoc][1] or 1
    local rarityModifier = rarityModifiers[itemRarity] or 1
    print(itemLevel)
    local enchantID = GetEnchantIDFromItemLink(itemLink)
    -- Check for enchantment
    local enchantModifier = enchantID and enchantID > 0 and 1.05 or 1

    -- Calculate score for this item
    return (itemLevel / rarityModifier) * slotModifier * enchantModifier * globalScale
end



local function CalculateGearScoreAndAverageItemLevel(unit)
    local totalScore = 0
    local totalItemLevel = 0
    local itemCount = 0

    -- Loop through all the equipment slots
    for i = 1, 19 do
        -- Skip the body (shirt, slot 4) and tabard (slot 19)
        if i ~= 4 and i ~= 19 then
            local itemLink = GetInventoryItemLink(unit, i)
            if itemLink then
                local itemScore = CalculateItemScore(itemLink)
                totalScore = totalScore + itemScore

                local _, _, _, itemLevel = GetItemInfo(itemLink)
                if itemLevel and itemLevel > 0 then
                    totalItemLevel = totalItemLevel + itemLevel
                    itemCount = itemCount + 1
                end
            end
        end
    end

    local avgItemLevel = itemCount > 0 and (totalItemLevel / itemCount) or 0
    return totalScore, avgItemLevel
end


local function UpdateFrame(frame, unit)
    local score, avgItemLevel = CalculateGearScoreAndAverageItemLevel(unit)
    frame.text:SetText(math.floor(score + 0.5).."\nGS")
    frame.avgItemLevelText:SetText(math.floor(avgItemLevel + 0.5) .. "\niLvl")

    if Test then
        frame.text:ClearAllPoints()
        frame.text:SetPoint("LEFT", frame, "LEFT", 0, 40)  -- Shifted up by 30 pixels

        frame.avgItemLevelText:ClearAllPoints()
        frame.avgItemLevelText:SetPoint("BOTTOMRIGHT", frame, "RIGHT", 115, 20)  -- Shifted up by 30 pixels
    end
end



-- Event handling
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" or event == "PLAYER_EQUIPMENT_CHANGED" then
        UpdateFrame(scoreFrame, "player")
    end
end)

InspectFrame:HookScript("OnShow", function()
    if InspectFrame.unit then
        UpdateFrame(inspectScoreFrame, InspectFrame.unit)
    end
end)