if not IsAddOnLoaded("Blizzard_InspectUI") then
    LoadAddOn("Blizzard_InspectUI")
end


local Test = false
local fontPath = "Fonts\\FRIZQT__.TTF"  -- Standard WoW font
local fontSize = 11  -- Adjust the font size as needed
local GLOBAL_SCALE = 1.7
local MAX_GEAR_SCORE = 350  -- Maximum reachable gearscore
local gearScoreCache = {}
local enchantmentModifier = 1.05  -- 5% increase for enchanted items
local isManualInspect = false

local itemTypeInfo = {
    ["INVTYPE_RELIC"] = { 0.3164, false },
    ["INVTYPE_TRINKET"] = { 0.5625, false },
    ["INVTYPE_2HWEAPON"] = { 2.000, true },
    ["INVTYPE_WEAPONMAINHAND"] = { 1.0000, true },
    ["INVTYPE_WEAPONOFFHAND"] = { 1.0000, true },
    ["INVTYPE_RANGED"] = { 0.3164, true },
    ["INVTYPE_THROWN"] = { 0.3164, false },
    ["INVTYPE_RANGEDRIGHT"] = { 0.3164, false },
    ["INVTYPE_SHIELD"] = { 1.0000, true },
    ["INVTYPE_WEAPON"] = { 1.0000, true },
    ["INVTYPE_HOLDABLE"] = { 1.0000, false },
    ["INVTYPE_HEAD"] = { 1.0000, true },
    ["INVTYPE_NECK"] = { 0.5625, false },
    ["INVTYPE_SHOULDER"] = { 0.7500, true },
    ["INVTYPE_CHEST"] = { 1.0000, true },
    ["INVTYPE_ROBE"] = { 1.0000, true },
    ["INVTYPE_WAIST"] = { 0.7500, false },
    ["INVTYPE_LEGS"] = { 1.0000, true },
    ["INVTYPE_FEET"] = { 0.75, true },
    ["INVTYPE_WRIST"] = { 0.5625, true },
    ["INVTYPE_HAND"] = { 0.7500, true },
    ["INVTYPE_FINGER"] = { 0.5625, false },
    ["INVTYPE_CLOAK"] = { 0.5625, true },
    ["INVTYPE_BODY"] = { 0, false },
    ["INVTYPE_TABARD"] = { 0, false },
}

local rarityModifiers = {
    -- Assuming rarity is a number from 1 (common) to 5 (legendary)
    [0] = 3.5, -- Poor
    [1] = 3, -- Common
    [2] = 2.5, -- Uncommon 
    [3] = 1.76, -- Rare
    [4] = 1.6, -- Epic
    [5] = 1.4, -- Legendary
}



-- Character Window
local scoreFrame = CreateFrame("Frame", "GearScoreDisplay", PaperDollFrame)
scoreFrame:SetSize(100, 30)
scoreFrame:SetPoint("BOTTOMLEFT", PaperDollFrame, "BOTTOMLEFT", 0, 0)

scoreFrame.text = scoreFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
scoreFrame.text:SetFont(fontPath, fontSize)
scoreFrame.text:SetTextColor(1, 1, 1)
scoreFrame.text:SetPoint("BOTTOMLEFT", scoreFrame, "LEFT", 73, 215)
scoreFrame.text:SetText("GearScore")

scoreFrame.avgItemLevelText = scoreFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
scoreFrame.avgItemLevelText:SetFont(fontPath, fontSize)
scoreFrame.avgItemLevelText:SetTextColor(1, 1, 1)
scoreFrame.avgItemLevelText:SetPoint("BOTTOMLEFT", scoreFrame.text, "LEFT", 185, -5)

scoreFrame.scoreValueText = scoreFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
scoreFrame.scoreValueText:SetFont(fontPath, fontSize)
scoreFrame.scoreValueText:SetTextColor(1, 1, 1)
scoreFrame.scoreValueText:SetPoint("BOTTOMLEFT", scoreFrame.text, "BOTTOMLEFT", 0, 10)



