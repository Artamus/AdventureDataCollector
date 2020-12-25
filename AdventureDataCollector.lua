local db
local defaultDb = {missionData = {}}
local _, addonTbl = ...
local hooksecurefunc = _G["hooksecurefunc"]

AdventureDataCollector = CreateFrame("Frame", "AdventureDataCollector", UIParent)
AdventureDataCollector.initDone = false

SLASH_ADVENTUREDATACOLLECTOR1 = "/adc"

function SerializeValue(val, type)
    if type == "string" then
        return '"' .. val .. '"'
    end

    if type == "boolean" then
        if val then
            return "true"
        else
            return "false"
        end
    end

    return val
end

function SerializeJson(obj)
    local type = type(obj)

    if type ~= "table" then
        return SerializeValue(obj, type)
    end

    -- Array check
    local isArray = obj[1] ~= nil

    local json = ""
    if isArray then
        local jsonItems = {}
        for k, v in pairs(obj) do
            local val = SerializeJson(v)
            table.insert(jsonItems, val)
        end

        json = "[" .. table.concat(jsonItems, ", ") .. "]"
    else
        local jsonItems = {}
        for k, v in pairs(obj) do
            local val = SerializeJson(v)

            local keyVal = '"' .. k .. '": ' .. tostring(val)
            table.insert(jsonItems, keyVal)
        end
        json = "{" .. table.concat(jsonItems, ", ") .. "}"
    end

    return json
end

function AdventureDataCollector:SetupTabsHook(...)
    hooksecurefunc(_G["CovenantMissionFrame"], "InitiateMissionCompletion", AdventureDataCollector.MissionCompleteHook)
end

function AdventureDataCollector:MissionCompleteHook(...)
    local missionFrame = _G["CovenantMissionFrame"]
    local missionComplete = missionFrame.MissionComplete
    local mission = missionComplete.currentMission

    local missionDetails = {
        dataVersion = 1,
        missionName = mission.name,
        winner = missionComplete.autoCombatResult.winner,
        missionLevel = mission.missionScalar,
        isRare = mission.encounterIconInfo.isRare,
        isElite = mission.encounterIconInfo.isElite,
        level = mission.level,
        isMaxLevel = mission.isMaxLevel
    }

    if mission.environmentEffect then
        table.insert(missionDetails, mission.environmentEffect.name)
        table.insert(missionDetails, mission.environmentEffect.autoCombatSpellInfo)
    end

    -- Loop over enemies
    local enemies = {}
    for k, v in pairs(missionComplete.missionEncounters) do
        local enemy = {
            boardIndex = v.boardIndex,
            attackPower = v.attack,
            maxHealth = v.maxHealth,
            role = v.role,
            name = v.name,
            spells = v.autoCombatSpells
        }

        table.insert(enemies, enemy)
    end
    missionDetails.enemies = enemies

    -- Loop over followers
    local followers = {}
    for k, v in pairs(missionComplete.followerGUIDToInfo) do
        local follower = {
            boardIndex = v.boardIndex,
            attackPower = v.autoCombatantStats.attack,
            maxHealth = v.autoCombatantStats.maxHealth,
            currentHealth = v.autoCombatantStats.currentHealth,
            level = v.level,
            name = v.name,
            quality = v.quality,
            role = v.role,
            className = v.className
        }

        table.insert(followers, follower)
    end
    missionDetails.followers = followers

    table.insert(db.missionData, missionDetails)
end

function AdventureDataCollector:ADDON_LOADED(event, addon)
    if addon == "Blizzard_GarrisonUI" then
        AdventureDataCollector:Init()
    end
end

function AdventureDataCollector:Init()
    if self.initDone then
        return
    end
    hooksecurefunc(_G["CovenantMissionFrame"], "SetupTabs", self.SetupTabsHook)

    AdventureDataCollectorDB = AdventureDataCollectorDB or {missionData = {}}
    db = AdventureDataCollectorDB

    self.initDone = true
end

SlashCmdList.ADVENTUREDATACOLLECTOR = function(msg, editBox)
    if msg == "" then
        print("Available commands for AdvancedAdventureStats:")
        print("    clear (clears all saved data)")
        print("    dump (opens a window where the content is easily visible and copiable)")
    end

    if msg == "clear" then
        db = defaultDb
    elseif msg == "dump" then
        local jsonSerialized = SerializeJson(db)
        local frame = addonTbl.GetExportFrame(jsonSerialized)
        frame:Show()
    end
end

AdventureDataCollector:RegisterEvent("ADDON_LOADED")
AdventureDataCollector:SetScript("OnEvent", AdventureDataCollector.ADDON_LOADED)
