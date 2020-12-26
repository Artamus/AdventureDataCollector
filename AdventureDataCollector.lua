local defaultDb = {missionData = {}}
local _, addonTbl = ...
local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/" -- You will need this for encoding/decoding
local hooksecurefunc = _G["hooksecurefunc"]

AdventureDataCollector = CreateFrame("Frame", "AdventureDataCollector", UIParent)
AdventureDataCollector.initDone = false

SLASH_ADVENTUREDATACOLLECTOR1 = "/adc"

local function SerializeValue(val, type)
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

local function SerializeJson(obj)
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

-- TODO: Might be another way to find this part
local function GetCompletedMissionInfo(missionID)
    local completedMissions = C_Garrison.GetCompleteMissions(123) -- Finds complete covenant missions if the argument is 123, I don't know why this works
    for i = 1, #completedMissions do
        if completedMissions[i].missionID == missionID then
            return completedMissions[i]
        end
    end
end

local function GetAutoCombatSpells(rawSpells)
    if not rawSpells then
        return nil
    end

    local spells = rawSpells
    for _, spell in pairs(spells) do
        spell.previewMask, spell.schoolMask, spell.icon, spell.spellTutorialFlag = nil
    end

    return spells
end

local function EncodeBase64(data)
    return ((data:gsub(
        ".",
        function(x)
            local r, b = "", x:byte()
            for i = 8, 1, -1 do
                r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
            end
            return r
        end
    ) .. "0000"):gsub(
        "%d%d%d?%d?%d?%d?",
        function(x)
            if (#x < 6) then
                return ""
            end
            local c = 0
            for i = 1, 6 do
                c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
            end
            return b:sub(c + 1, c + 1)
        end
    ) .. ({"", "==", "="})[#data % 3 + 1])
end

function AdventureDataCollector:GARRISON_MISSION_COMPLETE_RESPONSE(
    event,
    missionID,
    _canComplete,
    _success,
    _bonusRollSuccess,
    _followerDeaths,
    autoCombatResult)

    -- I do not care about the combat log
    local missionName = C_Garrison.GetMissionName(missionID)
    local mission = GetCompletedMissionInfo(missionID)

    local missionDetails = {
        dataVersion = 1,
        missionName = mission.name,
        winner = autoCombatResult.winner,
        missionLevel = mission.missionScalar,
        isRare = mission.isRare, -- TODO: Figure out if elite means anything and if I need it
        level = mission.level,
        isMaxLevel = mission.isMaxLevel
    }

    -- Environment effects
    local environmentEffect = C_Garrison.GetAutoMissionEnvironmentEffect(missionID)
    if environmentEffect then
        if environmentEffect.autoCombatSpellInfo then
            local spellInfo = environmentEffect.autoCombatSpellInfo
            spellInfo.previewMask, spellInfo.schoolMask, spellInfo.icon, spellInfo.spellTutorialFlag = nil
        end

        missionDetails.environmentEffect = environmentEffect
    end

    -- Enemies
    local encounters = C_Garrison.GetMissionCompleteEncounters(missionID)
    local enemies = {}
    for _, v in pairs(encounters) do
        local autoCombatSpells = GetAutoCombatSpells(v.autoCombatSpells)

        local enemy = {
            boardIndex = v.boardIndex,
            attackPower = v.attack,
            health = v.health,
            maxHealth = v.maxHealth,
            role = v.role,
            name = v.name,
            autoCombatSpells = autoCombatSpells
        }
        table.insert(enemies, enemy)
    end
    missionDetails.enemies = enemies

    -- Followers
    local followers = {}
    for _, followerID in pairs(mission.followers) do
        local followerInfo = C_Garrison.GetFollowerMissionCompleteInfo(followerID)
        local followerCombatStats = C_Garrison.GetFollowerAutoCombatStats(followerID)

        local followerCombatSpells = C_Garrison.GetFollowerAutoCombatSpells(followerID, followerInfo.level)
        local autoCombatSpells = GetAutoCombatSpells(followerCombatSpells)

        local follower = {
            boardIndex = followerInfo.boardIndex,
            attackPower = followerCombatStats.attack,
            maxHealth = followerCombatStats.maxHealth,
            currentHealth = followerCombatStats.currentHealth,
            level = followerInfo.level,
            name = followerInfo.name,
            quality = followerInfo.quality,
            role = followerInfo.role,
            className = followerInfo.className,
            spells = autoCombatSpells
        }
        followers[followerID] = follower
    end
    missionDetails.followers = followers

    AdventureDataCollectorDB = AdventureDataCollectorDB or defaultDb
    table.insert(AdventureDataCollectorDB.missionData, missionDetails)
end

function AdventureDataCollector:EventHandler(event, ...)
    if self[event] then
        self[event](self, event, ...)
    else
        print("No handler for event " .. event)
    end
end

SlashCmdList.ADVENTUREDATACOLLECTOR = function(msg, editBox)
    if msg == "" then
        print("Available commands for AdvancedAdventureStats:")
        print("    clear (clears all saved data)")
        print("    dump (opens a window where the content is easily visible and copiable)")
    end

    if msg == "clear" then
        AdventureDataCollectorDB = defaultDb
    elseif msg == "dump" then
        local jsonSerialized = SerializeJson(AdventureDataCollectorDB.missionData)
        local frame = addonTbl.GetExportFrame(EncodeBase64(jsonSerialized))
        frame:Show()
    end
end

AdventureDataCollector:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE")
AdventureDataCollector:SetScript("OnEvent", AdventureDataCollector.EventHandler)