-- Inspect Window   
local inspectScoreFrame = CreateFrame("Frame", "InspectGearScoreDisplay", InspectFrame)
inspectScoreFrame:SetSize(100, 30)
inspectScoreFrame:SetPoint("BOTTOMLEFT", InspectFrame, "BOTTOMLEFT", 0, 0)

inspectScoreFrame.text = inspectScoreFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
inspectScoreFrame.text:SetFont(fontPath, fontSize)
inspectScoreFrame.text:SetTextColor(1, 1, 1)
inspectScoreFrame.text:SetPoint("BOTTOMLEFT", inspectScoreFrame, "LEFT", 73, 130)
inspectScoreFrame.text:SetText("GearScore")

inspectScoreFrame.avgItemLevelText = inspectScoreFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
inspectScoreFrame.avgItemLevelText:SetFont(fontPath, fontSize)
inspectScoreFrame.avgItemLevelText:SetTextColor(1, 1, 1)
inspectScoreFrame.avgItemLevelText:SetPoint("BOTTOMLEFT", inspectScoreFrame, "RIGHT", 165, 130)

inspectScoreFrame.scoreValueText = inspectScoreFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
inspectScoreFrame.scoreValueText:SetFont(fontPath, fontSize)
inspectScoreFrame.scoreValueText:SetTextColor(1, 1, 1)
inspectScoreFrame.scoreValueText:SetPoint("BOTTOMLEFT", inspectScoreFrame.text, "BOTTOMLEFT", 0, 10)


local function OnInspectFrameShow()
    isManualInspect = true
end

local function OnInspectFrameHide()
    isManualInspect = false
end

local function GetColorForGearScore(gearScore)
    local percentile = gearScore / MAX_GEAR_SCORE * 100

    if percentile >= 100 then
        return 0.90, 0.80, 0.50  -- Gold
    elseif percentile >= 99 then
        return 0.89, 0.47, 0.65  -- Pink
    elseif percentile >= 95 then
        return 1.00, 0.50, 0.00  -- Orange
    elseif percentile >= 75 then
        return 0.63, 0.21, 0.93  -- Purple
    elseif percentile >= 50 then
        return 0.00, 0.44, 1.00  -- Blue
    elseif percentile >= 25 then
        return 0.12, 1.00, 0.00  -- Green
    else
        return 0.40, 0.40, 0.40  -- Grey
    end
end

local function GetColorForGearScoreText(gearScore)
    local percentile = gearScore / MAX_GEAR_SCORE * 100

    if percentile >= 100 then
        return "|cffe5cc80"  -- Gold for 100 and above
    elseif percentile >= 99 then
        return "|cffe268a8"  -- Pink for 99
    elseif percentile >= 95 then
        return "|cffff8000"  -- Orange for 95-98
    elseif percentile >= 75 then
        return "|cffa335ee"  -- Purple for 75-94
    elseif percentile >= 50 then
        return "|cff0070ff"  -- Blue for 50-74
    elseif percentile >= 25 then
        return "|cff1eff00"  -- Green for 25-49
    else
        return "|cff666666"  -- Grey for 0-24
    end
end

local function GetEnchantIDFromItemLink(itemLink)
    local enchantID = itemLink:match("item:%d+:(%d+)")
    return tonumber(enchantID)  -- Convert to number, will be nil if no enchantment
end

--Calculates the score of a single individual item
local function CalculateItemScore(itemLink)
    if not itemLink then
        return 0
    end
    local _, _, itemRarity, itemLevel, _, _, _, _, itemEquipLoc, _, _, _, _, _ = GetItemInfo(itemLink)
    local slotModifier = itemTypeInfo[itemEquipLoc][1] or 1
    local rarityModifier = rarityModifiers[itemRarity] or 1
    
    local enchantID = GetEnchantIDFromItemLink(itemLink)
    -- Check for enchantment
    local enchantModifier = enchantID and enchantID > 0 and 1.05 or 1

    -- Calculate score for this item
    return (itemLevel / rarityModifier) * slotModifier * enchantModifier * GLOBAL_SCALE
end

