local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L
local GetClassColor = ns.GetClassColor
local HS = {}

local RGB = ns.RGB
local GetClassRGB = ns.GetClassRGB
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID
local SendSystemMessage = BG.SendSystemMessage
local After = C_Timer.After
local realmName = BG.realmName

local classNameTbl = {
    WARRIOR = GetClassInfo(1),
    PALADIN = GetClassInfo(2),
    HUNTER = GetClassInfo(3),
    ROGUE = GetClassInfo(4),
    PRIEST = GetClassInfo(5),
    DEATHKNIGHT = GetClassInfo(6),
    SHAMAN = GetClassInfo(7),
    MAGE = GetClassInfo(8),
    WARLOCK = GetClassInfo(9),
    MONK = GetClassInfo(10),
    DRUID = GetClassInfo(11),
    DEMONHUNTER = GetClassInfo(12),
    EVOKER = GetClassInfo(13),
}

local function GetClassName(classFile)
    return classNameTbl[classFile]
end

local function CreateLine(parent, y, width, height, color, alpha)
    local line = parent:CreateLine()
    line:SetColorTexture(RGB(color or "808080", alpha or 1))
    line:SetStartPoint("BOTTOMLEFT", 0, y)
    line:SetEndPoint("BOTTOMLEFT", width, y)
    line:SetThickness(height or 1.5)
    return line
end

local function GetFN(name, realm)
    if realm then
        return name .. "-" .. realm
    else
        return name
    end
end
local function GetShortRealmName(realmName)
    if realmName:find("时光III") then
        return "时光III"
    elseif realmName:find("时光II") then
        return "时光II"
    elseif realmName:find("时光IV") then
        return "时光IV"
    elseif realmName:find("时光VI") then
        return "时光VI"
    elseif realmName:find("时光V") then
        return "时光V"
    end
    return realmName
end
ns.GetShortRealmName = GetShortRealmName

function HS.ChangeDate(value)
    value = tostring(value)
    local month = value:sub(3, 4)
    if month:sub(1, 1) == "0" then
        month = month:sub(2, 2)
    end
    local day = value:sub(5, 6)
    if day:sub(1, 1) == "0" then
        day = day:sub(2, 2)
    end
    return month .. L["月"] .. day .. L["日"], month, day
end

