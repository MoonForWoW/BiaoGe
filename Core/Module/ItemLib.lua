if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L
local GetClassColor = ns.GetClassColor

local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
local Size = ns.Size
local RGB = ns.RGB
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local Maxb = ns.Maxb
local HopeMaxn = ns.HopeMaxn
local HopeMaxb = ns.HopeMaxb
local HopeMaxi = ns.HopeMaxi
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID

local pt = print
local RealmID = GetRealmID()
local player = BG.myName
local _, class = UnitClass("player")

local MAXBUTTONS = 20
local BUTTONHEIGHT = 22
local WIDTH

local mainFrame
local db = {}
local dbByItemID = {}
local info = {}
local itemCacheState = {}
local itemCacheID = 0
local isYesItemCache = {}
local priceCache = {}
local currencyCache = {}
local exchangeIndex = {}
local exchangeIndexFB
local titleTbl
local maxhope
local CreateAllItemInfoCache, CheckItemInfo, Sort

-- 给获取途径排序
local typeIDtbl = {
    "raid",
    "sod_currency",
    "currency",
    "fb5",
    "quest",
    "faction",
    "profession",
    "world",
    "worldboss",
    "pvp",
    "pvp_currency",
}
local typeIDIndex = {}
for i, v in ipairs(typeIDtbl) do
    typeIDIndex[v] = i
end
local function GetTypeID(type)
    return typeIDIndex[type]
end

local function CreateLine(parent, y, width, height, color, alpha)
    local l = parent:CreateLine()
    l:SetColorTexture(RGB(color or "808080", alpha or 1))
    l:SetStartPoint("BOTTOMLEFT", 0, y)
    l:SetEndPoint("BOTTOMLEFT", width, y)
    l:SetThickness(height or 1.5)
    return l
end
local function GetHardNum(hard)
    for i, diffName in ipairs(BG.difficultyTable[BG.FB1]) do
        if hard == diffName then
            return i
        end
    end
end
local function AddPrice(itemID) -- 添加装备拍卖行价格
    if priceCache[itemID] ~= nil then
        return priceCache[itemID]
    end
    local m
    if BG.IsVanilla then
        m = BG.GetAuctionPrice(itemID, "notcopper")
    else
        m = BG.GetAuctionPrice(itemID, "notsilver")
    end
    priceCache[itemID] = m ~= "" and (" |cffFFFFFF" .. m .. RR) or ""
    return priceCache[itemID]
end
local function GetkExchangeItemInfo(itemID) -- 获取兑换物对应物品的ID和Link
    local currentFB = BG.FB1
    if exchangeIndexFB ~= currentFB then
        exchangeIndexFB = currentFB
        wipe(exchangeIndex)
        for _, FB in pairs(BG.phaseFBtable[currentFB]) do
            for exItemID, items in pairs(BG.Loot[FB].ExchangeItems) do
                for _, _itemID in pairs(items) do
                    _itemID = tonumber(_itemID) or _itemID
                    if not exchangeIndex[_itemID] then
                        exchangeIndex[_itemID] = { exItemID = exItemID, FB = FB }
                    end
                end
            end
        end
    end
    local exchange = exchangeIndex[tonumber(itemID) or itemID]
    if exchange then
        local itemInfo = info[exchange.FB] and info[exchange.FB][exchange.exItemID]
        return exchange.exItemID, itemInfo and itemInfo.link
    end
end
local function GetCurrencyInfoCached(currencyID)
    if not currencyCache[currencyID] then
        currencyCache[currencyID] = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    end
    return currencyCache[currencyID]
end
local function CreateLoadingText()
    local f = CreateFrame("Frame", nil, mainFrame.bg, "BackdropTemplate")
    f:SetSize(1, 1)
    f:SetPoint("TOP", 0, -38)
    f:SetFrameLevel(110)
    local t = f:CreateFontString()
    t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    t:SetPoint("TOP")
    t:SetText(L["读取中..."])
    return f
end

-- 第一步：先历遍所有来源的装备和兑换物，缓存装备的数据、鼠标提示工具文本
do
    local function IsCurrentCache(state)
        local current = itemCacheState[state.FB]
        return current and current.cacheID == state.cacheID
    end

    local function RequestUpdateForState(state)
        if itemCacheState[BG.FB1] ~= state then return end
        if mainFrame:IsVisible() then
            BG.UpdateItemLib()
        else
            BG.itemLibNeedUpdate = true
        end
    end

    local function InsertToAllItem(state, itemID)
        if state.isInsert[itemID] then return end
        state.isInsert[itemID] = true
        tinsert(state.allItem, itemID)
        BG.Tooltip_SetItemByID(itemID)
    end
    local function SaveItemInfo(state)
        local startI = 1
        local oneTime = 20
        local allCount = #state.allItem
        local cacheCount = 0
        local isDoing = true
        BG.OnUpdateTime(function(self, elapsed)
            if not IsCurrentCache(state) then
                self:SetScript("OnUpdate", nil)
                self:Hide()
                return
            end
            self.timeElapsed = self.timeElapsed + elapsed
            if cacheCount >= allCount or self.timeElapsed >= 2 then
                self:SetScript("OnUpdate", nil)
                self:Hide()
                state.status = "ready"
                if state.loadingText then
                    state.loadingText:Hide()
                    state.loadingText = nil
                end
                state.timedOut = cacheCount < allCount or nil
                if state.needUpdate then
                    state.needUpdate = nil
                    RequestUpdateForState(state)
                end
                return
            elseif isDoing then
                for ii = startI, startI + oneTime - 1 do
                    local itemID = state.allItem[ii]
                    if itemID then
                        BG.OnItemLoad(itemID):ContinueOnItemLoad(function()
                            if not IsCurrentCache(state) then return end
                            local name, link, quality, level, _, _, _, _, EquipLoc, Texture,
                            _, typeID, subclassID, bindType, _, setID = GetItemInfo(itemID)
                            if level > 1 then
                                local tooltipText = BG.GetTooltipTextLeftAll(itemID)
                                state.info[itemID] = {
                                    name = name,
                                    link = link,
                                    quality = quality,
                                    level = level,
                                    EquipLoc = EquipLoc,
                                    Texture = Texture,
                                    typeID = typeID,
                                    subclassID = subclassID,
                                    bindType = bindType,
                                    setID = setID,
                                    tooltipText = tooltipText,
                                }
                            end
                            cacheCount = cacheCount + 1
                            if state.status == "ready" and state.timedOut and cacheCount >= allCount then
                                state.timedOut = nil
                                RequestUpdateForState(state)
                            end
                        end)
                    else
                        isDoing = false
                        break
                    end
                end
                startI = startI + oneTime
            end
        end)
    end
    function CreateAllItemInfoCache(FB)
        itemCacheID = itemCacheID + 1
        local state = {
            FB = FB,
            cacheID = itemCacheID,
            status = "loading",
            info = {},
            allItem = {},
            isInsert = {},
        }
        itemCacheState[FB] = state
        info[FB] = state.info
        local delay = 0
        local add = 0.02
        -- 历遍同阶段的多个团本
        for _, FB in pairs(BG.phaseFBtable[FB]) do
            itemCacheState[FB] = state
            info[FB] = state.info
            -- 团本
            for _, hard in ipairs(BG.difficultyTable[FB]) do -- 历遍全部难度
                if BG.Loot[FB][hard] and next(BG.Loot[FB][hard]) then
                    BG.After(delay, function()
                        -- BOSS掉落
                        local ii = 1
                        while BG.Loot[FB][hard]["boss" .. ii] do
                            if not (FB == "TOC" and ii == 7 and hard:find("H")) then
                                for i, itemID in ipairs(BG.Loot[FB][hard]["boss" .. ii]) do
                                    InsertToAllItem(state, itemID)
                                end
                            end
                            ii = ii + 1
                        end
                    end)
                    delay = delay + add
                    BG.After(delay, function()
                        -- BOSS掉落后兑换的装备
                        local ii = 1
                        while BG.Loot[FB][hard]["boss" .. ii] do
                            if not (FB == "TOC" and ii == 7 and hard:find("H")) then
                                if BG.Loot[FB][hard]["boss" .. ii .. "other"] then
                                    for i, itemID in ipairs(BG.Loot[FB][hard]["boss" .. ii .. "other"]) do
                                        InsertToAllItem(state, itemID)
                                    end
                                end
                            end
                            ii = ii + 1
                        end
                        -- 团本任务奖励
                        if BG.Loot[FB][hard].Quest then
                            for name, _ in pairs(BG.Loot[FB][hard].Quest) do
                                for _, itemID in pairs(BG.Loot[FB][hard].Quest[name]) do
                                    InsertToAllItem(state, itemID)
                                end
                            end
                        end
                    end)
                    delay = delay + add
                end
            end
            -- 其他
            delay = delay + add
            BG.After(delay, function()
                -- 5人本
                for FB_5 in pairs(BG.Loot[FB].Team) do
                    for BossName, _ in pairs(BG.Loot[FB].Team[FB_5]) do
                        for _, itemID in pairs(BG.Loot[FB].Team[FB_5][BossName]) do
                            InsertToAllItem(state, itemID)
                        end
                    end
                end
                -- 任务
                for k, v in pairs(BG.Loot[FB].Quest) do
                    for i, itemID in ipairs(BG.Loot[FB].Quest[k].itemID) do
                        InsertToAllItem(state, itemID)
                    end
                end
                -- 牌子装备
                for itemID, v in pairs(BG.Loot[FB].Currency) do
                    InsertToAllItem(state, itemID)
                end
                -- 赛季服货币/牌子
                for i, v in pairs(BG.Loot[FB].Sod_Currency) do
                    for itemID, currency in pairs(BG.Loot[FB].Sod_Currency[i]) do
                        InsertToAllItem(state, itemID)
                    end
                end
                -- 声望装备
                for k, v in pairs(BG.Loot[FB].Faction) do
                    for i, itemID in ipairs(BG.Loot[FB].Faction[k]) do
                        InsertToAllItem(state, itemID)
                    end
                end
                -- 专业制造
                for k, v in pairs(BG.Loot[FB].Profession) do
                    for i, itemID in ipairs(BG.Loot[FB].Profession[k]) do
                        InsertToAllItem(state, itemID)
                    end
                end
                -- 世界掉落
                for i, itemID in ipairs(BG.Loot[FB].World) do
                    InsertToAllItem(state, itemID)
                end
                -- 世界BOSS
                for k, v in pairs(BG.Loot[FB].WorldBoss) do
                    for i, itemID in ipairs(BG.Loot[FB].WorldBoss[k]) do
                        InsertToAllItem(state, itemID)
                    end
                end
                -- PVP
                for k, v in pairs(BG.Loot[FB].PVP) do
                    for i, itemID in ipairs(BG.Loot[FB].PVP[k]) do
                        InsertToAllItem(state, itemID)
                    end
                end
                -- PVP货币
                for itemID, v in pairs(BG.Loot[FB].PVP_currency) do
                    InsertToAllItem(state, itemID)
                end
                -- 兑换物
                for itemID, v in pairs(BG.Loot[FB].ExchangeItems) do
                    InsertToAllItem(state, itemID)
                end
                -- 商店
                for _, v in pairs(BG.Loot[FB].Shop) do
                    InsertToAllItem(state, v.id)
                end
                -- 节日
                for _, holiday in pairs(BG.Loot[FB].Holiday) do
                    for _, itemID in pairs(holiday.items) do
                        InsertToAllItem(state, itemID)
                    end
                end
            end)
            delay = delay + add
        end
        BG.After(delay, function()
            if not IsCurrentCache(state) then return end
            SaveItemInfo(state)
        end)
        return state
    end
