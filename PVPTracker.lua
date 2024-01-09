PVP_HISTORY = PVP_HISTORY or {}

PVP_TRACKER = {}
local CURRENT_BATTLEGROUND
local BATTLEGROUND_START_TIME = nil


local function IsBattlegroundZone(zoneName)
    return zoneName == "Warsong Gulch" or zoneName == "Arathi Basin" or zoneName == "Alterac Valley"
end

local function StartBattleground(zoneName)
    CURRENT_BATTLEGROUND = {
        name = zoneName,
        kills = 0,
        deaths = 0,
        startTime = GetTime(),
        endTime = nil,
        outcome = "In Progress"
    }
    battlegroundStartTime = GetTime()
end

local function EndBattleground()
    if CURRENT_BATTLEGROUND then
        CURRENT_BATTLEGROUND.endTime = GetTime()
        CURRENT_BATTLEGROUND.duration = CURRENT_BATTLEGROUND.endTime - CURRENT_BATTLEGROUND.startTime
        table.insert(PVP_HISTORY, CURRENT_BATTLEGROUND)
        CURRENT_BATTLEGROUND = nil
    end
end

local function UpdateBattlegroundStats()
    if CURRENT_BATTLEGROUND then
        for i = 1, GetNumBattlefieldScores() do
            local name, killingBlows, honorableKills, deaths = GetBattlefieldScore(i)
            if name == UnitName("player") then
                CURRENT_BATTLEGROUND.kills = killingBlows
                CURRENT_BATTLEGROUND.deaths = deaths
                break
            end
        end

        local winner = GetBattlefieldWinner()
        if winner then
            CURRENT_BATTLEGROUND.outcome = (winner == 1 and "Victory") or "Defeat"
        else
            CURRENT_BATTLEGROUND.outcome = "Abandoned"
        end
    end
end

local function CreateBattlegroundHistoryFrame()
    local frame = CreateFrame("Frame", "BattlegroundHistoryFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(300, 360)  -- Width, Height
    frame:SetPoint("CENTER")  -- Position on the screen

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("Battleground History")

    frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.scrollFrame:SetPoint("TOPLEFT", 10, -30)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    frame.scrollChild = CreateFrame("Frame")
    frame.scrollChild:SetSize(270, 340)  -- Scroll child size
    frame.scrollFrame:SetScrollChild(frame.scrollChild)

    frame:Hide()  -- Hide the frame initially

    return frame
end

local function UpdateBattlegroundHistoryFrame(frame)
    local content = ""
    for i, bg in ipairs(PVP_HISTORY) do
        local startTime = date("%d.%m.%y %H:%M", bg.startTime)
        content = content .. string.format("%s - %s: Kills: %d, Deaths: %d, Outcome: %s\n", startTime, bg.name, bg.kills, bg.deaths, bg.outcome)
    end

    frame.scrollChild.text:SetText(content)
end

local battlegroundHistoryFrame = CreateBattlegroundHistoryFrame()

-- Function to toggle the display of the frame
function PVP_TRACKER.ToggleBattlegroundHistory()
    if battlegroundHistoryFrame:IsShown() then
        battlegroundHistoryFrame:Hide()
    else
        UpdateBattlegroundHistoryFrame(battlegroundHistoryFrame)
        battlegroundHistoryFrame:Show()
    end
end

-- Add a slash command to toggle the battleground history frame
SLASH_PVPHISTORY1 = "/pvphistory"
SlashCmdList["PVPHISTORY"] = PVP_TRACKER.ToggleBattlegroundHistory


function PVP_TRACKER.OnPlayerLogout()
    if CURRENT_BATTLEGROUND then
        UpdateBattlegroundStats()
        EndBattleground()
    end
end

function PVP_TRACKER.OnPlayerEnteringWorld()
    local zoneName = GetRealZoneText()
    if IsBattlegroundZone(zoneName) then
        StartBattleground(zoneName)
    else
        if CURRENT_BATTLEGROUND then
            UpdateBattlegroundStats()
            EndBattleground()
        end
    end
end