function HS.CreateTitleBg(bt)
    local w = 4
    local texture = [[Interface\FriendsFrame\WhoFrame-ColumnTabs]]

    local left = bt:CreateTexture(nil, "BACKGROUND")
    left:SetPoint("TOPLEFT", bt, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMRIGHT", bt, "BOTTOMLEFT", w, 1)
    left:SetTexture(texture)
    left:SetTexCoord(0, .078, 0, .75)

    local right = bt:CreateTexture(nil, "BACKGROUND")
    right:SetPoint("TOPLEFT", bt, "TOPRIGHT", -w, 0)
    right:SetPoint("BOTTOMRIGHT", bt, "BOTTOMRIGHT", 0, 1)
    right:SetTexture(texture)
    right:SetTexCoord(.9, .97, 0, .75)

    local middle = bt:CreateTexture(nil, "BACKGROUND")
    middle:SetPoint("TOPLEFT", bt, "TOPLEFT", w, 0)
    middle:SetPoint("BOTTOMRIGHT", bt, "BOTTOMRIGHT", -w, 1)
    middle:SetTexture(texture)
    middle:SetTexCoord(.078, .9, 0, .75)

    bt:SetHighlightTexture("Interface/PaperDollInfoFrame/UI-Character-Tab-Highlight")
    local text = bt:GetFontString()
    local width = bt:GetWidth()
    if width then
        text:SetWidth(width <= 60 and width - 5 or width - 15)
    end
    return left, right
end

local function RoadHistory()
    local mainFrame

    local realmName = GetShortRealmName(realmName)

    -- 查看汇总
    do
        local bt = BG.CreateButton(BG.History.List, true)
        bt:SetSize(100, 25)
        bt:SetPoint("BOTTOMRIGHT", BG.MainFrame, "TOPRIGHT", 0, -0)
        bt:SetText(L["查看汇总"])
        HS.ButtonWatch = bt
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            BG.MainFrame:Hide()
            mainFrame:Hide()
            mainFrame:Show()
        end)
        bt:SetScript("OnShow", function(self)
            local FB = BG.FB1
            if BiaoGe.historySummary[FB].hasThings then
                bt:Enable()
            else
                bt:Disable()
            end
        end)
    end

    -- 开始汇总
    do
        local bt = BG.CreateButton(BG.History.List, true)
        bt:SetSize(100, 25)
        bt:SetPoint("RIGHT", HS.ButtonWatch, "LEFT", -1, -0)
        bt.text1 = L["开始汇总"]
        bt.text2 = L["重新汇总"]
        HS.ButtonStart = bt
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            bt:Start(true)
        end)
        bt:SetScript("OnShow", function(self)
            local FB = BG.FB1
            if BiaoGe.historySummary[FB].hasThings then
                bt:SetText(self.text2)
            else
                bt:SetText(self.text1)
            end
        end)

        local updateFrame = CreateFrame("Frame", nil, UIParent)

        function bt:Start(click, show)
            local FB = BG.FB1
            HS.summaryGeneration = (HS.summaryGeneration or 0) + 1
            local summaryGeneration = HS.summaryGeneration
            mainFrame:Hide()
            HS.ButtonWatch:Disable()
            wipe(BiaoGe.historySummary[FB].player)
            wipe(BiaoGe.historySummary[FB].item)
            wipe(BiaoGe.historySummary[FB].historyID)
            wipe(BiaoGe.historySummary[FB].sameName)
            wipe(BiaoGe.historySummary.raidNumber[FB]) -- 跟团次数
            BiaoGe.historySummary[FB].hasThings = false
            local count = #BiaoGe.HistoryList[FB]
            local num = 0
            local db = BiaoGe
            local maijiaID = {}
            local zhuangbeiID = {}
            local itemCache = {}
            local sameName = {}
            local startI = 1
            local _startI = 1
            local oneTime = 5
            local allEnd = false
            local biaogeEnd = false
            local hasAccounts = false
            updateFrame.lastTime = 0
            if BiaoGeAccounts and BiaoGeAccounts.HistoryList and BiaoGeAccounts.HistoryList[FB] then
                hasAccounts = true
                count = count + #BiaoGeAccounts.HistoryList[FB]
            end

            if not click then
                UIErrorsFrame:AddMessage(BG.STC_b1("<BiaoGe>") .. " " .. L["历史表格正在汇总！"], 1, 1, 0)
            end

            local function EnsurePlayer(name, realm, class)
                if not name or name == "" or not realm then return end
                name = name:gsub("-.+", "")
                if not sameName[name] then
                    sameName[name] = {}
                    sameName[name][realm] = true
                elseif not sameName[name][realm] then
                    BiaoGe.historySummary[FB].sameName[name] = true
                    sameName[name][realm] = true
                end

                local fullName = GetFN(name, realm)
                if not maijiaID[fullName] then
                    tinsert(BiaoGe.historySummary[FB].player, {
                        all = {},
                        name = name,
                        realm = realm,
                        class = class,
                        sum = 0,
                        gz = 0,
                    })
                    maijiaID[fullName] = #BiaoGe.historySummary[FB].player
                    BiaoGe.historySummary[FB].hasThings = true
                elseif class and not BiaoGe.historySummary[FB].player[maijiaID[fullName]].class then
                    BiaoGe.historySummary[FB].player[maijiaID[fullName]].class = class
                end
                return maijiaID[fullName], fullName
            end

            local function AddDB(ii, isAccounts)
                num = num + 1
                bt:SetText(num .. "/" .. count)
                local DT = db.HistoryList[FB][ii][1]
                local titleName = db.HistoryList[FB][ii][2]
                local gz = tonumber((titleName or ""):match(L['工资:(%d+)'])) or 0
                if not BiaoGe.historySummary[FB].historyID[DT] then
                    BiaoGe.historySummary[FB].historyID[DT] = true
                    if db.History[FB][DT] then
                        local historyDB = db.History[FB][DT]
                        local raidRoster = historyDB.raidRoster
                        local hasRaidRoster = raidRoster and type(raidRoster.roster) == "table" and next(raidRoster.roster) ~= nil
                        local b = 1
                        local lastRealm = realmName
                        local gzAdded = {}

                        while historyDB["boss" .. b] do
                            for i = 1, BG.Maxi do
                                local zhuangbei = historyDB["boss" .. b]["zhuangbei" .. i]
                                local itemID = GetItemID(zhuangbei)
                                if zhuangbei and itemID then
                                    local maijia = historyDB["boss" .. b]["maijia" .. i]
                                    local realm = historyDB["boss" .. b]["realm" .. i] or lastRealm
                                    local class = historyDB["boss" .. b]["class" .. i]
                                    local jine = historyDB["boss" .. b]["jine" .. i]
                                    realm = GetShortRealmName(realm)
                                    lastRealm = realm
                                    if maijia and maijia ~= "" and realm then
                                        local playerName = maijia:gsub("-.+", "")
                                        local playerIndex, fullName = EnsurePlayer(playerName, realm, class)
                                        local num = playerIndex
                                        tinsert(BiaoGe.historySummary[FB].player[num].all, {
                                            item = zhuangbei,
                                            money = jine or 0,
                                            date = DT,
                                            isAccounts = isAccounts,
                                        })
                                        BiaoGe.historySummary[FB].player[num].sum = BiaoGe.historySummary[FB].player[num].sum + (tonumber(jine) or 0)
                                        -- 旧历史表格没有成员名单时，继续按买家推断其获得过工资。
                                        if not hasRaidRoster and not gzAdded[fullName] then
                                            BiaoGe.historySummary[FB].player[num].gz = (BiaoGe.historySummary[FB].player[num].gz or 0) + gz
                                            gzAdded[fullName] = true
                                        end

                                        -- 物品汇总只记录有成交金额的有效购买记录。
                                        if jine then
                                            local money = tonumber(jine) or 0
                                            if not zhuangbeiID[itemID] then
                                                local itemDB = {
                                                    all = {},
                                                    link = zhuangbei:match("|c.-|h|r") or zhuangbei,
                                                    itemID = itemID,
                                                    name = GetItemInfo(itemID) or zhuangbei:gsub("|c.-|h%[", ""):gsub("%]|h|r", ""),
                                                    EquipLoc = L["其他"],
                                                    iLevel = 0,
                                                    maxMoney = money,
                                                    max = {
                                                        player = playerName,
                                                        realm = realm,
                                                        class = class,
                                                        money = money,
                                                        date = DT,
                                                        isAccounts = isAccounts,
                                                    },
                                                }
                                                tinsert(BiaoGe.historySummary[FB].item, itemDB)
                                                zhuangbeiID[itemID] = #BiaoGe.historySummary[FB].item

                                                itemCache[itemID] = false
                                                Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
                                                    if summaryGeneration ~= HS.summaryGeneration then return end
                                                    local itemIndex = zhuangbeiID[itemID]
                                                    if not itemIndex or BiaoGe.historySummary[FB].item[itemIndex] ~= itemDB then return end

                                                    local name, link, _, level, _, _, itemSubType, _, EquipLoc, _,
                                                    _, classID, _, bindType = GetItemInfo(itemID)
                                                    local EquipLocText = L["其他"]
                                                    if EquipLoc and _G[EquipLoc] then
                                                        if classID == 2 then
                                                            EquipLocText = itemSubType or EquipLocText
                                                        else
                                                            EquipLocText = _G[EquipLoc]
                                                        end
                                                    end
                                                    itemDB.name = name or itemDB.name
                                                    itemDB.link = link or itemDB.link
                                                    itemDB.EquipLoc = EquipLocText
                                                    itemDB.iLevel = level or itemDB.iLevel
                                                    itemDB.bindOnEquip = bindType == 2 and true or nil
                                                    itemCache[itemID] = true
                                                    if mainFrame and mainFrame:IsVisible() and mainFrame.itemFrame and mainFrame.itemFrame:IsVisible() then
                                                        mainFrame.UpdateAllFrame()
                                                    end
                                                end)
                                            end

                                            local itemDB = BiaoGe.historySummary[FB].item[zhuangbeiID[itemID]]
                                            tinsert(itemDB.all, {
                                                player = playerName,
                                                realm = realm,
                                                class = class,
                                                money = jine,
                                                date = DT,
                                                isAccounts = isAccounts,
                                            })
                                            itemDB.maxMoney = max(itemDB.maxMoney, money)
                                            if money > itemDB.max.money then
                                                itemDB.max = {
                                                    player = playerName,
                                                    realm = realm,
                                                    class = class,
                                                    money = money,
                                                    date = DT,
                                                    isAccounts = isAccounts,
                                                }
                                            end
                                        end
                                    end
                                end
                            end
                            b = b + 1
                        end

                        if hasRaidRoster then
                            local rosterRealm = GetShortRealmName(raidRoster.realm or realmName)
                            for _, player in pairs(raidRoster.roster) do
                                if type(player) == "string" and player ~= "" then
                                    local playerName, playerRealm = strsplit("-", player)
                                    playerRealm = GetShortRealmName(playerRealm or rosterRealm)
                                    local playerIndex, fullName = EnsurePlayer(playerName, playerRealm)
                                    if playerIndex and not gzAdded[fullName] then
                                        local playerDB = BiaoGe.historySummary[FB].player[playerIndex]
                                        playerDB.gz = (playerDB.gz or 0) + gz
                                        gzAdded[fullName] = true
                                    end

                                    local raidFullName = playerRealm .. "-" .. playerName
                                    BiaoGe.historySummary.raidNumber[FB][raidFullName] = BiaoGe.historySummary.raidNumber[FB][raidFullName] or 0
                                    BiaoGe.historySummary.raidNumber[FB][raidFullName] = BiaoGe.historySummary.raidNumber[FB][raidFullName] + 1
                                end
                            end
                        end
                    end
                end
            end
            updateFrame:SetScript("OnUpdate", function(self, elapsed)
                if allEnd then
                    updateFrame.lastTime = updateFrame.lastTime + elapsed
                    local itemCacheReady = true
                    for _, isReady in pairs(itemCache) do
                        if not isReady then
                            itemCacheReady = false
                            break
                        end
                    end
                    if not itemCacheReady and updateFrame.lastTime < 1.5 then
                        bt:SetText(L["整理数据中..."])
                        return
                    end

                    self:SetScript("OnUpdate", nil)
                    if BiaoGe.historySummary[FB].hasThings then
                        for ii in ipairs(BiaoGe.historySummary[FB].player) do
                            sort(BiaoGe.historySummary[FB].player[ii].all, function(a, b)
                                return a.date > b.date
                            end)
                        end
                        for ii in ipairs(BiaoGe.historySummary[FB].item) do
                            sort(BiaoGe.historySummary[FB].item[ii].all, function(a, b)
                                return a.date > b.date
                            end)
                        end
                        HS.ButtonWatch:Enable()
                        bt:SetText(bt.text2)
                        if click or show then
                            SendSystemMessage(L["数据汇总完成！"])
                            BG.PlaySound(2)
                        end
                    else
                        bt:SetText(bt.text2)
                        if click or show then
                            SendSystemMessage(BG.STC_r1(L["缺少有效的历史表格数据！"]))
                        end
                    end
                    if show then
                        mainFrame:Show()
                    end
                    return
                end

                if not biaogeEnd then
                    for ii = startI, startI + oneTime - 1 do
                        if not db.HistoryList[FB][ii] then
                            if hasAccounts then
                                biaogeEnd = true
                                db = BiaoGeAccounts
                            else
                                allEnd = true
                            end
                            break
                        end
                        AddDB(ii)
                    end
                    startI = startI + oneTime
                else
                    for ii = _startI, _startI + oneTime - 1 do
                        if not db.HistoryList[FB][ii] then
                            allEnd = true
                            break
                        end
                        AddDB(ii, true)
                    end
                    _startI = _startI + oneTime
                end
            end)
        end

        hooksecurefunc(BG, "SaveBiaoGe", function()
            if BiaoGe.options.historySummaryAutoStart ~= 1 then return end
            After(0.1, function()
                bt:Start()
            end)
        end)
    end

    -- 历史表格数据汇总
    local BUTTONHEIGHT = 21
    local MAXBUTTONS = 30
    local FONTSIZE = 14
    local WIDTH = 32
    local HEIGHT = (MAXBUTTONS + 2) * BUTTONHEIGHT + 30
    -- 主界面
    do
        local f = CreateFrame("Frame", "BiaoGeHistorySummaryFrame", UIParent, "BackdropTemplate")
        f:SetBackdrop({
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 1,
        })
        f:SetBackdropBorderColor(GetClassRGB(nil, "player", .5))
        f:SetPoint("CENTER")
        f:SetToplevel(true)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:Hide()
        mainFrame = f
        HS.HistoryMainFrame = f
        BG.HistorySummaryMainFrame = f
        tinsert(UISpecialFrames, "BiaoGeHistorySummaryFrame")
        f:SetScript("OnMouseUp", function(self)
            self:StopMovingOrSizing()
        end)
        f:SetScript("OnMouseDown", function(self)
            self:StartMoving()
        end)
        f:SetScript("OnShow", function(self)
            self:SetScale(BiaoGe.options["scale"])
            mainFrame.FB = BG.FB1
            local tableName = BG.GetFBinfo(mainFrame.FB, "shortName") or mainFrame.FB or ""
            self.title:SetFormattedText(L["历史表格汇总（%s）"], tableName)
            if mainFrame.outFrame then
                mainFrame.outFrame:Hide()
            end
            mainFrame.Frame:Show()
            mainFrame.UpdateAllFrame()
        end)

        local title = f:CreateFontString()
        title:SetPoint("TOP", f, "TOP", 0, -3);
        title:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        title:SetTextColor(0, .72, 1)
        title:SetText(L["历史表格汇总"])
        f.title = title

        local r, g, b = GetClassRGB(nil, "player")
        local l = f:CreateLine()
        l:SetColorTexture(r, g, b, .5)
        l:SetStartPoint("TOPLEFT", 1, -21)
        l:SetEndPoint("TOPRIGHT", -1, -21)
        l:SetThickness(1)

        f.titleBg = f:CreateTexture(nil, "BACKGROUND", nil, 1)
        f.titleBg:SetPoint("TOPLEFT")
        f.titleBg:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, -22)
        f.titleBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        f.titleBg:SetGradient("VERTICAL", CreateColor(r, g, b, .2), CreateColor(r, g, b, .0))

        f.Bg = f:CreateTexture(nil, "BACKGROUND", nil, 0)
        f.Bg:SetAllPoints()
        f.Bg:SetColorTexture(0, 0, 0, .8)

        f.CloseButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        f.CloseButton:SetPoint("TOPRIGHT", 5, 5)

        mainFrame.Frame = CreateFrame("Frame", nil, mainFrame)

        local t = mainFrame.Frame:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetPoint("TOP", mainFrame, "TOP", 0, -80)
        t:SetTextColor(.5, .5, .5)
        t:SetText(L["没有数据，请尝试重新汇总。\n如果还是没有，说明你的历史表格里没有合适的数据。"])
        t:Hide()
        mainFrame.noDBText = t

        function mainFrame:UpdateNoDBText(type)
            mainFrame.noDBText:SetShown(not next(BiaoGe.historySummary[BG.FB1][type]))
        end
    end

    -- 汇总选项
    do
        local text = mainFrame.Frame:CreateFontString()
        text:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -4 - BUTTONHEIGHT)
        text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        text:SetTextColor(1, .82, 0)
        text:SetText(L["汇总："])

        local buttons = {}
        local options = {
            { name = L["玩家"], frameName = "playerFrame" },
            { name = L["物品"], frameName = "itemFrame" },
        }
        local buttonGroup = CreateFrame("Frame", nil, mainFrame.Frame)
        buttonGroup:SetPoint("LEFT", text, "RIGHT", 0, 1)
        buttonGroup:SetSize(1, 1)
        mainFrame.buttonGroup = buttons

        for i, option in ipairs(options) do
            local frameName = option.frameName
            local bt = CreateFrame("CheckButton", nil, buttonGroup, "UIRadioButtonTemplate")
            bt:SetPoint("LEFT", (i - 1) * 50, -1)
            bt:SetSize(15, 15)
            tinsert(buttons, bt)
            bt.Text = bt:CreateFontString()
            bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            bt.Text:SetPoint("LEFT", bt, "RIGHT", 0, 0)
            bt.Text:SetText(option.name)
            bt.Text:SetTextColor(1, .82, 0)
            bt:SetHitRectInsets(0, -bt.Text:GetWidth(), -5, -5)
            if frameName == BiaoGe.historySummary.lastFrame then
                bt:SetChecked(true)
                bt.Text:SetTextColor(0, 1, 0)
            end
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                for _, radioButton in ipairs(buttons) do
                    radioButton:SetChecked(radioButton == self)
                    radioButton.Text:SetTextColor(radioButton == self and 0 or 1, radioButton == self and 1 or .82, 0)
                end
                BiaoGe.historySummary.lastFrame = frameName
                mainFrame.playerFrame:Hide()
                mainFrame.itemFrame:Hide()
                mainFrame[frameName]:Show()
                mainFrame.serachEdit:ClearFocus()
                if mainFrame.serachEdit:GetText() == "" then
                    mainFrame.UpdateAllFrame()
                else
                    mainFrame.serachEdit:SetText("")
                end
                LibBG:CloseDropDownMenus()
            end)
        end
    end

    -- 仅显示我的角色
    do
        local bt = CreateFrame("CheckButton", nil, mainFrame.Frame, "ChatConfigCheckButtonTemplate")
        bt:SetSize(20, 20)
        bt:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 170, -2 - BUTTONHEIGHT)
        bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        bt.Text:SetText(L["仅显示我的角色"])
        bt.Text:SetPoint("LEFT", bt, "RIGHT", 0, 0)
        bt.Text:SetTextColor(1, .82, 0)
        bt:SetHitRectInsets(0, -bt.Text:GetWidth(), 0, 0)
        if BiaoGe.historySummary.onlyShowMe == 1 then
            bt:SetChecked(true)
        end
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            BiaoGe.historySummary.onlyShowMe = self:GetChecked() and 1 or 0
            mainFrame.UpdateAllFrame()
        end)

        local totalText = mainFrame.Frame:CreateFontString()
        totalText:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        totalText:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -10, -4 - BUTTONHEIGHT)
        -- totalText:SetPoint("LEFT", bt.Text, "RIGHT", 50, 0)
        totalText:SetTextColor(1, .82, 0)

        mainFrame.myNames = {}
        local function GetMyNames(db)
            if db and db.playerInfo then
                for realmID in pairs(db.playerInfo) do
                    local realmName = db.realmName and db.realmName[realmID] or BiaoGe.realmName[realmID] or nil
                    if realmName then
                        realmName = GetShortRealmName(realmName)
                        for player in pairs(db.playerInfo[realmID]) do
                            mainFrame.myNames[player .. "-" .. realmName] = true
                            mainFrame.myNames[player] = true
                        end
                    end
                end
            end
        end
        GetMyNames(BiaoGe)
        GetMyNames(BiaoGeAccounts)

        local function IsMyCharacter(player, realmName)
            if not realmName then
                return mainFrame.myNames[player]
            else
                realmName = GetShortRealmName(realmName)
                return mainFrame.myNames[player .. "-" .. realmName]
            end
        end

        function mainFrame.CheckOnlyMe(player, realmName)
            if BiaoGe.historySummary.onlyShowMe == 1 then
                return IsMyCharacter(player, realmName)
            else
                return true
            end
        end

        function mainFrame:UpdateMyTotal()
            local sum, gz = 0, 0
            local FB = mainFrame.FB or BG.FB1
            for _, v in ipairs(BiaoGe.historySummary[FB].player) do
                if IsMyCharacter(v.name, v.realm) then
                    sum = sum + (tonumber(v.sum) or 0)
                    gz = gz + (tonumber(v.gz) or 0)
                end
            end
            totalText:SetText(L["我的所有角色"] .. L["合计消费"] .. ": |cffffffff" .. BG.FormatNumber(sum, 1) ..
                "|r    " .. L["合计工资"] .. ": |cffffffff" .. BG.FormatNumber(gz, 1) .. "|r")
        end
    end

    -- 搜索
    do
        local edit = CreateFrame("EditBox", nil, mainFrame.Frame, "SearchBoxTemplate")
        edit:SetSize(150, 20)
        edit:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 35, -1)
        edit:SetScale(0.95)
        edit.Instructions:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
        edit.Instructions:ClearAllPoints()
        edit.Instructions:SetPoint("LEFT", 15, 0)
        edit.Instructions:SetWidth(edit:GetWidth() - 20)
        mainFrame.serachEdit = edit
        edit:SetScript("OnMouseDown", function(self, button)
            if button == "RightButton" then
                self:SetEnabled(false)
                self:SetText("")
            end
        end)
        edit:SetScript("OnMouseUp", function(self, button)
            self:SetEnabled(true)
        end)
        edit:HookScript("OnTextChanged", function(self, button)
            mainFrame.UpdateAllFrame()
        end)
        edit:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            if mainFrame.playerFrame:IsVisible() then
                GameTooltip:AddLine(L["搜索玩家或职业"], 1, 0.82, 0, true)
            else
                GameTooltip:AddLine(L["搜索装备或类型"], 1, 0.82, 0, true)
            end
            GameTooltip:Show()
        end)
        edit:SetScript("OnLeave", GameTooltip_Hide)

        local function Insert(text)
            if not (IsShiftKeyDown() and text and edit:HasFocus()) then return end
            edit:SetText(text)
        end
        hooksecurefunc("SetItemRef", function(link, text, button)
            Insert(GetItemInfo(link))
        end)

        if BG.IsRetail then
            hooksecurefunc("ContainerFrameItemButton_OnClick", function(self, button)
                local link = C_Container.GetContainerItemLink(self:GetParent():GetID(), self:GetID())
                if link then
                    Insert(GetItemInfo(link))
                end
            end)
        else
            hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self, button)
                local link = C_Container.GetContainerItemLink(self:GetParent():GetID(), self:GetID())
                if link then
                    Insert(GetItemInfo(link))
                end
            end)
        end
    end

    -- 设置
    do
        local option = CreateFrame("Button", nil, mainFrame)
        option:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 5, -1)
        option:SetSize(18, 18)
        option:SetNormalTexture([[Interface\Buttons\UI-OptionsButton]])
        option:SetHighlightTexture([[Interface\Buttons\UI-OptionsButton]])
        option:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            if L_DropDownList1:IsVisible() then
                L_DropDownList1:Hide()
            else
                local menu = {
                    {
                        text = L["设置"],
                        isTitle = true,
                        notCheckable = true,
                    },
                    {
                        text = L["保存表格时，自动进行汇总"],
                        checked = BiaoGe.options.historySummaryAutoStart == 1,
                        isNotRadio = true,
                        keepShownOnClick = true,
                        func = function()
                            if BiaoGe.options.historySummaryAutoStart == 1 then
                                BiaoGe.options.historySummaryAutoStart = 0
                            else
                                BiaoGe.options.historySummaryAutoStart = 1
                            end
                        end
                    },
                    {
                        text = CANCEL,
                        notCheckable = true,
                        func = LibBG.CloseDropDownMenus,
                    }
                }
                LibBG:EasyMenu(menu, BG.dropDown, self, 0, 0, "MENU", 2)
            end
        end)
    end

    -- 重新汇总
    do
        local bt = CreateFrame("Button", nil, mainFrame)
        bt:SetPoint("TOPRIGHT", -35, -1)
        bt:SetNormalFontObject(BG.FontGreen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        BG.SetTextHighlightTexture(bt)
        bt.text1 = L["开始汇总"]
        bt.text2 = L["重新汇总"]
        mainFrame.startButton = bt
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            HS.ButtonStart:Start(nil, true)
        end)
        bt:SetScript("OnShow", function(self)
            local FB = BG.FB1
            if BiaoGe.historySummary[FB].hasThings then
                self:SetText(self.text2)
            else
                self:SetText(self.text1)
            end
            self:SetSize(self:GetFontString():GetWidth(), 20)
        end)
    end

    -- 导出数据
    do
        local bt = CreateFrame("Button", nil, mainFrame)
        bt:SetPoint("RIGHT", mainFrame.startButton, "LEFT", -5, 0)
        bt:SetNormalFontObject(BG.FontGreen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        bt:SetText(L["导出数据"])
        bt:SetSize(bt:GetFontString():GetWidth(), 20)
        BG.SetTextHighlightTexture(bt)
        mainFrame.outButton = bt
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            if mainFrame.outFrame:IsVisible() then
                mainFrame.outFrame:Hide()
                mainFrame.Frame:Show()
            else
                mainFrame.outFrame:Show()
                mainFrame.Frame:Hide()
                self:Disable()
                local text = ""
                for i, v in ipairs(mainFrame.Frame.titleTbl) do
                    text = text .. v.name .. ","
                end
                text = text .. "\n"
                local startI = 1
                local oneTime = 20
                local db = mainFrame.Frame.db
                BG.OnUpdateTime(function(self)
                    for ii = startI, startI + oneTime - 1 do
                        if not db[ii] then
                            self:SetScript("OnUpdate", nil)
                            bt:Enable()
                            mainFrame.outChild:SetText(text)
                            mainFrame.outChild:HighlightText()
                            mainFrame.outChild:SetFocus()
                            After(0, function()
                                local max = select(2, mainFrame.outFrame.ScrollBar:GetMinMaxValues())
                                mainFrame.outFrame.ScrollBar:SetValue(max)
                            end)
                            return
                        end

                        local tbl = mainFrame.Frame.GetButtonInfo(ii, true)
                        if tbl then
                            for i, v in ipairs(tbl) do
                                text = text .. tostring(v):gsub("|T.-|t", ""):gsub("*", "") .. ","
                                mainFrame.outChild:SetText(ii .. "/" .. #db)
                            end
                            if ii ~= #db then
                                text = text .. "\n"
                            end
                        end
                    end
                    startI = startI + oneTime
                end)
            end
        end)

        local scroll = CreateFrame("ScrollFrame", nil, mainFrame, BG.scrollTemplate) -- 滚动
        scroll:SetPoint("TOPLEFT", 5, -25)
        scroll:SetPoint("BOTTOMRIGHT", -25, 3)
        scroll:Hide()
        BG.CreateSrollBarBackdrop(scroll.ScrollBar)
        mainFrame.outFrame = scroll
        scroll:SetScript("OnShow", function()
            mainFrame.outButton:SetText(L["关闭导出"])
        end)
        scroll:SetScript("OnHide", function()
            mainFrame.outButton:SetText(L["导出数据"])
        end)

        local child = CreateFrame("EditBox", nil, mainFrame) -- 子框架
        child:SetAutoFocus(false)
        child:EnableMouse(true)
        child:SetTextInsets(0, 5, 0, 0)
        child:SetMultiLine(true)
        child:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
        scroll:SetScrollChild(child)
        mainFrame.outChild = child
    end

    -- 全部折叠
    do
        local bt = CreateFrame("Button", nil, mainFrame.Frame)
        bt:SetPoint("RIGHT", mainFrame.outButton, "LEFT", -5, 0)
        bt:SetNormalFontObject(BG.FontGreen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        BG.SetTextHighlightTexture(bt)
        mainFrame.openButton = bt
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            local FB = mainFrame.FB
            BiaoGe.historySummary[FB].allOpen = not BiaoGe.historySummary[FB].allOpen
            self:GetScript("OnShow")(self)
            for ii, vv in ipairs(BiaoGe.historySummary[FB].player) do
                local fullName = GetFN(vv.name, vv.realm)
                BiaoGe.historySummary.playerFrame.close[fullName] = not BiaoGe.historySummary[FB].allOpen
            end
            for _, vv in ipairs(BiaoGe.historySummary[FB].item) do
                BiaoGe.historySummary.itemFrame.close[vv.itemID] = not BiaoGe.historySummary[FB].allOpen
            end
            mainFrame.UpdateAllFrame()
        end)
        bt:SetScript("OnShow", function(self)
            local FB = BG.FB1
            if BiaoGe.historySummary[FB].allOpen then
                self:SetText(L["全部折叠"])
            else
                self:SetText(L["全部展开"])
            end
            self:SetSize(self:GetFontString():GetWidth(), 20)
        end)
    end

    -- 玩家汇总
    do
        local titleTbl
        local db = {}
        local GetDB, UpdateScrollFrame, UpdateScrollButtonState, GetButtonInfo, UpdateButtons, UpdateAllFrame
        local playerFrame = CreateFrame("Frame", nil, mainFrame.Frame)
        playerFrame:Hide()
        mainFrame.playerFrame = playerFrame
        playerFrame:SetScript("OnShow", function()
            mainFrame.Frame.titleTbl = titleTbl
            mainFrame.Frame.GetButtonInfo = GetButtonInfo
            mainFrame.Frame.db = db
            mainFrame.UpdateAllFrame = UpdateAllFrame
        end)

        local titleWidth = 0
        local titlebuttons = {}
        local buttons = {}
        titleTbl = {
            { name = L["序号"], width = 50, color = "808080", JustifyH = "CENTER", Enable = false, fontSize = FONTSIZE - 2, },
            { name = L["角色"], width = 110, color = "FFFFFF", JustifyH = "CENTER", Enable = true },
            { name = L["职业"], width = 80, color = "FFFFFF", JustifyH = "CENTER", Enable = true },
            { name = L["跟团"], width = 60, color = "FFFFFF", JustifyH = "CENTER", Enable = true },
            { name = L["合计消费"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = true },
            { name = L["合计工资"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = true },
            { name = L["日期"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = false },
            { name = L["装备"], width = 130, color = "FFFFFF", JustifyH = "LEFT", Enable = false },
            { name = L["金额"], width = 80, color = "FFFFFF", JustifyH = "CENTER", Enable = false },
        }
        for i, v in ipairs(titleTbl) do
            WIDTH = WIDTH + v.width
            titleWidth = titleWidth + v.width
        end
        mainFrame:SetSize(WIDTH, HEIGHT)
        mainFrame.outChild:SetSize(mainFrame.outFrame:GetSize())

        -- 滚动框
        local scroll, bar
        do
            scroll = CreateFrame("ScrollFrame", nil, playerFrame, BG.scrollTemplate) -- 滚动
            scroll:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 5, -27 - BUTTONHEIGHT * 2)
            scroll:SetWidth(WIDTH - 30)
            scroll:SetHeight(BUTTONHEIGHT * MAXBUTTONS)
            BG.CreateSrollBarBackdrop(scroll.ScrollBar)
            playerFrame.scroll = scroll
            bar = scroll.ScrollBar
            bar.scrollStep = 5
            bar:HookScript("OnValueChanged", function(self)
                UpdateButtons()
                UpdateScrollButtonState()
                GameTooltip:Hide()
            end)

            for ii = 1, MAXBUTTONS do
                buttons[ii] = {}
                for i = 1, #titleTbl do
                    local f = CreateFrame("Frame", nil, scroll)
                    f:SetSize(titleTbl[i].width, BUTTONHEIGHT)
                    if ii == 1 and i == 1 then
                        f:SetPoint("TOPLEFT", scroll, 0, 0)
                        f:SetParent(scroll)
                    elseif i == 1 then
                        f:SetPoint("TOPLEFT", buttons[(ii - 1)][1], "BOTTOMLEFT", 0, 0)
                        f:SetParent(scroll)
                    else
                        f:SetPoint("LEFT", buttons[ii][i - 1], "RIGHT", 0, 0)
                        f:SetParent(buttons[ii][1])
                    end
                    f.num = ii
                    buttons[ii][i] = f

                    f.Text = f:CreateFontString()
                    f.Text:SetFont(BIAOGE_TEXT_FONT, titleTbl[i].fontSize or FONTSIZE, "OUTLINE")
                    f.Text:SetPoint("CENTER")
                    f.Text:SetTextColor(RGB(titleTbl[i].color))
                    f.Text:SetJustifyH(titleTbl[i].JustifyH)
                    f.Text:SetWidth(f:GetWidth() - 2)
                    f.Text:SetWordWrap(false)

                    f:SetScript("OnEnter", function(self)
                        if self.link then
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                            GameTooltip:ClearLines()
                            GameTooltip:SetHyperlink(self.link)
                            GameTooltip:Show()
                        elseif self.onenter then
                            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                            GameTooltip:ClearLines()
                            GameTooltip:AddLine(self.onenter, 1, 1, 1, true)
                            GameTooltip:Show()
                        end
                        if self.player then
                            buttons[ii][1].ds2:Show()
                        end
                    end)
                    f:SetScript("OnLeave", function(self)
                        GameTooltip:Hide()
                        buttons[ii][1].ds2:Hide()
                    end)
                    f:SetScript("OnMouseUp", function(self, _button)
                        if not self.player then
                            mainFrame:StopMovingOrSizing()
                            return
                        end
                        if _button == "LeftButton" then
                            if IsShiftKeyDown() and self.link then
                                ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
                                ChatEdit_InsertLink(self.link)
                            else
                                BiaoGe.historySummary.playerFrame.close[self.fullName] = not BiaoGe.historySummary.playerFrame.close[self.fullName]
                                UpdateAllFrame()
                            end
                        end
                    end)
                    f:SetScript("OnMouseDown", function(self)
                        if not self.player then
                            mainFrame:StartMoving()
                        end
                    end)
                end

                -- 底色材质
                local f = buttons[ii][1]
                f.ds = f:CreateTexture()
                f.ds:SetPoint("TOPLEFT", 0, 0)
                f.ds:SetPoint("BOTTOMRIGHT", buttons[ii][#titleTbl], "BOTTOMRIGHT", 0, 0)

                local f = buttons[ii][1]
                f.ds2 = f:CreateTexture()
                f.ds2:SetPoint("TOPLEFT", 0, 0)
                f.ds2:SetPoint("BOTTOMRIGHT", buttons[ii][#titleTbl], "BOTTOMRIGHT", 0, 0)
                f.ds2:SetColorTexture(1, 1, 0, 0.2)
                f.ds2:Hide()
            end
        end
        -- 标题
        do
            for i, v in ipairs(titleTbl) do
                local bt = CreateFrame("Button", nil, playerFrame)
                bt:SetSize(titleTbl[i].width, BUTTONHEIGHT)
                if i == 1 then
                    bt:SetPoint("BOTTOMLEFT", scroll, "TOPLEFT", 0, 0)
                else
                    bt:SetPoint("LEFT", titlebuttons[i - 1], "RIGHT", 0, 0)
                    bt:SetParent(titlebuttons[i - 1])
                end
                bt:SetNormalFontObject(BG.FontWhite15)
                bt:SetText(titleTbl[i].name)
                bt.textwidth = bt:GetFontString():GetStringWidth()
                bt.textJustifyH = titleTbl[i].JustifyH
                bt.sortOrder = 1
                bt.id = i
                bt:SetEnabled(v.Enable)
                bt:RegisterForClicks("AnyUp")
                tinsert(titlebuttons, bt)

                bt.Text = bt:GetFontString()
                bt.Text:SetJustifyH(titleTbl[i].JustifyH)
                bt.Text:SetWordWrap(false)
                HS.CreateTitleBg(bt)

                bt:SetScript("OnClick", function(self, _button)
                    BG.PlaySound(1)
                    if _button == "LeftButton" then
                        playerFrame.isnewsorter = nil
                        if BiaoGe.historySummary.playerFrame.OrderButtonID ~= self.id then
                            playerFrame.isnewsorter = true
                        end
                        if not playerFrame.isnewsorter then
                            BiaoGe.historySummary.playerFrame.Order = BiaoGe.historySummary.playerFrame.Order == 1 and 0 or 1
                        end
                        BiaoGe.historySummary.playerFrame.OrderButtonID = self.id

                        UpdateAllFrame()
                    elseif _button == "RightButton" and i == 3 then
                        local FB = mainFrame.FB
                        local tbl = {
                            { class = "PALADIN", count = 0 },
                            { class = "WARRIOR", count = 0 },
                            { class = "SHAMAN", count = 0 },
                            { class = "HUNTER", count = 0 },
                            { class = "DRUID", count = 0 },
                            { class = "ROGUE", count = 0 },
                            { class = "MAGE", count = 0 },
                            { class = "WARLOCK", count = 0 },
                            { class = "PRIEST", count = 0 },
                        }
                        if BG.verOver3 then
                            tinsert(tbl, 1, { class = "DEATHKNIGHT", count = 0 })
                        end
                        if BG.verOver5 then
                            tinsert(tbl, 6, { class = "MONK", count = 0 })
                        end
                        local menu = {}
                        tinsert(menu, {
                            text = L["职业"],
                            isTitle = true,
                            notCheckable = true,
                        })
                        for ii, vv in ipairs(BiaoGe.historySummary[FB].player) do
                            for _, v in ipairs(tbl) do
                                if vv.class == v.class then
                                    v.count = v.count + 1
                                end
                            end
                        end
                        for _, v in ipairs(tbl) do
                            local className = GetClassName(v.class)
                            local searchEdit = mainFrame.serachEdit
                            tinsert(menu, {
                                text = "|c" .. select(4, GetClassColor(v.class)) .. className .. format(" |cff808080(%s)", v.count),
                                checked = searchEdit:GetText() == className,
                                func = function()
                                    searchEdit:SetText(className)
                                end
                            })
                        end
                        tinsert(menu, {
                            text = "   ",
                            isTitle = true,
                        })
                        tinsert(menu, {
                            text = CANCEL,
                            notCheckable = true,
                            func = LibBG.CloseDropDownMenus,
                        })
                        LibBG:EasyMenu(menu, BG.dropDown, "cursor", 0, 0, "MENU", 2)
                    end
                end)
            end
            CreateLine(titlebuttons[1], 0, titleWidth)
            -- 排序材质
            local sorter = playerFrame:CreateTexture(nil, "OVERLAY")
            sorter:SetSize(8, 8)
            sorter:SetTexture("Interface/Buttons/ui-sortarrow")
            playerFrame.sorter = sorter
        end

        local function Sort(tbl, isClickMoney)
            local FB = mainFrame.FB
            sort(BiaoGe.historySummary[FB].player, function(a, b)
                for _, key in ipairs(tbl) do
                    if key == "name" then
                        if a[key] and b[key] then
                            if a[key] ~= b[key] then
                                if BiaoGe.historySummary.playerFrame.Order == 1 then
                                    return a[key] > b[key]
                                else
                                    return b[key] > a[key]
                                end
                            end
                        end
                    elseif key == "class" then
                        if a[key] and b[key] then
                            if a[key] ~= b[key] then
                                if BiaoGe.historySummary.playerFrame.Order == 1 then
                                    return a[key] > b[key]
                                else
                                    return b[key] > a[key]
                                end
                            end
                        elseif a[key] or b[key] then
                            if BiaoGe.historySummary.playerFrame.Order == 1 then
                                ---@diagnostic disable-next-line: return-type-mismatch
                                return a[key]
                            else
                                ---@diagnostic disable-next-line: return-type-mismatch
                                return b[key]
                            end
                        end
                    elseif key == "sum" or key == "gz" then
                        local aValue = tonumber(a[key]) or 0
                        local bValue = tonumber(b[key]) or 0
                        if aValue ~= bValue then
                            if isClickMoney then
                                if BiaoGe.historySummary.playerFrame.Order == 1 then
                                    return aValue > bValue
                                else
                                    return bValue > aValue
                                end
                            else
                                return aValue > bValue
                            end
                        end
                    elseif key == "raidNumber" then
                        if a.realm and b.realm then
                            local aFullName = a.realm .. "-" .. a.name
                            local bFullName = b.realm .. "-" .. b.name
                            local aNum = BiaoGe.historySummary.raidNumber[FB][aFullName] or 0
                            local bNum = BiaoGe.historySummary.raidNumber[FB][bFullName] or 0
                            if aNum ~= bNum then
                                if BiaoGe.historySummary.playerFrame.Order == 1 then
                                    return aNum > bNum
                                else
                                    return bNum > aNum
                                end
                            end
                        end
                    end
                end
                return false
            end)
        end
        function GetDB()
            local FB = mainFrame.FB
            if BiaoGe.historySummary.playerFrame.OrderButtonID == 2 then     -- 按玩家
                Sort({ "name", "sum", "class", })
            elseif BiaoGe.historySummary.playerFrame.OrderButtonID == 3 then -- 按职业
                Sort({ "class", "sum", "name", })
            elseif BiaoGe.historySummary.playerFrame.OrderButtonID == 4 then -- 按跟团次数
                Sort({ "raidNumber", "sum", "class", })
            elseif BiaoGe.historySummary.playerFrame.OrderButtonID == 5 then -- 按合计消费
                Sort({ "sum", "class", "name", }, true)
            elseif BiaoGe.historySummary.playerFrame.OrderButtonID == 6 then -- 按合计工资
                Sort({ "gz", "class", "name", }, true)
            end

            wipe(db)
            local num = 1
            for ii, vv in ipairs(BiaoGe.historySummary[FB].player) do
                if mainFrame.CheckOnlyMe(vv.name, vv.realm) then
                    local searchText = mainFrame.serachEdit:GetText()
                    local className = GetClassName(vv.class) or ""
                    if searchText == "" or vv.name:find(searchText, 1, true) or className:find(searchText, 1, true) then
                        local first = true
                        for _, v in ipairs(BiaoGe.historySummary[FB].player[ii].all) do
                            local fullName = GetFN(vv.name, vv.realm)
                            if first or not (BiaoGe.historySummary.playerFrame.close[fullName]) then
                                tinsert(db, {
                                    name = vv.name,
                                    realm = vv.realm,
                                    class = vv.class,
                                    sum = vv.sum,
                                    gz = vv.gz or 0,
                                    item = v.item,
                                    money = v.money,
                                    date = v.date,
                                    isAccounts = v.isAccounts,
                                    num = num,
                                    first = first,
                                    close = BiaoGe.historySummary.playerFrame.close[fullName],
                                })
                            end
                            first = false
                        end
                        if not first then
                            num = (num + 1) % 2
                        end
                    end
                end
            end
        end

        function UpdateScrollFrame()
            GetDB()

            local sorter = playerFrame.sorter
            local bt = titlebuttons[BiaoGe.historySummary.playerFrame.OrderButtonID]
            sorter:SetParent(bt)
            sorter:ClearAllPoints()
            if bt.textJustifyH == "CENTER" then
                sorter:SetPoint("LEFT", bt, "CENTER", bt.textwidth / 2, 0)
            else
                sorter:SetPoint("LEFT", bt, "LEFT", bt.textwidth, 0)
            end
            if not playerFrame.isnewsorter then
                if BiaoGe.historySummary.playerFrame.Order == 1 then
                    sorter:SetTexCoord(0, 0.5, 0, 1)
                else
                    sorter:SetTexCoord(0, 0.5, 1, 0)
                end
            end

            local m = #db - MAXBUTTONS
            bar:SetMinMaxValues(0, max(0, m))
            if scroll.SetScrollExtent then
                scroll:SetScrollExtent(MAXBUTTONS, #db)
            end
            UpdateScrollButtonState()
        end

        function UpdateScrollButtonState()
            if bar.ThumbButton then return end
            local currValue = bar:GetValue();
            local scrollDownButton = bar.ScrollDownButton or _G[bar:GetName() .. "ScrollDownButton"];
            local scrollUpButton = bar.ScrollUpButton or _G[bar:GetName() .. "ScrollUpButton"];
            scrollUpButton:Enable();
            scrollDownButton:Enable();
            local minVal, maxVal = bar:GetMinMaxValues();
            if (currValue >= maxVal) then
                if (scrollDownButton) then
                    scrollDownButton:Disable()
                end
            end
            if (currValue <= minVal) then
                if (scrollUpButton) then
                    scrollUpButton:Disable();
                end
            end
        end

        function GetButtonInfo(num, first)
            local v = db[num]
            if not v then return end
            local FB = mainFrame.FB
            local name = v.name
            -- if BiaoGe.historySummary[FB].sameName[name] and v.realm ~= realmName then
            if v.realm ~= realmName then
                name = name .. "-" .. v.realm
            end
            local isOpen = not v.close
            local color = "ff808080"
            if v.class then
                color = select(4, GetClassColor(v.class))
            end
            local itemText = v.item or ""
            local itemID = GetItemID(v.item)
            if itemID then
                local icon = select(5, GetItemInfoInstant(itemID))
                itemText = AddTexture(icon) .. v.item
            end
            local dateText = v.date and HS.ChangeDate(v.date) or ""
            local moneyText = v.money and BG.FormatNumber(v.money, 2) or ""
            if v.isAccounts and moneyText then
                moneyText = moneyText .. "*"
            end

            local fullName = v.realm .. "-" .. name
            local raidNumber = BiaoGe.historySummary.raidNumber[FB][fullName] or 0
            return {
                    num,                                               -- 序号
                    (v.first) and "|c" .. color .. name .. "|r" or "", -- 玩家
                    (v.first) and GetClassName(v.class) or "",         -- 职业
                    (v.first) and raidNumber or "",
                    (v.first) and BG.FormatNumber(v.sum, 1) or "",     -- 合计消费
                    (v.first) and BG.FormatNumber(v.gz, 1) or "",      -- 合计工资
                    isOpen and dateText or "",                         -- 日期
                    isOpen and itemText or "",                         -- 装备
                    isOpen and moneyText or "",                        -- 金额
                },
                v.num == 1,
                v.first,
                v.name,
                v.close,
                v.name .. "-" .. v.realm,
                isOpen and v.item or nil
        end

        function UpdateButtons()
            local value = floor(bar:GetValue()) or 0
            for ii = 1, MAXBUTTONS do
                local num = value + ii
                local tbl, isOne, isFirst, player, isClose, fullName, itemLink = GetButtonInfo(num)
                for i = 1, #titleTbl do
                    if tbl then
                        buttons[ii][i].Text:SetText(tbl[i])
                        if buttons[ii][i].Text:IsTruncated() then
                            buttons[ii][i].onenter = tbl[i]
                        else
                            buttons[ii][i].onenter = nil
                        end
                        buttons[ii][i].link = i == 8 and itemLink or nil
                        if isOne then
                            local color = .8
                            buttons[ii][1].ds:SetColorTexture(color, color, color, 0.2)
                        else
                            local color = .4
                            buttons[ii][1].ds:SetColorTexture(color, color, color, 0.2)
                        end
                        buttons[ii][i].player = isFirst and player or nil
                        buttons[ii][i].fullName = isFirst and fullName or nil
                        buttons[ii][i].isClose = isClose
                        buttons[ii][i]:Show()
                    else
                        buttons[ii][i].link = nil
                        buttons[ii][i]:Hide()
                    end
                end
            end
        end

        function UpdateAllFrame()
            UpdateScrollFrame()
            UpdateButtons()
            mainFrame:UpdateMyTotal()
            mainFrame:UpdateNoDBText("player")
        end

    end

    -- 物品汇总
    do
        local titleTbl
        local db = {}
        local GetDB, UpdateScrollFrame, UpdateScrollButtonState, GetButtonInfo, UpdateButtons, UpdateAllFrame
        local itemFrame = CreateFrame("Frame", nil, mainFrame.Frame)
        itemFrame:Hide()
        mainFrame.itemFrame = itemFrame
        itemFrame:SetScript("OnShow", function()
            mainFrame.Frame.titleTbl = titleTbl
            mainFrame.Frame.GetButtonInfo = GetButtonInfo
            mainFrame.Frame.db = db
            mainFrame.UpdateAllFrame = UpdateAllFrame
        end)

        local titleWidth = 0
        local titlebuttons = {}
        local buttons = {}
        titleTbl = {
            { name = L["序号"], width = 50, color = "808080", JustifyH = "CENTER", Enable = false, fontSize = FONTSIZE - 2 },
            { name = L["装备"], width = 150, color = "FFFFFF", JustifyH = "LEFT", Enable = false },
            { name = L["等级"], width = 80, color = "FFFFFF", JustifyH = "CENTER", Enable = true },
            { name = L["类型"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = true },
            { name = L["最高价"], width = 100, color = "FFFFFF", JustifyH = "CENTER", Enable = true },
            { name = L["日期"], width = 100, color = "FFFFFF", JustifyH = "CENTER", Enable = false },
            { name = L["角色"], width = 110, color = "FFFFFF", JustifyH = "CENTER", Enable = false },
            { name = L["金额"], width = 100, color = "FFFFFF", JustifyH = "CENTER", Enable = false },
        }
        for _, v in ipairs(titleTbl) do
            titleWidth = titleWidth + v.width
        end

        local scroll, bar
        do
            scroll = CreateFrame("ScrollFrame", nil, itemFrame, BG.scrollTemplate)
            scroll:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 5, -27 - BUTTONHEIGHT * 2)
            scroll:SetWidth(WIDTH - 30)
            scroll:SetHeight(BUTTONHEIGHT * MAXBUTTONS)
            BG.CreateSrollBarBackdrop(scroll.ScrollBar)
            itemFrame.scroll = scroll
            bar = scroll.ScrollBar
            bar.scrollStep = 5
            bar:HookScript("OnValueChanged", function()
                UpdateButtons()
                UpdateScrollButtonState()
                GameTooltip:Hide()
            end)

            for ii = 1, MAXBUTTONS do
                buttons[ii] = {}
                for i = 1, #titleTbl do
                    local f = CreateFrame("Frame", nil, scroll)
                    f:SetSize(titleTbl[i].width, BUTTONHEIGHT)
                    if ii == 1 and i == 1 then
                        f:SetPoint("TOPLEFT", scroll, 0, 0)
                        f:SetParent(scroll)
                    elseif i == 1 then
                        f:SetPoint("TOPLEFT", buttons[ii - 1][1], "BOTTOMLEFT", 0, 0)
                        f:SetParent(scroll)
                    else
                        f:SetPoint("LEFT", buttons[ii][i - 1], "RIGHT", 0, 0)
                        f:SetParent(buttons[ii][1])
                    end
                    buttons[ii][i] = f

                    f.Text = f:CreateFontString()
                    f.Text:SetFont(BIAOGE_TEXT_FONT, titleTbl[i].fontSize or FONTSIZE, "OUTLINE")
                    f.Text:SetPoint("CENTER")
                    f.Text:SetTextColor(RGB(titleTbl[i].color))
                    f.Text:SetJustifyH(titleTbl[i].JustifyH)
                    f.Text:SetWidth(f:GetWidth() - 2)
                    f.Text:SetWordWrap(false)

                    f:SetScript("OnEnter", function(self)
                        if self.link then
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                            GameTooltip:ClearLines()
                            GameTooltip:SetHyperlink(self.link)
                            GameTooltip:Show()
                        elseif self.onenter then
                            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                            GameTooltip:ClearLines()
                            GameTooltip:AddLine(self.onenter, 1, 1, 1, true)
                            GameTooltip:Show()
                        end
                        if self.item then
                            buttons[ii][1].ds2:Show()
                        end
                    end)
                    f:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                        buttons[ii][1].ds2:Hide()
                    end)
                    f:SetScript("OnMouseUp", function(self, button)
                        if not self.item or not self.collapseItemID then
                            mainFrame:StopMovingOrSizing()
                            return
                        end
                        if button == "LeftButton" then
                            if IsShiftKeyDown() and self.link then
                                ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
                                ChatEdit_InsertLink(self.link)
                            else
                                local itemID = self.collapseItemID
                                BiaoGe.historySummary.itemFrame.close[itemID] = not BiaoGe.historySummary.itemFrame.close[itemID]
                                UpdateAllFrame()
                            end
                        end
                    end)
                    f:SetScript("OnMouseDown", function(self)
                        if not self.item then
                            mainFrame:StartMoving()
                        end
                    end)
                end

                local f = buttons[ii][1]
                f.ds = f:CreateTexture()
                f.ds:SetPoint("TOPLEFT", 0, 0)
                f.ds:SetPoint("BOTTOMRIGHT", buttons[ii][#titleTbl], "BOTTOMRIGHT", 0, 0)

                f.ds2 = f:CreateTexture()
                f.ds2:SetPoint("TOPLEFT", 0, 0)
                f.ds2:SetPoint("BOTTOMRIGHT", buttons[ii][#titleTbl], "BOTTOMRIGHT", 0, 0)
                f.ds2:SetColorTexture(1, 1, 0, 0.2)
                f.ds2:Hide()
            end
        end

        do
            for i, v in ipairs(titleTbl) do
                local bt = CreateFrame("Button", nil, itemFrame)
                bt:SetSize(v.width, BUTTONHEIGHT)
                if i == 1 then
                    bt:SetPoint("BOTTOMLEFT", scroll, "TOPLEFT", 0, 0)
                else
                    bt:SetPoint("LEFT", titlebuttons[i - 1], "RIGHT", 0, 0)
                    bt:SetParent(titlebuttons[i - 1])
                end
                bt:SetNormalFontObject(BG.FontWhite15)
                bt:SetText(v.name)
                bt.textwidth = bt:GetFontString():GetStringWidth()
                bt.textJustifyH = v.JustifyH
                bt.id = i
                bt:SetEnabled(v.Enable)
                bt:RegisterForClicks("AnyUp")
                tinsert(titlebuttons, bt)

                bt.Text = bt:GetFontString()
                bt.Text:SetJustifyH(v.JustifyH)
                bt.Text:SetWordWrap(false)
                HS.CreateTitleBg(bt)

                bt:SetScript("OnClick", function(self, button)
                    BG.PlaySound(1)
                    if button == "LeftButton" then
                        itemFrame.isnewsorter = nil
                        if BiaoGe.historySummary.itemFrame.OrderButtonID ~= self.id then
                            itemFrame.isnewsorter = true
                        end
                        if not itemFrame.isnewsorter then
                            BiaoGe.historySummary.itemFrame.Order = BiaoGe.historySummary.itemFrame.Order == 1 and 0 or 1
                        end
                        BiaoGe.historySummary.itemFrame.OrderButtonID = self.id
                        UpdateAllFrame()
                    elseif button == "RightButton" and self.id == 4 then
                        local equipTypes = {
                            INVTYPE_HEAD, INVTYPE_NECK, INVTYPE_SHOULDER, INVTYPE_CLOAK,
                            INVTYPE_CHEST, INVTYPE_WRIST, INVTYPE_HAND, INVTYPE_WAIST,
                            INVTYPE_LEGS, INVTYPE_FEET, INVTYPE_FINGER, INVTYPE_TRINKET,
                            L["单手剑"], L["双手剑"], L["单手锤"], L["双手锤"],
                            L["单手斧"], L["双手斧"], L["匕首"], L["拳套"],
                            L["长柄武器"], L["法杖"], L["魔杖"], L["枪械"],
                            L["弓"], L["弩"], L["投掷武器"], L["其他"],
                        }
                        local counts = {}
                        for _, itemDB in ipairs(BiaoGe.historySummary[mainFrame.FB].item) do
                            counts[itemDB.EquipLoc] = (counts[itemDB.EquipLoc] or 0) + 1
                        end
                        local menu = {
                            { text = L["类型"], isTitle = true, notCheckable = true },
                        }
                        for index, equipType in ipairs(equipTypes) do
                            local selectedEquipType = equipType
                            if index == 13 then
                                tinsert(menu, { text = "   ", isTitle = true })
                            end
                            local count = counts[selectedEquipType] or 0
                            local color = count == 0 and "|cff808080" or "|cffffffff"
                            tinsert(menu, {
                                text = color .. selectedEquipType .. format(" |cff808080(%s)", count),
                                checked = mainFrame.serachEdit:GetText() == selectedEquipType,
                                func = function()
                                    mainFrame.serachEdit:SetText(selectedEquipType)
                                end,
                            })
                        end
                        tinsert(menu, { text = "   ", isTitle = true })
                        tinsert(menu, { text = CANCEL, notCheckable = true, func = LibBG.CloseDropDownMenus })
                        LibBG:EasyMenu(menu, BG.dropDown, "cursor", 0, 0, "MENU", 2)
                    end
                end)
            end
            CreateLine(titlebuttons[1], 0, titleWidth)

            local sorter = itemFrame:CreateTexture(nil, "OVERLAY")
            sorter:SetSize(8, 8)
            sorter:SetTexture("Interface/Buttons/ui-sortarrow")
            itemFrame.sorter = sorter
        end

        local function GetVisibleMax(itemDB)
            local maxMoney, maxRecord
            for _, record in ipairs(itemDB.all) do
                if mainFrame.CheckOnlyMe(record.player, record.realm) then
                    local money = tonumber(record.money) or 0
                    if not maxMoney or money > maxMoney then
                        maxMoney = money
                        maxRecord = record
                    end
                end
            end
            return maxMoney, maxRecord
        end

        local function Sort(keys, isClickMoney)
            local order = BiaoGe.historySummary.itemFrame.Order
            sort(BiaoGe.historySummary[mainFrame.FB].item, function(a, b)
                for _, key in ipairs(keys) do
                    local aValue, bValue = a[key], b[key]
                    if key == "maxMoney" then
                        aValue = GetVisibleMax(a) or 0
                        bValue = GetVisibleMax(b) or 0
                    end
                    if key == "iLevel" or key == "maxMoney" then
                        aValue = tonumber(aValue) or 0
                        bValue = tonumber(bValue) or 0
                    else
                        aValue = aValue or ""
                        bValue = bValue or ""
                    end
                    if aValue ~= bValue then
                        if key == "maxMoney" and not isClickMoney then
                            return aValue > bValue
                        end
                        if order == 1 then
                            return aValue > bValue
                        else
                            return aValue < bValue
                        end
                    end
                end
                return false
            end)
        end

        function GetDB()
            local history = BiaoGe.historySummary
            if history.itemFrame.OrderButtonID == 3 then
                Sort({ "iLevel", "maxMoney", "EquipLoc", "name" })
            elseif history.itemFrame.OrderButtonID == 4 then
                Sort({ "EquipLoc", "maxMoney", "iLevel", "name" })
            elseif history.itemFrame.OrderButtonID == 5 then
                Sort({ "maxMoney", "iLevel", "EquipLoc", "name" }, true)
            end

            wipe(db)
            local colorIndex = 1
            for _, itemDB in ipairs(history[mainFrame.FB].item) do
                local searchText = mainFrame.serachEdit:GetText()
                local name = itemDB.name or ""
                local equipLoc = itemDB.EquipLoc or L["其他"]
                if searchText == "" or name:find(searchText, 1, true) or equipLoc:find(searchText, 1, true) then
                    local maxMoney, maxRecord = GetVisibleMax(itemDB)
                    local first = true
                    for _, record in ipairs(itemDB.all) do
                        if mainFrame.CheckOnlyMe(record.player, record.realm) then
                            if first or not history.itemFrame.close[itemDB.itemID] then
                                tinsert(db, {
                                    name = name,
                                    link = itemDB.link,
                                    itemID = itemDB.itemID,
                                    maxMoney = maxMoney or 0,
                                    max = maxRecord,
                                    iLevel = itemDB.iLevel or 0,
                                    EquipLoc = equipLoc,
                                    player = record.player,
                                    realm = record.realm,
                                    class = record.class,
                                    money = record.money,
                                    date = record.date,
                                    isAccounts = record.isAccounts,
                                    num = colorIndex,
                                    first = first,
                                })
                            end
                            first = false
                        end
                    end
                    if not first then
                        colorIndex = (colorIndex + 1) % 2
                    end
                end
            end
        end

        function UpdateScrollFrame()
            GetDB()

            local sorter = itemFrame.sorter
            local bt = titlebuttons[BiaoGe.historySummary.itemFrame.OrderButtonID]
            sorter:SetParent(bt)
            sorter:ClearAllPoints()
            if bt.textJustifyH == "CENTER" then
                sorter:SetPoint("LEFT", bt, "CENTER", bt.textwidth / 2, 0)
            else
                sorter:SetPoint("LEFT", bt, "LEFT", bt.textwidth, 0)
            end
            if not itemFrame.isnewsorter then
                sorter:SetTexCoord(0, 0.5, BiaoGe.historySummary.itemFrame.Order == 1 and 0 or 1,
                    BiaoGe.historySummary.itemFrame.Order == 1 and 1 or 0)
            end

            bar:SetMinMaxValues(0, max(0, #db - MAXBUTTONS))
            if scroll.SetScrollExtent then
                scroll:SetScrollExtent(MAXBUTTONS, #db)
            end
            UpdateScrollButtonState()
        end

        function UpdateScrollButtonState()
            if bar.ThumbButton then return end
            local currValue = bar:GetValue()
            local scrollDownButton = bar.ScrollDownButton or _G[bar:GetName() .. "ScrollDownButton"]
            local scrollUpButton = bar.ScrollUpButton or _G[bar:GetName() .. "ScrollUpButton"]
            scrollUpButton:Enable()
            scrollDownButton:Enable()
            local minVal, maxVal = bar:GetMinMaxValues()
            if currValue >= maxVal then scrollDownButton:Disable() end
            if currValue <= minVal then scrollUpButton:Disable() end
        end

        local function GetPlayerText(record)
            if not record then return "" end
            local color = record.class and select(4, GetClassColor(record.class)) or "ff808080"
            local player = record.player or L["未知买家"]
            if record.realm and record.realm ~= realmName then
                player = player .. "-" .. record.realm
            end
            return "|c" .. color .. player .. "|r"
        end

        function GetButtonInfo(num)
            local v = db[num]
            if not v then return end
            local isOpen = not BiaoGe.historySummary.itemFrame.close[v.itemID]
            local icon = select(5, GetItemInfoInstant(v.itemID))
            local itemText = (icon and AddTexture(icon) or "") .. (v.link or v.name)
            local moneyText = v.money and BG.FormatNumber(v.money, 2) or ""
            if v.isAccounts and moneyText ~= "" then
                moneyText = moneyText .. "*"
            end
            local maxRecord = v.max
            return {
                    num,
                    v.first and itemText or "",
                    v.first and v.iLevel or "",
                    v.first and v.EquipLoc or "",
                    v.first and BG.FormatNumber(v.maxMoney, 2) or "",
                    isOpen and HS.ChangeDate(v.date) or (maxRecord and HS.ChangeDate(maxRecord.date) or ""),
                    isOpen and GetPlayerText(v) or GetPlayerText(maxRecord),
                    isOpen and moneyText or "",
                },
                v.num == 1,
                v.first,
                v.link,
                v.itemID,
                v.iLevel
        end

        function UpdateButtons()
            local value = floor(bar:GetValue()) or 0
            for ii = 1, MAXBUTTONS do
                local tbl, isOne, isFirst, link, itemID, iLevel = GetButtonInfo(value + ii)
                for i = 1, #titleTbl do
                    local button = buttons[ii][i]
                    if tbl then
                        button.Text:SetText(tbl[i])
                        button.onenter = button.Text:IsTruncated() and tbl[i] or nil
                        button.link = i == 2 and isFirst and link or nil
                        button.collapseItemID = isFirst and itemID or nil
                        button.item = isFirst and link or nil
                        button.iLevel = isFirst and iLevel or nil
                        local color = isOne and .8 or .4
                        buttons[ii][1].ds:SetColorTexture(color, color, color, 0.2)
                        button:Show()
                    else
                        button.onenter = nil
                        button.link = nil
                        button.collapseItemID = nil
                        button.item = nil
                        button:Hide()
                    end
                end
            end
        end

        function UpdateAllFrame()
            UpdateScrollFrame()
            UpdateButtons()
            mainFrame:UpdateMyTotal()
            mainFrame.noDBText:SetShown(not next(db))
        end
    end

    mainFrame[BiaoGe.historySummary.lastFrame]:Show()

    SlashCmdList["BiaoGeHistorySummary"] = function()
        mainFrame:Show()
    end
    _G['SLASH_' .. 'BiaoGeHistorySummary' .. '1'] = "/bghs"
    _G['SLASH_' .. 'BiaoGeHistorySummary' .. '2'] = "/biaogehistory"
end

BG.Init2(function()
    BiaoGe.historySummary = BiaoGe.historySummary or {}
    local history = BiaoGe.historySummary
    history.onlyShowMe = history.onlyShowMe or 1

    history.playerFrame = history.playerFrame or {}
    history.playerFrame.OrderButtonID = history.playerFrame.OrderButtonID or 5
    history.playerFrame.Order = history.playerFrame.Order or 1
    history.playerFrame.close = history.playerFrame.close or {}

    history.itemFrame = history.itemFrame or {}
    history.itemFrame.OrderButtonID = history.itemFrame.OrderButtonID or 5
    history.itemFrame.Order = history.itemFrame.Order or 1
    history.itemFrame.close = history.itemFrame.close or {}
    if history.lastFrame ~= "playerFrame" and history.lastFrame ~= "itemFrame" then
        history.lastFrame = "playerFrame"
    end
    history.raidNumber = history.raidNumber or {}

    for _, FB in ipairs(BG.FBtable) do
        history[FB] = history[FB] or {}
        history[FB].player = history[FB].player or {}
        history[FB].item = history[FB].item or {}
        history[FB].historyID = history[FB].historyID or {}
        history[FB].sameName = history[FB].sameName or {}
        if history[FB].allOpen == nil then
            history[FB].allOpen = true
        end
        history.raidNumber[FB] = history.raidNumber[FB] or {}
    end

    if BiaoGe.options.historySummaryAutoStart == nil then
        BiaoGe.options.historySummaryAutoStart = 1
    end

    RoadHistory()
end)