local function CalculateGearScoreAndAverageItemLevel(unit)
    local totalScore = 0
    local totalItemLevel = 0
    local itemCount = 0
    local itemMissing = false

    -- Loop through all the equipment slots
    for i = 1, 19 do
        if itemMissing then
            break
        end
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
            elseif  GetInventoryItemID(unit, i) then
                itemMissing = true
            end
        end
    end

    local avgItemLevel = itemCount > 0 and (totalItemLevel / itemCount) or 0
    return totalScore, avgItemLevel, itemMissing
end

local function CalculateAndCacheGearScore(unit)
    local gearScore, avgItemLevel, itemMissing = CalculateGearScoreAndAverageItemLevel(unit)
    local guid = UnitGUID(unit)
    if guid and gearScore and avgItemLevel then
        local cachedData = gearScoreCache[guid]
        if not cachedData or cachedData[1] ~= gearScore or cachedData[2] ~= avgItemLevel then
            -- Update cache if it's a new entry or if the gear score or avg item level has changed
            gearScoreCache[guid] = {gearScore, avgItemLevel}
        end
    end
    return gearScore, avgItemLevel, itemMissing
end

local function UpdateFrame(frame, unit)
    local score, avgItemLevel,_ = CalculateAndCacheGearScore(unit)
    local r, g, b = GetColorForGearScore(score)

    -- Set the numerical gear score with color
    frame.scoreValueText:SetTextColor(r, g, b)
    frame.scoreValueText:SetText(math.floor(score + 0.5))

    -- Set the average item level text
    frame.avgItemLevelText:SetText(math.floor(avgItemLevel + 0.5) .. "\niLvl:")
end

local function OnPlayerEquipmentChanged()
    UpdateFrame(scoreFrame, "player")
end

local function AddGearScoreToTooltip(tooltip, unit)
    if unit then
        local guid = UnitGUID(unit)
        local gearScore, avgItemLevel

        -- First, try to use the cached data if it exists
        local cachedData = gearScoreCache[guid]
        if cachedData then
            gearScore, avgItemLevel = unpack(cachedData)
        end

        -- Finally, display the gear score if available
        if gearScore and gearScore > 0 then
            local color = GetColorForGearScoreText(gearScore)
            tooltip:AddLine("Gear Score: " .. color .. math.floor(gearScore + 0.5))
            tooltip:Show()  -- Force tooltip to refresh
        end
    end
end

local function OnInspectReady(inspectGUID)
    if lastInspection and UnitGUID(lastInspection) == inspectGUID then
        local  gs , avg , itemMissing = CalculateGearScoreAndAverageItemLevel(lastInspection)
        -- Check if the tooltip is still showing the same unit
        if itemMissing then
            NotifyInspect(lastInspection)
            C_Timer.After(0.1, function()
                OnInspectReady(inspectGUID)
            end)
        else 
            gearScoreCache[inspectGUID] = {gs, avg}
            AddGearScoreToTooltip(GameTooltip, lastInspection)
            lastInspection = nil
        end
    end
end


-- Event handling
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("INSPECT_READY")

frame:SetScript("OnEvent", function(self, event,inspectGUID)
    if event == "PLAYER_EQUIPMENT_CHANGED" then
        OnPlayerEquipmentChanged()
    elseif event == "INSPECT_READY" then
        C_Timer.After(0.3, function()
            OnInspectReady(inspectGUID)
        end)
    end
end)

InspectFrame:HookScript("OnShow", OnInspectFrameShow)
InspectFrame:HookScript("OnHide", OnInspectFrameHide)

CharacterFrame:HookScript("OnShow", function()
    UpdateFrame(scoreFrame, "player")
end)

InspectFrame:HookScript("OnShow", function()
    if InspectFrame.unit then
        UpdateFrame(inspectScoreFrame, InspectFrame.unit)
    end
end)


GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    local _, unit = self:GetUnit()
    if unit and UnitIsPlayer(unit) then
        local guid = UnitGUID(unit)
        local cachedData = gearScoreCache[guid]

        lastInspection = unit
        print("added tooltip")
        AddGearScoreToTooltip(self, unit)
        
        if not isManualInspect  then
            if CheckInteractDistance(unit, "1") and not cachedData then
                NotifyInspect(unit)
            end
        end
       
    end
end)


