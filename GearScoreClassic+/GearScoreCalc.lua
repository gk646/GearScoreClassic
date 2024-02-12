if not IsAddOnLoaded("Blizzard_InspectUI") then
    LoadAddOn("Blizzard_InspectUI")
end

GearScoreCalc = {}

IS_MANUAL_INSPECT_ACTIVE = false
GEAR_SCORE_CACHE = {}

-- Create frames for character and inspect windows
scoreFrame = nil
inspectScoreFrame = nil

local fontPath = "Fonts\\FRIZQT__.TTF"  -- Standard WoW font
local FONT_SIZE = 11  -- Adjust the font size as needed
local GLOBAL_SCALE = 1.7
local MAX_GEAR_SCORE = 530 -- Phase1: 350  -- Maximum reachable gearscore
local GS_ENCHANT_MODIFIER = 1.05  -- 5% increase for enchanted items
local MAX_RETRIES = 3
local INSPECT_RETRY_DELAY = 0.2
local INSPECT_RETRIES = {}
local TOTAL_EQUIPPABLE_SLOTS = 17

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

local function CreateGearScoreFrame(name, parentFrame, point, relativePoint, xOffset, yOffset, textXOffset, textYOffset)
    local frame = CreateFrame("Frame", name, parentFrame)
    frame:SetSize(100, 30)
    frame:SetPoint(point, parentFrame, relativePoint, xOffset, yOffset)

    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text:SetFont(fontPath, FONT_SIZE)
    frame.text:SetTextColor(1, 1, 1)
    frame.text:SetPoint("BOTTOMLEFT", frame, "LEFT", textXOffset, textYOffset)
    frame.text:SetText("GearScore")

    frame.avgItemLevelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.avgItemLevelText:SetFont(fontPath, FONT_SIZE)
    frame.avgItemLevelText:SetTextColor(1, 1, 1)
    frame.avgItemLevelText:SetPoint("BOTTOMLEFT", frame.text, "LEFT", 185, -5)

    frame.scoreValueText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.scoreValueText:SetFont(fontPath, FONT_SIZE)
    frame.scoreValueText:SetTextColor(1, 1, 1)
    frame.scoreValueText:SetPoint("BOTTOMLEFT", frame.text, "BOTTOMLEFT", 0, 10)

    return frame
end

scoreFrame = CreateGearScoreFrame("GearScoreDisplay", PaperDollFrame, "BOTTOMLEFT", "BOTTOMLEFT", 0, 0, 73, 225)
inspectScoreFrame = CreateGearScoreFrame("InspectGearScoreDisplay", InspectFrame, "BOTTOMLEFT", "BOTTOMLEFT", 0, 0, 73, 130)


-- Returns in r g b values from 0.0 - 1.0
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

-- Returns the color string which can be used in text formatting
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

-- Tries to find the enchant id from an itemLink
local function GetEnchantIDFromItemLink(itemLink)
    local enchantID = itemLink:match("item:%d+:(%d+)")
    return tonumber(enchantID)  -- Convert to number, will be nil if no enchantment
end

--Calculates the score of a single individual item
local function CalculateItemScore(itemLink)
    if not itemLink then
        return 0, 0
    end
    local _, _, itemRarity, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    local slotModifier = itemTypeInfo[itemEquipLoc][1] or 1
    local rarityModifier = rarityModifiers[itemRarity] or 1

    local enchantID = GetEnchantIDFromItemLink(itemLink)
    -- Check for enchantment
    local enchantModifier = enchantID and enchantID > 0 and GS_ENCHANT_MODIFIER or 1

    -- Double item level for two-handed weapons
    local adjustedItemLevel = itemLevel
    if itemEquipLoc == "INVTYPE_2HWEAPON" then
        adjustedItemLevel = itemLevel * 2
    end

    -- Calculate score for this item
    return (itemLevel / rarityModifier) * slotModifier * enchantModifier * GLOBAL_SCALE, adjustedItemLevel
end