end

-- 第二步：找出符合条件的装备
do
    local function InsertDB(v)
        local old = dbByItemID[v.itemID]
        if old then
            tinsert(old.getTbl, v.get)
        else
            v.getTbl = { v.get }
            dbByItemID[v.itemID] = v
            tinsert(db, v)
        end
    end

    local function IsYesItem(itemID)
        if isYesItemCache[itemID] ~= nil then
            return isYesItemCache[itemID]
        end
        local FB = BG.FB1
        if not (info[FB] and info[FB][itemID]) then
            isYesItemCache[itemID] = false
            return false
        end
        local typeID = info[FB][itemID].typeID
        local EquipLoc = info[FB][itemID].EquipLoc
        if not (typeID == 2 or typeID == 4 or EquipLoc == "INVTYPE_TRINKET") then
            isYesItemCache[itemID] = false
            return false
        end

        local EquipLoc = info[FB][itemID].EquipLoc
        local isSameEquipLoc
        for _, _EquipLoc in pairs(BiaoGe.ItemLib.ItemLibInvType) do
            if EquipLoc == _EquipLoc then
                isSameEquipLoc = true
                break
            end
        end
        if not isSameEquipLoc then
            isYesItemCache[itemID] = false
            return false
        end

        if BiaoGe.ItemLib.iLevel[FB] then
            if info[FB][itemID].level < BiaoGe.ItemLib.iLevel[FB] then
                isYesItemCache[itemID] = false
                return false
            end
        end

        local subclassID = info[FB][itemID].subclassID
        local tooltipText = info[FB][itemID].tooltipText
        isYesItemCache[itemID] = not BG.FilterAll(itemID, typeID, EquipLoc, subclassID, tooltipText)
        return isYesItemCache[itemID]
    end
    local function InsertItemInfo(FB, itemID, _type, hard, ii, other)
        if not IsYesItem(itemID) then return end
        local link = info[FB][itemID].link
        local quality = info[FB][itemID].quality
        local level = info[FB][itemID].level
        local Texture = info[FB][itemID].Texture
        local bindType = info[FB][itemID].bindType
        local setID = info[FB][itemID].setID

        if _type == "raid" then -- 团本掉落
            local hardnum = GetHardNum(hard)
            local color = "|cff" .. "00BFFF"
            if strfind(hard, "10") then
                color = "|cff" .. "99CCFF"
            end
            if BG.IsCTM or BG.IsMOP then
                if hard == "N" then
                    color = "|cff" .. "99CCFF"
                end
            end
            if BG.IsRetail then
                if hard == "N" then
                    hard = "|cff" .. "00BFFF" .. hard .. "|r"
                elseif hard == "H" then
                    hard = "|cff" .. "FF0000" .. hard .. "|r"
                elseif hard == "M" then
                    hard = "|cff" .. "a335ee" .. hard .. "|r"
                end
            end

            local get
            local bossname

            if other and other ~= "other" then
                bossname = other
            else
                bossname = BG.Boss[FB]["boss" .. ii].name2
                if bossname == L["杂项"] then
                    if FB == 'TOCtitan' then
                        bossname = L["嘉奖宝箱"]
                    else
                        bossname = L["小怪"]
                    end
                end
            end
            if ii == Maxb[FB] then
                bossname = ""
            end

            -- 兑换物
            local exText = ""
            local exItemID, exItemLink = GetkExchangeItemInfo(itemID)
            if exItemLink then
                local tex = select(5, GetItemInfoInstant(exItemID))
                exText = " " .. AddTexture(tex) .. exItemLink
            end

            if BG.onlyOneHard then
                get = color .. BG.FBfromBossPosition[FB][ii].localName .. " " .. bossname .. exText .. AddPrice(itemID)
            else
                get = color .. BG.FBfromBossPosition[FB][ii].localName .. " " .. hard .. " " .. bossname .. exText .. AddPrice(itemID)
            end

            -- 团本正常掉落/兑换物（比如套装）
            local isRaid = true
            if other and exItemLink == "" then
                isRaid = false
            end

            local players
            if BG.IsVanilla then
                players = BG.GetFBinfo(FB, "maxplayers") or 10
            else
                players = tonumber(strmatch(hard, "%d+")) -- 副本规模10人/25人
            end

            InsertDB({
                FB = FB,
                isRaid = isRaid,
                itemID = itemID,
                link = link,
                level = level,
                quality = quality,
                texture = Texture,
                get = get,
                bindType = bindType,
                setID = setID,
                i = ii,
                hard = hard,
                hardnum = hardnum,
                players = players,
                type = GetTypeID(_type),
                type2 = FB,
                exItemID = exItemID,
            })
        elseif _type == "quest" then -- 野外任务
            local FBname = other.FBname
            local color = other.color
            local players = other.players
            local classID = other.classID
            local faction = other.faction
            local get

            if FBname ~= "" then
                FBname = FBname .. " "
            end

            -- 阵营
            if faction == 1 then
                faction = FACTION_ALLIANCE
            elseif faction == 2 then
                faction = FACTION_HORDE
            else
                faction = ""
            end

            -- 兑换物
            local exText = ""
            local exItemID, exItemLink = GetkExchangeItemInfo(itemID)
            if exItemLink then
                local tex = select(5, GetItemInfoInstant(exItemID))
                exText = " " .. AddTexture(tex) .. exItemLink
            end

            -- 是否职业任务
            if classID then
                local className, classFile = GetClassInfo(classID)
                local _, _, _, colorStr = GetClassColor(classFile)
                get = "|cff" .. color .. FBname .. "|c" .. colorStr .. className .. BG.STC_y1(QUESTS_LABEL) .. RR .. exText .. AddPrice(itemID) .. RR
            else
                get = "|cff" .. color .. FBname .. BG.STC_y1(faction .. QUESTS_LABEL) .. RR .. exText .. AddPrice(itemID) .. RR
            end

            InsertDB({
                itemID = itemID,
                link = link,
                level = level,
                quality = quality,
                texture = Texture,
                get = get,
                bindType = bindType,
                setID = setID,
                i = 0,
                players = players,
                type = GetTypeID(_type),
            })
        elseif _type == "currency" then -- 牌子
            local v = other
            local count = v.count
            local currencyID = v.currencyID
            local phase = v.phase
            local phaseText = ""
            if phase then
                phaseText = " |cff808080<" .. phase .. ">|r"
            end
            local otherItemID1 = v.otherItemID1
            local otherItemID1Count = v.otherItemID1Count
            local otherText = ""
            if otherItemID1 then
                local otherItemID1CountText = ""
                if otherItemID1Count and otherItemID1Count ~= 1 then
                    otherItemID1CountText = "x" .. otherItemID1Count
                end
                local name, link, quality, level, _, _, _, _, EquipLoc, Texture, _, typeID, subclassID, bindType = GetItemInfo(otherItemID1)
                otherText = " + " .. AddTexture(Texture) .. link .. otherItemID1CountText
            end

            local info = GetCurrencyInfoCached(currencyID)
            local name = info.name
            local tex = info.iconFileID
            local quantity = info.quantity
            local color = "00FF00"
            if count then
                if quantity < count then
                    color = "FF0000"
                end
            else
                count = ""
            end
            local get = BG.STC_y1(AddTexture(tex) .. name .. " " .. "|cff" .. color .. count .. RR) .. AddPrice(itemID) .. otherText .. phaseText

            InsertDB({
                itemID = itemID,
                link = link,
                level = level,
                quality = quality,
                texture = Texture,
                get = get,
                bindType = bindType,
                setID = setID,
                type = GetTypeID(_type),
                type2 = get,
            })
        elseif _type == "faction" then -- 声望
            local tbl = {
                FACTION_STANDING_LABEL4,
                FACTION_STANDING_LABEL5,
                FACTION_STANDING_LABEL6,
                FACTION_STANDING_LABEL7,
                FACTION_STANDING_LABEL8,
            }
            local faction, standingID = strsplit(":", other)
            local standing = ""
            if standingID then
                standing = "-" .. tbl[tonumber(standingID)]
            end
            local factionName = GetFactionInfoByID(faction) or ""

            local name = REPUTATION .. ": " .. factionName .. standing
            local get = BG.STC_g2(name) .. AddPrice(itemID)

            InsertDB({
                itemID = itemID,
                link = link,
                level = level,
                quality = quality,
                texture = Texture,
                get = get,
                bindType = bindType,
                setID = setID,
                type = GetTypeID(_type),
                type2 = faction,
            })
        elseif _type == "profession" then -- 专业制造
            local icon = ""
            if other == "锻造" then
                icon = AddTexture(136241, nil, ":100:100:8:92:8:92")
            elseif other == "制皮" then
                icon = AddTexture(133611, nil, ":100:100:8:92:8:92")
            elseif other == "裁缝" then
                icon = AddTexture(136249, nil, ":100:100:8:92:8:92")
            elseif other == "工程" then
                icon = AddTexture(136243, nil, ":100:100:8:92:8:92")
            elseif other == "附魔" then
                icon = AddTexture(136244, nil, ":100:100:8:92:8:92")
            elseif other == "珠宝加工" or other == "珠宝" then
                icon = AddTexture(134071, nil, ":100:100:8:92:8:92")
            elseif other == "铭文" then
                icon = AddTexture(237171, nil, ":100:100:8:92:8:92")
            elseif other == "考古" then
                icon = AddTexture(441139, nil, ":100:100:8:92:8:92")
            elseif other == "炼金" then
                icon = AddTexture(136240, nil, ":100:100:8:92:8:92")
            end
            local name = icon .. TRADE_SKILLS .. ": " .. L[other]
            local get = BG.STC_y2(name) .. AddPrice(itemID)
            InsertDB({
                itemID = itemID,
                link = link,
                level = level,
                quality = quality,
                texture = Texture,
                get = get,
                bindType = bindType,
                setID = setID,
                type = GetTypeID(_type),
                type2 = other,
            })
        elseif _type == "fb5" then -- 5人本
            local FB_5, BossName = strsplit("#", other)

            -- 兑换物
            local exText = ""
            local exItemID, exItemLink = GetkExchangeItemInfo(itemID)
            if exItemLink then
                local tex = select(5, GetItemInfoInstant(exItemID))
                exText = " " .. AddTexture(tex) .. exItemLink
            end

            local get = "|cff" .. "9999FF" .. FB_5 .. " " .. BossName .. exText .. RR .. AddPrice(exItemID or itemID)

            InsertDB({
                itemID = itemID,
                link = link,
                level = level,
                quality = quality,
                texture = Texture,
                get = get,
                bindType = bindType,
                setID = setID,
                type = GetTypeID(_type),
                type2 = FB_5,
            })
        elseif _type == "world" then -- 世界掉落
            -- 兑换物
            local exText = ""
            local exItemID, exItemLink = GetkExchangeItemInfo(itemID)
            if exItemLink then
                local tex = select(5, GetItemInfoInstant(exItemID))
                exText = " " .. AddTexture(tex) .. exItemLink
            end

            local get = "|cff" .. "DEB887" .. L["世界掉落"] .. RR .. exText .. AddPrice(exItemID or itemID)

            InsertDB({
                itemID = itemID,
                link = link,
                level = level,
                quality = quality,
                texture = Texture,
                get = get,
                bindType = bindType,
                setID = setID,
                type = GetTypeID(_type),
            })
        elseif _type == "worldboss" then -- 世界BOSS
            -- 兑换物
            local exText = ""
            local exItemID, exItemLink = GetkExchangeItemInfo(itemID)
            if exItemLink then
                local tex = select(5, GetItemInfoInstant(exItemID))
                exText = " " .. AddTexture(tex) .. exItemLink
            end

            local name = L["世界BOSS"] .. " " .. L[other]
            local get = "|cff" .. "FF6347" .. name .. exText .. AddPrice(itemID)

            InsertDB({
                itemID = itemID,
                link = link,
                level = level,
                quality = quality,
                texture = Texture,
                get = get,
                bindType = bindType,
                setID = setID,
                type = GetTypeID(_type),
            })
        elseif _type == "pvp" then -- PVP
            local faction, levelID = strsplit(":", other)
            local tx
            if faction == "Alliance" then
                tx = "1"
            elseif faction == "Horde" then
                tx = "0"
            end
            local tbl = {
                _G["PVP_RANK_5_" .. tx],
                _G["PVP_RANK_6_" .. tx],
                _G["PVP_RANK_7_" .. tx],
                _G["PVP_RANK_8_" .. tx],
                _G["PVP_RANK_9_" .. tx],
                _G["PVP_RANK_10_" .. tx],
                _G["PVP_RANK_11_" .. tx],
                _G["PVP_RANK_12_" .. tx],
                _G["PVP_RANK_13_" .. tx],
                _G["PVP_RANK_14_" .. tx],
                _G["PVP_RANK_15_" .. tx],
                _G["PVP_RANK_16_" .. tx],
                _G["PVP_RANK_17_" .. tx],
                _G["PVP_RANK_18_" .. tx],
            }

            local standing = tbl[tonumber(levelID)]
            local newID
            if tonumber(levelID) < 10 then
                newID = "0" .. levelID
            else
                newID = levelID
            end
            local icon = AddTexture("interface/pvprankbadges/pvprank" .. newID) or ""

            local name = "PVP: " .. standing .. icon
            local get = "|cff" .. "EE82EE" .. name .. RR .. AddPrice(itemID)

            InsertDB({
                itemID = itemID,
                link = link,
                level = level,
                quality = quality,
                texture = Texture,
                get = get,
                bindType = bindType,
                setID = setID,
                type = GetTypeID(_type),
            })
        elseif _type == "sod_currency" then -- 赛季服货币/牌子
            local _get, count, icon, color, _type = strsplit("-", other)
            local get
            if _type and _type ~= "" then
                count = select(2, GetItemInfo(count)) or ""
            end
            if icon == "" then
                icon = select(5, GetItemInfoInstant(count))
                get = format("|cff%s%s|r %s%s|r%s", color, _get, AddTexture(icon), count, AddPrice(itemID))
            else
                get = format("|cff%s%s|r %s%s|r%s", color, _get, count, AddTexture(icon), AddPrice(itemID))
            end
            InsertDB({
                itemID = itemID,
                link = link,
                level = level,
                quality = quality,
                texture = Texture,
                get = get,
                bindType = bindType,
                setID = setID,
                type = GetTypeID(_type),
                type2 = get,
            })
        elseif _type == "pvp_currency" then -- 牌子
            local v = other
            local count = v.count
            local currencyID = v.currencyID
            local phase = v.phase
            local phaseText = ""
            if phase then
                phaseText = " |cff808080<" .. phase .. ">|r"
            end
            local otherItemID1 = v.otherItemID1
            local otherItemID1Count = v.otherItemID1Count
            local otherText = ""
            if otherItemID1 then
                local otherItemID1CountText = ""
                if otherItemID1Count and otherItemID1Count ~= 1 then
                    otherItemID1CountText = "x" .. otherItemID1Count
                end
                local name, link, quality, level, _, _, _, _, EquipLoc, Texture, _, typeID, subclassID, bindType = GetItemInfo(otherItemID1)
                otherText = " + " .. AddTexture(Texture) .. link .. otherItemID1CountText
            end

            local currencyInfo = GetCurrencyInfoCached(currencyID)
            local name = currencyInfo.name
            local tex = currencyInfo.iconFileID
            local quantity = currencyInfo.quantity
            local color = "00FF00"
            if count then
                if quantity < count then
                    color = "FF0000"
                end
            else
                count = ""
            end
            local get = "|cffEE82EE" .. (AddTexture(tex) .. name .. " " .. "|cff" .. color .. count .. RR) .. AddPrice(itemID) .. otherText .. phaseText

            InsertDB({
                itemID = itemID,
                link = link,
                level = level,
                quality = quality,
                texture = Texture,
                get = get,
                bindType = bindType,
                setID = setID,
                type = GetTypeID(_type),
            })
        elseif _type == "shop" then -- 商人
            local name = L["商人"] .. " " .. GetMoneyString(other)
            local get = "|cff" .. "EE82EE" .. name

            InsertDB({
                itemID = itemID,
                link = link,
                level = level,
                quality = quality,
                texture = Texture,
                get = get,
                bindType = bindType,
                setID = setID,
                type = GetTypeID(_type),
            })
        elseif _type == "holiday" then -- 节日
            local get = "|cff" .. "FF9900" .. L["节日:"] .. other

            InsertDB({
                itemID = itemID,
                link = link,
                level = level,
                quality = quality,
                texture = Texture,
                get = get,
                bindType = bindType,
                setID = setID,
                type = GetTypeID(_type),
            })
        end
    end
    function CheckItemInfo()
        db = {}
        dbByItemID = {}
        isYesItemCache = {}
        priceCache = {}
        currencyCache = {}
        local FB = BG.FB1
        local hard, ii, k, otherID
        for _, FB in pairs(BG.phaseFBtable[FB]) do
            -- 团本
            for _, hard in ipairs(BG.difficultyTable[FB]) do
                local trueRaidDifficulty = true
                if BG.onlyOneHard then
                    if BiaoGe.ItemLib.fitlerGet.raid then
                        trueRaidDifficulty = false
                    end
                else
                    if BiaoGe.ItemLib.fitlerGet.raidmyth and strfind(hard, "M") then
                        trueRaidDifficulty = false
                    elseif BiaoGe.ItemLib.fitlerGet.raidhero and strfind(hard, "H") then
                        trueRaidDifficulty = false
                    elseif BiaoGe.ItemLib.fitlerGet.raidnormal and strfind(hard, "N") then
                        trueRaidDifficulty = false
                    elseif BiaoGe.ItemLib.fitlerGet.raid25 and strfind(hard, "25") then
                        trueRaidDifficulty = false
                    elseif BiaoGe.ItemLib.fitlerGet.raid10 and strfind(hard, "10") then
                        trueRaidDifficulty = false
                    end
                end

                if trueRaidDifficulty then
                    if BG.Loot[FB][hard] then
                        local ii = 1
                        while BG.Loot[FB][hard]["boss" .. ii] do
                            if not (FB == "TOC" and ii == 7 and hard:find("H")) then
                                for i, itemID in ipairs(BG.Loot[FB][hard]["boss" .. ii]) do
                                    InsertItemInfo(FB, itemID, "raid", hard, ii, k)
                                end
                                -- BOSS掉落后兑换的装备
                                if BG.Loot[FB][hard]["boss" .. ii .. "other"] then
                                    for i, itemID in ipairs(BG.Loot[FB][hard]["boss" .. ii .. "other"]) do
                                        InsertItemInfo(FB, itemID, "raid", hard, ii, "other")
                                    end
                                end
                            end
                            ii = ii + 1
                        end
                        -- 团本任务奖励
                        local ii = 1
                        if BG.Loot[FB][hard].Quest then
                            for name, _ in pairs(BG.Loot[FB][hard].Quest) do
                                for _, itemID in pairs(BG.Loot[FB][hard].Quest[name]) do
                                    InsertItemInfo(FB, itemID, "raid", hard, ii, name)
                                end
                            end
                        end
                    end
                end
            end
            -- 5人本
            if not BiaoGe.ItemLib.fitlerGet.fb5 then
                for FB_5 in pairs(BG.Loot[FB].Team) do
                    for BossName, _ in pairs(BG.Loot[FB].Team[FB_5]) do
                        for _, itemID in pairs(BG.Loot[FB].Team[FB_5][BossName]) do
                            InsertItemInfo(FB, itemID, "fb5", hard, ii, FB_5 .. "#" .. BossName)
                        end
                    end
                end
            end
            -- 野外任务
            for k, v in pairs(BG.Loot[FB].Quest) do
                for i, itemID in ipairs(BG.Loot[FB].Quest[k].itemID) do
                    InsertItemInfo(FB, itemID, "quest", hard, ii, v)
                end
            end
            -- 牌子装备
            if not BiaoGe.ItemLib.fitlerGet.currency then
                for itemID, v in pairs(BG.Loot[FB].Currency) do
                    InsertItemInfo(FB, itemID, "currency", hard, ii, v)
                end
            end
            -- 赛季服货币/牌子
            if not BiaoGe.ItemLib.fitlerGet.currency then
                for i, v in pairs(BG.Loot[FB].Sod_Currency) do
                    for itemID, currency in pairs(BG.Loot[FB].Sod_Currency[i]) do
                        InsertItemInfo(FB, itemID, "sod_currency", hard, ii, currency)
                    end
                end
            end
            -- 声望装备
            if not BiaoGe.ItemLib.fitlerGet.faction then
                for k, v in pairs(BG.Loot[FB].Faction) do
                    for i, itemID in ipairs(BG.Loot[FB].Faction[k]) do
                        InsertItemInfo(FB, itemID, "faction", hard, ii, k)
                    end
                end
            end
            -- 专业制造
            if not BiaoGe.ItemLib.fitlerGet.profession then
                for k, v in pairs(BG.Loot[FB].Profession) do
                    for i, itemID in ipairs(BG.Loot[FB].Profession[k]) do
                        InsertItemInfo(FB, itemID, "profession", hard, ii, k)
                    end
                end
            end
            -- 世界掉落
            if not BiaoGe.ItemLib.fitlerGet.world then
                for i, itemID in ipairs(BG.Loot[FB].World) do
                    InsertItemInfo(FB, itemID, "world", hard, ii, k)
                end
            end
            -- 世界BOSS
            if not BiaoGe.ItemLib.fitlerGet.worldboss then
                for k, v in pairs(BG.Loot[FB].WorldBoss) do
                    for i, itemID in ipairs(BG.Loot[FB].WorldBoss[k]) do
                        InsertItemInfo(FB, itemID, "worldboss", hard, ii, k)
                    end
                end
            end
            -- PVP
            if not BiaoGe.ItemLib.fitlerGet.pvp then
                for k, v in pairs(BG.Loot[FB].PVP) do
                    for i, itemID in ipairs(BG.Loot[FB].PVP[k]) do
                        InsertItemInfo(FB, itemID, "pvp", hard, ii, k)
                    end
                end
            end
            -- PVP货币
            if not BiaoGe.ItemLib.fitlerGet.pvp then
                for itemID, v in pairs(BG.Loot[FB].PVP_currency) do
                    InsertItemInfo(FB, itemID, "pvp_currency", hard, ii, v)
                end
            end
            -- 商店
            if not BiaoGe.ItemLib.fitlerGet.shop then
                for _, v in pairs(BG.Loot[FB].Shop) do
                    InsertItemInfo(FB, v.id, "shop", hard, ii, v.m)
                end
            end
            -- 节日
            if not BiaoGe.ItemLib.fitlerGet.holiday then
                for _, holiday in pairs(BG.Loot[FB].Holiday) do
                    for _, itemID in pairs(holiday.items) do
                        InsertItemInfo(FB, itemID, "holiday", hard, ii, holiday.name)
                    end
                end
            end
        end
    end

    -- 排序
    function Sort()
        local tbl
        if BiaoGe.ItemLib.itemLibOrderButtonID == 2 then -- 按装等排序
            tbl = {
                { key = "level", order = 1 },
                { key = "quality", order = 1 },
                { key = "type", order = 4 },
                { key = "type2", order = 1 },
                { key = "players", order = 3 },
            }
        elseif BiaoGe.ItemLib.itemLibOrderButtonID == 3 then -- 按装备品质排序
            tbl = {
                { key = "quality", order = 1 },
                { key = "level", order = 1 },
                { key = "type", order = 4 },
                { key = "type2", order = 1 },
                { key = "players", order = 3 },
            }
        elseif BiaoGe.ItemLib.itemLibOrderButtonID == 4 then -- 按获取途径排序
            tbl = {
                { key = "type", order = 2 },
                { key = "type2", order = 2 },
                { key = "players", order = 3 },
                { key = "hardnum", order = 3 },
                { key = "level", order = 3 },
                { key = "quality", order = 3 },
            }
        end
        tinsert(tbl, { key = "i", order = 3 })
        tinsert(tbl, { key = "hardnum", order = 3 })

        sort(db, function(a, b)
            for _, v in ipairs(tbl) do
                local key = v.key
                if a[key] and b[key] then
                    if a[key] ~= b[key] then
                        local order = v.order
                        if order == 1 then
                            if BiaoGe.ItemLib.itemLibOrder == 1 then
                                return a[key] > b[key]
                            else
                                return b[key] > a[key]
                            end
                        elseif order == 2 then
                            if BiaoGe.ItemLib.itemLibOrder == 1 then
                                return b[key] > a[key]
                            else
                                return a[key] > b[key]
                            end
                        elseif order == 3 then
                            return a[key] > b[key]
                        elseif order == 4 then
                            return a[key] < b[key]
                        end
                    end
                end
            end
            return false
        end)

        local sorter = BG.ItemLibMainFrame.sorter
        local bt = BG.ItemLibMainFrame["title" .. BiaoGe.ItemLib.itemLibOrderButtonID]
        sorter:SetParent(bt)
        sorter:ClearAllPoints()
        if bt.textJustifyH == "CENTER" then
            sorter:SetPoint("LEFT", bt, "CENTER", bt.textwidth / 2, 0)
        else
            sorter:SetPoint("LEFT", bt, "LEFT", bt.textwidth, 0)
        end
        if not mainFrame.isnewsorter then
            if BiaoGe.ItemLib.itemLibOrder == 1 then
                sorter:SetTexCoord(0, 0.5, 0, 1)
            else
                sorter:SetTexCoord(0, 0.5, 1, 0)
            end
        end
    end
