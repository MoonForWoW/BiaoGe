local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local RGB = ns.RGB
local SetClassCFF = ns.SetClassCFF
local GetItemID = ns.GetItemID
local After = C_Timer.After
local realmID = GetRealmID()

local function CreateLine(parent, y, width, height, color, alpha)
    local line = parent:CreateLine()
    line:SetColorTexture(RGB(color or "808080", alpha or 1))
    line:SetStartPoint("BOTTOMLEFT", 0, y)
    line:SetEndPoint("BOTTOMLEFT", width, y)
    line:SetThickness(height or 1.5)
    return line
end

local function CreateCheckButton(name, text, parent, ontext)
    local bt = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    bt:SetSize(30, 30)
    bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    bt.Text:SetText(text)
    bt:SetHitRectInsets(0, -bt.Text:GetWidth(), 0, 0)
    bt.name = name
    bt.ontext = ontext
    BG.options["button" .. name] = bt
    bt:SetChecked(BiaoGe.options[name] == 1)
    bt:SetScript("OnClick", function(self)
        BiaoGe.options[self.name] = self:GetChecked() and 1 or 0
        BG.PlaySound(1)
    end)
    bt:SetScript("OnEnter", function(self)
        if not self.ontext then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
        GameTooltip:SetText(self.ontext)
        GameTooltip:Show()
    end)
    bt:SetScript("OnLeave", GameTooltip_Hide)
    bt:SetScript("OnShow", function(self)
        self:SetChecked(BiaoGe.options[self.name] == 1)
    end)
    return bt
end

local function UpdateScrollButtonState(bar)
    local value = bar:GetValue()
    local down = bar.ScrollDownButton or (bar.GetName and bar:GetName() and _G[bar:GetName() .. "ScrollDownButton"])
    local up = bar.ScrollUpButton or (bar.GetName and bar:GetName() and _G[bar:GetName() .. "ScrollUpButton"])
    local minValue, maxValue = bar:GetMinMaxValues()
    if up then
        up:SetEnabled(value > minValue)
    end
    if down then
        down:SetEnabled(value < maxValue)
    end
end

local function PlayerNamesMatch(name1, name2)
    if not name1 or not name2 then return false end
    if name1 == name2 then return true end
    local shortName1 = Ambiguate and Ambiguate(name1, "none") or name1:gsub("%-.+", "")
    local shortName2 = Ambiguate and Ambiguate(name2, "none") or name2:gsub("%-.+", "")
    return shortName1 == shortName2
end

