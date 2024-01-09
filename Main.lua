-- Event handling
frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("INSPECT_READY")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event,  inspectGUID)
    if event == "PLAYER_EQUIPMENT_CHANGED" then
        GearScoreCalc.OnPlayerEquipmentChanged()
    elseif event == "INSPECT_READY" then
        C_Timer.After(0.2, function()
            GearScoreCalc.OnInspectReady(inspectGUID)
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        PVP_TRACKER.OnPlayerEnteringWorld()
    elseif event == "PLAYER_LOGOUT" then
        PVP_TRACKER.OnPlayerLogout()
    elseif event == "UPDATE_BATTLEFIELD_SCORE" then
        UpdateBattlegroundStats()
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
    if initialUnit and UnitIsPlayer(initialUnit) then
        local guid = UnitGUID(initialUnit)
        local cachedData = GEAR_SCORE_CACHE[guid]

        lastInspection = initialUnit
        GearScoreCalc.AddGearScoreToTooltip(self, initialUnit)

        if not IS_MANUAL_INSPECT_ACTIVE then
            if CheckInteractDistance(initialUnit, "1") and not cachedData then
                NotifyInspect(initialUnit)
            end
        end
    end
end)