end

local itemRowPool = {}
local itemRenderFrame = CreateFrame("Frame")
local itemUpdateID = 0
local ITEM_ROWS_PER_FRAME = 5

local function ItemLibCellOnMouseDown(self, button)
    local row = self.row
    local data = row and row.data
    if not data then return end

    if BG.IsSetBestPriceKeyDown(button == "RightButton") then
        BG.SetBestPrice(data.link, self)
    elseif IsShiftKeyDown() then
        BG.InsertLink(data.link)
    elseif IsAltKeyDown() then
        if row.item.hope:IsVisible() then return end
        local itemID = GetItemInfoInstant(data.link)
        local nandu, boss, FB, isRaid = data.hardnum, data.i, data.FB, data.isRaid
        if not (isRaid and nandu and boss and FB) then
            UIErrorsFrame:AddMessage(L["只能设置团本BOSS正常掉落的装备为心愿"], RED_FONT_COLOR:GetRGB())
            return
        end
        local exItemID, exItemLink = GetkExchangeItemInfo(itemID)
        BG.SetHope(exItemID and exItemLink or data.link, FB, true)
    elseif IsControlKeyDown() then
        DressUpItemLink(data.link)
    end
end

local function ItemLibCellOnEnter(self)
    local row = self.row
    local data = row and row.data
    if not data then return end

    if self.column == 4 and #data.getTbl > 1 then
        BiaoGeTooltip2:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 0)
        BiaoGeTooltip2:ClearLines()
        local text = BG.STC_w1(L["多个获取途径"]) .. NN .. NN
        for _, getText in ipairs(data.getTbl) do
            text = text .. getText .. NN
        end
        BiaoGeTooltip2:SetText(text)
    elseif self.onenter and self.column ~= 3 then
        BiaoGeTooltip2:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 0)
        BiaoGeTooltip2:ClearLines()
        BiaoGeTooltip2:AddLine(self.onenter, 1, 1, 1, false)
        BiaoGeTooltip2:Show()
    end

    local point
    if BG.ButtonIsInRight(mainFrame.bg) then
        GameTooltip:SetOwner(mainFrame.bg.tooltip2, "ANCHOR_BOTTOMLEFT", 0, 0)
        point = 'LEFT'
    else
        GameTooltip:SetOwner(mainFrame.bg.tooltip, "ANCHOR_BOTTOMRIGHT", 0, 0)
        point = 'RIGHT'
    end
    GameTooltip:ClearLines()
    GameTooltip:SetHyperlink(BG.SetSpecIDToLink(data.link))
    BG.SetZUGSetTooltip(data.itemID, point)
    row.ds:Show()

    BG.DressUpLastButton = self
    if IsControlKeyDown() and not IsShiftKeyDown() then
        SetCursor("Interface/Cursor/Inspect")
        BG.DressUp()
    elseif IsAltKeyDown() then
        SetCursor("interface/cursor/quest")
    end
    BG.canShowInspectCursor = true
    BG.canShowHopeCursor = true
