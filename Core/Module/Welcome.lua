local AddonName, ns = ...

if BG.IsRetail then return end

local LibBG             = ns.LibBG
local L                 = ns.L

local After             = C_Timer.After

local IsAddOnLoaded     = IsAddOnLoaded or C_AddOns.IsAddOnLoaded
local GetAddOnMetadata  = GetAddOnMetadata or C_AddOns.GetAddOnMetadata


local function CreateCheckButton(name, text, parent, ontext)
    local button = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    button:SetSize(30, 30)
    button.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    button.Text:SetText(text)
    button:SetHitRectInsets(0, -button.Text:GetWidth(), 0, 0)
    button.name = name
    button.ontext = ontext
    button:SetChecked(BiaoGe.welcome[name] == 1)
    button:SetScript("OnClick", function(self)
        BiaoGe.welcome[self.name] = self:GetChecked() and 1 or 0
        BG.PlaySound(1)
    end)
    button:SetScript("OnEnter", function(self)
        if not self.ontext then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
        GameTooltip:ClearLines()
        if type(self.ontext) == "table" then
            for i, tipText in ipairs(self.ontext) do
                if i == 1 then
                    GameTooltip:AddLine(tipText, 1, 1, 1, true)
                else
                    GameTooltip:AddLine(tipText, 1, .82, 0, true)
                end
            end
        else
            GameTooltip:SetText(self.ontext)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnShow", function(self)
        self:SetChecked(BiaoGe.welcome[self.name] == 1)
    end)
    return button
end

