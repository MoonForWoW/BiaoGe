local AddonName, ns = ...


local LibBG = ns.LibBG
local L = ns.L

local Size = ns.Size
local RGB = ns.RGB
local RGB_16 = ns.RGB_16
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local GetText_T = ns.GetText_T
local AddTexture = ns.AddTexture
local SendSystemMessage = ns.SendSystemMessage
local After = C_Timer.After
local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded

local function ToGold(copper)
    return floor(copper / 10000)
end

local function RoadSendMail()
    BiaoGe.sendMail = BiaoGe.sendMail or {}
    BiaoGe.sendMail.title = BiaoGe.sendMail.title or L["工资{A}金"]
    BiaoGe.sendMail.body = BiaoGe.sendMail.body or
        L["{C}，这是你的工资，请查收。\n感谢你参与本次金团活动！^_^\n\n邮件发送时间：{E}"]
    BiaoGe.sendMail.member = BiaoGe.sendMail.member or "raid"
    BiaoGe.sendMail.split = BiaoGe.sendMail.split or "\n"

    BiaoGe.options.enableSendMail = BiaoGe.options.enableSendMail or 1
    if BiaoGe.options.enableSendMail == 0 then return end

    local choose = {}
    local chooseBackdropColor = { 0, 1, 0, .2 }
    local chooseBorderColor = { 0, 1, 0, .8 }
    local notChooseBackdropColor = { 0, 0, 0, 0.2 }
    local notChooseBorderColor = { 1, 1, 1, .3 }
    local CreateRaidButton, DefaultRaidFrame, UpdateRaidFrame, UpdateMailFrame, InsetFrameSkin, IsRaidMember
    local goldTex = "|TInterface/MoneyFrame/UI-MoneyIcons:0:0:0:0:100:100:0:25:0:100|t"
    local mainFrame
    local MAXLETTER1 = 50
    local MAXLETTER2 = 450
    local sendStartTime = BG.IsTitan and 1.5 or .5
    local sendCD = sendStartTime + .5
    local sendTimeOutCD = sendCD + 1

    -- TAB按钮
    do
        local num = MailFrame.numTabs + 1
        local bt = CreateFrame("Button", "MailFrameTab" .. num, MailFrame, "FriendsFrameTabTemplate")
        bt:SetID(num)
        bt:SetPoint("LEFT", _G["MailFrameTab" .. (num - 1)], "RIGHT", -8, 0)
        bt:SetText(L["批量"])
        BG.SendMailButton = bt
        PanelTemplates_SetNumTabs(MailFrame, num)
        bt:SetScript("OnClick", nil)

        local function HookMailFrameTabs()
            for i = 1, MailFrame.numTabs or 0 do
                local tab = _G["MailFrameTab" .. i]
                if tab and not tab.BiaoGeSendMailHooked then
                    tab.BiaoGeSendMailHooked = true
                    if tab == bt then
                        tab:HookScript("OnClick", function(self)
                            PanelTemplates_SetTab(MailFrame, self:GetID())
                            PanelTemplates_SelectTab(self)
                            ButtonFrameTemplate_HideButtonBar(MailFrame)
                            MailFrameInset:Hide()
                            InboxFrame:Hide()
                            SendMailFrame:Hide()
                            SetSendMailShowing(false)
                            if InboxMailbagFrame then
                                InboxMailbagFrame:Hide()
                            end
                            mainFrame:Show()
                            PlaySound(829)
                        end)
                    else
                        tab:HookScript("OnClick", function(self)
                            mainFrame:Hide()
                            MailFrameInset:Show()
                        end)
                    end
                end
            end
        end
        HookMailFrameTabs()

        MailFrame:HookScript("OnShow", function()
            After(0, HookMailFrameTabs)
        end)
        hooksecurefunc("PanelTemplates_SetNumTabs", function(frame)
            if frame == MailFrame then
                After(0, HookMailFrameTabs)
            end
        end)

        -- 适配美化
        if IsAddOnLoaded("ElvUI") then
            local E = unpack(ElvUI)
            local S = E:GetModule('Skins')
            local tab = BG.SendMailButton
            tab:StripTextures()
            tab:ClearAllPoints()
            S:HandleTab(tab)
            tab:Point('TOPLEFT', _G["MailFrameTab" .. (num - 1)], 'TOPRIGHT', -19, 0)
        elseif IsAddOnLoaded("NDui") and not (IsAddOnLoaded("NDui_Plus") and IsAddOnLoaded("InboxMailBag")) then
            local B = unpack(NDui)
            B.ReskinTab(BG.SendMailButton)
        end
    end

    -- 主界面
    do
        local width = 600
        local w, h = MailFrame:GetSize()
        mainFrame = CreateFrame("Frame", nil, MailFrame, "BackdropTemplate")
        mainFrame:SetPoint("TOPLEFT", 0, -58)
        mainFrame:SetPoint("BOTTOMRIGHT", 0, 0)
        mainFrame:Hide()
        BG.SendMailMainFrame = mainFrame
        BG.SendMailButton.frame = mainFrame
        mainFrame:SetScript("OnShow", function(self)
            MailFrame:SetSize(width, h)
            self:RegisterEvent("PLAYER_MONEY")
            mainFrame:UpdateGZFrame()
        end)
        mainFrame:SetScript("OnHide", function(self)
            MailFrame:SetSize(w, h)
            StaticPopup_Hide("BiaoGe_SendMail")
            self:UnregisterEvent("PLAYER_MONEY")
        end)
        mainFrame:SetScript("OnEvent", function(self, event)
            if event == "PLAYER_MONEY" then
                UpdateMailFrame()
            end
        end)

        local t = mainFrame:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetPoint("CENTER", MailFrame, "TOP", 0, -11)
        t:SetText(L["批量邮寄工资"])

        -- 禁用此功能
        do
            local bt = CreateFrame("Button", nil, mainFrame)
            bt:SetPoint("TOPRIGHT", MailFrame, "TOPRIGHT", -55, -2)
            bt:SetNormalFontObject(BG.FontGreen15)
            bt:SetDisabledFontObject(BG.FontDis15)
            bt:SetHighlightFontObject(BG.FontWhite15)
            bt:SetText(L["禁用此功能"])
            bt:SetSize(bt:GetFontString():GetWidth(), 20)
            BG.SetTextHighlightTexture(bt)
            bt:SetScript("OnClick", function()
                local name = "BiaoGe_DisableSendMail"
                if not StaticPopupDialogs[name] then
                    StaticPopupDialogs[name] = {
                        text = L["确定禁用批量邮寄功能？\n需要重载游戏才能生效。"],
                        button1 = OKAY,
                        button2 = CANCEL,
                        OnAccept = function()
                            BiaoGe.options.enableSendMail = 0
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        showAlert = true,
                    }
                end
                StaticPopup_Show(name)
            end)
        end

        local f = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
        f:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(.5, .5, .5, 0.1)
        f:SetPoint("TOPLEFT", MailFrame, 1, -20)
        f:SetPoint("BOTTOMRIGHT", MailFrame, -2, 2)
        f:SetFrameLevel(f:GetParent():GetFrameLevel() + 10)
        f:EnableMouse(true)
        f:Hide()
        mainFrame.disFrame = f

        MailFrame:HookScript("OnMouseDown", function(self)
            if mainFrame.lastFocus then
                mainFrame.lastFocus:ClearFocus()
            end
        end)
        MailFrame:HookScript("OnHide", function(self)
            mainFrame:Hide()
            MailFrameInset:Show()
        end)

        function InsetFrameSkin(f)
            if IsAddOnLoaded("NDui") or IsAddOnLoaded("ElvUI") then
                if f.NineSlice then
                    f.NineSlice:Hide()
                else
                    f.InsetBorderBottom:Hide()
                    f.InsetBorderBottomLeft:Hide()
                    f.InsetBorderBottomRight:Hide()
                    f.InsetBorderTop:Hide()
                    f.InsetBorderTopLeft:Hide()
                    f.InsetBorderTopRight:Hide()
                    f.InsetBorderLeft:Hide()
                    f.InsetBorderRight:Hide()
                end
                f.Bg:Hide()
            end
        end
    end

    -- 团队框架
    do
        local f = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
        f:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", -335, 0)
        f:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -4, 4)
        BG.SendMailMemberFrame = f
        BG.SendMailMemberFrame.buttons = {}
        f:SetScript("OnShow", function(self)
            if not f.init then
                f.init = true
                for i = 1, 40 do
                    CreateRaidButton(i)
                end
                InsetFrameSkin(mainFrame.bg1)
                InsetFrameSkin(mainFrame.bg2)
                InsetFrameSkin(mainFrame.bg3)
            end
            UpdateRaidFrame()
        end)
        local f = CreateFrame("Frame", nil, BG.SendMailMemberFrame, "InsetFrameTemplate")
        f:SetAllPoints()
        f:SetFrameLevel(BG.SendMailMemberFrame:GetFrameLevel())
        mainFrame.bg1 = f

        local function SetChoose(bt, _choose)
            if _choose == 1 then
                bt.ischoose = true
                bt:SetBackdropColor(unpack(chooseBackdropColor))
                bt:SetBackdropBorderColor(unpack(chooseBorderColor))
                choose[bt.name] = {
                    name = bt.name,
                    colorName = bt.nameText:GetText(),
                    guid = bt.guid,
                    num = bt.num,
                }
            else
                bt.ischoose = false
                bt:SetBackdropColor(unpack(notChooseBackdropColor))
                bt:SetBackdropBorderColor(unpack(notChooseBorderColor))
                choose[bt.name] = nil
            end
        end

        local function CreateTeamNum(parent, id)
            local f = CreateFrame("Frame", nil, parent)
            f:SetPoint("BOTTOM", parent, "TOP", 0, 0)
            f:SetSize(60, 15)
            f.id = id
            local t = f:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
            t:SetPoint("CENTER")
            t:SetText(id)
            t:SetTextColor(.5, .5, .5)
            f:SetScript("OnMouseDown", function(self)
                local hasName = 0
                local ischoose = 0
                local startID = (self.id - 1) * 5 + 1
                for i = startID, startID + 4 do
                    local bt = BG.SendMailMemberFrame.buttons[i]
                    if bt.name then
                        if not (bt.name == BG.myName) then
                            hasName = hasName + 1
                        end
                    end
                    if bt.ischoose then
                        ischoose = ischoose + 1
                    end
                end
                if hasName == 0 then return end
                if hasName == ischoose then
                    for i = startID, startID + 4 do
                        local bt = BG.SendMailMemberFrame.buttons[i]
                        if bt.name then
                            SetChoose(bt, 0)
                        end
                    end
                else
                    for i = startID, startID + 4 do
                        local bt = BG.SendMailMemberFrame.buttons[i]
                        if bt.name then
                            if not (bt.name == BG.myName) then
                                SetChoose(bt, 1)
                            end
                        end
                    end
                end
                UpdateMailFrame()
                BG.PlaySound(1)
            end)
            f:SetScript("OnEnter", function(self)
                local startID = (self.id - 1) * 5 + 1
                for i = startID, startID + 4 do
                    local bt = BG.SendMailMemberFrame.buttons[i]
                    if bt.name then
                        if not (bt.name == BG.myName) then
                            t:SetTextColor(1, 1, 1)
                            return
                        end
                    end
                end
            end)
            f:SetScript("OnLeave", function(self)
                t:SetTextColor(.5, .5, .5)
            end)
        end

        function CreateRaidButton(i)
            local bt = CreateFrame("Frame", nil, nil, "BackdropTemplate")
            bt:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            bt:SetBackdropColor(unpack(notChooseBackdropColor))
            bt:SetBackdropBorderColor(unpack(notChooseBorderColor))
            bt:SetSize(75, 25)
            bt.num = i
            do
                if i == 1 then
                    bt:SetPoint("TOPLEFT", BG.SendMailMemberFrame, "TOPLEFT", 10, -20)
                    bt:SetParent(BG.SendMailMemberFrame)
                    CreateTeamNum(bt, 1)
                elseif i == 21 then
                    bt:SetPoint("TOPLEFT", BG.SendMailMemberFrame.buttons[5], "BOTTOMLEFT", 0, -25)
                    bt:SetParent(BG.SendMailMemberFrame)
                    CreateTeamNum(bt, (i - 1) / 5 + 1)
                elseif (i - 1) % 5 == 0 then
                    bt:SetPoint("TOPLEFT", BG.SendMailMemberFrame.buttons[i - 5], "TOPRIGHT", 5, 0)
                    bt:SetParent(BG.SendMailMemberFrame)
                    CreateTeamNum(bt, (i - 1) / 5 + 1)
                else
                    bt:SetPoint("TOPLEFT", BG.SendMailMemberFrame.buttons[i - 1], "BOTTOMLEFT", 0, -1)
                    local num = floor((i - 1) / 5) * 5 + 1
                    bt:SetParent(BG.SendMailMemberFrame.buttons[num])
                end
            end
            tinsert(BG.SendMailMemberFrame.buttons, bt)
            bt:SetScript("OnMouseUp", function(self, button)
                if not self.name then return end
                if button == "LeftButton" then
                    if self.name == BG.myName then return end
                    if self.ischoose then
                        SetChoose(self, 0)
                    else
                        SetChoose(self, 1)
                    end
                    UpdateMailFrame()
                    BG.PlaySound(1)
                elseif button == "RightButton" and not IsRaidMember() then
                    local menu = {
                        {
                            text = self.name,
                            isTitle = true,
                            notCheckable = true,
                        },
                        {
                            text = "   ",
                            isTitle = true,
                            notCheckable = true,
                        },
                        {
                            text = L["删除该玩家"],
                            notCheckable = true,
                            func = function()
                                local key = BiaoGe.sendMail.member
                                tremove(BiaoGe.sendMail[key], i)
                                UpdateRaidFrame()
                            end
                        },
                        {
                            text = CANCEL,
                            notCheckable = true,
                            func = LibBG.CloseDropDownMenus,
                        }
                    }
                    LibBG:EasyMenu(menu, BG.dropDown, "cursor", 0, 0, "MENU", 2)
                    BG.PlaySound(1)
                end
            end)
            bt:SetScript("OnEnter", function(self)
                if not self.name then return end
                if not self.ds then
                    self.ds = self:CreateTexture(nil, "BACKGROUND")
                    self.ds:SetAllPoints()
                    self.ds:SetColorTexture(.5, .5, .5, .3)
                end
                self.ds:Show()
                if self.name == BG.myName then
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(L["提示："], 1, 1, 1, true)
                    GameTooltip:AddLine(L["不能给自己邮寄！"], 1, 0.82, 0, true)
                    GameTooltip:Show()
                    return
                end
                if self.nameText:IsTruncated() then
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(self.nameText:GetText(), 1, 1, 1, true)
                    GameTooltip:Show()
                end
            end)
            bt:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
                if self.ds then
                    self.ds:Hide()
                end
            end)

            local t = bt:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
            t:SetPoint("TOPLEFT", 2, -2)
            t:SetWidth(bt:GetWidth() - 4)
            t:SetJustifyH("LEFT")
            t:SetWordWrap(false)
            bt.nameText = t

            local t = bt:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 10, "OUTLINE")
            t:SetPoint("BOTTOMLEFT", 2, 1)
            t:SetWidth(bt:GetWidth() - 4)
            t:SetJustifyH("LEFT")
            t:SetWordWrap(false)
            bt.otherText = t

            local tex = bt:CreateTexture(nil, "OVERLAY")
            tex:SetPoint("CENTER", bt, "TOPLEFT", 0, -2)
            tex:SetSize(10, 10)
            bt.icon = tex

            local tex = bt:CreateTexture(nil, "OVERLAY")
            tex:SetPoint("RIGHT", 0, 0)
            tex:SetSize(25, 25)
            bt.tex = tex
        end

        function DefaultRaidFrame()
            wipe(choose)
            for i, bt in ipairs(BG.SendMailMemberFrame.buttons) do
                bt:SetBackdropColor(unpack(notChooseBackdropColor))
                bt:SetBackdropBorderColor(unpack(notChooseBorderColor))
                bt.nameText:Hide()
                bt.otherText:Hide()
                bt.name = nil
                bt.guid = nil
                bt.ischoose = nil
                bt.icon:SetTexture(nil)
                bt.tex:SetTexture(nil)
            end
        end

        function UpdateRaidFrame()
            local function UpdateNameSize(fontString)
                fontString:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                if fontString:IsTruncated() then
                    fontString:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                end
                if fontString:IsTruncated() then
                    fontString:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
                end
            end
            DefaultRaidFrame()
            if IsRaidMember() then
                BG.SendMailMemberFrame.refreshButton:Show()
                BG.SendMailMemberFrame.importButton:Hide()
                if mainFrame.importFrame then
                    mainFrame.importFrame:Hide()
                end
                if IsInRaid(1) then
                    for _, v in ipairs(BG.raidRosterInfo) do
                        for i = (v.subgroup - 1) * 5 + 1, v.subgroup * 5 do
                            local bt = BG.SendMailMemberFrame.buttons[i]
                            if not bt.name then
                                bt.name = v.name
                                bt.guid = v.guid
                                bt.nameText:SetText(SetClassCFF(v.name))
                                bt.nameText:Show()
                                UpdateNameSize(bt.nameText)
                                if v.rank == 2 then
                                    bt.icon:SetTexture("interface/groupframe/ui-group-leadericon")
                                elseif v.role == "MAINTANK" then
                                    bt.icon:SetTexture(132064)
                                elseif v.role == "MAINASSIST" then
                                    bt.icon:SetTexture(132063)
                                elseif v.rank == 1 then
                                    bt.icon:SetTexture("interface/groupframe/ui-group-assistanticon")
                                end
                                if not BG.raidRosterIsOnline[v.name] then
                                    bt.otherText:SetText(L["离线"])
                                    bt.otherText:SetTextColor(.5, .5, .5)
                                    bt.otherText:Show()
                                end
                                break
                            end
                        end
                    end
                end
            else
                BG.SendMailMemberFrame.refreshButton:Hide()
                BG.SendMailMemberFrame.importButton:Show()
                local key = BiaoGe.sendMail.member
                if type(BiaoGe.sendMail[key]) == "table" then
                    for i, name in ipairs(BiaoGe.sendMail[key]) do
                        if i > 40 then break end
                        local bt = BG.SendMailMemberFrame.buttons[i]
                        bt.name = name
                        bt.nameText:SetText(name)
                        bt.nameText:Show()
                        UpdateNameSize(bt.nameText)
                    end
                end
            end
            UpdateMailFrame(true)
        end

        function IsRaidMember()
            return BiaoGe.sendMail.member == "raid"
        end

        -- 全选
        do
            local bt = BG.CreateButton(BG.SendMailMemberFrame)
            bt:SetSize(80, 25)
            bt:SetPoint("BOTTOMLEFT", 10, 20)
            bt:SetText(L["全选"])
            BG.SendMailMemberFrame.allChooseButton = bt
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                wipe(choose)
                for i, bt in ipairs(BG.SendMailMemberFrame.buttons) do
                    if bt.name then
                        if not (bt.name == BG.myName) then
                            SetChoose(bt, 1)
                        end
                    end
                end
                UpdateMailFrame()
            end)
        end
        -- 取消全选
        do
            local bt = BG.CreateButton(BG.SendMailMemberFrame)
            bt:SetSize(80, 25)
            bt:SetPoint("LEFT", BG.SendMailMemberFrame.allChooseButton, "RIGHT", 5, 0)
            bt:SetText(L["取消全选"])
            BG.SendMailMemberFrame.cancelChooseButton = bt
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                bt.Click()
            end)
            function bt.Click()
                wipe(choose)
                for _, bt in ipairs(BG.SendMailMemberFrame.buttons) do
                    if bt.name then
                        bt.ischoose = false
                        bt:SetBackdropColor(unpack(notChooseBackdropColor))
                        bt:SetBackdropBorderColor(unpack(notChooseBorderColor))
                    end
                end
                UpdateMailFrame()
            end
        end
        -- 刷新团队框架
        do
            local bt = BG.CreateButton(BG.SendMailMemberFrame)
            bt:SetSize(120, 25)
            bt:SetPoint("BOTTOMRIGHT", -10, 20)
            bt:SetText(L["刷新团队框架"])
            BG.SendMailMemberFrame.refreshButton = bt
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                UpdateRaidFrame()
            end)
        end
    end

    -- 名单下拉菜单
    do
        local tbl = {
            { key = "raid", name = L["团队成员"] },
            { key = "my1", name = L["自定义名单1"] },
            { key = "my2", name = L["自定义名单2"] },
            { key = "my3", name = L["自定义名单3"] },
            { key = "my4", name = L["自定义名单4"] },
            { key = "my5", name = L["自定义名单5"] },
        }
        local function Set(key)
            for i, v in ipairs(tbl) do
                if v.key == key then
                    return v.name
                end
            end
        end

        local dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
        dropDown:SetPoint("BOTTOMRIGHT", mainFrame, "TOPRIGHT", 8, -3)
        LibBG:UIDropDownMenu_SetWidth(dropDown, 120)
        LibBG:UIDropDownMenu_SetAnchor(dropDown, -15, 0, "TOPRIGHT", dropDown, "BOTTOMRIGHT")
        BG.dropDownToggle(dropDown)
        mainFrame.dropDown = dropDown
        local text = dropDown:CreateFontString()
        text:SetPoint("RIGHT", dropDown, "LEFT", 15, 2)
        text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        text:SetTextColor(RGB(BG.y2))
        text:SetText(L["名单："])
        LibBG:UIDropDownMenu_SetText(dropDown, Set(BiaoGe.sendMail.member))
        LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
            for _, v in ipairs(tbl) do
                local info = LibBG:UIDropDownMenu_CreateInfo()
                info.text = v.name
                if v.key == BiaoGe.sendMail.member then
                    info.checked = true
                end
                info.func = function()
                    BiaoGe.sendMail.member = v.key
                    LibBG:UIDropDownMenu_SetText(dropDown, Set(BiaoGe.sendMail.member))
                    UpdateRaidFrame()
                end
                LibBG:UIDropDownMenu_AddButton(info)
            end
        end)
    end

    -- 导入名单
    do
        local CreateUI
        local bt = BG.CreateButton(BG.SendMailMemberFrame)
        bt:SetSize(100, 25)
        bt:SetPoint("BOTTOMRIGHT", -10, 20)
        bt:SetText(L["导入名单"])
        BG.SendMailMemberFrame.importButton = bt
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            if not mainFrame.importFrame then
                CreateUI()
                return
            end
            mainFrame.importFrame:SetShown(not mainFrame.importFrame:IsVisible())
        end)

        local function GetNameTbl()
            local parent = mainFrame.importFrame
            local split = BiaoGe.sendMail.split
            local tbl = { strsplit(split, parent.edit:GetText()) }
            for i = #tbl, 1, -1 do
                local name = tbl[i]
                if name:gsub(" ", "") == "" or string.utf8len(name) > MAXLETTER1 then
                    tremove(tbl, i)
                end
            end
            -- 去重
            local seen = {}
            local result = {}
            for _, value in ipairs(tbl) do
                if not seen[value] then
                    tinsert(result, value)
                    seen[value] = true
                end
            end
            return result
        end

        local function StartImport()
            local parent = mainFrame.importFrame
            local key = BiaoGe.sendMail.member
            BiaoGe.sendMail[key] = {}
            local tbl = GetNameTbl()
            for i, name in ipairs(tbl) do
                if i > 40 then break end
                tinsert(BiaoGe.sendMail[key], name)
            end
            UpdateRaidFrame()
            parent:Hide()
        end

        function CreateUI()
            local parent

            local function SetEditText()
                local edit = parent.edit
                local text = ""
                local key = BiaoGe.sendMail.member
                local split = BiaoGe.sendMail.split
                if type(BiaoGe.sendMail[key]) == "table" then
                    for i, name in ipairs(BiaoGe.sendMail[key]) do
                        if i == #BiaoGe.sendMail[key] then
                            text = text .. name
                        else
                            text = text .. name .. split
                        end
                    end
                end
                edit:SetText(text)
                edit:SetFocus()
                edit:HighlightText()
                After(0, function()
                    local max = select(2, parent.scroll.ScrollBar:GetMinMaxValues())
                    parent.scroll.ScrollBar:SetValue(max)
                end)
            end
            -- 背景
            do
                local f = CreateFrame("Frame", nil, BG.SendMailMemberFrame.importButton, "BackdropTemplate")
                f:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = 1,
                })
                f:SetBackdropColor(0, 0, 0, 0.8)
                f:SetBackdropBorderColor(0, 0, 0, 1)
                f:SetPoint("TOPLEFT", mainFrame.gzFrame, "TOPRIGHT", 1, 0)
                f:SetPoint("BOTTOMRIGHT", mainFrame.gzFrame, "BOTTOMRIGHT", 200, 0)
                f:EnableMouse(true)
                mainFrame.importFrame = f
                parent = f

                local t = parent:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetPoint("TOP", 0, -5)
                t:SetText(L["导入名单"])
            end
            -- 滚动框
            do
                local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
                frame:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = 1,
                })
                frame:SetBackdropColor(0, 0, 0, 0.5)
                frame:SetBackdropBorderColor(.5, .5, .5, 1)
                frame:SetPoint("TOPLEFT", 5, -50)
                frame:SetPoint("BOTTOMRIGHT", -5, 64)
                frame:EnableMouse(true)
                parent.frame = frame
                local scroll = CreateFrame("ScrollFrame", nil, frame, BG.scrollTemplate)
                scroll:SetWidth(frame:GetWidth() - 31)
                scroll:SetHeight(frame:GetHeight() - 9)
                scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
                parent.scroll = scroll
                local edit = CreateFrame("EditBox", nil, frame)
                edit:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                edit:SetWidth(scroll:GetWidth())
                edit:SetHeight(scroll:GetHeight())
                edit:SetAutoFocus(false)
                edit:SetMultiLine(true)
                parent.edit = edit
                scroll:SetScrollChild(edit)
                SetEditText()
                edit:SetScript("OnShow", function(self)
                    SetEditText()
                end)
                edit:SetScript("OnTextChanged", function(self)
                    local bt = parent.SureButton
                    if bt.isOnEnter then
                        bt:GetScript("OnEnter")(bt)
                    end
                end)
                edit:SetScript("OnEscapePressed", function(self)
                    self:ClearFocus()
                end)
                edit:SetScript("OnMouseDown", function(self, enter)
                    if enter == "RightButton" then
                        edit:SetEnabled(false)
                        edit:SetText("")
                    else
                        edit:SetFocus()
                    end
                end)
                edit:SetScript("OnMouseUp", function(self, enter)
                    if enter == "RightButton" then
                        edit:SetEnabled(true)
                    end
                end)
                edit:SetScript("OnEditFocusGained", function(self)
                    mainFrame.lastFocus = self
                end)
                edit:SetScript("OnEditFocusLost", function(self)
                    self:ClearHighlightText()
                end)
                frame:SetScript("OnMouseDown", edit:GetScript("OnMouseDown"))
                frame:SetScript("OnMouseUp", edit:GetScript("OnMouseUp"))
            end
            -- 分隔符
            do
                local buttons = {}
                local numOptions = {
                    { key = "\n", name = L["回车"], point = { x = 0, y = 0 } },
                    { key = " ", name = L["空格"], point = { x = 55, y = 0 } },
                    { key = ",", name = L["英文逗号"], point = { x = 110, y = 0 } },
                }
                local buttonGroup = CreateFrame("Frame", nil, parent)
                buttonGroup:SetPoint("BOTTOMLEFT", parent.frame, "TOPLEFT", 0, 5)
                buttonGroup:SetSize(1, 1)
                for i = 1, #numOptions do
                    local v = numOptions[i]
                    local bt = CreateFrame("CheckButton", nil, buttonGroup, "UIRadioButtonTemplate")
                    bt:SetPoint("BOTTOMLEFT", v.point.x, v.point.y)
                    bt:SetSize(15, 15)
                    tinsert(buttons, bt)
                    bt.Text = bt:CreateFontString()
                    bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                    bt.Text:SetPoint("LEFT", bt, "RIGHT", 0, 0)
                    bt.Text:SetText(v.name)
                    bt.Text:SetTextColor(1, .82, 0)
                    bt:SetHitRectInsets(0, -bt.Text:GetWidth(), -5, -5)
                    if v.key == BiaoGe.sendMail.split then
                        bt:SetChecked(true)
                        bt.Text:SetTextColor(0, 1, 0)
                    end
                    bt:SetScript("OnClick", function(self)
                        BG.PlaySound(1)
                        for _, radioButton in ipairs(buttons) do
                            if radioButton ~= self then
                                radioButton:SetChecked(false)
                                radioButton.Text:SetTextColor(1, .82, 0)
                            end
                        end
                        self:SetChecked(true)
                        self.Text:SetTextColor(0, 1, 0)
                        BiaoGe.sendMail.split = v.key
                    end)
                    bt:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(format(L["使用|cffffffff%s|r作为多个名字的分隔符。"], v.name), 1, 0.82, 0, true)
                        GameTooltip:Show()
                    end)
                    bt:SetScript("OnLeave", GameTooltip_Hide)
                end
            end
            -- 确认按钮
            do
                local bt = BG.CreateButton(parent)
                bt:SetSize(90, 25)
                bt:SetPoint("BOTTOMLEFT", 5, 24)
                bt:SetText(L["确认"])
                parent.SureButton = bt
                bt:SetScript("OnClick", function(self)
                    BG.PlaySound(1)
                    StartImport()
                end)
                bt:SetScript("OnEnter", function(self)
                    self.isOnEnter = true
                    local tbl = GetNameTbl()
                    local allCount = #tbl

                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(format(L["名字一共|cff00ff00%s|r个"], allCount), 1, 1, 1, true)
                    for i, name in ipairs(tbl) do
                        GameTooltip:AddLine(i .. ". " .. name, 1, .82, 0)
                    end
                    if #tbl > 40 then
                        GameTooltip:AddLine(L["（只会导入前40个名字）"], .5, .5, .5, true)
                    end
                    GameTooltip:Show()
                end)
                bt:SetScript("OnLeave", function(self)
                    self.isOnEnter = nil
                    GameTooltip:Hide()
                end)

                local bt = BG.CreateButton(parent)
                bt:SetSize(90, 25)
                bt:SetPoint("BOTTOMRIGHT", -5, 24)
                bt:SetText(L["关闭"])
                bt:SetScript("OnClick", function(self)
                    BG.PlaySound(1)
                    parent:Hide()
                end)
            end
            -- 复制团队成员
            do
                local bt = BG.CreateButton(parent)
                bt:SetSize(20, 20)
                bt:SetPoint("TOPRIGHT", -2, -2)
                bt:SetText("+")
                bt:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(L["导入当前团队成员名单"], 1, 1, 1, true)
                    if not IsInRaid(1) then
                        GameTooltip:AddLine(L["你当前没有团队。"], 1, 0, 0, true)
                    end
                    GameTooltip:Show()
                end)
                bt:SetScript("OnLeave", GameTooltip_Hide)
                bt:SetScript("OnClick", function(self)
                    if IsInRaid(1) then
                        BG.PlaySound(1)
                        local edit = parent.edit
                        local split = BiaoGe.sendMail.split
                        edit:SetText("")
                        for i, v in ipairs(BG.raidRosterInfo) do
                            if i == #BG.raidRosterInfo then
                                edit:Insert(v.name)
                            else
                                edit:Insert(v.name .. split)
                            end
                        end
                        edit:SetFocus()
                        After(0, function()
                            local max = select(2, parent.scroll.ScrollBar:GetMinMaxValues())
                            parent.scroll.ScrollBar:SetValue(max)
                        end)
                    end
                end)
            end
        end
    end

    -- 邮寄
    do
        local var, SwitchVar, lastName, oldVarToNewVar
        -- 变量
        do
            var = {
                {
                    key = "{A}",
                    text = L["邮寄金额"],
                    func = function()
                        return tonumber(mainFrame.moneyEdit:GetText()) or 0
                    end,
                    func_color = function()
                        return BG.STC_g1(tonumber(mainFrame.moneyEdit:GetText()) or 0)
                    end,
                },
                {
                    key = "{B}",
                    text = L["邮寄人数"],
                    func = function()
                        return Size(choose)
                    end,
                    func_color = function()
                        return BG.STC_g1(Size(choose))
                    end,
                },
                {
                    key = "{C}",
                    text = L["收件人名字"],
                    func = function()
                        return lastName or L["(收件人名字)"]
                    end,
                    func_color = function()
                        return BG.STC_g1(lastName or L["(收件人名字)"])
                    end,
                },
                {
                    key = "{D}",
                    text = L["发件人名字"],
                    func = function()
                        return BG.myName
                    end,
                    func_color = function()
                        return BG.STC_g1(BG.myName)
                    end,
                },
                {
                    key = "{E}",
                    text = L["日期和时间"],
                    func = function()
                        return date("%y-%m-%d %H:%M")
                    end,
                    func_color = function()
                        return BG.STC_g1(date("%y-%m-%d %H:%M"))
                    end,
                },
            }
            function SwitchVar(text, color)
                local has
                for _, v in ipairs(var) do
                    local yes
                    if color then
                        text, yes = text:gsub(v.key, v.func_color)
                    else
                        text, yes = text:gsub(v.key, v.func)
                    end
                    if yes ~= 0 then
                        has = true
                    end
                end
                return text, has
            end

            function oldVarToNewVar(text)
                return text:gsub("{1}", "{A}"):gsub("{2}", "{B}"):gsub("{3}", "{C}"):gsub("{4}", "{D}")
            end

            local bt = CreateFrame("Button", nil, mainFrame)
            bt:SetPoint("TOPLEFT", MailFrame, "TOPLEFT", 65, -1)
            bt:SetNormalFontObject(BG.FontGreen15)
            bt:SetDisabledFontObject(BG.FontDis15)
            bt:SetHighlightFontObject(BG.FontWhite15)
            bt:SetText(L["变量"])
            bt:SetSize(bt:GetFontString():GetWidth(), 20)
            mainFrame.varButton = bt
            bt:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
                GameTooltip:AddLine(L["你可以在主题和内容里使用变量，系统会把特定字符自动变为对应的数字或文本。"], 1, 0.82, 0, true)
                GameTooltip:AddLine(L[ [[比如：在主题里输入"工资{A}金"，在邮寄金额里输入"2000"，那么实际发送的主题是"工资2000金"。]] ], 1, 0.82, 0, true)
                GameTooltip:AddLine(" ", 1, 1, 1, true)
                GameTooltip:AddDoubleLine(L["特定字符:"], L["实际效果:"])
                for _, v in ipairs(var) do
                    GameTooltip:AddDoubleLine(v.key, v.text, 1, 1, 1, 1, 1, 1)
                end

                GameTooltip:Show()
            end)
            bt:SetScript("OnLeave", GameTooltip_Hide)
        end

        -- 邮寄记录
        do
            local bt = CreateFrame("Button", nil, mainFrame)
            bt:SetPoint("LEFT", mainFrame.varButton, "RIGHT", 15, 0)
            bt:SetNormalFontObject(BG.FontGreen15)
            bt:SetDisabledFontObject(BG.FontDis15)
            bt:SetHighlightFontObject(BG.FontWhite15)
            bt:SetText(L["邮寄记录"])
            bt:SetSize(bt:GetFontString():GetWidth(), 20)
            BG.SetTextHighlightTexture(bt)
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                BG.MainFrame:Show()
                BG.ClickTabButton(BG.MailHistoryMainFrameTabNum)
                CloseAllBags()
            end)
        end

        -- 背景
        do
            local f = CreateFrame("Frame", nil, mainFrame, "InsetFrameTemplate")
            f:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)
            f:SetPoint("BOTTOMRIGHT", BG.SendMailMemberFrame, "TOPLEFT", 0, -210)
            f:SetFrameLevel(mainFrame:GetFrameLevel())
            mainFrame.bg2 = f
            local f = CreateFrame("Frame", nil, mainFrame, "InsetFrameTemplate")
            f:SetPoint("TOPLEFT", mainFrame.bg2, "BOTTOMLEFT", 0, 0)
            f:SetPoint("BOTTOMRIGHT", BG.SendMailMemberFrame, "BOTTOMLEFT", -0, 0)
            f:SetFrameLevel(mainFrame:GetFrameLevel())
            mainFrame.bg3 = f
        end

        -- 主题
        do
            local t = mainFrame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPRIGHT", mainFrame, "TOPLEFT", 60, -15)
            t:SetTextColor(1, 0.82, 0)
            t:SetText(MAIL_SUBJECT_LABEL)
            t:SetJustifyH("RIGHT")
            local text1 = t
            local edit = CreateFrame("EditBox", nil, mainFrame,  BG.editTemplate)
            edit:SetSize(170, 20)
            edit:SetPoint("LEFT", text1, "RIGHT", 10, 0)
            edit:SetAutoFocus(false)
            edit:SetMaxLetters(MAXLETTER1)
            edit:SetText(oldVarToNewVar(BiaoGe.sendMail.title))
            mainFrame.Edit1 = edit
            edit:SetScript("OnEditFocusGained", function(self)
                mainFrame.lastFocus = self
            end)
            edit:SetScript("OnTextChanged", function(self)
                BiaoGe.sendMail.title = self:GetText()
                UpdateMailFrame()
                if self.isOnEnter then
                    self:GetScript("OnEnter")(self)
                end
            end)
            edit:SetScript("OnEnterPressed", function(self)
                self:ClearFocus()
            end)
            edit:SetScript("OnTabPressed", function(self)
                mainFrame.Edit2:SetFocus()
            end)
            edit:SetScript("OnMouseDown", function(self, enter)
                if enter == "RightButton" then
                    edit:SetEnabled(false)
                    edit:SetText("")
                else
                    edit:SetFocus()
                end
            end)
            edit:SetScript("OnMouseUp", function(self, enter)
                if enter == "RightButton" then
                    edit:SetEnabled(true)
                end
            end)
            edit:SetScript("OnEnter", function(self)
                self.isOnEnter = true
                local has
                local text = self:GetText()
                text, has = SwitchVar(text, true)
                if has then
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", -5, 0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(L["实际发送效果："], 1, .82, 0, true)
                    GameTooltip:AddLine(text, 1, 1, 1, true)
                    GameTooltip:Show()
                else
                    GameTooltip:Hide()
                end
            end)
            edit:SetScript("OnLeave", function(self)
                self.isOnEnter = nil
                GameTooltip:Hide()
            end)
        end

        -- 邮件内容
        do
            local t = mainFrame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPRIGHT", mainFrame, "TOPLEFT", 60, -45)
            t:SetTextColor(1, 0.82, 0)
            t:SetText(L["内容："])
            t:SetJustifyH("RIGHT")
            local text2 = t
            local frame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
            frame:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 16,
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            frame:SetBackdropColor(0, 0, 0, 0.5)
            frame:SetBackdropBorderColor(1, 1, 1, 0.6)
            frame:SetSize(mainFrame.Edit1:GetWidth() + 8, 150)
            frame:SetPoint("TOPLEFT", text2, "TOPRIGHT", 4, 2)
            local edit = CreateFrame("EditBox", nil, frame)
            edit:SetWidth(frame:GetWidth())
            edit:SetAutoFocus(false)
            edit:SetMaxLetters(MAXLETTER2)
            edit:EnableMouse(true)
            edit:SetTextInsets(0, 10, 0, 0)
            edit:SetMultiLine(true)
            edit:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
            edit:SetText(oldVarToNewVar(BiaoGe.sendMail.body))
            mainFrame.Edit2 = edit
            mainFrame.Edit2.frame = frame
            local scroll = CreateFrame("ScrollFrame", nil, frame, BG.scrollTemplate)
            scroll:SetWidth(frame:GetWidth() - 10)
            scroll:SetHeight(frame:GetHeight() - 10)
            scroll:SetPoint("CENTER")
            BG.CreateSrollBarBackdrop(scroll.ScrollBar)
            BG.HookScrollBarShowOrHide(scroll, true)
            scroll:SetScrollChild(edit)

            edit:SetScript("OnEditFocusGained", function(self)
                mainFrame.lastFocus = self
            end)
            edit:SetScript("OnEditFocusLost", function(self)
                self:ClearHighlightText()
            end)
            edit:SetScript("OnTextChanged", function(self)
                BiaoGe.sendMail.body = self:GetText()
                if self.isOnEnter then
                    self:GetScript("OnEnter")(self)
                end
            end)
            edit:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
            end)
            edit:SetScript("OnTabPressed", function(self)
                mainFrame.moneyEdit:SetFocus()
            end)
            edit:SetScript("OnMouseDown", function(self, enter)
                if enter == "RightButton" then
                    edit:SetEnabled(false)
                    edit:SetText("")
                else
                    edit:SetFocus()
                end
            end)
            edit:SetScript("OnMouseUp", function(self, enter)
                if enter == "RightButton" then
                    edit:SetEnabled(true)
                end
            end)
            edit:SetScript("OnEnter", function()
                local self = edit
                self.isOnEnter = true
                local has
                local text = self:GetText()
                text, has = SwitchVar(text, true)
                if has then
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", -5, 0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(L["实际发送效果："], 1, .82, 0, true)
                    GameTooltip:AddLine(text, 1, 1, 1, true)
                    GameTooltip:Show()
                else
                    GameTooltip:Hide()
                end
            end)
            edit:SetScript("OnLeave", function()
                local self = edit
                self.isOnEnter = nil
                GameTooltip:Hide()
            end)
            frame:SetScript("OnMouseDown", edit:GetScript("OnMouseDown"))
            frame:SetScript("OnMouseUp", edit:GetScript("OnMouseUp"))
            frame:SetScript("OnEnter", edit:GetScript("OnEnter"))
            frame:SetScript("OnLeave", edit:GetScript("OnLeave"))
        end

        -- 邮寄人数
        do
            local t = mainFrame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPRIGHT", mainFrame, "TOPLEFT", 100, -230)
            t:SetTextColor(1, 0.82, 0)
            t:SetText(L["邮寄人数："])
            t:SetJustifyH("RIGHT")
            local text = t
            local t = mainFrame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPLEFT", text, "TOPRIGHT", 5, 0)
            t:SetTextColor(1, 0.82, 0)
            t:SetJustifyH("LEFT")
            mainFrame.countText = t
            -- 提示
            local bt = CreateFrame("Button", nil, mainFrame)
            bt:SetSize(28, 28)
            bt:SetPoint("LEFT", mainFrame.countText, "RIGHT", 0, 0)
            bt:Hide()
            mainFrame.tipsButton = bt
            local tex = bt:CreateTexture()
            tex:SetAllPoints()
            tex:SetTexture(616343)
            bt:SetHighlightTexture(616343)
            bt:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["提示："], 1, 1, 1, true)
                GameTooltip:AddLine(L["服务器限制短时间内最多只能给20名不同玩家发送邮件。你当前选择的人数已经超过20人，可能会导致部分玩家邮寄失败。"], 1, 0.82, 0, true)
                GameTooltip:Show()
            end)
            bt:SetScript("OnLeave", GameTooltip_Hide)
        end

        -- 邮寄金额
        do
            local t = mainFrame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPRIGHT", mainFrame, "TOPLEFT", 100, -260)
            t:SetTextColor(1, 0.82, 0)
            t:SetText(L["邮寄金额："])
            t:SetJustifyH("RIGHT")
            local text = t
            local edit = CreateFrame("EditBox", nil, mainFrame,  BG.editTemplate)
            edit:SetSize(100, 20)
            edit:SetPoint("LEFT", text, "RIGHT", 10, 0)
            edit:SetAutoFocus(false)
            edit:SetNumeric(true)
            mainFrame.moneyEdit = edit
            edit:SetScript("OnEditFocusGained", function(self)
                self:HighlightText()
                mainFrame.lastFocus = self
            end)
            edit:SetScript("OnTextChanged", function()
                UpdateMailFrame()
                local bt = mainFrame.startButton
                if bt.isOnEnter then
                    bt:GetScript("OnEnter")(bt)
                end
                local bt = mainFrame.startButton.disFrame
                if bt.isOnEnter then
                    bt:GetScript("OnEnter")(bt)
                end
                local bt = mainFrame.Edit1
                if bt.isOnEnter then
                    bt:GetScript("OnEnter")(bt)
                end
                local bt = mainFrame.Edit2
                if bt.isOnEnter then
                    bt:GetScript("OnEnter")(bt)
                end
            end)
            BG.SetEditBaseClass(edit)
            local tex = edit:CreateTexture()
            tex:SetPoint("LEFT", edit, "RIGHT", 0, 0)
            tex:SetSize(16, 16)
            tex:SetTexture([[Interface\MoneyFrame\UI-MoneyIcons]])
            tex:SetTexCoord(0, .25, 0, 1)
        end

        -- 顶部进度条
        do
            local t = mainFrame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("LEFT", mainFrame, "TOPLEFT", 65, 15)
            t:SetTextColor(1, 1, 1)
            t:SetJustifyH("LEFT")
            mainFrame.topText = t
        end

        -- 开始批量邮寄
        do
            local updateFrame = CreateFrame("Frame")
            local lastSend = {}
            local success = 0
            local addFriend = {}
            local SendTbl = {}

            local bt = BG.CreateButton(mainFrame)
            bt:SetSize(150, 25)
            bt:SetPoint("BOTTOM", mainFrame, "BOTTOMLEFT", 265 / 2, 24)
            bt.text1 = L["开始批量邮寄"]
            bt.text0 = L["停止"]
            bt:SetText(bt.text1)
            bt:SetFrameLevel(bt:GetParent():GetFrameLevel() + 20)
            mainFrame.startButton = bt
            bt:SetScript("OnClick", function(self)
                if self:GetText() == self.text1 then
                    if mainFrame.lastFocus then
                        mainFrame.lastFocus:ClearFocus()
                    end
                    StaticPopup_Show("BiaoGe_SendMail")
                else
                    mainFrame.EndSend()
                    BG.PlaySound(1)
                end
            end)
            bt:SetScript("OnEnter", function(self)
                self.isOnEnter = true
                local count = Size(choose)
                local money = (tonumber(mainFrame.moneyEdit:GetText()) or 0) * 10000
                GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
                GameTooltip:AddLine(format(L["邮寄人数：%s人"], count), 1, .82, 0)
                GameTooltip:AddLine(format(L["邮寄金额：%s %s"], ToGold(money), goldTex), 1, .82, 0)
                GameTooltip:AddLine(format(L["合计金额：%s %s"], count * ToGold(money), goldTex), 1, .82, 0)
                GameTooltip:Show()
            end)
            bt:SetScript("OnLeave", function(self)
                self.isOnEnter = nil
                GameTooltip:Hide()
            end)

            local f = CreateFrame("Frame", nil, bt)
            f:SetAllPoints()
            f:Hide()
            f.tooltip = {}
            mainFrame.startButton.disFrame = f
            f:SetScript("OnEnter", function(self)
                self.isOnEnter = true
                GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["错误："], 1, 1, 1, true)
                for i, text in ipairs(self.tooltip) do
                    GameTooltip:AddLine(text, 1, .82, 0, true)
                end
                GameTooltip:Show()
            end)
            f:SetScript("OnLeave", function(self)
                self.isOnEnter = nil
                GameTooltip:Hide()
            end)

            function mainFrame.EndSend(type)
                local maxPlayer = mainFrame.topText.count
                After(1, function()
                    if lastSend.fullName and addFriend[lastSend.fullName] then
                        C_FriendList.RemoveFriend(lastSend.name)
                    end
                    wipe(addFriend)
                    wipe(lastSend)
                    mainFrame.isSending = nil
                    mainFrame.disFrame:Hide()
                    mainFrame.startButton:SetText(mainFrame.startButton.text1)
                    local msg
                    if type == "success" then
                        msg = format(L["批量邮寄已完成。\n邮寄人数：%s，成功：%s，失败：%s。"],
                            maxPlayer, success, maxPlayer - success)
                        SendSystemMessage(msg:gsub("\n", ""))
                    elseif type == "noMoney" then
                        msg = format(L["|cffff0000身上金币不够，批量邮寄已停止。|r\n邮寄人数：%s，已邮寄：%s，未邮寄：%s。"],
                            maxPlayer, success, maxPlayer - success)
                        SendSystemMessage(msg:gsub("\n", ""))
                    else
                        msg = format(L["|cffff0000批量邮寄被终止。|r\n邮寄人数：%s，已邮寄：%s，未邮寄：%s。"],
                            maxPlayer, success, maxPlayer - success)
                        SendSystemMessage(msg:gsub("\n", ""))
                    end
                    mainFrame.topText:SetText(msg)
                    for _, bt in ipairs(BG.SendMailMemberFrame.buttons) do
                        if bt.ischoose and bt.name and not bt.tex:GetTexture() then
                            bt.tex:SetTexture("interface/raidframe/readycheck-notready")
                        end
                    end
                    BG.SendMailMemberFrame.cancelChooseButton.Click()
                end)
                updateFrame:SetScript("OnUpdate", nil)
            end

            function mainFrame.Send(fullName, name, colorName, money)
                lastSend = { fullName = fullName, name = name, colorName = colorName }
                ClearSendMail()
                SetSendMailMoney(money)
                lastName = BG.GSN(fullName)
                SendMail(lastName, SwitchVar(mainFrame.Edit1:GetText()), SwitchVar(mainFrame.Edit2:GetText()))
                lastName = nil
                if addFriend[fullName] then
                    C_FriendList.RemoveFriend(name)
                end
                updateFrame.elapsed = 0
            end

            StaticPopupDialogs["BiaoGe_SendMail"] = {
                text = L["确定开始批量邮寄？"],
                button1 = L["是"],
                button2 = L["否"],
                OnAccept = function()
                    LibBG.CloseDropDownMenus()
                    if mainFrame.lastFocus then
                        mainFrame.lastFocus:ClearFocus()
                    end
                    if mainFrame.importFrame then
                        mainFrame.importFrame:Hide()
                    end
                    local money = (tonumber(mainFrame.moneyEdit:GetText()) or 0) * 10000
                    wipe(SendTbl)
                    for _, v in pairs(choose) do
                        tinsert(SendTbl, {
                            fullName = v.name,
                            name = v.name,
                            colorName = v.colorName,
                            guid = v.guid,
                            num = v.num,
                        })
                    end
                    sort(SendTbl, function(a, b)
                        return a.num < b.num
                    end)
                    local maxPlayer = #SendTbl
                    mainFrame.topText.count = maxPlayer
                    local topText = mainFrame.topText
                    topText.send = 0
                    wipe(addFriend)
                    wipe(lastSend)
                    success = 0
                    mainFrame.isSending = true
                    mainFrame.disFrame:Show()
                    mainFrame.startButton:SetText(mainFrame.startButton.text0)
                    for i, bt in ipairs(BG.SendMailMemberFrame.buttons) do
                        bt.tex:SetTexture(nil)
                    end

                    local i = 1
                    updateFrame.elapsed = sendStartTime
                    updateFrame:SetScript("OnUpdate", function(_, elapsed)
                        if not mainFrame:IsVisible() then
                            mainFrame.EndSend()
                            return
                        end
                        local nowMoney = GetMoney()
                        if i <= maxPlayer then
                            if money + 30 > nowMoney then -- 钱不够了
                                mainFrame.EndSend("noMoney")
                                return
                            end
                            updateFrame.elapsed = updateFrame.elapsed + elapsed
                            if updateFrame.elapsed >= sendCD then -- 每x秒邮寄一次
                                local fullName = SendTbl[i].fullName
                                local name = SendTbl[i].name
                                local colorName = SendTbl[i].colorName
                                local isFriend = C_FriendList.GetFriendInfo(name)
                                if isFriend then -- 如果是好友，直接邮寄
                                    mainFrame.Send(fullName, name, colorName, money)
                                    topText.send = topText.send + 1
                                    topText:SetText(format(L["正在批量邮寄：%s/%s"], topText.send, topText.count))
                                    i = i + 1
                                elseif not addFriend[fullName] then -- 不是朋友，先加好友
                                    addFriend[fullName] = true
                                    C_FriendList.AddFriend(fullName)
                                    After(0, function()
                                        C_FriendList.ShowFriends()
                                    end)
                                elseif updateFrame.elapsed >= sendTimeOutCD then -- 如果超过x秒还没添加为好友，则邮寄下一个玩家
                                    updateFrame.elapsed = sendStartTime
                                    topText.send = topText.send + 1
                                    topText:SetText(format(L["正在批量邮寄：%s/%s"], topText.send, topText.count))
                                    i = i + 1
                                end
                            end
                        else
                            mainFrame.EndSend("success")
                            return
                        end
                    end)
                end,
                OnCancel = function()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }

            -- 邮寄成功/失败事件
            local f = CreateFrame("Frame")
            f:RegisterEvent("UI_INFO_MESSAGE")
            f:SetScript("OnEvent", function(self, event, _, message)
                if not (mainFrame.isSending and lastSend.colorName) then return end
                local money = (tonumber(mainFrame.moneyEdit:GetText()) or 0) * 10000
                if message == ERR_MAIL_SENT then
                    success = success + 1
                    SendSystemMessage(format(L["已邮寄%s%s金。"], lastSend.colorName, ToGold(money)))
                    for _, bt in ipairs(BG.SendMailMemberFrame.buttons) do
                        if bt.name then
                            if lastSend.fullName == bt.name then
                                bt.tex:SetTexture("interface/raidframe/readycheck-ready")
                                break
                            end
                        end
                    end
                end
            end)

            -- 屏蔽XX已添加为好友的系统消息
            local function Filter(self, event, msg, player, l, cs, t, flag, channelId, ...)
                local fullName = msg:match(ERR_FRIEND_ADDED_S:gsub("%%s", "(.+)")) or
                    msg:match(ERR_FRIEND_ALREADY_S:gsub("%%s", "(.+)")) or
                    msg:match(ERR_FRIEND_ONLINE_SS:gsub("%%s", "(.+)"):gsub("%[", "%%["):gsub("%]", "%%]"))
                if fullName then
                    if addFriend[fullName] then
                        return true
                    end
                end
            end
            ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", Filter)
        end

        -- 刷新框架
        function UpdateMailFrame(clearTopText)
            if clearTopText then
                mainFrame.topText:SetText("")
            end
            if IsRaidMember() and not IsInRaid(1) then
                mainFrame.topText:SetText(BG.STC_r1(L["你当前没有团队。"]))
            end

            if not mainFrame.isSending then
                local count = Size(choose)
                mainFrame.countText:SetText(count .. L["人"])
                if count == 0 or count > 20 then
                    mainFrame.countText:SetTextColor(1, 0, 0)
                else
                    mainFrame.countText:SetTextColor(1, .82, 0)
                end
                mainFrame.tipsButton:SetShown(count > 20)
                local money = (tonumber(mainFrame.moneyEdit:GetText()) or 0) * 10000
                local totalMoney = count * (money + 30)
                local nowMoney = GetMoney()
                if count == 0 or count > 20 or money == 0 or BiaoGe.sendMail.title == "" or totalMoney > nowMoney then
                    mainFrame.startButton:Disable()
                    mainFrame.startButton.disFrame:Show()
                    local tbl = mainFrame.startButton.disFrame.tooltip
                    wipe(tbl)
                    if count == 0 then
                        tinsert(tbl, L["请在右边团队框架选择你要邮寄的对象。"])
                    end
                    if count > 20 then
                        tinsert(tbl, L["服务器限制同一账号1小时内最多只能邮寄20人。你可以用当前账号邮寄20人，双开用另一个账号邮寄剩下的人。"])
                    end
                    if money == 0 then
                        tinsert(tbl, L["邮寄金额不能为0。"])
                    elseif totalMoney > nowMoney then
                        tinsert(tbl, format(L["合计邮寄金额%s %s，你的钱不够。"], ToGold(totalMoney), goldTex))
                    end
                    if BiaoGe.sendMail.title == "" then
                        tinsert(tbl, L["主题不能为空。"])
                    end
                else
                    mainFrame.startButton:Enable()
                    mainFrame.startButton.disFrame:Hide()
                end
            end
        end
    end

    -- 补贴与工资
    do
        local frame, child, width
        local buttons = {}

        local function CreateUI()
            if mainFrame.gzFrame then return end
            local f = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            f:SetBackdropColor(0, 0, 0, 0.8)
            f:SetBackdropBorderColor(0, 0, 0, 1)
            f:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", 0, 0)
            f:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 200, 0)
            f:EnableMouse(true)
            f.events = {}
            mainFrame.gzFrame = f

            local text = f:CreateFontString()
            text:SetPoint("TOP", 0, -5)
            text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            text:SetText(L["工资与补贴"])

            local bt = BG.CreateButton(f)
            bt:SetSize(50, 17)
            bt:SetPoint("TOPLEFT", 2, -3)
            bt:SetText(L["刷新"])
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                mainFrame:UpdateGZFrame()
            end)

            frame = CreateFrame("Frame", nil, f, "BackdropTemplate")
            frame:SetPoint("TOPLEFT", 2.5, -22)
            frame:SetPoint("BOTTOMRIGHT", -2.5, 2.5)
            frame:SetBackdrop({
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            frame:SetBackdropBorderColor(.5, .5, .5, .5)
            frame.scroll = CreateFrame("ScrollFrame", nil, frame, BG.scrollTemplate)
            frame.scroll:SetPoint("TOPLEFT", 5, -2)
            frame.scroll:SetPoint("BOTTOMRIGHT", -5, 5)
            frame.scroll.ScrollBar.scrollStep = nil
            BG.HookScrollBarShowOrHide(frame.scroll, true)
            width = frame.scroll:GetWidth()
            child = CreateFrame("Frame", nil, frame.scroll)
            child:SetPoint("TOPLEFT")
            child:SetWidth(frame.scroll:GetWidth())
            child:SetHeight(frame.scroll:GetHeight())
            frame.scroll:SetScrollChild(child)
        end

        local function CreateButton(name, money, hasMan)
            local ds
            local f = CreateFrame("Frame", nil, child)
            do
                f:SetSize(width, 20)
                if next(buttons) then
                    f:SetPoint("TOPLEFT", buttons[#buttons], "BOTTOMLEFT", 0, -2)
                else
                    f:SetPoint("TOPLEFT", 0, 0)
                end
                tinsert(buttons, f)
                f.ds = f:CreateTexture()
                f.ds:SetAllPoints()
                f.ds:SetColorTexture(.5, .5, .5, .3)
                f.ds:Hide()
                ds = f.ds
                f:SetScript("OnEnter", function(self)
                    ds:Show()
                end)
                f:SetScript("OnLeave", function(self)
                    ds:Hide()
                end)
            end

            local nameFrame = CreateFrame("Frame", nil, f)
            do
                nameFrame:SetSize(width * .40, f:GetHeight())
                nameFrame:SetPoint("LEFT", 0, 0)
                local t = nameFrame:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                t:SetAllPoints()
                t:SetText(name)
                t:SetJustifyH("LEFT")
                t:SetWordWrap(false)
                nameFrame:SetScript("OnEnter", function(self)
                    if t:IsTruncated() then
                        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(name, 1, .82, 0, true)
                        GameTooltip:Show()
                    end
                    ds:Show()
                end)
                nameFrame:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                    ds:Hide()
                end)
            end

            local moneyFrame = CreateFrame("Frame", nil, f)
            do
                moneyFrame:SetSize(width * .35, nameFrame:GetHeight())
                moneyFrame:SetPoint("LEFT", nameFrame, "RIGHT", 2, 0)
                local t = moneyFrame:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                t:SetAllPoints()
                t:SetText(money)
                t:SetJustifyH("LEFT")
                t:SetWordWrap(false)
                moneyFrame:SetScript("OnEnter", function(self)
                    if t:IsTruncated() then
                        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(name, 1, .82, 0, true)
                        GameTooltip:Show()
                    end
                    ds:Show()
                end)
                moneyFrame:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                    ds:Hide()
                end)
            end

            local bt = BG.CreateButton(f)
            do
                bt:SetSize(width * .25 - 5, nameFrame:GetHeight() - 2)
                bt:SetPoint("LEFT", moneyFrame, "RIGHT", 2, 0)
                bt:SetText(L["应用"])
                bt:RegisterForClicks("AnyUp")
                bt:SetScript("OnClick", function(self, button)
                    BG.PlaySound(1)
                    local money = money
                    if button == "RightButton" and hasMan then
                        money = hasMan.avg
                    end
                    if money < 0 then
                        UIErrorsFrame:AddMessage(L["金额不能为负数！"], 1, 0, 0)
                    else
                        for _, f in pairs(buttons) do
                            f.ds:Hide()
                        end
                        ds:Show()
                        mainFrame.moneyEdit:SetText(money)
                    end
                end)
                bt:SetScript("OnEnter", function(self)
                    ds:Show()
                    if hasMan then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
                        GameTooltip:AddLine(AddTexture("LEFT") .. self:GetText() .. money, 1, .82, 0, true)
                        GameTooltip:AddLine(AddTexture("RIGHT") .. self:GetText() .. hasMan.avg, 1, .82, 0, true)
                        GameTooltip:Show()
                    end
                end)
                bt:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                    ds:Hide()
                end)
            end

            local l = nameFrame:CreateLine()
            l:SetColorTexture(RGB("808080", 1))
            l:SetStartPoint("BOTTOMLEFT", 0, 0)
            l:SetEndPoint("BOTTOMLEFT", width, 0)
            l:SetThickness(1)
        end

        function mainFrame:UpdateGZFrame()
            CreateUI()
            for _, bt in pairs(buttons) do
                bt:Hide()
            end
            wipe(buttons)
            local FB = BG.FB1
            local Maxb = BG.Maxb
            local money = tonumber(BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. 5]:GetText()) or 0
            CreateButton(L["单人工资"], money)
            local i = 1
            while BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei" .. i] do
                local item = BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei" .. i]:GetText()
                local hasMan = BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei" .. i].hasMan
                local money = tonumber(BG.Frame[FB]["boss" .. Maxb[FB] + 1]["jine" .. i]:GetText())
                if item ~= "" and money and money ~= 0 then
                    CreateButton(item, money, hasMan)
                end
                i = i + 1
            end
        end
    end
end

BG.Init2(RoadSendMail)