end

local function ItemLibCellOnLeave(self)
    GameTooltip:Hide()
    BiaoGeTooltip2:Hide()
    if self.row then
        self.row.ds:Hide()
    end
    SetCursor(nil)
    BG.canShowInspectCursor = false
    BG.canShowHopeCursor = false
    if BG.DressUpFrame then
        BG.DressUpFrame:Hide()
    end
    BG.DressUpLastButton = nil
end

local function CreateItemLibRow()
    local row = CreateFrame("Frame", nil, mainFrame.child)
    row.cells = {}
    local lastCell

    for i, titleInfo in ipairs(titleTbl) do
        local cell = i == 1 and row or CreateFrame("Frame", nil, row)
        cell.row = row
        cell.column = i
        cell:SetSize(titleInfo.width - (i == #titleTbl and 2 or 0), BUTTONHEIGHT)
        if i > 1 then
            cell:SetPoint("LEFT", lastCell, "RIGHT", 0, 0)
        end
        lastCell = cell
        row.cells[i] = cell

        cell.Text = cell:CreateFontString()
        cell.Text:SetFont(BIAOGE_TEXT_FONT, i == 1 and 13 or 15, "OUTLINE")
        cell.Text:SetPoint("CENTER")
        cell.Text:SetTextColor(RGB(titleInfo.color))
        if i == 1 then
            cell.Text:SetTextColor(RGB(BG.dis))
        end
        cell.Text:SetJustifyH(titleInfo.JustifyH)
        cell.Text:SetWidth(cell:GetWidth())
        cell.Text:SetWordWrap(false)
        cell:SetScript("OnMouseDown", ItemLibCellOnMouseDown)
        BG.OnEnterDelay(cell, ItemLibCellOnEnter, BG.itemOnEnterDelay)
        BG.OnLeaveDelay(cell, ItemLibCellOnLeave)
    end

    row.item = row.cells[3]
    row.get = row.cells[4]

    BG.BindOnEquip(row.item, nil, row.item:GetHeight())
    row.item.bindingTex.owner = row.item
    row.item.bindingTex:SetScript("OnEnter", function(self)
        BiaoGeTooltip2:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
        BiaoGeTooltip2:ClearLines()
        BiaoGeTooltip2:AddLine(L["装绑"], 1, 1, 1, true)
        BiaoGeTooltip2:Show()
        local owner = self.owner
        owner:GetScript("OnEnter")(owner)
    end)
    row.item.bindingTex:SetScript("OnLeave", function(self)
        local owner = self.owner
        owner:GetScript("OnLeave")(owner)
    end)

    local hope = CreateFrame("Frame", nil, row.item)
    hope:SetSize(50, 20)
    hope:SetPoint("RIGHT", -5, 0)
    hope:SetFrameLevel(110)
    hope.row = row
    hope:Hide()
    row.item.hope = hope
    local hopeText = hope:CreateFontString()
    hopeText:SetPoint("RIGHT")
    hopeText:SetSize(50, 20)
    hopeText:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    hopeText:SetTextColor(RGB(BG.y2))
    hopeText:SetText(BG.STC_g1(L["心愿"]))
    hopeText:SetJustifyH("RIGHT")
    hope:SetWidth(hopeText:GetWrappedWidth())
    hope:SetScript("OnEnter", function(self)
        local owner = self.row.item
        BiaoGeTooltip2:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
        BiaoGeTooltip2:ClearLines()
        BiaoGeTooltip2:AddLine(BG.STC_g1(L["心愿装备"]), 1, 1, 1, true)
        local itemID = owner.itemID
        local exItemID, exItemLink = GetkExchangeItemInfo(itemID)
        if exItemLink then
            local tex = select(5, GetItemInfoInstant(exItemID))
            BiaoGeTooltip2:AddLine(AddTexture(tex) .. exItemLink .. L["掉落后会提醒"], 1, 1, 1, true)
        else
            BiaoGeTooltip2:AddLine(L["掉落后会提醒"], 1, 1, 1, true)
        end
        BiaoGeTooltip2:AddLine(AddTexture("RIGHT") .. L["取消心愿装备"], 1, 0.82, 0, true)
        BiaoGeTooltip2:Show()
        owner:GetScript("OnEnter")(owner)
    end)
    hope:SetScript("OnLeave", function(self)
        local owner = self.row.item
        owner:GetScript("OnLeave")(owner)
    end)
    hope:SetScript("OnMouseDown", function(self, button)
        if button ~= "RightButton" then return end
        local data = self.row.data
        if not data then return end
        local itemID = GetItemID(data.link)
        local exItemID = GetkExchangeItemInfo(itemID)
        BG.DeleteHope(exItemID or itemID, BG.FB1)
        BG.UpdateItemLib_LeftHope_All()
        BG.UpdateItemLib_RightHope_All()
    end)

    local haved = row.item:CreateTexture(nil, "OVERLAY")
    haved:SetSize(28, 28)
    haved:SetPoint("LEFT", row.item, "LEFT", -5, 0)
    haved:SetTexture("interface/raidframe/readycheck-ready")
    haved:Hide()
    row.item.haved = haved

    BG.LootedText(row.get)

    row.ds = row:CreateTexture()
    row.ds:SetSize(WIDTH, row:GetHeight())
    row.ds:SetPoint("LEFT")
    row.ds:SetColorTexture(1, 1, 1, 0.1)
    row.ds:Hide()
    CreateLine(row, 0, WIDTH, 1, nil, 0.2)

    return row
end

local function ReleaseItemLibRows()
    for _, row in ipairs(mainFrame.buttons) do
        row:Hide()
        row:ClearAllPoints()
        row.data = nil
        row.itemID = nil
        row.exItemID = nil
        row.ds:Hide()
        row.item.hope:Hide()
        row.item.haved:Hide()
        row.item.bindingTex:Hide()
        row.get.looted:Hide()
        for _, cell in ipairs(row.cells) do
            cell:SetScript("OnUpdate", nil)
            cell.isOnEnter = nil
            cell.onenter = nil
            cell.itemID = nil
            cell.itemLink = nil
            cell.exItemID = nil
        end
    end
    wipe(mainFrame.buttons)
    mainFrame.buttoncount = 0
end

local function BindItemLibRow(ii, vv)
    local row = itemRowPool[ii]
    if not row then
        row = CreateItemLibRow()
        itemRowPool[ii] = row
    end
    mainFrame.buttons[ii] = row
    mainFrame.buttoncount = ii
    row.data = vv
    row.num = ii
    row.itemID = GetItemID(vv.link)
    row.exItemID = vv.exItemID
    row:ClearAllPoints()
    if ii == 1 then
        row:SetPoint("TOPLEFT", mainFrame.child, 10, 0)
    else
        row:SetPoint("TOPLEFT", mainFrame.buttons[ii - 1], "BOTTOMLEFT", 0, 0)
    end

    local setText = ""
    if vv.setID then
        setText = format(L["|c%s★|r"], select(4, GetItemQualityColor(vv.quality)))
    end
    local values = {
        ii,
        vv.level,
        AddTexture(vv.texture) .. setText .. vv.link .. setText,
        vv.getTbl[1],
    }
    for i, cell in ipairs(row.cells) do
        cell.num = ii
        cell.itemID = GetItemInfoInstant(vv.link)
        cell.itemLink = vv.link
        cell.exItemID = vv.exItemID
        cell.onenter = nil
        local value = values[i]
        if i == 4 and #vv.getTbl > 1 then
            cell.Text:SetText(value .. "\n\n")
        else
            cell.Text:SetText(value)
        end
        if cell.Text:GetStringWidth() > cell.Text:GetWidth() or tostring(value):find("\n", 1, true) then
            cell.onenter = value
        end
    end

    BG.BindOnEquip(row.item, vv.bindType, row.item:GetHeight())
    row.item.hope:SetShown(vv.isRaid and BG.IsHope(vv.exItemID or vv.itemID, vv.FB) or false)
    row.item.haved:SetShown(BG.GetItemCount(vv.itemID) ~= 0)
    BG.Update_IsLooted(row.get, vv.itemID)
    row.ds:Hide()
    row:Show()
end

local function StopItemLibRender()
    itemRenderFrame:SetScript("OnUpdate", nil)
    itemRenderFrame.task = nil
end

local function ProcessItemLibRows(self)
    local task = self.task
    if not task or task.updateID ~= itemUpdateID then
        StopItemLibRender()
        return
    end

    local lastIndex = min(task.index + ITEM_ROWS_PER_FRAME - 1, #task.rows)
    for ii = task.index, lastIndex do
        BindItemLibRow(ii, task.rows[ii])
    end
    task.index = lastIndex + 1

    if task.index > #task.rows then
        local onComplete = task.onComplete
        StopItemLibRender()
        if onComplete then
            onComplete()
        end
    end
end

local function SetItemLib(updateID, onComplete)
    mainFrame.scroll.ScrollBar:Hide()
    ReleaseItemLibRows()

    local rows = {}
    for i, v in ipairs(db) do
        rows[i] = v
    end
    itemRenderFrame.task = {
        updateID = updateID,
        rows = rows,
        index = 1,
        onComplete = onComplete,
    }

    if #rows == 0 then
        StopItemLibRender()
        if onComplete then
            onComplete()
        end
        return
    end

    itemRenderFrame:SetScript("OnUpdate", ProcessItemLibRows)
    ProcessItemLibRows(itemRenderFrame)
end
local function UpdateTiptext()
    local FB = BG.FB1
    if BiaoGe.FilterClassItemDB[RealmID][player].chooseID then
        mainFrame.noItem:SetText(L["该部位没有合适当前过滤方案的装备"])
    else
        mainFrame.noItem:SetText(L["请在下方选择一个过滤方案"])
    end
    mainFrame.noItem:SetShown(not next(db))

    local P = BG.GetFBinfo(FB, "phase")
    local B = ""
    for i, v in ipairs(BG.invtypetable) do
        if v.key[1] == BiaoGe.ItemLib.ItemLibInvType[1] then
            B = (v.name)
        end
    end

    local F = BG.STC_dis(L["没有过滤方案"])
    local n = BiaoGe.FilterClassItemDB[RealmID][player].chooseID
    if n then
        F = BiaoGe.FilterClassItemDB[RealmID][player][n].Name
    end

    local C
    local count = #db
    if count == 0 then
        C = BG.STC_dis(count .. L["件"])
    else
        C = BG.STC_g1(count .. L["件"])
    end
    mainFrame.toptitle:SetText(BG.STC_b1(P .. "   " .. B .. "   " .. F .. "   " .. C))
end

local function BeginItemLibUpdate()
    itemUpdateID = itemUpdateID + 1
    StopItemLibRender()
    return itemUpdateID
end

local function StartUpdate(updateID)
    if not updateID then
        updateID = BeginItemLibUpdate()
    elseif updateID ~= itemUpdateID then
        return
    end
    CheckItemInfo() -- 找出符合条件的装备
    BG.After(0, function()
        if updateID ~= itemUpdateID then return end
        Sort()
        BG.After(0, function()
            if updateID ~= itemUpdateID then return end
            SetItemLib(updateID, UpdateTiptext) -- 生成列表
        end)
    end)
end

local function StartSort()
    local state = itemCacheState[BG.FB1]
    if not state or state.status ~= "ready" then
        BG.UpdateItemLib()
        return
    end

    local updateID = BeginItemLibUpdate()
    Sort()
    BG.After(0, function()
        if updateID ~= itemUpdateID then return end
        SetItemLib(updateID, UpdateTiptext)
    end)
end

function BG.UpdateItemLib()
    if not mainFrame:IsVisible() then return end
    BG.itemLibNeedUpdate = false
    local updateID = BeginItemLibUpdate()
    local FB = BG.FB1
    local state = itemCacheState[FB]
    if not state then
        state = CreateAllItemInfoCache(FB)
    end
    if state.status ~= "ready" then
        state.needUpdate = true
        if not state.loadingText then
            state.loadingText = CreateLoadingText()
        end
        return
    end
    StartUpdate(updateID)
end

function BG.UpdateAllItemLib()
    BG.UpdateItemLib()
    BG.UpdateItemLib_RightHope_All()
    BG.UpdateItemLib_RightHope_IsHaved_All()
    BG.UpdateItemLib_RightHope_IsLooted_All()
    BG.ItemLibMainFrame.iLevelEdit:SetText(BiaoGe.ItemLib.iLevel[BG.FB1] or "")
end

-- 更新心愿装备
do
    function BG.GetEquipLocName(EquipLoc) -- 返回该装备部位对应的invtypetable名称
        return BG.invtypetable2[EquipLoc]
    end

    local function CheckIsSame_ItemLib_RightHope(itemID)
        for i, v in ipairs(BG.invtypetable) do
            local EquipLoc = v.name2
            for i = 1, maxhope do
                local hope = mainFrame.Hope[EquipLoc .. i]
                local _itemID = GetItemID(hope:GetText())
                if _itemID == itemID then
                    return true
                end
            end
        end
    end
    function BG.UpdateItemLib_RightHope(itemIDorLink, ShoworHide) -- 更新心愿汇总，ShoworHide：1为添加装备，0为删除装备
        local FB = BG.FB1
        local _EquipLoc, Texture = select(4, GetItemInfoInstant(itemIDorLink))
        local EquipLoc = BG.GetEquipLocName(_EquipLoc)
        if not EquipLoc then
            local itemID = type(itemIDorLink) == 'string' and GetItemID(itemIDorLink) or itemIDorLink
            local tbl = BG.Loot[FB].ExchangeItems[itemID]
            if tbl then
                local lastExItem = tbl[1]
                if lastExItem then
                    EquipLoc = BG.GetEquipLocName(select(4, GetItemInfoInstant(lastExItem)))
                end
            end
        end
        if not EquipLoc then return end
        -- 只需历遍对应部位的心愿格子
        for i = 1, maxhope do
            local hope = mainFrame.Hope[EquipLoc .. i]
            if ShoworHide == 1 then
                if not CheckIsSame_ItemLib_RightHope(itemIDorLink) then
                    if hope:GetText() == "" then
                        hope:SetText(AddTexture(Texture) .. itemIDorLink)
                        hope:SetCursorPosition(0)
                        return
                    end
                end
            else
                if GetItemID(hope:GetText()) == itemIDorLink then
                    hope:SetText("")
                end
            end
        end
    end

    function BG.UpdateItemLib_LeftHope(itemID, ShoworHide)
        local count = mainFrame.buttoncount
        if count then
            for i = 1, count do
                local f = mainFrame.buttons[i]
                if f then
                    local _itemID = f.exItemID or f.itemID
                    if itemID == _itemID then
                        if ShoworHide == 1 then
                            f.item.hope:Show()
                        else
                            f.item.hope:Hide()
                        end
                    end
                end
            end
        end
    end

    function BG.UpdateItemLib_LeftHope_HideAll()
        local count = mainFrame.buttoncount
        if count then
            for i = 1, count do
                if mainFrame.buttons[i] then
                    mainFrame.buttons[i].item.hope:Hide()
                end
            end
        end
    end

    function BG.UpdateItemLib_RightHope_HideAll()
        for i, v in ipairs(BG.invtypetable) do
            local EquipLoc = v.name2
            for i = 1, maxhope do
                local hope = mainFrame.Hope[EquipLoc .. i]
                hope:SetText("")
            end
        end
    end

    function BG.UpdateItemLib_LeftHope_All()
        BG.UpdateItemLib_LeftHope_HideAll()
        for _, FB in pairs(BG.phaseFBtable[BG.FB1]) do
            for n = HopeMaxn[FB], 1, -1 do
                for b = HopeMaxb[FB], 1, -1 do
                    for i = 1, HopeMaxi do
                        local link = BiaoGe.Hope[RealmID][player][FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                        if link then
                            local itemID = GetItemID(link)
                            if itemID then
                                BG.UpdateItemLib_LeftHope(itemID, 1)
                            end
                        end
                    end
                end
            end
        end
    end

    function BG.UpdateItemLib_RightHope_All()
        BG.UpdateItemLib_RightHope_HideAll()
        local FBtable = BG.phaseFBtable[BG.FB1]
        if BG.IsVanilla_60 then
            FBtable = { BG.FB1 }
        end
        for _, FB in pairs(FBtable) do
            for n = HopeMaxn[FB], 1, -1 do
                for b = HopeMaxb[FB], 1, -1 do
                    for i = 1, HopeMaxi do
                        local link = BiaoGe.Hope[RealmID][player][FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                        if link and GetItemID(link) then
                            BG.UpdateItemLib_RightHope(link, 1)
                        end
                    end
                end
            end
        end
    end

    function BG.Update_IsHaved(bt)
        local itemID = GetItemID(bt:GetText())
        if itemID then
            if BG.GetItemCount(itemID) ~= 0 then
                bt.haved:Show()
            else
                bt.haved:Hide()
            end
        else
            bt.haved:Hide()
        end
    end

    function BG.UpdateItemLib_LeftLib_IsHaved_All()
        local count = mainFrame.buttoncount
        if count then
            for i = 1, count do
                if mainFrame.buttons[i] then
                    local item = mainFrame.buttons[i].item
                    local itemID = mainFrame.buttons[i].itemID
                    if BG.GetItemCount(itemID) ~= 0 then
                        item.haved:Show()
                    else
                        item.haved:Hide()
                    end
                end
            end
        end
    end

    function BG.UpdateItemLib_RightHope_IsHaved_All()
        if mainFrame:IsVisible() then
            for k, bt in pairs(mainFrame.Hope) do
                if type(bt) == "table" and bt.EquipLoc then
                    BG.Update_IsHaved(bt)
                end
            end
        end
    end

    function BG.Update_IsLooted(bt, itemID)
        local FB = BG.FB1
        local itemID = itemID or GetItemID(bt:GetText())
        if itemID then
            for b = 1, Maxb[FB] do
                for i = 1, BG.GetMaxi(FB, b) do
                    local zb = BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]
                    if zb then
                        local _itemID = BG.GetLeiTingItem(GetItemID(zb:GetText()), FB)
                        if itemID == _itemID then
                            bt.looted:Show()
                            return
                        end
                    end
                end
            end
        end
        bt.looted:Hide()
    end

    function BG.UpdateItemLib_LeftLib_IsLooted_All()
        local count = mainFrame.buttoncount
        if count then
            for i = 1, count do
                if mainFrame.buttons[i] then
                    local get = mainFrame.buttons[i].get
                    local itemID = mainFrame.buttons[i].itemID
                    BG.Update_IsLooted(get, itemID)
                end
            end
        end
    end

    function BG.UpdateItemLib_RightHope_IsLooted_All()
        if mainFrame:IsVisible() then
            for k, bt in pairs(mainFrame.Hope) do
                if type(bt) == "table" and bt.EquipLoc then
                    BG.Update_IsLooted(bt)
                end
            end
        end
    end

    function BG.UpdateHopeFrame_IsLooted_All()
        local FB = BG.FB1
        if BG["HopeFrame" .. FB]:IsVisible() then
            for n = 1, HopeMaxn[FB] do
                for b = 1, HopeMaxb[FB] do
                    for i = 1, HopeMaxi do
                        local hope = BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                        if hope then
                            BG.Update_IsLooted(hope)
                        end
                    end
                end
            end
            for k, bt in pairs(mainFrame.Hope) do
                if type(bt) == "table" and bt.EquipLoc then
                    BG.Update_IsLooted(bt)
                end
            end
        end
    end
end


------------------------------------------------------------------------
------------------------------------------------------------------------

function BG.ItemLibUI()
    BiaoGe.ItemLibInvType = nil
    BiaoGe.ItemLib = BiaoGe.ItemLib or {}
    BiaoGe.ItemLib.ItemLibInvType = BiaoGe.ItemLib.ItemLibInvType or { "INVTYPE_HEAD" }
    BiaoGe.ItemLib.itemLibOrderButtonID = BiaoGe.ItemLib.itemLibOrderButtonID or 3
    BiaoGe.ItemLib.itemLibOrder = BiaoGe.ItemLib.itemLibOrder or 1
    BiaoGe.ItemLib.fitlerGet = BiaoGe.ItemLib.fitlerGet or {}
    BiaoGe.ItemLib.iLevel = BiaoGe.ItemLib.iLevel or {}

    mainFrame = BG.ItemLibMainFrame
    mainFrame.buttons = {}

    BG.itemLib_Hope_Buttons = {}
    BG.itemLib_Inv_Buttons = {}

    titleTbl = {
        { name = L["序号"], width = 35, color = "FFFFFF", JustifyH = "CENTER" },
        { name = L["等级"], width = 60, color = "FFFFFF", JustifyH = "CENTER" },
        { name = L["装备"], width = 180, color = "FFFFFF", JustifyH = "LEFT", type = "item" },
        { name = L["获取途径"], width = 250, color = "FFFFFF", JustifyH = "LEFT" },
    }
    WIDTH = 20
    for i, v in ipairs(titleTbl) do
        WIDTH = WIDTH + v.width
    end

    function BG.InvOnClick(self)
        BiaoGe.ItemLib.ItemLibInvType = self.key
        BG.UpdateItemLib()

        for i, bt in ipairs(BG.itemLib_Inv_Buttons) do
            if bt.inv == self.inv then
                bt:Disable()
            else
                bt:Enable()
            end
        end
        for i, bt in ipairs(BG.itemLib_Hope_Buttons) do
            if bt.inv == self.inv then
                bt:Disable()
            else
                bt:Enable()
            end
        end

        BG.PlaySound(1)
    end

    local function Next_OnClick(nextbutton)
        for i, v in ipairs(BG.invtypetable) do
            if BiaoGe.ItemLib.ItemLibInvType[1] == v.key[1] then
                if nextbutton._type == "next" then
                    if BG.invtypetable[i + 1] then
                        nextbutton.key = BG.invtypetable[i + 1].key
                        nextbutton.inv = BG.invtypetable[i + 1].name2
                    else
                        nextbutton.key = BG.invtypetable[1].key
                        nextbutton.inv = BG.invtypetable[1].name2
                    end
                elseif nextbutton._type == "prev" then
                    if BG.invtypetable[i - 1] then
                        nextbutton.key = BG.invtypetable[i - 1].key
                        nextbutton.inv = BG.invtypetable[i - 1].name2
                    else
                        nextbutton.key = BG.invtypetable[#BG.invtypetable].key
                        nextbutton.inv = BG.invtypetable[#BG.invtypetable].name2
                    end
                end
                break
            end
        end

        if not nextbutton.key then
            nextbutton.key = BG.invtypetable[1].key
            nextbutton.inv = BG.invtypetable[1].name2
        end

        BG.InvOnClick(nextbutton)
    end
    local function OnMouseWheel(self, delta)
        local nextbutton = {}
        if delta == 1 then
            nextbutton._type = "prev"
        else
            nextbutton._type = "next"
        end
        Next_OnClick(nextbutton)
    end

    -- UI
    do
        -- Frame
        do
            local f = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 10,
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            f:SetBackdropColor(0, 0, 0, 0.4)
            f:SetSize(WIDTH + 20, BUTTONHEIGHT * (MAXBUTTONS + 1) + 20)
            f:SetPoint("TOPLEFT", BG.MainFrame, 30, -80)
            mainFrame.bg = f
            local scroll = CreateFrame("ScrollFrame", nil, f, "BiaoGe_ModernScrollFrameTemplate")
            scroll:SetPoint("TOPLEFT", 0, -35)
            scroll:SetPoint("BOTTOMRIGHT", -30, 5)
            scroll.ScrollBar.scrollStep = BUTTONHEIGHT * 4
            BG.CreateSrollBarBackdrop(scroll.ScrollBar)
            BG.HookScrollBarShowOrHide(scroll)
            mainFrame.scroll = scroll
            local child = CreateFrame("Frame", nil, scroll)
            child:SetSize(1, 1)
            mainFrame.child = child
            scroll:SetScrollChild(child)
            -- 鼠标提示定位
            local _f = CreateFrame("Frame", nil, f)
            _f:SetSize(1, 1)
            _f:SetPoint("TOPRIGHT", 0, 1)
            f.tooltip = _f
            local _f = CreateFrame("Frame", nil, f)
            _f:SetSize(1, 1)
            _f:SetPoint("TOPLEFT", 0, 1)
            f.tooltip2 = _f
            -- 排序按钮
            local sorter = f:CreateTexture(nil, "OVERLAY")
            sorter:SetSize(8, 8)
            sorter:SetTexture("Interface/Buttons/ui-sortarrow")
            mainFrame.sorter = sorter
            -- 头顶大标题
            local t = f:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("BOTTOM", mainFrame.bg, "TOP", 0, 0)
            mainFrame.toptitle = t
            -- 没有合适的装备
            local t = f:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOP", 0, -38)
            t:SetTextColor(.5, .5, .5)
            mainFrame.noItem = t
        end

        -- 标题
        local buttons = {}
        for i, v in ipairs(titleTbl) do
            local bt = CreateFrame("Button", nil, mainFrame.bg, "BackdropTemplate")
            bt:SetSize(titleTbl[i].width, BUTTONHEIGHT)
            if i == 1 then
                bt:SetPoint("TOPLEFT", 10, -10)
            else
                bt:SetPoint("LEFT", buttons[i - 1], "RIGHT", 0, 0)
            end
            bt:SetNormalFontObject(BG.FontWhite15)
            bt:SetText(titleTbl[i].name)
            bt.textwidth = bt:GetFontString():GetStringWidth()
            bt.textJustifyH = titleTbl[i].JustifyH
            bt.sortOrder = 1
            bt.id = i
            bt:SetHighlightTexture("Interface/PaperDollInfoFrame/UI-Character-Tab-Highlight")
            bt:Disable()
            if i ~= 1 then
                bt:Enable()
            end
            mainFrame["title" .. i] = bt
            tinsert(buttons, bt)

            bt.text = bt:GetFontString()
            bt.text:SetTextColor(RGB(titleTbl[i].color))
            bt.text:SetJustifyH(titleTbl[i].JustifyH)
            bt.text:SetWidth(bt:GetWidth())
            bt.text:SetWordWrap(false)
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                mainFrame.isnewsorter = nil
                if BiaoGe.ItemLib.itemLibOrderButtonID ~= self.id then
                    mainFrame.isnewsorter = true
                end
                if not mainFrame.isnewsorter then
                    BiaoGe.ItemLib.itemLibOrder = BiaoGe.ItemLib.itemLibOrder == 1 and 0 or 1
                end
                BiaoGe.ItemLib.itemLibOrderButtonID = self.id
                StartSort()
            end)
        end
        CreateLine(mainFrame["title1"], 0, WIDTH - 20)

        -- 获取途径过滤
        do
            local parent = mainFrame["title4"]
            local bt = CreateFrame("Button", nil, parent) -- 下滚
            bt:SetSize(35, 25)
            bt:SetPoint("RIGHT", parent, "RIGHT", 5, 0)
            bt.normalTex = bt:CreateTexture()
            bt.normalTex:SetPoint("CENTER")
            bt.normalTex:SetSize(20, 20)
            bt.normalTex:SetTexture("interface/garrison/garrisonbuildingui")
            bt.normalTex:SetTexCoord(0.28, 0.33, 0.9, 1)
            bt:SetNormalTexture(bt.normalTex)
            bt.highlightTex = bt:CreateTexture()
            bt.highlightTex:SetPoint("CENTER")
            bt.highlightTex:SetSize(20, 20)
            bt.highlightTex:SetTexture("interface/garrison/garrisonbuildingui")
            bt.highlightTex:SetTexCoord(0.28, 0.33, 0.9, 1)
            bt:SetHighlightTexture(bt.highlightTex)
            mainFrame.fitlerGetButton = bt
            bt:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["获取途径显示"], 1, 1, 1, true)
                GameTooltip:Show()
            end)
            bt:SetScript("OnLeave", GameTooltip_Hide)


            local function UpdateTex()
                local hasFitlerGet
                for kk, vv in pairs(BG.itemLibGetFiter) do
                    for k, v in pairs(BiaoGe.ItemLib.fitlerGet) do
                        if vv.name2 == k then
                            hasFitlerGet = true
                            break
                        end
                    end
                    if hasFitlerGet then break end
                end
                if hasFitlerGet then
                    bt.normalTex:SetVertexColor(0, 1, 0)
                    bt.highlightTex:SetVertexColor(0, 1, 0)
                else
                    bt.normalTex:SetVertexColor(1, 1, 1)
                    bt.highlightTex:SetVertexColor(1, 1, 1)
                end
            end
            UpdateTex()

            local f = CreateFrame("Frame", nil, bt, "BackdropTemplate")
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 10,
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            f:SetBackdropColor(0, 0, 0, 0.8)
            f:SetSize(180, #BG.itemLibGetFiter * 25 + 40)
            f:SetPoint("TOPLEFT", mainFrame.bg, "TOPRIGHT", 0, 1)
            f:EnableMouse(true)
            f:SetFrameLevel(110)
            f:Hide()

            mainFrame.fitlerGetButton:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                if f:IsVisible() then
                    f:Hide()
                else
                    f:Show()
                end
            end)

            local t = f:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOP", f, "TOP", 0, -10)
            t:SetTextColor(RGB("FFD100"))
            t:SetText(L["获取途径显示"])
            t:SetJustifyH("CENTER")

            BG.CreateCloseButton(f)

            local buttons = {}
            for i, v in ipairs(BG.itemLibGetFiter) do
                local bt = CreateFrame("CheckButton", nil, f, "ChatConfigCheckButtonTemplate")
                bt:SetSize(25, 25)
                if i == 1 then
                    bt:SetPoint("TOPLEFT", f, 10, -30)
                else
                    bt:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT", 0, -0)
                end
                bt.name = v.name
                bt.name2 = v.name2
                bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                bt.Text:SetText(v.name)
                bt:SetHitRectInsets(0, -bt.Text:GetWidth(), 0, 0)
                bt.Text:SetWidth(150)
                bt.Text:SetWordWrap(false)

                tinsert(buttons, bt)
                if BiaoGe.ItemLib.fitlerGet[bt.name2] then
                    bt:SetChecked(false)
                else
                    bt:SetChecked(true)
                end
                bt:SetScript("OnClick", function(self)
                    BG.PlaySound(1)
                    if self:GetChecked() then
                        BiaoGe.ItemLib.fitlerGet[self.name2] = nil
                    else
                        BiaoGe.ItemLib.fitlerGet[self.name2] = true
                    end
                    UpdateTex()
                    BG.UpdateItemLib()
                end)
            end
        end
    end

    -- 装备部位
    do
        BG.invtypetable = {
            { name = INVTYPE_HEAD, name2 = "INVTYPE_HEAD", key = { "INVTYPE_HEAD" } },                                                                 -- 头
            { name = INVTYPE_NECK, name2 = "INVTYPE_NECK", key = { "INVTYPE_NECK" } },                                                                 -- 项链
            { name = INVTYPE_SHOULDER, name2 = "INVTYPE_SHOULDER", key = { "INVTYPE_SHOULDER" } },                                                     -- 肩膀
            { name = INVTYPE_CLOAK, name2 = "INVTYPE_CLOAK", key = { "INVTYPE_CLOAK" } },                                                              -- 背
            { name = INVTYPE_CHEST, name2 = "INVTYPE_CHEST", key = { "INVTYPE_CHEST", "INVTYPE_ROBE" } },                                              -- 胸
            { name = INVTYPE_WRIST, name2 = "INVTYPE_WRIST", key = { "INVTYPE_WRIST" } },                                                              -- 手腕
            { name = INVTYPE_HAND, name2 = "INVTYPE_HAND", key = { "INVTYPE_HAND" } },                                                                 -- 手
            { name = INVTYPE_WAIST, name2 = "INVTYPE_WAIST", key = { "INVTYPE_WAIST" } },                                                              -- 腰带
            { name = INVTYPE_LEGS, name2 = "INVTYPE_LEGS", key = { "INVTYPE_LEGS" } },                                                                 -- 腿
            { name = INVTYPE_FEET, name2 = "INVTYPE_FEET", key = { "INVTYPE_FEET" } },                                                                 -- 脚
            { name = INVTYPE_FINGER, name2 = "INVTYPE_FINGER", key = { "INVTYPE_FINGER" } },                                                           -- 戒指
            { name = INVTYPE_TRINKET, name2 = "INVTYPE_TRINKET", key = { "INVTYPE_TRINKET" } },                                                        -- 饰品
            { name = TWO_HANDED, name2 = "TWO_HANDED", key = { "INVTYPE_2HWEAPON" } },                                                                 -- 双手
            { name = INVTYPE_WEAPON, name2 = "INVTYPE_WEAPON", key = { "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND" } },                                 -- 单手
            { name = INVTYPE_SHIELD, name2 = "INVTYPE_SHIELD", key = { "INVTYPE_SHIELD", "INVTYPE_HOLDABLE", "INVTYPE_WEAPONOFFHAND" } },              -- 副手
            { name = INVTYPE_RANGED, name2 = "INVTYPE_RANGED", key = { "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT", "INVTYPE_THROWN", "INVTYPE_RELIC" } }, -- 远程
            -- { name = INVTYPE_RANGED, name2 = "INVTYPE_RANGED", key = { "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT", "INVTYPE_THROWN" } },     -- 远程
            -- { name = INVTYPE_RELIC, name2 = "INVTYPE_RELIC", key = { "INVTYPE_RELIC" } },                                                 -- 圣物
        }
        BG.invtypetable2 = {}
        for _, v in ipairs(BG.invtypetable) do
            for _, EquipLoc in ipairs(v.key) do
                BG.invtypetable2[EquipLoc] = v.name2
            end
        end

        local f = CreateFrame("Frame", nil, mainFrame.bg, "BackdropTemplate")
        f:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(0, 0, 0, 0.4)
        f:SetSize(WIDTH + 20, 0)
        f:SetPoint("TOPLEFT", f:GetParent(), "BOTTOMLEFT", 0, -10)
        mainFrame.invtypeFrame = f
        f:SetScript("OnMouseWheel", OnMouseWheel)

        local l = 6
        for i, v in ipairs(BG.invtypetable) do
            local bt = CreateFrame("Button", nil, f)
            bt:SetSize(80, BUTTONHEIGHT)
            bt:SetNormalFontObject(BG.FontGreen15)
            bt:SetDisabledFontObject(BG.FontWhite18)
            bt:SetHighlightFontObject(BG.FontWhite15)
            if i == 1 then
                bt:SetPoint("TOPLEFT", 10, -10)
                f:SetHeight(BUTTONHEIGHT + 20)
            elseif (i - 1) % l == 0 then
                bt:SetPoint("TOPLEFT", BG.itemLib_Inv_Buttons[i - l], "BOTTOMLEFT", 0, 0)
                f:SetHeight(BUTTONHEIGHT * ((i - 1) / l + 1) + 20)
            else
                bt:SetPoint("LEFT", BG.itemLib_Inv_Buttons[i - 1], "RIGHT", 0, 0)
            end
            bt:SetText(v.name)
            BG.ButtonTextSetWordWrap(bt)
            bt.inv = v.name2
            bt.key = v.key
            tinsert(BG.itemLib_Inv_Buttons, bt)
            if v.key[1] == BiaoGe.ItemLib.ItemLibInvType[1] then
                bt:Disable()
            end

            local tex = bt:CreateTexture(nil, "ARTWORK") -- 高亮材质
            tex:ClearAllPoints()
            tex:SetSize(bt:GetFontString():GetWrappedWidth() + 20, 20)
            tex:SetPoint("CENTER")
            tex:SetTexture("interface/paperdollinfoframe/ui-character-tab-highlight")
            bt:SetHighlightTexture(tex)

            bt:SetScript("OnClick", BG.InvOnClick)
        end

        local bt = CreateFrame("Button", nil, f)
        bt:SetSize(BUTTONHEIGHT + 5, BUTTONHEIGHT)
        bt:SetNormalTexture("interface/buttons/ui-spellbookicon-nextpage-up")
        bt:SetPushedTexture("interface/buttons/ui-spellbookicon-nextpage-down")
        bt:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight")
        bt:SetPoint("BOTTOMRIGHT", -20, 5)
        bt._type = "next"
        local nextbt = bt
        bt:SetScript("OnClick", Next_OnClick)

        local bt = CreateFrame("Button", nil, f)
        bt:SetSize(nextbt:GetWidth(), BUTTONHEIGHT)
        bt:SetNormalTexture("interface/buttons/ui-spellbookicon-prevpage-up")
        bt:SetPushedTexture("interface/buttons/ui-spellbookicon-prevpage-down")
        bt:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight")
        bt:SetPoint("RIGHT", nextbt, "LEFT", 0, 0)
        bt._type = "prev"
        bt:SetScript("OnClick", Next_OnClick)
    end

    -- 装等过滤
    do
        local t = mainFrame:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetPoint("TOPLEFT", BG.ItemLibMainFrame.invtypeFrame, "BOTTOMLEFT", 10, -10)
        t:SetTextColor(1, 0.82, 0)
        t:SetText(L["仅显示高于该装等的装备："])
        t:SetJustifyH("LEFT")
        BG.ItemLibMainFrame.iLevelText = t

        local edit = CreateFrame("EditBox", nil, mainFrame, BG.editTemplate)
        edit:SetSize(100, 20)
        edit:SetPoint("LEFT", t, "RIGHT", 10, 0)
        edit:SetAutoFocus(false)
        edit:SetNumeric(true)
        edit:SetText(BiaoGe.ItemLib.iLevel[BG.FB1] or "")
        BG.ItemLibMainFrame.iLevelEdit = edit
        BG.SetEditBaseClass(edit)
        edit:HookScript("OnTextChanged", function(self)
            if self:HasFocus() then
                local FB = BG.FB1
                BiaoGe.ItemLib.iLevel[FB] = tonumber(self:GetText())
                BG.UpdateItemLib()
            end
        end)
        edit:SetScript("OnMouseDown", function(self, button)
            if button == "RightButton" then
                self:SetEnabled(false)
                self:SetText("")
                local FB = BG.FB1
                BiaoGe.ItemLib.iLevel[FB] = nil
                BG.UpdateItemLib()
            end
        end)
    end

    -- 过滤方案
    do
        local t = mainFrame:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetPoint("TOPLEFT", BG.ItemLibMainFrame.iLevelText, "BOTTOMLEFT", 0, -25)
        t:SetText(L["过滤方案："])
        t:SetTextColor(1, 0.82, 0)
        BG.ItemLibMainFrame.filtleText = t
    end

    -- 心愿汇总
    do
        local w = 120
        local w_jiange = 5
        local h_jiange = 1
        local width = 80 + (w + w_jiange) * 4 + 25

        local f = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
        f:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(0, 0, 0, 0.4)
        f:SetSize(width, mainFrame.bg:GetHeight())
        f:SetPoint("TOPLEFT", mainFrame.bg, "TOPRIGHT", 30, 0)
        mainFrame.Hope = f

        -- 头顶大标题
        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetPoint("BOTTOM", mainFrame.Hope, "TOP", 0, 0)
        t:SetText(L["心愿汇总"])
        t:SetTextColor(RGB(BG.b1))
        -- 底下提示文字
        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
        t:SetPoint("TOP", mainFrame.Hope, "BOTTOM", 0, 0)
        t:SetText(AddTexture("RIGHT") .. L["（删除心愿装备）"])

        local title_table = {
            { name = "", width = 80, color = "FFFFFF", JustifyH = "CENTER" },
            { name = L["心愿"] .. 1, width = w, color = "FFFFFF", JustifyH = "LEFT" },
            { name = L["心愿"] .. 2, width = w, color = "FFFFFF", JustifyH = "LEFT" },
            { name = L["心愿"] .. 3, width = w, color = "FFFFFF", JustifyH = "LEFT" },
            { name = L["心愿"] .. 4, width = w, color = "FFFFFF", JustifyH = "LEFT" },
        }
        maxhope = #title_table - 1
        -- 标题
        local right
        for i, v in ipairs(title_table) do
            local f = CreateFrame("Frame", nil, f)
            f:SetSize(title_table[i].width, BUTTONHEIGHT)
            if i == 1 then
                f:SetPoint("TOPLEFT", 10, -10)
            elseif i == 2 then
                f:SetPoint("LEFT", right, "RIGHT", w_jiange, 0)
            else
                f:SetPoint("LEFT", right, "RIGHT", w_jiange, 0)
            end
            local t = f:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("CENTER")
            t:SetText(title_table[i].name)
            t:SetTextColor(RGB(title_table[i].color))
            t:SetJustifyH(title_table[i].JustifyH)
            t:SetWidth(f:GetWidth())
            t:SetWordWrap(false)
            right = f
            mainFrame["Hopetitle" .. i] = f
        end
        -- CreateLine(mainFrame["Hopetitle1"], 0, width - 25)

        local right
        local function CreateSlotButton(i, v, ii)
            local bt = CreateFrame("Button", nil, f)
            bt:SetSize(title_table[ii].width, BUTTONHEIGHT + 4)
            bt:SetNormalFontObject(BG.FontGold15)
            bt:SetDisabledFontObject(BG.FontWhite15)
            bt:SetHighlightFontObject(BG.FontWhite15)
            if i == 1 then
                bt:SetPoint("TOPLEFT", 10, -32)
            else
                bt:SetPoint("TOP", BG.itemLib_Hope_Buttons[i - 1], "BOTTOM", 0, -h_jiange)
            end
            bt:SetText(v.name)
            bt.text = bt:GetFontString()
            bt.text:SetWidth(bt:GetWidth())
            bt.text:SetJustifyH(title_table[ii].JustifyH)
            bt.text:SetWordWrap(false)
            bt.inv = v.name2
            bt.key = v.key
            BG.itemLib_Hope_Buttons[i] = bt
            right = bt
            if v.key[1] == BiaoGe.ItemLib.ItemLibInvType[1] then
                bt:Disable()
            end

            local tex = bt:CreateTexture(nil, "ARTWORK") -- 高亮材质
            tex:ClearAllPoints()
            tex:SetSize(bt:GetFontString():GetWrappedWidth() + 20, 20)
            tex:SetPoint("CENTER")
            tex:SetTexture("interface/paperdollinfoframe/ui-character-tab-highlight")
            bt:SetHighlightTexture(tex)

            bt:SetScript("OnClick", BG.InvOnClick)
            bt:SetScript("OnMouseWheel", OnMouseWheel)
        end
        local function CreateEdit(i, v, ii)
            local edit = CreateFrame("EditBox", nil, f, BG.editTemplate)
            edit:SetSize(title_table[ii].width, BUTTONHEIGHT)
            edit:SetPoint("LEFT", right, "RIGHT", w_jiange, 0)
            edit:SetAutoFocus(false)
            edit:Disable()
            edit.EquipLoc = v.name2
            right = edit
            mainFrame.Hope[v.name2 .. (ii - 1)] = edit
            -- 已掉落文字
            BG.LootedText(edit)

            -- 是否已拥有
            edit.haved = edit:CreateTexture(nil, "OVERLAY")
            edit.haved:SetSize(25, 25)
            edit.haved:SetPoint("LEFT", edit, "LEFT", -5, 0)
            edit.haved:SetTexture("interface/raidframe/readycheck-ready")
            edit.haved:Hide()

            -- 悬停底色
            edit.ds = edit:CreateTexture()
            edit.ds:SetPoint("TOPLEFT", -4, -2)
            edit.ds:SetPoint("BOTTOMRIGHT", -1, 0)
            edit.ds:SetColorTexture(1, 1, 1, BG.onEnterAlpha)
            edit.ds:Hide()

            edit:SetScript("OnTextChanged", function(self)
                local text = self:GetText()
                local name, link, quality, level, _, _, _, _, EquipLoc, Texture, _, typeID, subclassID, bindType = GetItemInfo(text)

                local num = BiaoGe.FilterClassItemDB[RealmID][player].chooseID -- 隐藏
                if num ~= 0 then
                    BG.UpdateFilter(self)
                end

                -- 已拥有
                BG.Update_IsHaved(self)
                -- 装绑图标
                BG.BindOnEquip(self, bindType)
                -- 在按钮右边增加装等显示
                BG.LevelText(self, level, typeID)
                -- 更新已掉落
                BG.Update_IsLooted(self)
            end)
            edit:SetScript("OnMouseDown", function(self, button)
                if button == "RightButton" and not IsAltKeyDown() then
                    local itemID = GetItemID(self:GetText())
                    if itemID then
                        local exItemID = GetkExchangeItemInfo(itemID)
                        BG.DeleteHope(exItemID or itemID, BG.FB1)
                        BG.UpdateItemLib_LeftHope_All()
                        BG.UpdateItemLib_RightHope_All()
                    end
                else
                    local link = self:GetText()
                    local itemID = GetItemID(link)
                    if itemID then
                        link = select(2, GetItemInfo(link))
                        if BG.IsSetBestPriceKeyDown(button == "RightButton") then
                            BG.SetBestPrice(link, self)
                        elseif IsShiftKeyDown() then
                            BG.InsertLink(link)
                        elseif IsControlKeyDown() then
                            DressUpItemLink(link)
                            -- elseif IsAltKeyDown() and BG.SetBestPrice then
                            --     BG.SetBestPrice(link)
                        end
                    end
                end
            end)
            edit:SetScript("OnEnter", function(self)
                local link = self:GetText()
                local itemID = GetItemInfoInstant(link)
                if itemID then
                    local point
                    if BG.ButtonIsInRight(self) then
                        GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
                        point = 'LEFT'
                    else
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                        point = 'RIGHT'
                    end
                    GameTooltip:ClearLines()
                    GameTooltip:SetHyperlink(BG.SetSpecIDToLink(link))
                    BG.SetZUGSetTooltip(itemID, point)

                    BG.DressUpLastButton = self
                    if IsControlKeyDown() and not IsShiftKeyDown() then
                        SetCursor("Interface/Cursor/Inspect")
                        BG.DressUp()
                    end
                    BG.canShowTrunToItemLibCursor = true
                end
                self.ds:Show()
            end)
            edit:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
                self.ds:Hide()
                SetCursor(nil)
                BG.canShowTrunToItemLibCursor = false
                if BG.DressUpFrame then
                    BG.DressUpFrame:Hide()
                end
                BG.DressUpLastButton = nil
            end)
        end
        for i, v in ipairs(BG.invtypetable) do
            for ii, vv in ipairs(title_table) do
                if ii == 1 then
                    CreateSlotButton(i, v, ii)
                else
                    CreateEdit(i, v, ii)
                end
            end
        end
    end
end

BG.itemLibNeedUpdate = true
BG.Init2(function()
    mainFrame.first = true
    mainFrame:HookScript("OnShow", function(self)
        if BG.itemLibNeedUpdate then
            BG.After(mainFrame.first and 0.2 or 0, function()
                BG.UpdateItemLib()
            end)
        end
        BG.UpdateItemLib_LeftHope_All()
        BG.UpdateItemLib_LeftLib_IsHaved_All()
        BG.UpdateItemLib_LeftLib_IsLooted_All()
        BG.UpdateItemLib_RightHope_All()
        mainFrame.first = nil
    end)
end)