BG.Init2(function()
    BiaoGe.welcome = BiaoGe.welcome or {}
    BiaoGe.welcome.choose = BiaoGe.welcome.choose or 0
    BiaoGe.welcome.ban = BiaoGe.welcome.ban or 0
    BiaoGe.welcome.templateChoose = BiaoGe.welcome.templateChoose or 1
    if not BiaoGe.welcome.template then
        local templateNames = {
            L["模版一"],
            L["模版二"],
            L["模版三"],
            L["模版四"],
            L["模版五"],
        }
        BiaoGe.welcome.template = {}
        for i = 1, 5 do
            BiaoGe.welcome.template[i] = {
                {
                    choose = 0,
                    text = L["YY："],
                },
                {
                    choose = 0,
                    text = L["分金规则："],
                },
                {
                    choose = 0,
                    text = L["拍卖规则："],
                },
                channel = "RAID",
                name = templateNames[i],
            }
        end
    end
    for i, template in ipairs(BiaoGe.welcome.template) do
        template.channel = template.channel or "WHISPER"
        template.name = template.name or format(L["模版%s"], i)
    end
    BiaoGe.welcome.autoSendYY = BiaoGe.welcome.autoSendYY or 1
    BiaoGe.welcome.autoSendYY_leader = BiaoGe.welcome.autoSendYY_leader or 1
    BiaoGe.welcome.autoSendYY_assistant = BiaoGe.welcome.autoSendYY_assistant or 1
    BiaoGe.welcome.autoSendYY_YY = BiaoGe.welcome.autoSendYY_YY or ""

    local mainFrame = BG.WelcomeMainFrame
    local mainButton, welcomeframe, UpdateFrames
    local optionsButton, mainButton2
    local editHeight = 100

    local function UpdateAllDropDown()
        local choose = BiaoGe.welcome.templateChoose
        local channel = BiaoGe.welcome.template[choose].channel
        local channelName = welcomeframe.channelTbl[channel]
        LibBG:UIDropDownMenu_SetText(welcomeframe.channelDropDown, channelName)

        local parentName = BiaoGe.welcome.template[choose].name
        LibBG:UIDropDownMenu_SetText(welcomeframe.dropDown, parentName)
        if welcomeframe.dropDown2 then
            LibBG:UIDropDownMenu_SetText(welcomeframe.dropDown2, parentName)
        end
    end

    -- 主界面
    do
        welcomeframe = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
        welcomeframe:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 1,
        })
        welcomeframe:SetBackdropColor(0, 0, 0, 0.8)
        welcomeframe:SetBackdropBorderColor(1, 1, 1, .8)
        welcomeframe:SetPoint("TOPLEFT", BG.MainFrame, "TOPLEFT", 10, -65)
        welcomeframe:SetSize(500, (editHeight + 30) * 3 + 40)
        welcomeframe:EnableMouse(true)
        welcomeframe.child = {}

        welcomeframe.channelTbl = {
            WHISPER = L["发送频道：密语"],
            RAID = L["发送频道：团队"],
        }

        local t = welcomeframe:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetPoint("BOTTOM", welcomeframe, "TOP", 0, 2)
        t:SetTextColor(1, .82, 0)
        t:SetText(L["进组欢迎语"])

        function welcomeframe:UpdateAlpha()
            self:SetAlpha(BiaoGe.welcome.choose == 1 and 1 or .5)
        end

        welcomeframe:UpdateAlpha()
    end

    -- 进组欢迎语
    do
        mainButton = CreateFrame("CheckButton", nil, mainFrame, "ChatConfigCheckButtonTemplate")
        mainButton:SetSize(30, 30)
        mainButton.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        mainButton.Text:SetPoint("LEFT", mainButton, "RIGHT")
        mainButton.Text:SetText(L["启用进组欢迎语"])
        mainButton:SetHitRectInsets(0, -mainButton.Text:GetWidth(), 0, 0)
        mainButton:SetPoint("TOPLEFT", welcomeframe, "BOTTOMLEFT", 0, 0)
        mainButton:SetChecked(BiaoGe.welcome.choose == 1)
        mainButton:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            BiaoGe.welcome.choose = self:GetChecked() and 1 or 0
            self:UpdateTextColor()
        end)
        mainButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["进组欢迎语"], 1, 1, 1, true)
            GameTooltip:AddLine(L["当有人进组时，自动密语对方。一个输入框为一条密语。"], 1, 0.82, 0, true)
            if BG.IsWLK then
                GameTooltip:AddLine(L["开组宝库时，不会发送欢迎语。"], 1, .82, 0, true)
            end
            GameTooltip:Show()
        end)
        mainButton:SetScript("OnLeave", GameTooltip_Hide)
    end

    -- 屏蔽欢迎语
    do
        local bt = CreateFrame("CheckButton", nil, mainFrame, "ChatConfigCheckButtonTemplate")
        bt:SetSize(30, 30)
        bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        bt.Text:SetText(L["屏蔽欢迎语"])
        bt.Text:SetPoint("LEFT", bt, "RIGHT")
        bt:SetHitRectInsets(0, -bt.Text:GetWidth(), 0, 0)
        bt:SetPoint("TOPLEFT", mainButton, "BOTTOMLEFT", 0, 0)
        bt:SetChecked(BiaoGe.welcome.ban == 1)
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            BiaoGe.welcome.ban = self:GetChecked() and 1 or 0
        end)
        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["屏蔽欢迎语"], 1, 1, 1, true)
            GameTooltip:AddLine(L["在聊天框不显示你发送的欢迎语，避免刷屏。但实际上欢迎语已经发送给对方，对方能看到。"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        bt:SetScript("OnLeave", GameTooltip_Hide)
    end

    -- 输入框
    do
        local function CreateF(i)
            local parent = welcomeframe
            parent.child[i] = {}

            local bt = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
            bt:SetSize(25, 25)
            bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            bt.Text:SetText(format(L["启用该消息"]))
            bt.Text:SetPoint("LEFT", bt, "RIGHT")
            bt:SetHitRectInsets(0, -bt.Text:GetWidth(), 0, 0)
            if parent.child[i - 1] then
                bt:SetPoint("TOPLEFT", parent.child[i - 1].frame, "BOTTOMLEFT", -5, -5)
            else
                bt:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -35)
            end
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                local chooseID = BiaoGe.welcome.templateChoose
                BiaoGe.welcome.template[chooseID][i].choose = self:GetChecked() and 1 or 0
                bt:UpdateAlpha()
                BG.ClearFocus()
            end)
            parent.child[i].bt = bt

            function bt:UpdateAlpha()
                if self:GetChecked() then
                    self.Text:SetTextColor(1, 1, 1)
                    self.frame:SetBackdropBorderColor(1, 1, 1, .8)
                    self.child:SetTextColor(1, 1, 1)
                else
                    self.Text:SetTextColor(.5, .5, .5)
                    self.frame:SetBackdropBorderColor(.5, .5, .5, .3)
                    self.child:SetTextColor(.5, .5, .5)
                end
            end

            local frame = CreateFrame("Frame", nil, bt, "BackdropTemplate")
            frame:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            frame:SetBackdropColor(0, 0, 0, 0)
            frame:SetPoint("TOPLEFT", bt, "BOTTOMLEFT", 5, 0)
            frame:SetSize(parent:GetWidth() - 20, editHeight)
            frame:EnableMouse(true)
            parent.child[i].frame = frame
            bt.frame = frame
            local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
            scroll:SetWidth(frame:GetWidth() - 30)
            scroll:SetHeight(frame:GetHeight() - 8)
            scroll:SetPoint("TOPLEFT", 5, -4)
            bt.scroll = scroll
            BG.CreateSrollBarBackdrop(scroll.ScrollBar)
            BG.HookScrollBarShowOrHide(scroll)
            local edit = CreateFrame("EditBox", nil, scroll)
            edit:SetWidth(scroll:GetWidth())
            edit:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
            edit:SetMaxBytes(255)
            edit:SetMultiLine(true)
            edit:SetAutoFocus(false)
            bt.child = edit
            scroll:SetScrollChild(edit)
            local rightt = frame:CreateFontString(nil, "ARTWORK")
            rightt:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
            rightt:SetTextColor(.5, .5, .5)
            rightt:SetPoint("BOTTOMRIGHT", -2, 2)
            BG.SetEditBaseClass(edit)
            edit:SetScript("OnTextChanged", function(self)
                local text = self:GetText()
                if text then
                    if text:find("\n") then
                        self:SetText(text:gsub("\n", ""))
                        return
                    end
                    rightt:SetText(edit:GetMaxBytes() - strlen(text))
                    local chooseID = BiaoGe.welcome.templateChoose
                    BiaoGe.welcome.template[chooseID][i].text = text
                end
            end)
            frame:SetScript("OnMouseDown", function(self, enter)
                if enter == "RightButton" then
                    edit:SetEnabled(false)
                    edit:SetText("")
                else
                    edit:SetFocus()
                end
            end)
            frame:SetScript("OnMouseUp", function(self, enter)
                if enter == "RightButton" then
                    edit:SetEnabled(true)
                end
            end)

            bt:UpdateAlpha()
        end
        function UpdateFrames()
            local chooseID = BiaoGe.welcome.templateChoose
            for i = 1, 3 do
                local bt = welcomeframe.child[i].bt
                bt:SetChecked(BiaoGe.welcome.template[chooseID][i].choose == 1)
                bt:UpdateAlpha()
                if BiaoGe.welcome.template[chooseID][i].text then
                    BiaoGe.welcome.template[chooseID][i].text = BiaoGe.welcome.template[chooseID][i].text:gsub("\n", "")
                end
                bt.child:SetText(BiaoGe.welcome.template[chooseID][i].text)
            end
        end

        for i = 1, 3 do
            CreateF(i)
        end
        UpdateFrames()
    end

    -- 模版
    do
        local dropDown = LibBG:Create_UIDropDownMenu(nil, welcomeframe)
        dropDown:SetPoint("TOPLEFT", -5, -5)
        LibBG:UIDropDownMenu_SetWidth(dropDown, 100)
        LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
        BG.dropDownToggle(dropDown)
        dropDown:SetScale(0.95)
        welcomeframe.dropDown = dropDown
        LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
            for i, v in ipairs(BiaoGe.welcome.template) do
                local info = LibBG:UIDropDownMenu_CreateInfo()
                info.text = v.name
                info.checked = i == BiaoGe.welcome.templateChoose
                info.arg1 = i
                info.func = function()
                    BiaoGe.welcome.templateChoose = i
                    UpdateFrames()
                    UpdateAllDropDown()
                    BG.ClearFocus()
                end
                LibBG:UIDropDownMenu_AddButton(info)
            end
        end)
    end

    -- 模版改名
    do
        for i = 1, L_UIDROPDOWNMENU_MAXBUTTONS do
            local button = _G["L_DropDownList1Button" .. i]
            button:HookScript("OnEnter", function()
                if L_DropDownList1.dropdown ~= welcomeframe.dropDown then return end
                if not button.sendWelcomeChangeName then
                    local bt = CreateFrame("Button", nil, button)
                    bt:SetSize(15, 15)
                    bt:SetPoint("RIGHT", -2, 0)
                    bt:SetNormalAtlas("AzeriteSpawning")
                    bt:SetHighlightAtlas("AzeriteSpawning")
                    bt:RegisterForClicks("AnyUp")
                    bt.num = i
                    bt:Hide()
                    button.sendWelcomeChangeName = bt
                    bt:SetScript("OnClick", function(self)
                        LibBG:CloseDropDownMenus()
                        local i = button.arg1
                        StaticPopupDialogs["BiaoGe_SendWelcomeChangeName"].OnAccept = function(self)
                            local editBox = self.EditBox or self.editBox
                            BiaoGe.welcome.template[i].name = editBox:GetText()
                            UpdateAllDropDown()
                        end
                        local name = BiaoGe.welcome.template[i].name
                        StaticPopup_Show("BiaoGe_SendWelcomeChangeName", name, nil, name)
                    end)
                    bt:SetScript("OnEnter", function(self)
                        button.isOnEnter = true
                        LibBG:UIDropDownMenu_StopCounting(self:GetParent():GetParent())
                        button.Highlight:Show()
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(L["模版改名"], 1, 1, 1, true)
                        GameTooltip:Show()
                    end)
                    bt:SetScript("OnLeave", function(self)
                        LibBG:UIDropDownMenu_StartCounting(self:GetParent():GetParent())
                        button.Highlight:Hide()
                        GameTooltip:Hide()
                    end)
                    bt:SetScript("OnHide", function(self)
                        self:Hide()
                    end)
                end
                button.isOnEnter = true
                for ii = 1, _G['L_DropDownList1'].numButtons do
                    local bt = _G["L_DropDownList1Button" .. ii]
                    if bt.sendWelcomeChangeName then
                        bt.sendWelcomeChangeName:Hide()
                    end
                end
                button.sendWelcomeChangeName:Show()
            end)
            button:HookScript("OnLeave", function()
                if L_DropDownList1.dropdown ~= welcomeframe.dropDown then return end
                button.isOnEnter = false
                After(0, function()
                    if not button.isOnEnter then
                        button.sendWelcomeChangeName:Hide()
                    end
                end)
            end)
        end

        StaticPopupDialogs["BiaoGe_SendWelcomeChangeName"] = {
            text = L["正在更改\"%s\"的名字"],
            button1 = L["是"],
            button2 = L["否"],
            OnCancel = function()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            hasEditBox = true,
            editBoxWidth = 230,
            OnShow = function(self, name)
                local edit = self.EditBox or self.editBox
                edit:SetFocus()
                edit:SetText(name)
                edit:HighlightText()
            end,
            EditBoxOnEnterPressed = function(self)
                self:GetParent():GetButton1():Click()
            end,
            EditBoxOnEscapePressed = function(self)
                self:GetParent():Hide()
            end,
        }
    end

    -- 通报频道
    do
        local dropDown = LibBG:Create_UIDropDownMenu(nil, welcomeframe)
        dropDown:SetPoint("TOPRIGHT", 5, -5)
        LibBG:UIDropDownMenu_SetWidth(dropDown, 140)
        LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
        BG.dropDownToggle(dropDown)
        dropDown:SetScale(0.95)
        welcomeframe.channelDropDown = dropDown
        LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
            for channelKey, name in pairs(welcomeframe.channelTbl) do
                local info = LibBG:UIDropDownMenu_CreateInfo()
                info.text = name
                info.checked = LibBG:UIDropDownMenu_GetText(dropDown) == info.text
                info.func = function()
                    local choose = BiaoGe.welcome.templateChoose
                    BiaoGe.welcome.template[choose].channel = channelKey
                    UpdateAllDropDown()
                end
                LibBG:UIDropDownMenu_AddButton(info)
            end
        end)
    end

    -- 发送消息
    local addonName = "MeetingHorn"
    local MeetingHorn, LFG, Activity, CreatorFrame, hasActivity, MeetingHornFrame
    if IsAddOnLoaded(addonName) then
        local ver = GetAddOnMetadata(addonName, "Version"):gsub("%-%d+", ""):gsub("%D", "")
        ver = tonumber(ver)
        BG.hasMeetingHorn = true
        if BG.IsTitan and ver >= 400 then
            BG.isNewMeetingHorn = true
        else
            BG.isOldMeetingHorn = true
        end
    end

    if BG.hasMeetingHorn then
        MeetingHorn = LibStub("AceAddon-3.0"):GetAddon(addonName)
        LFG = MeetingHorn:GetModule('LFG', 'AceEvent-3.0', 'AceTimer-3.0', 'AceComm-3.0', 'LibCommSocket-3.0')
        if BG.isOldMeetingHorn then
            Activity = MeetingHorn.MainPanel.Manage.Creator.Activity
        end

        local func
        if BG.isOldMeetingHorn then
            func = function()
                local yes = true
                local activity = LFG:GetCurrentActivity()
                if activity then
                    local ActivityID = Activity:GetValue()
                    -- pt(ActivityID)
                    if BG.IsWLK then
                        if ActivityID == 7 or ActivityID == 8 then -- 宝库
                            yes = nil
                        end
                    elseif BG.IsMOP then
                    end
                end
                if yes then
                    hasActivity = activity
                else
                    After(.2, function()
                        if not LFG:GetCurrentActivity() then
                            hasActivity = nil
                        end
                    end)
                end
                mainButton:UpdateTextColor()
            end
        else
            if not MeetingHornHeroicMainFrame then
                local icon = LibStub("LibDBIcon-1.0", true)
                if icon then
                    local bt = icon:GetMinimapButton('MeetingHornHeroic')
                    bt:Click()
                    if MeetingHornHeroicMainFrameTab1 then
                        MeetingHornHeroicMainFrameTab1:Click()
                    end
                    if MeetingHornHeroicMainFrameTab2 then
                        MeetingHornHeroicMainFrameTab2:Click()
                    end
                    bt:Click()
                end
            end
            if MeetingHornHeroicMainFrame then
                for _, child in pairs({ MeetingHornHeroicMainFrame.contentFrame:GetChildren() }) do
                    if child.createButton then
                        CreatorFrame = child
                        break
                    end
                end
                if CreatorFrame then
                    func = function()
                        local yes = CreatorFrame.closeButton:IsEnabled()
                        local ActivityID = CreatorFrame.selectedRaidId
                        if ActivityID then
                            if ActivityID == 4603 then -- 宝库
                                yes = nil
                            end
                        end
                        hasActivity = yes
                        mainButton:UpdateTextColor()
                    end
                end
            end
        end
        if func then
            C_Timer.NewTicker(1, func)
        end

        local sendtimer = CreateFrame("Frame")
        -- 发送消息
        do
            local function GetChannel()
                local chooseID = BiaoGe.welcome.templateChoose
                local channel = BiaoGe.welcome.template[chooseID].channel
                if channel == "RAID" and not IsInRaid(1) then
                    channel = "PARTY"
                end
                return channel
            end

            local strRaid = ERR_RAID_MEMBER_ADDED_S:gsub("%%s", "(.+)")
            local strTeam = ERR_JOINED_GROUP_S:gsub("%%s", "(.+)")
            BG.RegisterEvent("CHAT_MSG_SYSTEM", function(self, event, msg)
                if BiaoGe.welcome.choose ~= 1 then return end
                if not hasActivity then return end
                local needSendMSG = {}
                for i = 1, 3 do
                    local bt = welcomeframe.child[i].bt
                    local text = bt.child:GetText()
                    if bt:GetChecked() and text ~= "" then
                        tinsert(needSendMSG, text)
                    end
                end
                if not next(needSendMSG) then return end

                local name = msg:match(strRaid) or msg:match(strTeam)
                if name and not name:find("[| ]") then
                    local channel = GetChannel()
                    After(1, function()
                        local late = 0
                        for _, text in ipairs(needSendMSG) do
                            After(late, function()
                                SendChatMessage(text, channel, nil, name)
                            end)
                            late = late + BG.tongBaoSendCD
                        end
                    end)
                    sendtimer.sending = true
                    sendtimer.t = 0
                    sendtimer:SetScript("OnUpdate", function(self, t)
                        self.t = self.t + t
                        if self.t >= 3 then
                            sendtimer.sending = nil
                            self:SetScript("OnUpdate", nil)
                        end
                    end)
                end
            end)
        end

        -- 屏蔽消息
        do
            local function Ban(self, event, msg, player, l, cs, t, flag, channelId, ...)
                if BiaoGe.welcome.choose == 1 and BiaoGe.welcome.ban == 1 and sendtimer.sending then
                    for i = 1, 3 do
                        local bt = welcomeframe.child[i].bt
                        local text = bt.child:GetText()
                        if bt:GetChecked() and (msg:find(text, 1, true) or msg:find("YY:", 1, true)) then
                            return true
                        end
                    end
                end
            end
            local function Afk(self, event, msg, player, l, cs, t, flag, channelId, ...)
                if BiaoGe.welcome.choose == 1 and BiaoGe.welcome.ban == 1 and sendtimer.sending then
                    return true
                end
            end

            ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", Ban)
            ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", Ban)
            ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", Ban)
            ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", Ban)
            ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", Ban)
            ChatFrame_AddMessageEventFilter("CHAT_MSG_AFK", Afk)
        end
    end

    -- 集结号按钮
    if BG.hasMeetingHorn then
        if BG.isOldMeetingHorn then
            MeetingHornFrame = MeetingHorn.MainPanel.Manage
        else
            MeetingHornFrame = CreatorFrame
        end
    end
    if MeetingHornFrame then
        -- 设置按钮
        do
            local bt = CreateFrame("CheckButton", nil, MeetingHornFrame)
            if BG.isOldMeetingHorn then
                bt:SetPoint("BOTTOMRIGHT", MeetingHornFrame, "TOPRIGHT", 0, 0)
            else
                bt:SetPoint("TOPRIGHT", MeetingHornFrame, "TOPRIGHT", 0, -33)
            end
            bt:SetSize(25, 25)
            bt:SetNormalTexture([[Interface\Buttons\UI-OptionsButton]])
            bt:SetHighlightTexture([[Interface\Buttons\UI-OptionsButton]])
            optionsButton = bt
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                BG.MainFrame:Show()
                BG.ClickTabButton(BG.WelcomeMainFrameTabNum)
            end)
        end

        -- 进组欢迎语
        do
            local bt = CreateFrame("CheckButton", nil, MeetingHornFrame, "ChatConfigCheckButtonTemplate")
            bt:SetSize(30, 30)
            bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            bt.Text:SetText(L["进组欢迎语"])
            bt.Text:SetPoint("LEFT", bt, "RIGHT")
            bt:SetHitRectInsets(0, -bt.Text:GetWidth(), 0, 0)
            bt:SetPoint("RIGHT", optionsButton, "LEFT", -bt.Text:GetWidth() - 5, 0)
            bt:SetChecked(BiaoGe.welcome.choose == 1)
            mainButton2 = bt
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                BiaoGe.welcome.choose = self:GetChecked() and 1 or 0
                self:UpdateTextColor()
            end)
            bt:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["进组欢迎语"], 1, 1, 1, true)
                GameTooltip:AddLine(L["当有人进组时，自动密语对方。"], 1, 0.82, 0, true)
                GameTooltip:AddLine(L["点击黄色齿轮修改密语内容。"], 1, 0.82, 0, true)
                if BG.IsWLK then
                    GameTooltip:AddLine(L["开组宝库时，不会发送欢迎语。"], 1, .82, 0, true)
                end
                GameTooltip:Show()
            end)
            bt:SetScript("OnLeave", GameTooltip_Hide)
        end

        -- 模板
        do
            local dropDown = LibBG:Create_UIDropDownMenu(nil, MeetingHornFrame)
            dropDown:SetPoint("BOTTOMRIGHT", optionsButton, "TOPRIGHT", 12, -3)
            LibBG:UIDropDownMenu_SetWidth(dropDown, 100)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
            BG.dropDownToggle(dropDown)
            dropDown:SetScale(0.9)
            welcomeframe.dropDown2 = dropDown
            LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
                for i, v in ipairs(BiaoGe.welcome.template) do
                    local info = LibBG:UIDropDownMenu_CreateInfo()
                    info.text = v.name
                    info.checked = i == BiaoGe.welcome.templateChoose
                    info.arg1 = i
                    info.func = function()
                        BiaoGe.welcome.templateChoose = i
                        UpdateFrames()
                        UpdateAllDropDown()
                        BG.ClearFocus()
                    end
                    LibBG:UIDropDownMenu_AddButton(info)
                end
            end)
        end
    end

    function mainButton:UpdateTextColor()
        local color, text
        if self:GetChecked() then
            if hasActivity then
                color = { 0, 1, 0 }
                text = L["启用进组欢迎语（生效中）"]
            else
                color = { 1, 0, 0 }
                text = L["启用进组欢迎语（需要创建集结号活动才生效）"]
            end
        else
            color = { 1, 1, 1 }
            text = L["启用进组欢迎语"]
        end
        mainButton:SetChecked(self:GetChecked())
        mainButton.Text:SetTextColor(unpack(color))
        mainButton.Text:SetText(text)
        welcomeframe:UpdateAlpha()
        if mainButton2 then
            mainButton2:SetChecked(self:GetChecked())
            mainButton2.Text:SetTextColor(unpack(color))
            mainButton2.Text:SetText(text)
            mainButton2:ClearAllPoints()
            mainButton2:SetPoint("RIGHT", optionsButton, "LEFT", -mainButton2.Text:GetWidth() - 5, 0)
        end
    end

    if mainButton2 then
        mainButton2.UpdateTextColor = mainButton.UpdateTextColor
    end
    mainButton:UpdateTextColor()
    UpdateAllDropDown()

    -- 自动发YY
    do
        local frame, mainButton, leaderButton, assistantButton, yyEdit
        local keys = { "yy", "歪歪" }

        local function UpdateOptions()
            if mainButton then
                mainButton:SetChecked(BiaoGe.welcome.autoSendYY == 1)
                if mainButton.child then
                    for _, child in ipairs(mainButton.child) do
                        child:SetShown(BiaoGe.welcome.autoSendYY == 1)
                    end
                end
            end
            if leaderButton then
                leaderButton:SetChecked(BiaoGe.welcome.autoSendYY_leader == 1)
            end
            if assistantButton then
                assistantButton:SetChecked(BiaoGe.welcome.autoSendYY_assistant == 1)
            end
            if yyEdit then
                yyEdit:SetText(BiaoGe.welcome.autoSendYY_YY)
            end
            if frame then
                frame:UpdateAlpha()
            end
        end

        -- 主界面
        do
            frame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
            frame:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            frame:SetBackdropColor(0, 0, 0, 0.8)
            frame:SetBackdropBorderColor(1, 1, 1, .8)
            frame:SetPoint("TOPLEFT", welcomeframe, "TOPRIGHT", 50, 0)
            frame:SetSize(400, 50)
            frame:EnableMouse(true)

            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("BOTTOM", frame, "TOP", 0, 2)
            t:SetTextColor(1, .82, 0)
            t:SetText(L["关键词自动发YY"])

            function frame:UpdateAlpha()
                self:SetAlpha(BiaoGe.welcome.autoSendYY == 1 and 1 or .5)
            end

            frame:UpdateAlpha()
        end

        -- 启用按钮
        do
            local function SetParent(self, key, parent)
                if BiaoGe.welcome[key] ~= 1 then
                    self:Hide()
                end
                parent.child = parent.child or {}
                tinsert(parent.child, self)
                if not parent.hookDisable then
                    parent.hookDisable = true
                    hooksecurefunc(parent, "Disable", function()
                        if parent.Text then
                            parent.Text:SetTextColor(.5, .5, .5)
                        end
                        for i, child in ipairs(parent.child) do
                            child:Hide()
                        end
                    end)
                    parent:HookScript("OnClick", function(self)
                        if self.child then
                            for _, f in pairs(self.child) do
                                f:SetShown(self:GetChecked())
                            end
                        end
                    end)
                end
            end

            local ontext = {
                L["关键词自动发YY"],
                L["当团队频道有人打字\"YY\"(不分大小写)时，自动发送你的YY号。"],
            }
            mainButton = CreateCheckButton("autoSendYY", L["启用关键词自动发YY"], mainFrame, ontext)
            mainButton:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0)
            mainButton:HookScript("OnClick", function(self)
                frame:UpdateAlpha()
            end)
            mainButton:HookScript("OnShow", function(self)
                UpdateOptions()
            end)

            local bt = CreateCheckButton("autoSendYY_leader", L["当我是团长时生效"], mainButton)
            bt:SetPoint("TOPLEFT", mainButton, "BOTTOMRIGHT", 0, 0)
            leaderButton = bt
            SetParent(bt, 'autoSendYY', mainButton)

            local bt = CreateCheckButton("autoSendYY_assistant", L["当我是助理时生效"], mainButton)
            bt:SetPoint("TOPLEFT", leaderButton, "BOTTOMLEFT", 0, 0)
            assistantButton = bt
            SetParent(bt, 'autoSendYY', mainButton)
        end

        -- YY号
        do
            local t = frame:CreateFontString()
            t:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPLEFT", 10, -15)
            t:SetTextColor(1, 1, 1)
            t:SetText(L["YY："])

            local edit = CreateFrame("EditBox", nil, frame, BG.editTemplate)
            edit:SetSize(150, 20)
            edit:SetPoint("LEFT", t, "RIGHT", 10, 0)
            edit:SetText(BiaoGe.welcome.autoSendYY_YY)
            edit:SetAutoFocus(false)
            edit:SetNumeric(true)
            edit:SetMaxBytes(255)
            BG.SetEditBaseClass(edit)
            edit:SetScript("OnTextChanged", function(self)
                BiaoGe.welcome.autoSendYY_YY = self:GetText()
            end)
            yyEdit = edit
        end

        mainFrame:HookScript("OnShow", UpdateOptions)
        UpdateOptions()

        local function GetChannel()
            return IsInRaid(1) and "RAID" or "PARTY"
        end

        local f = CreateFrame("Frame")
        f:RegisterEvent("CHAT_MSG_PARTY")
        f:RegisterEvent("CHAT_MSG_PARTY_LEADER")
        f:RegisterEvent("CHAT_MSG_RAID")
        f:RegisterEvent("CHAT_MSG_RAID_LEADER")
        f:SetScript("OnEvent", function(self, event, msg, ...)
            if not f.cd
                and BiaoGe.welcome.autoSendYY == 1
                and BiaoGe.welcome.autoSendYY_YY ~= ""
                and ((BiaoGe.welcome.autoSendYY_leader == 1 and UnitIsGroupLeader("player"))
                    or (BiaoGe.welcome.autoSendYY_assistant == 1 and UnitIsGroupAssistant("player")))
            then
                msg = msg:lower()
                for _, key in ipairs(keys) do
                    if msg:match(key) then
                        f.cd = true
                        After(2, function()
                            f.cd = nil
                        end)
                        SendChatMessage("YY" .. BiaoGe.welcome.autoSendYY_YY, GetChannel())
                        return
                    end
                end
            end
        end)
    end
end)