local function RoadChannelHistory()
    local db = BiaoGe.channelHistory[realmID]
    local mainFrame
    local channelList = {
        [1] = { key = COMMUNITIES_DEFAULT_CHANNEL_NAME, name = COMMUNITIES_DEFAULT_CHANNEL_NAME },
        [2] = { key = TRADE, name = TRADE },
        [3] = { key = LOOK_FOR_GROUP, name = L["组队"] },
        [4] = { key = "大脚世界", name = "大脚" },
        [5] = { key = "MeetingHorn", name = "集结" },
        [10] = { name = L["系统消息"] },
    }

    mainFrame = BG.ChannelHistoryMainFrame

    -- UI
    do
        local db = {}
        local BUTTONHEIGHT = 40
        local MAXBUTTONS = 13
        local HEIGHT = MAXBUTTONS * BUTTONHEIGHT + 5
        local leaderframe, leaderscroll, leaderchild, leaderbar
        local msgframe, msgscroll, msgchild, msgbar
        local GetDB, UpdateScrollFrame, UpdateButtons, GetLastChoose, GetChooseInfo
        local lastChoose
        -- 团长框体
        do
            leaderframe = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
            leaderframe:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            leaderframe:SetBackdropColor(0, 0, 0, 0.4)
            leaderframe:SetBackdropBorderColor(1, 1, 1, .8)
            leaderframe:SetPoint("TOPLEFT", BG.MainFrame, "TOPLEFT", 10, -65)
            leaderframe:SetSize(180, HEIGHT)
            leaderframe:EnableMouse(true)
            leaderframe.buttons = {}
            mainFrame.leaderframe = leaderframe
            leaderframe:SetScript("OnShow", function(self)
                mainFrame:UpdateFrame()
            end)

            leaderscroll = CreateFrame("ScrollFrame", nil, leaderframe, "UIPanelScrollFrameTemplate")
            leaderscroll:SetPoint("TOPLEFT", 0, -2)
            leaderscroll:SetPoint("BOTTOMRIGHT", -25, 2)
            leaderbar = leaderscroll.ScrollBar
            leaderbar.scrollStep = 4
            BG.CreateSrollBarBackdrop(leaderbar)
            -- BG.HookScrollBarShowOrHide(dungeonscroll)
            leaderbar:SetScript("OnValueChanged", function(self)
                UpdateButtons()
                UpdateScrollButtonState(leaderbar)
            end)

            leaderchild = CreateFrame("Frame", nil, leaderframe)
            leaderchild:SetWidth(leaderscroll:GetWidth())
            leaderchild:SetHeight(leaderscroll:GetHeight())
            leaderscroll:SetScrollChild(leaderchild)

            local t = leaderframe:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("BOTTOM", leaderframe, "TOP", 0, 2)
            t:SetTextColor(1, .82, 0)
            t:SetText(L["团长"])

            -- 提示
            local t = leaderframe:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOP", 0, -5)
            t:SetTextColor(.5, .5, .5)
            t:SetText(L["没有团长记录。"])
            leaderframe.notText = t

            local function OnClick(self, button)
                BG.PlaySound(1)
                if button == "RightButton" then
                    local menu = {
                        {
                            text = self.Text1:GetText(),
                            isTitle = true,
                            notCheckable = true,
                        },
                        {
                            text = "   ",
                            isTitle = true,
                            notCheckable = true,
                        },
                        {
                            text = L["删除该团长"],
                            notCheckable = true,
                            func = function()
                                local v = self.info
                                local player = v.player
                                local realmID = v.realmID
                                BiaoGe.channelHistory[realmID][player] = nil
                                lastChoose = nil
                                mainFrame:UpdateFrame()
                                BG.PlaySound(1)
                            end
                        },
                        {
                            text = CANCEL,
                            notCheckable = true,
                            func = LibBG.CloseDropDownMenus,
                        }
                    }
                    LibBG:EasyMenu(menu, BG.dropDown, "cursor", 0, 0, "MENU", 2)
                else
                    lastChoose = self.index
                    leaderframe:UpdateChooseTex()
                    msgframe:UpdateInfo()
                end
            end

            function leaderframe:CreateButton(ii)
                local bt = CreateFrame("Frame", nil, leaderscroll)
                bt:SetSize(leaderchild:GetWidth() - 2, BUTTONHEIGHT)
                if ii == 1 then
                    bt:SetPoint("TOPLEFT", leaderscroll, 2, 0)
                else
                    bt:SetPoint("TOPLEFT", leaderframe.buttons[(ii - 1)], "BOTTOMLEFT", 0, 0)
                end
                bt.num = ii
                leaderframe.buttons[ii] = bt

                bt.Text1 = bt:CreateFontString()
                bt.Text1:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                bt.Text1:SetPoint("TOPLEFT", 5, -1)
                bt.Text1:SetTextColor(1, .82, 0)
                bt.Text1:SetWidth(bt:GetWidth() - 5)
                bt.Text1:SetHeight(bt:GetHeight() / 2)
                bt.Text1:SetWordWrap(false)
                bt.Text1:SetJustifyH("LEFT")

                bt.Text2 = bt:CreateFontString()
                bt.Text2:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                bt.Text2:SetPoint("BOTTOMLEFT", 5, 1)
                bt.Text2:SetTextColor(.6, .6, .6)
                bt.Text2:SetWidth(bt:GetWidth() - 5)
                bt.Text2:SetHeight(bt:GetHeight() / 2)
                bt.Text2:SetWordWrap(false)
                bt.Text2:SetJustifyH("LEFT")
                bt:SetScript("OnEnter", function(self)
                    for i, bt in ipairs(leaderframe.buttons) do
                        bt.ds:Hide()
                    end
                    bt.ds:Show()
                end)
                bt:SetScript("OnLeave", function(self)
                    bt.ds:Hide()
                    GameTooltip:Hide()
                end)
                bt:SetScript("OnMouseUp", OnClick)
                CreateLine(bt, 0, bt:GetWidth(), 1, nil, 0.5)

                -- 底色材质
                bt.ds = bt:CreateTexture()
                bt.ds:SetAllPoints()
                bt.ds:SetColorTexture(1, 1, 1, 0.1)
                bt.ds:Hide()

                bt.chooseds = bt:CreateTexture()
                bt.chooseds:SetAllPoints()
                bt.chooseds:SetColorTexture(0, .75, 1, .8)
                bt.chooseds:Hide()
            end

            function leaderframe:UpdateChooseTex()
                for i, bt in ipairs(self.buttons) do
                    if lastChoose and bt.index == lastChoose then
                        bt.chooseds:Show()
                    else
                        bt.chooseds:Hide()
                    end
                end
            end

            for ii = 1, MAXBUTTONS do
                leaderframe:CreateButton(ii)
            end
        end

        -- 聊天记录
        do
            msgframe = CreateFrame("Frame", nil, leaderframe, "BackdropTemplate")
            msgframe:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            msgframe:SetBackdropColor(0, 0, 0, 0.4)
            msgframe:SetBackdropBorderColor(1, 1, 1, .8)
            msgframe:SetPoint("TOPLEFT", leaderframe, "TOPRIGHT", 5, 0)
            msgframe:SetSize(1070, HEIGHT)
            msgframe:EnableMouse(true)
            mainFrame.msgframe = msgframe
            msgscroll = CreateFrame("ScrollFrame", nil, msgframe, "UIPanelScrollFrameTemplate")
            msgscroll:SetPoint("TOPLEFT", 0, -2)
            msgscroll:SetPoint("BOTTOMRIGHT", -25, 2)
            msgbar = msgscroll.ScrollBar
            msgbar.scrollStep = 80
            BG.CreateSrollBarBackdrop(msgbar)
            BG.HookScrollBarShowOrHide(msgscroll)
            msgchild = CreateFrame("EditBox", nil, msgscroll)
            msgchild:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
            msgchild:SetWidth(msgscroll:GetWidth())
            msgchild:SetAutoFocus(false)
            msgchild:EnableMouse(false)
            msgchild:SetTextInsets(3, 3, 3, 3)
            msgchild:SetMultiLine(true)
            msgchild:SetHyperlinksEnabled(true)
            msgscroll:SetScrollChild(msgchild)
            msgchild:SetScript("OnHyperlinkEnter", function(self, link, text, button)
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 0, 0)
                GameTooltip:ClearLines()
                local itemID = GetItemID(link)
                if itemID then
                    GameTooltip:SetHyperlink(link)
                end
                if (strsub(link, 1, 5) == "spell") then
                    GameTooltip:SetHyperlink(link)
                end
            end)
            msgchild:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
            msgchild:SetScript("OnHyperlinkClick", function(self, link, text, button)
                if (strsub(link, 1, 6) == "player") then
                    local _, name, lineID, chatType = strsplit(":", link)
                    if button == "LeftButton" then
                        ChatFrame_SendTell(name, ChatFrame1)
                    elseif button == "RightButton" then
                        FriendsFrame_ShowDropdown(name, 1, nil, "CHANNEL", nil)
                    end
                elseif (strsub(link, 1, 4) == "item") or (strsub(link, 1, 5) == "spell") then
                    if IsShiftKeyDown() then
                        BG.InsertLink(text)
                    else
                        ShowUIPanel(ItemRefTooltip)
                        if (not ItemRefTooltip:IsShown()) then
                            ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
                        end
                        ItemRefTooltip:SetHyperlink(link)
                    end
                end
            end)
            local t = msgframe:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("BOTTOM", msgframe, "TOP", -20, 2)
            t:SetTextColor(1, .82, 0)
            t:SetText(L["喊话记录"])
            local bt = CreateFrame("Button", nil, msgframe)
            bt:SetSize(18, 18)
            bt:SetNormalAtlas("AzeriteReady")
            bt:SetHighlightAtlas("AzeriteReady")
            bt:SetPoint("BOTTOMRIGHT", msgframe, "TOPRIGHT", -0, -0)
            bt:RegisterForClicks("AnyUp")
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                BG.CreateExportFrame(L["导出聊天记录"], msgchild:GetText():gsub("|T.-|t", ""):gsub("|A.-|a", ""))
            end)
            bt:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["导出聊天记录"], 1, 1, 1, true)
                GameTooltip:Show()
            end)
            bt:SetScript("OnLeave", GameTooltip_Hide)

            -- 提示
            local t = msgframe:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOP", -20, -5)
            t:SetTextColor(.5, .5, .5)
            t:SetText(L["没有喊话记录。"])
            msgframe.notText = t

            function msgframe:UpdateInfo()
                msgchild:SetText("")
                local info = GetChooseInfo()
                local hasMessage
                if info and info.msgs then
                    for i = #info.msgs, 1, -1 do
                        local v = info.msgs[i]
                        if BiaoGe.options["channelHistory" .. v.c] == 1 then
                            local time = date("%H:%M", v.t)
                            local color
                            local msg
                            if v.c == 10 then
                                color = "ffff00"
                                msg = format(L["|cff808080%s|r |cff%s%s|r"], time, color, v.m or "")
                            else
                                color          = "ffc0c0"
                                local channel  = channelList[v.c] and channelList[v.c].name or UNKNOWN
                                local nameLink = "|Hplayer:" .. info.player .. "|h[" .. info.colorPlayer .. "]|h"
                                msg            = format(L["|cff808080%s|r |cff%s[%s]%s：%s|r"], time, color, channel, nameLink, v.m or "")
                            end

                            msg = BG.GsubRaidTargetingIcons(msg)
                            if i ~= 1 then
                                msg = msg .. "\n"
                            end
                            msgchild:Insert(msg)
                            hasMessage = true
                        end
                    end
                end
                msgframe.notText:SetShown(not hasMessage)
            end
        end

        -- 刷新列表
        do
            local bt = BG.CreateButton(mainFrame)
            bt:SetPoint("TOPLEFT", leaderframe, "BOTTOMLEFT", 0, -5)
            bt:SetPoint("BOTTOMRIGHT", leaderframe, "BOTTOMRIGHT", 0, -28)
            bt:SetText(L["刷新列表"])
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                mainFrame:UpdateFrame()
            end)
        end

        -- 频道过滤
        do
            local t = msgframe:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPLEFT", msgframe, "BOTTOMLEFT", 5, -10)
            t:SetTextColor(1, .82, 0)
            t:SetText(L["频道过滤："])

            local last
            for channelID = 1, 20 do
                local v = channelList[channelID]
                if v then
                    local name = "channelHistory" .. channelID
                    BiaoGe.options[name] = BiaoGe.options[name] or 1
                    local bt = CreateCheckButton(name, v.name, mainFrame)
                    if last then
                        bt:SetPoint("LEFT", last, "RIGHT", last.Text:GetWidth() + 5, 0)
                    else
                        bt:SetPoint("LEFT", t, "RIGHT", 5, -2)
                    end
                    last = bt
                    bt:HookScript("OnClick", function(self)
                        msgframe:UpdateInfo()
                    end)
                end
            end
        end

        function mainFrame:UpdateFrame()
            if not self:IsVisible() then return end
            UpdateScrollFrame()
            UpdateButtons()
            msgframe:UpdateInfo()
            if next(db) then
                leaderframe:UpdateChooseTex()
            end
        end

        function mainFrame:ChoosePlayer(player)
            for i, info in ipairs(db) do
                if info.player == player then
                    lastChoose = i
                    leaderframe:UpdateChooseTex()
                    msgframe:UpdateInfo()
                    return
                end
            end
        end

        function GetLastChoose()
            if not lastChoose then
                lastChoose = 1
            end
            if next(db) and not db[lastChoose] then
                lastChoose = 1
            end
            return lastChoose
        end

        function GetChooseInfo()
            return db[GetLastChoose()]
        end

        function GetDB()
            wipe(db)
            for realmID in pairs(BiaoGe.channelHistory) do
                for _, v in pairs(BiaoGe.channelHistory[realmID]) do
                    if v.isLeader then
                        tinsert(db, BG.Copy(v))
                    end
                end
            end
            sort(db, function(a, b)
                local key = "createTime"
                if a[key] and b[key] then
                    if a[key] ~= b[key] then
                        return a[key] > b[key]
                    end
                end
                return false
            end)
        end

        function UpdateScrollFrame()
            GetDB()
            local m = #db - MAXBUTTONS
            leaderbar:SetMinMaxValues(0, max(0, m))
            UpdateScrollButtonState(leaderbar)
            leaderframe.notText:SetShown(not next(db))
        end

        function UpdateButtons()
            local value = floor(leaderbar:GetValue()) or 0
            for ii = 1, MAXBUTTONS do
                local index = value + ii
                local v = db[index]
                local bt = leaderframe.buttons[ii]
                if v then
                    bt:Show()
                    bt.Text1:SetText(v.colorPlayer)
                    bt.Text2:SetText(date("%m-%d %H:%M", v.createTime))
                    bt.info = v
                    bt.index = index
                else
                    bt:Hide()
                end
            end
            leaderframe:UpdateChooseTex()
            GameTooltip:Hide()
        end
    end

    -- 记录频道消息
    do
        local function IsLeaderName(name)
            if not name then return false end
            for i = 1, GetNumGroupMembers() do
                local raidName, rank = GetRaidRosterInfo(i)
                if raidName and rank == 2 and PlayerNamesMatch(raidName, name) then
                    return true
                end
            end
            return false
        end

        local function CheckLeader()
            if IsInGroup(1) then
                for i = 1, GetNumGroupMembers() do
                    local player, rank = GetRaidRosterInfo(i)
                    if player and rank == 2 then
                        for savedName, info in pairs(BiaoGe.channelHistory[realmID]) do
                            if PlayerNamesMatch(savedName, player) and not info.isLeader then
                                info.isLeader = true
                                info.colorPlayer = SetClassCFF(player)
                                break
                            end
                        end
                        return
                    end
                end
            end
        end
        BG.RegisterEvent("GROUP_ROSTER_UPDATE", function()
            After(.5, CheckLeader)
        end)

        BG.RegisterEvent("CHAT_MSG_CHANNEL", function(_, _, msg, fullName, languageName, channelName, target,
                                                      specialFlags, zoneChannelID, channelIndex, channelBaseName)
            local channelID
            for i, v in pairs(channelList) do
                if v and v.key and channelBaseName and channelBaseName:find(v.key, 1, true) then
                    channelID = i
                    break
                end
            end
            if channelID and fullName and fullName ~= "" then
                local player = BG.GSN(fullName)
                db[player] = db[player] or {
                    player = player,
                    colorPlayer = player,
                    realmID = realmID,
                    isLeader = nil,
                    createTime = time(),
                    msgs = {},
                }
                if not db[player].isLeader then
                    if IsLeaderName(player) then
                        db[player].isLeader = true
                        db[player].colorPlayer = SetClassCFF(player)
                    end
                end

                if channelID == 5 then
                    -- msg = msg:match("^.-%.(.-)%..-%..-%..-%..-%..-%..-%..-%..-@@$")
                    local p1 = msg:find(".", 1, true)
                    if p1 then
                        local p2 = msg:find(".", p1 + 1, true)
                        if p2 then
                            msg = msg:sub(p1 + 1, p2 - 1)
                        end
                    end
                end
                tinsert(db[player].msgs, 1, {
                    t = time(),
                    c = channelID,
                    m = msg,
                })
            end
        end)

        if ERR_INVITED_TO_GROUP_SS then
            local inviteText = ERR_INVITED_TO_GROUP_SS:gsub(".+|h", "")
            if inviteText ~= "" then
                BG.RegisterEvent("CHAT_MSG_SYSTEM", function(_, _, msg)
                    if msg:find(inviteText, 1, true) then
                        for _, info in pairs(BiaoGe.channelHistory[realmID]) do
                            tinsert(info.msgs, 1, {
                                t = time(),
                                c = 10,
                                m = msg,
                            })
                        end
                    end
                end)
            end
        end
    end

    -- 定时清理消息
    do
        local f = CreateFrame("Frame")
        local one = 20
        local msgSaveTime = 60 * 5
        local msgSaveTime_leader = 60 * 60 * 5
        local function DeleteTimeOutMSG()
            local names = {}
            local time = time()
            for realmID in pairs(BiaoGe.channelHistory) do
                for player in pairs(BiaoGe.channelHistory[realmID]) do
                    tinsert(names, { player = player, realmID = realmID })
                end
            end
            local startI = 1
            f:SetScript("OnUpdate", function(self, t)
                for i = startI, startI + one - 1 do
                    if not names[i] then
                        self:SetScript("OnUpdate", nil)
                        return
                    end

                    local player = names[i].player
                    local realmID = names[i].realmID
                    local v = BiaoGe.channelHistory[realmID][player]
                    if v then
                        local saveTime = v.isLeader and msgSaveTime_leader or msgSaveTime
                        local msgs = v.msgs
                        for i = #msgs, 1, -1 do
                            if time - msgs[i].t >= saveTime then
                                tremove(msgs, i)
                            end
                        end
                        if not next(msgs) then
                            BiaoGe.channelHistory[realmID][player] = nil
                        end
                    end
                end
                startI = startI + one
            end)
        end
        DeleteTimeOutMSG()
        C_Timer.NewTicker(30, DeleteTimeOutMSG)
    end

    -- 右键菜单
    do
        local target
        local function FindSavedPlayer(player)
            for savedName, info in pairs(BiaoGe.channelHistory[realmID]) do
                if info.isLeader and PlayerNamesMatch(savedName, player) then
                    return savedName
                end
            end
        end
        local function OpenFrame()
            BG.MainFrame:Show()
            BG.ClickTabButton(BG.ChannelHistoryMainFrameTabNum)
            mainFrame:ChoosePlayer(target)
        end
        local function CreateButton(description, player)
            target = player
            description:CreateDivider()
            description:CreateButton(L["团长历史喊话"], OpenFrame)
        end

        local menus = {
            "MENU_UNIT_SELF",
            "MENU_UNIT_TARGET",
            "MENU_UNIT_PLAYER",
            "MENU_UNIT_FRIEND",
            "MENU_UNIT_PARTY",
            "MENU_UNIT_RAID",
            "MENU_UNIT_RAID_PLAYER",
        }
        if Menu and Menu.ModifyMenu then
            for _, menu in ipairs(menus) do
                Menu.ModifyMenu(menu, function(owner, description, contextData)
                    local unit = contextData.unit
                    local savedPlayer = unit and UnitIsPlayer(unit) and FindSavedPlayer(contextData.name)
                    if savedPlayer then
                        CreateButton(description, savedPlayer)
                    end
                end)
            end
        end
    end
end

BG.Init(function()
    BiaoGe.channelHistory = BiaoGe.channelHistory or {}
    BiaoGe.channelHistory[realmID] = BiaoGe.channelHistory[realmID] or {}
    RoadChannelHistory()
end)
