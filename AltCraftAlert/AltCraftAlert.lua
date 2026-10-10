-- AltCraftAlert.lua
local CLASS_COLORS = {
    ["DRUID"]   = "FF7D0A",
    ["HUNTER"]  = "ABD473",
    ["MAGE"]    = "40C7EB",
    ["PALADIN"] = "F58CBA",
    ["PRIEST"]  = "FFFFFF",
    ["ROGUE"]   = "FFF569",
    ["SHAMAN"]  = "0070DE",
    ["WARLOCK"] = "8787ED",
    ["WARRIOR"] = "C79C6E",
    ["DEATHKNIGHT"] = "C41F3B",
}

local function GetColoredCharName(charName, charKey)
    local hexColor = "FFFFFF"
    if DataStore_CharactersDB and DataStore_CharactersDB.global and DataStore_CharactersDB.global.Characters then
        local charData = DataStore_CharactersDB.global.Characters[charKey]
        if charData and charData.englishClass then
            hexColor = CLASS_COLORS[charData.englishClass] or hexColor
        elseif charData and charData.class then
            local upperClass = string.upper(charData.class):gsub("%s+", "")
            hexColor = CLASS_COLORS[upperClass] or hexColor
        end
    end
    return string.format("|cff%s%s|r", hexColor, charName)
end

local function FormatTimeRemaining(seconds)
    if seconds <= 0 then
        return "|cffffd100READY!|r"
    end

    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local mins = math.floor((seconds % 3600) / 60)

    if days > 0 then
        return string.format("|cffffd100%dd %dh %dm|r", days, hours, mins)
    else
        return string.format("|cffffd100%dh %dm|r", hours, mins)
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    
    local elapsed = 0
    local timerFrame = CreateFrame("Frame")
    timerFrame:SetScript("OnUpdate", function(tSelf, step)
        elapsed = elapsed + step
        if elapsed >= 3 then
            tSelf:SetScript("OnUpdate", nil)
            
            local db = DataStore_CraftsDB
            if not db or not db.global or not db.global.Characters then
                print("|cffaf70ff[Crafting Cooldowns]|r DataStore_Crafts database not found.")
                return
            end

            print("|cffaf70ff[Crafting Cooldowns]|r")
            local now = time()
            local found = false
            local cooldownSpells = AltCraftCooldowns_Spells or {}

            for charKey, charData in pairs(db.global.Characters) do
                local charName = charKey:match("%.([^%.]+)$") or charKey
                local coloredName = GetColoredCharName(charName, charKey)
                local lastUpdate = charData.lastUpdate or now
                
                if charData.Professions then
                    for profName, profData in pairs(charData.Professions) do
                        
                        -- Category tracking to prevent duplicates for shared CDs
                        local activeCategories = {}
                        local knownCategories = {}

                        -- 1. Scan Active Cooldowns
                        if profData.Cooldowns then
                            for _, cdString in ipairs(profData.Cooldowns) do
                                local craftName, engineTimeStr, expireTimeStr = string.match(cdString, "^([^|]+)|([^|]+)|(%d+)")
                                local expireTime = tonumber(expireTimeStr)
                                local engineTime = tonumber(engineTimeStr)
                                
                                if craftName and expireTime then
                                    found = true
                                    
                                    local rem = 0
                                    if expireTime > now then
                                        rem = expireTime - now
                                    elseif engineTime and lastUpdate then
                                        local elapsedSinceUpdate = now - lastUpdate
                                        local totalDuration = expireTime - (lastUpdate - engineTime)
                                        rem = totalDuration - elapsedSinceUpdate
                                    end
                                    
                                    -- Map to category if it's a known shared spell
                                    local categoryName = craftName
                                    if craftName:find("^Transmute:") then
                                        categoryName = "Transmute"
                                    elseif craftName:find("Research") then
                                        categoryName = "Inscription Research"
                                    end

                                    activeCategories[categoryName] = true
                                    local timeString = FormatTimeRemaining(rem)
                                    print(string.format(" - %s: |cffaf70ff<%s>|r - %s", coloredName, craftName, timeString))
                                end
                            end
                        end

                        -- 2. Scan Learned Crafts for READY shared categories
                        if profData.Crafts then
                            for _, craftString in ipairs(profData.Crafts) do
                                local spellID = tonumber(craftString:match("^%d+|(%d+)"))
                                if spellID and cooldownSpells[spellID] then
                                    local info = cooldownSpells[spellID]
                                    local cat = info.category
                                    local displayName = info.name

                                    -- If category is not on active cooldown and hasn't already been reported
                                    if not activeCategories[cat] and not knownCategories[cat] then
                                        knownCategories[cat] = true
                                        found = true
                                        print(string.format(" - %s: |cffaf70ff<%s>|r - %s", coloredName, displayName, "|cffffd100READY!|r"))
                                    end
                                end
                            end
                        end
                        
                    end
                end
            end

            if not found then
                print(" No recorded craft cooldowns found in DataStore.")
            end
        end
    end)
end)