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

-- Map a raw craft name to its broader display category
local function GetCategoryName(craftName)
    local lower = string.lower(craftName)
    if lower:find("transmute") then
        return "Transmute"
    elseif lower:find("alchemy research") or lower:find("northrend alchemy") then
        return "Alchemy Research"
    elseif lower:find("minor inscription") then
        return "Minor Inscription Research"
    elseif lower:find("northrend inscription") then
        return "Northrend Inscription Research"
    end
    return craftName
end

local function IsCharCategoryEnabled(charName, catName)
    if not AltCraftAlertDB then return true end
    if not AltCraftAlertDB[charName] then return true end
    if AltCraftAlertDB[charName][catName] == nil then return true end
    return AltCraftAlertDB[charName][catName]
end

local function CheckCooldowns()
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
                
                local activeCategories = {}
                local reportedCategories = {}

                -- 1. Scan Active Cooldowns
                if profData.Cooldowns then
                    for _, cdString in ipairs(profData.Cooldowns) do
                        local craftName, engineTimeStr, expireTimeStr = string.match(cdString, "^([^|]+)|([^|]+)|(%d+)")
                        local expireTime = tonumber(expireTimeStr)
                        local engineTime = tonumber(engineTimeStr)
                        
                        if craftName and expireTime then
                            
                            local rem = 0
                            if expireTime > now then
                                rem = expireTime - now
                            elseif engineTime and lastUpdate then
                                local elapsedSinceUpdate = now - lastUpdate
                                local totalDuration = expireTime - (lastUpdate - engineTime)
                                rem = totalDuration - elapsedSinceUpdate
                            end
                            
                            local categoryName = GetCategoryName(craftName)
                            activeCategories[categoryName] = true

                            -- Only print once per category for each character
                            if IsCharCategoryEnabled(charName, categoryName) and not reportedCategories[categoryName] then
                                reportedCategories[categoryName] = true
                                found = true
                                local timeString = FormatTimeRemaining(rem)
                                print(string.format(" - %s: |cffaf70ff<%s>|r - %s", coloredName, categoryName, timeString))
                            end
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

                            if IsCharCategoryEnabled(charName, cat) and not activeCategories[cat] and not reportedCategories[cat] then
                                reportedCategories[cat] = true
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
        print(" No active or tracked craft cooldowns found.")
    end
end

----------------------------------------------------
-- Fully Dynamic Config Panel Construction
----------------------------------------------------
local configPanel = CreateFrame("Frame", "AltCraftAlertOptionsPanel", UIParent)
configPanel.name = "AltCraftAlert"

local function CreateConfigGUI()
    local title = configPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("AltCraftAlert Options")

    local subtext = configPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtext:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtext:SetText("Toggle monitoring for detected cooldowns per character.")

    local scrollFrame = CreateFrame("ScrollFrame", "ACA_ScrollFrame", configPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", subtext, "BOTTOMLEFT", 0, -12)
    scrollFrame:SetPoint("BOTTOMRIGHT", configPanel, "BOTTOMRIGHT", -32, 16)

    local content = CreateFrame("Frame", "ACA_ScrollContent", scrollFrame)
    content:SetSize(380, 600)
    scrollFrame:SetScrollChild(content)

    local db = DataStore_CraftsDB
    if not db or not db.global or not db.global.Characters then return end

    local cooldownSpells = AltCraftCooldowns_Spells or {}
    local cbCount = 0
    local yOffset = -8

    for charKey, charData in pairs(db.global.Characters) do
        local charName = charKey:match("%.([^%.]+)$") or charKey
        
        if not AltCraftAlertDB[charName] then
            AltCraftAlertDB[charName] = {}
        end

        local charCategories = {}
        local seenCats = {}

        if charData.Professions then
            for profName, profData in pairs(charData.Professions) do
                -- 1. Active Cooldowns
                if profData.Cooldowns then
                    for _, cdString in ipairs(profData.Cooldowns) do
                        local craftName = string.match(cdString, "^([^|]+)|")
                        if craftName then
                            local cat = GetCategoryName(craftName)
                            if not seenCats[cat] then
                                seenCats[cat] = true
                                table.insert(charCategories, cat)
                            end
                        end
                    end
                end

                -- 2. Learned Crafts
                if profData.Crafts then
                    for _, craftString in ipairs(profData.Crafts) do
                        local spellID = tonumber(craftString:match("^%d+|(%d+)"))
                        if spellID and cooldownSpells[spellID] then
                            local cat = cooldownSpells[spellID].category
                            if not seenCats[cat] then
                                seenCats[cat] = true
                                table.insert(charCategories, cat)
                            end
                        end
                    end
                end
            end
        end

        if #charCategories > 0 then
            table.sort(charCategories)

            local header = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
            header:SetText(GetColoredCharName(charName, charKey))
            yOffset = yOffset - 20

            for _, cat in ipairs(charCategories) do
                cbCount = cbCount + 1
                local cb = CreateFrame("CheckButton", "ACA_CharCB_" .. cbCount, content, "InterfaceOptionsCheckButtonTemplate")
                cb:SetPoint("TOPLEFT", content, "TOPLEFT", 12, yOffset)

                _G[cb:GetName() .. "Text"]:SetText(cat)
                cb.charName = charName
                cb.cat = cat

                cb:SetScript("OnShow", function(self)
                    local enabled = AltCraftAlertDB[self.charName][self.cat]
                    if enabled == nil then enabled = true end
                    self:SetChecked(enabled)
                end)

                cb:SetScript("OnClick", function(self)
                    AltCraftAlertDB[self.charName][self.cat] = self:GetChecked() and true or false
                end)

                yOffset = yOffset - 26
            end

            yOffset = yOffset - 10
        end
    end

    InterfaceOptions_AddCategory(configPanel)
end

----------------------------------------------------
-- Events & Initialization
----------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "AltCraftAlert" then
        if not AltCraftAlertDB then
            AltCraftAlertDB = {}
        end
        CreateConfigGUI()
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        
        local elapsed = 0
        local timerFrame = CreateFrame("Frame")
        timerFrame:SetScript("OnUpdate", function(tSelf, step)
            elapsed = elapsed + step
            if elapsed >= 3 then
                tSelf:SetScript("OnUpdate", nil)
                CheckCooldowns()
            end
        end)
    end
end)

----------------------------------------------------
-- Slash Commands
----------------------------------------------------
SLASH_ALTCRAFTALERT1 = "/aca"
SLASH_ALTCRAFTALERT2 = "/altcraft"
SlashCmdList["ALTCRAFTALERT"] = function(msg)
    local cmd = string.lower(msg or "")
    if cmd == "config" or cmd == "options" or cmd == "opt" then
        InterfaceOptionsFrame_OpenToCategory(configPanel)
        InterfaceOptionsFrame_OpenToCategory(configPanel)
    else
        CheckCooldowns()
    end
end