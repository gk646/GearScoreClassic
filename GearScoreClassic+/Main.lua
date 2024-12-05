-- Event handling
gearScoreFrame = CreateFrame("Frame")
gearScoreFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
gearScoreFrame:RegisterEvent("INSPECT_READY")
gearScoreFrame:HookScript("OnEvent", function(self, event, inspectGUID)
    if event == "PLAYER_EQUIPMENT_CHANGED" then
        GearScoreCalc.OnPlayerEquipmentChanged()
    elseif event == "INSPECT_READY" then
        C_Timer.After(0.2, function()
            GearScoreCalc.OnInspectReady(inspectGUID)
        end)
    end
end)

InspectFrame:HookScript("OnHide", GearScoreCalc.OnInspectFrameHide)

InspectFrame:HookScript("OnShow", function()
    GearScoreCalc.OnInspectFrameShow()
    if InspectFrame.unit then
        GearScoreCalc.UpdateFrame(inspectScoreFrame, InspectFrame.unit)
    end
end)
CharacterFrame:HookScript("OnShow", function()
    GearScoreCalc.UpdateFrame(scoreFrame, "player")
end)

GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    local _, initialUnit = self:GetUnit()
    if initialUnit and UnitIsPlayer(initialUnit) and not InCombatLockdown() then
        local guid = UnitGUID(initialUnit)
        local cachedData = GEAR_SCORE_CACHE[guid]

        lastInspection = initialUnit
        GearScoreCalc.AddGearScoreToTooltip(self, initialUnit)

        if not IS_MANUAL_INSPECT_ACTIVE then
            if not InCombatLockdown() and CheckInteractDistance(initialUnit, "1") and not cachedData then
                C_Timer.After(0.2, function()
                    local _, currentUnit = self:GetUnit()
                    if currentUnit == initialUnit then
                        NotifyInspect(currentUnit)
                    end
                end)
            end
        end
    end
end)

-- Hook into item tooltips
GameTooltip:HookScript("OnTooltipSetItem", GearScoreCalc.AppendItemScoreToTooltip)
ItemRefTooltip:HookScript("OnTooltipSetItem", GearScoreCalc.AppendItemScoreToTooltip)