local function CalculateGearScoreAndAverageItemLevel(unit)
    local totalScore = 0
    local totalItemLevel = 0
    local itemMissing = false

    -- Loop through all the equipment slots
    for i = 1, 19 do
        -- Skip the body (shirt, slot 4) and tabard (slot 19)
        if i ~= 4 and i ~= 19 then
            local itemLink = GetInventoryItemLink(unit, i)
            if itemLink then
                local itemScore, iLevel = CalculateItemScore(itemLink)
                totalScore = totalScore + itemScore
                if iLevel and iLevel > 0 then
                    totalItemLevel = totalItemLevel + iLevel
                end
            else
                -- Check if the slot is not legitimately empty
                local itemID = GetInventoryItemID(unit, i)
                if itemID then
                    itemMissing = true
                end
            end
        end
    end
    local avgItemLevel = (totalItemLevel / TOTAL_EQUIPPABLE_SLOTS) or 0
    return totalScore, avgItemLevel, itemMissing
end

local function CalculateAndCacheGearScore(unit)
    local gearScore, avgItemLevel, itemMissing = CalculateGearScoreAndAverageItemLevel(unit)
    local guid = UnitGUID(unit)
    if guid and gearScore and avgItemLevel then
        local cachedData = GEAR_SCORE_CACHE[guid]
        if not cachedData or cachedData[1] ~= gearScore or cachedData[2] ~= avgItemLevel then
            -- Update cache if it's a new entry or if the gear score or avg item level has changed
            GEAR_SCORE_CACHE[guid] = { gearScore, avgItemLevel }
        end
    end
    return gearScore, avgItemLevel, itemMissing
end

function GearScoreCalc.OnInspectFrameShow()
    IS_MANUAL_INSPECT_ACTIVE = true
end

function GearScoreCalc.OnInspectFrameHide()
    IS_MANUAL_INSPECT_ACTIVE = false
end

function GearScoreCalc.UpdateFrame(frame, unit)
    local score, avgItemLevel, _ = CalculateAndCacheGearScore(unit)
    local r, g, b = GetColorForGearScore(score)

    -- Set the numerical gear score with color
    frame.scoreValueText:SetTextColor(r, g, b)
    frame.scoreValueText:SetText(math.floor(score + 0.5))

    -- Set the average item level text
    frame.avgItemLevelText:SetText(math.floor(avgItemLevel + 0.5) .. "\niLvl")
end

function GearScoreCalc.OnPlayerEquipmentChanged()
    GearScoreCalc.UpdateFrame(scoreFrame, "player")
end

function GearScoreCalc.AddGearScoreToTooltip(tooltip, unit)
    if unit then
        local guid = UnitGUID(unit)
        local gearScore, avgItemLevel

        -- Get cached data
        local cachedData = GEAR_SCORE_CACHE[guid]
        if cachedData then
            gearScore, avgItemLevel = unpack(cachedData)
        end

        -- Display the gearscore
        if gearScore and gearScore > 0 then
            local color = GetColorForGearScoreText(gearScore)
            tooltip:AddLine("Gear Score: " .. color .. math.floor(gearScore + 0.5))
            tooltip:Show()  -- Force tooltip to refresh
        end
    end
end

function GearScoreCalc.OnInspectReady(inspectGUID)
    if lastInspection and UnitGUID(lastInspection) == inspectGUID then
        local gs, avg, itemMissing = CalculateGearScoreAndAverageItemLevel(lastInspection)

        if itemMissing then
            INSPECT_RETRIES[inspectGUID] = (INSPECT_RETRIES[inspectGUID] or 0) + 1

            if INSPECT_RETRIES[inspectGUID] <= MAX_RETRIES then
                C_Timer.After(INSPECT_RETRY_DELAY, function()
                    if lastInspection then
                        NotifyInspect(lastInspection)
                    end
                end)
            else
                GEAR_SCORE_CACHE[inspectGUID] = { gs, avg }
                GearScoreCalc.AddGearScoreToTooltip(GameTooltip, lastInspection)
                lastInspection = nil
                INSPECT_RETRIES[inspectGUID] = nil
            end
        else
            GEAR_SCORE_CACHE[inspectGUID] = { gs, avg }
            GearScoreCalc.AddGearScoreToTooltip(GameTooltip, lastInspection)
            INSPECT_RETRIES[inspectGUID] = nil
        end
    end
end

function GearScoreCalc.AppendItemScoreToTooltip(tooltip)
    local _, itemLink = tooltip:GetItem()
    if itemLink and IsEquippableItem(itemLink) then
        local score = CalculateItemScore(itemLink)
        local itemName, _, _, itemLevel = GetItemInfo(itemLink)
        if score then
            tooltip:AddLine("GearScore: " .. math.floor(score))
            tooltip:AddLine("iLvl: " .. itemLevel)
            tooltip:Show()
        end
    end
end
