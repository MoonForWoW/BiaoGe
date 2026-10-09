if BG.IsBlackListPlayer then return end
local _, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
local Size = ns.Size
local RGB = ns.RGB
local GetClassColor = ns.GetClassColor
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local Maxb = ns.Maxb
local HopeMaxn = ns.HopeMaxn
local HopeMaxb = ns.HopeMaxb
local HopeMaxi = ns.HopeMaxi
local AddTexture = ns.AddTexture
local RGB_16 = ns.RGB_16
local GetItemID = ns.GetItemID

local pt = print

local realmID = GetRealmID()

BG.History = {}

function BG.UpdateHistoryButton()
    local bt = BG.History.HistoryButton
    bt:SetFormattedText(L["历史表格（%d个）"], #BiaoGe.HistoryList[BG.FB1])
    bt:SetSize(bt:GetFontString():GetWidth(), 20)
end

function BG.HistoryUI()
    local parent = BG.FBMainFrame
    local width_jiange = -7

    ------------------下拉框架------------------
    do
        local f = CreateFrame("Frame", nil, BG.MainFrame, "BackdropTemplate")
        f:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(0, 0, 0, 0.9)
        f:SetSize(300, 450)
        f:SetPoint("TOPRIGHT", BG.MainFrame, "TOPRIGHT", 0, -20)
        f.frameLevel = 130
        f:SetFrameLevel(f.frameLevel)
        f:EnableMouse(true)
        f:Hide()
        BG.History.List = f
        f:SetScript("OnHide", function(self)
            BG.History.GaiMingFrame:Hide()
        end)

        local scroll = CreateFrame("ScrollFrame", nil, BG.History.List, BG.scrollTemplate) -- 滚动
        scroll:SetWidth(BG.History.List:GetWidth() - 27)
        scroll:SetHeight(BG.History.List:GetHeight() - 9)
        scroll:SetPoint("TOPLEFT", BG.History.List, "TOPLEFT", 0, -5)
        scroll.ScrollBar.scrollStep = BG.scrollStep
        BG.CreateSrollBarBackdrop(scroll.ScrollBar)
        BG.HookScrollBarShowOrHide(scroll)
        BG.History.scroll = scroll

        local child = CreateFrame("Frame", nil, BG.History.List) -- 子框架
        child:SetWidth(scroll:GetWidth())
        child:SetHeight(scroll:GetHeight())
        BG.History.child = child
        scroll:SetScrollChild(child)

        local TitleText = BG["HistoryFrame" .. BG.FB1]:CreateFontString() -- 标题
        TitleText:SetPoint("TOP", BG.MainFrame, "TOP", 0, -4);
        TitleText:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        TitleText:SetTextColor(RGB("00FF00"))
        BG.History.Title = TitleText

        local text = BG.History.List:CreateFontString() -- 提示文字
        text:SetPoint("TOP", BG.History.List, "BOTTOM", 0, 0)
        text:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
        text:SetText(BG.STC_w1(format(L["（ALT+%s改名，ALT+%s删除表格）"], AddTexture("LEFT"), AddTexture("RIGHT"))))

        local bt = BG.CreateButton(BG.History.List)
        bt:SetSize(110, 25)
        bt:SetPoint("TOP", BG.History.List, "BOTTOM", -0, -20)
        bt:SetText(L["清空历史表格"])
        bt:SetScript("OnClick", function(self)
            local FB = BG.FB1
            StaticPopupDialogs["BiaoGe_ClearAllHistory"].OnAccept = function()
                wipe(BiaoGe.History[FB])
                wipe(BiaoGe.HistoryList[FB])
                BG.ClickTabButton(BG.FBMainFrameTabNum)
                BG.EscHistoryFrame()
                BG.UpdateHistoryButton()
            end
            StaticPopup_Show("BiaoGe_ClearAllHistory", BG.GetFBinfo(FB, "shortName"))
        end)

        StaticPopupDialogs["BiaoGe_ClearAllHistory"] = {
            text = L["确定清空<%s>的所有历史表格？"],
            button1 = L["是"],
            button2 = L["否"],
            OnCancel = function()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
        }
    end
    ------------------历史表格按键------------------
    do
        local bt = CreateFrame("Button", nil, parent)
        bt:SetPoint("TOPRIGHT", BG.MainFrame, "TOPRIGHT", -30, -1)
        bt:SetNormalFontObject(BG.FontGreen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        bt:RegisterForClicks("AnyUp")
        BG.SetTextHighlightTexture(bt)
        BG.History.HistoryButton = bt
        BG.UpdateHistoryButton()
        -- 单击触发
        bt:SetScript("OnClick", function(self, button)
            if button == "LeftButton" then
                BG.FrameHide(2)
                if BG.History.SaveButton:GetButtonState() ~= "DISABLED" then
                    BG.CreatHistoryListButton(BG.FB1)
                end
                if BG.History.List and BG.History.List:IsVisible() then
                    BG.History.List:Hide()
                else
                    BG.History.List:Show()
                end
            end
            BG.PlaySound(1)
        end)
    end
    ------------------保存当前表格按键------------------
    do
        function BG.SaveBiaoGe(FB)
            local FB = FB or BG.FB1
            local serverTime = BiaoGe[FB].raidRoster and BiaoGe[FB].raidRoster.time or GetServerTime()
            local DT = tonumber(date("%y%m%d%H%M%S", serverTime))
            if BiaoGe.History[FB][DT] then
                serverTime = GetServerTime()
                DT = tonumber(date("%y%m%d%H%M%S", serverTime))
            end
            local DTcn = date(L["%m月%d日%H:%M:%S\n"], serverTime)
            BiaoGe.History[FB][DT] = {}
            BiaoGe.History[FB][DT].tradeTbl = {}
            for b = 1, Maxb[FB] + 2 do
                BiaoGe.History[FB][DT]["boss" .. b] = {}
                for i = 1, BG.GetMaxi(FB, b) do
                    local zhuangbei = BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]
                    if zhuangbei then
                        if zhuangbei:GetText() ~= "" then
                            BiaoGe.History[FB][DT]["boss" .. b]["zhuangbei" .. i] = zhuangbei:GetText()
                            BiaoGe.History[FB][DT]["boss" .. b]["itemLevel" .. i] = BiaoGe[FB]["boss" .. b]["itemLevel" .. i]
                            BiaoGe.History[FB][DT]["boss" .. b]["bindOnEquip" .. i] = BiaoGe[FB]["boss" .. b]["bindOnEquip" .. i]
                        end

                        local maijia = BG.Frame[FB]["boss" .. b]["maijia" .. i]
                        if maijia:GetText() ~= "" then
                            BiaoGe.History[FB][DT]["boss" .. b]["maijia" .. i] = maijia:GetText()
                            for k, v in pairs(BG.playerClass) do
                                BiaoGe.History[FB][DT]["boss" .. b][k .. i] = BiaoGe[FB]["boss" .. b][k .. i]
                            end
                        end

                        local jine = BG.Frame[FB]["boss" .. b]["jine" .. i]
                        if jine:GetText() ~= "" then
                            BiaoGe.History[FB][DT]["boss" .. b]["jine" .. i] = jine:GetText()
                        end

                        local guanzhu = BiaoGe[FB]["boss" .. b]["guanzhu" .. i]
                        if guanzhu then
                            BiaoGe.History[FB][DT]["boss" .. b]["guanzhu" .. i] = true
                        end

                        local qiankuan = BiaoGe[FB]["boss" .. b]["qiankuan" .. i]
                        if qiankuan then
                            BiaoGe.History[FB][DT]["boss" .. b]["qiankuan" .. i] = qiankuan
                        end

                        if BGDEBUG then
                            BiaoGe.History[FB][DT]["boss" .. b]["loot" .. i] = BiaoGe[FB]["boss" .. b]["loot" .. i]
                        end
                    end
                end
            end
            for i, v in ipairs(BiaoGe[FB].tradeTbl) do
                BiaoGe.History[FB][DT].tradeTbl[i] = BG.Copy(v)
            end
            if BiaoGe[FB].raidRoster then
                BiaoGe.History[FB][DT].raidRoster = {}
                for k, v in pairs(BiaoGe[FB].raidRoster) do
                    BiaoGe.History[FB][DT].raidRoster[k] = BG.Copy(v)
                end
            end
            if BiaoGe[FB].auctionLog then
                BiaoGe.History[FB][DT].auctionLog = {}
                for k, v in pairs(BiaoGe[FB].auctionLog) do
                    BiaoGe.History[FB][DT].auctionLog[k] = BG.Copy(v)
                end
            end
            if BiaoGe[FB].leaderInfo then
                BiaoGe.History[FB][DT].leaderInfo = BG.Copy(BiaoGe[FB].leaderInfo)
            end


            local d = { DT, format(L["%s%s %s人 工资:%s"], DTcn, BG.GetFBinfo(FB, "shortName"),
                BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. 4]:GetText(),
                BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. 5]:GetText()) }
            table.insert(BiaoGe.HistoryList[FB], 1, d)
            BG.UpdateHistoryButton()
            BG.CreatHistoryListButton(FB)
        end

        local bt = CreateFrame("Button", nil, parent)
        bt:SetPoint("TOPRIGHT", BG.History.HistoryButton, "TOPLEFT", width_jiange, 0)
        bt:SetNormalFontObject(BG.FontGreen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        bt:SetText(L["保存"])
        bt:SetSize(bt:GetFontString():GetWidth(), 20)
        BG.SetTextHighlightTexture(bt)
        BG.History.SaveButton = bt

        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_NONE")
            GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["保存表格"], 1, 1, 1, true)
            GameTooltip:AddLine(L["把当前表格保存至历史表格。"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        bt:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        bt:SetScript("OnClick", function(self)
            BG.FrameHide(2)
            self:SetEnabled(false)
            C_Timer.After(0.5, function()
                bt:SetEnabled(true)
            end)
            BG.SaveBiaoGe()
            BG.ClearBiaoGe("biaoge", BG.FB1)
            BG.PlaySound(2)
        end)
    end
    ------------------分享表格按键------------------
    do
        local bt = CreateFrame("Button", nil, parent)
        bt:SetPoint("TOPRIGHT", BG.History.SaveButton, "TOPLEFT", width_jiange, 0)
        bt:SetNormalFontObject(BG.FontGreen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        bt:SetText(L["分享"])
        bt:SetSize(bt:GetFontString():GetWidth(), 20)
        bt:RegisterForClicks("AnyUp")
        BG.SetTextHighlightTexture(bt)
        BG.History.SendButton = bt

        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_NONE")
            GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["分享表格"], 1, 1, 1, true)
            if IsInRaid(1) then
                GameTooltip:AddLine(AddTexture("LEFT") .. L["把链接发到聊天框"], 1, 0.82, 0, true)
                GameTooltip:AddLine(AddTexture("RIGHT") .. L["把链接私发给团长"], 1, 0.82, 0, true)
                GameTooltip:AddLine(" ", 1, 0.82, 0, true)
            end
            GameTooltip:AddLine(L["把当前表格发给别人，类似发WA那样。"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        bt:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        local updateFrame = CreateFrame("Frame")
        updateFrame.timeElapsed = 0
        BG.canSendBiaoGe = false
        bt:SetScript("OnClick", function(self, button)
            if BG.InBoss() then return end
            BG.canSendBiaoGe = true
            updateFrame.timeElapsed = 0
            updateFrame:SetScript("OnUpdate", function(self, elapsed)
                updateFrame.timeElapsed = updateFrame.timeElapsed + elapsed
                if updateFrame.timeElapsed >= 300 then
                    BG.canSendBiaoGe = false
                    updateFrame.timeElapsed = 0
                    updateFrame:SetScript("OnUpdate", nil)
                end
            end)
            BG.FrameHide(2)
            local msg = BG.GetSendBiaoGeMsg()
            if button == "LeftButton" then
                ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
                ChatEdit_InsertLink(msg)
            elseif button == "RightButton" and IsInRaid(1) then
                local leader = BG.masterLooter or BG.raidLeader
                if leader then
                    SendChatMessage(msg, "WHISPER", nil, leader)
                end
            end
            BG.PlaySound(1)
        end)
    end
    ------------------导出表格按键------------------
    do
        -- 创建按键
        local bt = CreateFrame("Button", nil, parent)
        bt:SetPoint("TOPRIGHT", BG.History.SendButton, "TOPLEFT", width_jiange, 0)
        bt:SetNormalFontObject(BG.FontGreen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        bt:SetText(L["导出"])
        bt:SetSize(bt:GetFontString():GetWidth(), 20)
        BG.SetTextHighlightTexture(bt)
        BG.History.DaoChuButton = bt

        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_NONE")
            GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["导出表格"], 1, 1, 1, true)
            GameTooltip:AddLine(L["把表格导出为文本。"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        bt:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            local FB = BG.FB1
            local Frame
            local text = ""
            if BG["Frame" .. FB]:IsVisible() then
                Frame = BG.Frame
            elseif BG["HistoryFrame" .. FB]:IsVisible() then
                Frame = BG.HistoryFrame
            end
            for b = 1, Maxb[FB] + 2 do
                local bossname2 = BG.Boss[FB]["boss" .. b].name2
                local bosscolor = BG.Boss[FB]["boss" .. b].color
                text = text .. "|cff" .. bosscolor .. bossname2 .. "|r\n"
                for i = 1, BG.GetMaxi(FB, b) do
                    if Frame[FB]["boss" .. b]["zhuangbei" .. i] then
                        if Frame[FB]["boss" .. b]["zhuangbei" .. i]:GetText() ~= ""
                            or Frame[FB]["boss" .. b]["maijia" .. i]:GetText() ~= ""
                            or Frame[FB]["boss" .. b]["jine" .. i]:GetText() ~= "" then
                            text = text .. Frame[FB]["boss" .. b]["zhuangbei" .. i]:GetText() .. " "
                                .. RGB_16(Frame[FB]["boss" .. b]["maijia" .. i]) .. " "
                                .. Frame[FB]["boss" .. b]["jine" .. i]:GetText() .. "|r\n"
                        end
                    end
                end
                if b ~= Maxb[FB] + 2 then
                    text = text .. "\n"
                end
            end
            BG.CreateExportFrame(L["导出表格"], text)
        end)
    end
    ------------------应用表格按键------------------
    do
        function BG.SetBiaoGeFormHistory(FB, num)
            local num = num or BG.History.chooseNum
            local FB = FB or BG.FB1
            for _date, value in pairs(BiaoGe.History[FB]) do
                if tonumber(_date) == tonumber(BiaoGe.HistoryList[FB][num][1]) then
                    local DT = BiaoGe.HistoryList[FB][num][1]
                    for b = 1, Maxb[FB] + 2 do
                        for i = 1, BG.GetMaxi(FB, b) do
                            if BG.Frame[FB]["boss" .. b]["zhuangbei" .. i] then
                                BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]:SetText(BiaoGe.History[FB][DT]["boss" .. b]["zhuangbei" .. i] or "")
                                BG.Frame[FB]["boss" .. b]["maijia" .. i]:SetText(BiaoGe.History[FB][DT]["boss" .. b]["maijia" .. i] or "")
                                BG.Frame[FB]["boss" .. b]["maijia" .. i]:SetCursorPosition(0)
                                if BiaoGe.History[FB][DT]["boss" .. b]["color" .. i] then
                                    BG.Frame[FB]["boss" .. b]["maijia" .. i]:SetTextColor(unpack(BiaoGe.History[FB][DT]["boss" .. b]["color" .. i]))
                                end
                                BG.Frame[FB]["boss" .. b]["jine" .. i]:SetText(BiaoGe.History[FB][DT]["boss" .. b]["jine" .. i] or "")
                                BG.Frame[FB]["boss" .. b]["guanzhu" .. i]:Hide()
                                BiaoGe[FB]["boss" .. b]["guanzhu" .. i] = nil

                                BiaoGe[FB]["boss" .. b]["zhuangbei" .. i] = BiaoGe.History[FB][DT]["boss" .. b]["zhuangbei" .. i]
                                BiaoGe[FB]["boss" .. b]["maijia" .. i] = BiaoGe.History[FB][DT]["boss" .. b]["maijia" .. i]
                                BiaoGe[FB]["boss" .. b]["jine" .. i] = BiaoGe.History[FB][DT]["boss" .. b]["jine" .. i]
                                BiaoGe[FB]["boss" .. b]["itemLevel" .. i] = BiaoGe.History[FB][DT]["boss" .. b]["itemLevel" .. i]
                                BiaoGe[FB]["boss" .. b]["bindOnEquip" .. i] = BiaoGe.History[FB][DT]["boss" .. b]["bindOnEquip" .. i]
                                for k, v in pairs(BG.playerClass) do
                                    BiaoGe[FB]["boss" .. b][k .. i] = BiaoGe.History[FB][DT]["boss" .. b][k .. i]
                                end

                                if BiaoGe.History[FB][DT]["boss" .. b]["guanzhu" .. i] then
                                    BiaoGe[FB]["boss" .. b]["guanzhu" .. i] = true
                                    BG.Frame[FB]["boss" .. b]["guanzhu" .. i]:Show()
                                else
                                    BiaoGe[FB]["boss" .. b]["guanzhu" .. i] = nil
                                    BG.Frame[FB]["boss" .. b]["guanzhu" .. i]:Hide()
                                end

                                if BiaoGe.History[FB][DT]["boss" .. b]["qiankuan" .. i] then
                                    BiaoGe[FB]["boss" .. b]["qiankuan" .. i] = BiaoGe.History[FB][DT]["boss" .. b]["qiankuan" .. i]
                                    BG.Frame[FB]["boss" .. b]["qiankuan" .. i]:Show()
                                else
                                    BiaoGe[FB]["boss" .. b]["qiankuan" .. i] = nil
                                    BG.Frame[FB]["boss" .. b]["qiankuan" .. i]:Hide()
                                end

                                BiaoGe[FB]["boss" .. b]["loot" .. i] = BiaoGe.History[FB][DT]["boss" .. b]["loot" .. i]
                            end
                        end
                    end
                    BiaoGe[FB].tradeTbl = {}
                    if type(BiaoGe.History[FB][DT].tradeTbl) == "table" then
                        for i, v in ipairs(BiaoGe.History[FB][DT].tradeTbl) do
                            BiaoGe[FB].tradeTbl[i] = BG.Copy(v)
                        end
                    end
                    if type(BiaoGe.History[FB][DT].raidRoster) == "table" then
                        BiaoGe[FB].raidRoster = {}
                        for k, v in pairs(BiaoGe.History[FB][DT].raidRoster) do
                            BiaoGe[FB].raidRoster[k] = BG.Copy(v)
                        end
                    end
                    if type(BiaoGe.History[FB][DT].auctionLog) == "table" then
                        BiaoGe[FB].auctionLog = {}
                        for k, v in pairs(BiaoGe.History[FB][DT].auctionLog) do
                            BiaoGe[FB].auctionLog[k] = BG.Copy(v)
                        end
                    end
                    if type(BiaoGe.History[FB][DT].leaderInfo) == "table" then
                        BiaoGe[FB].leaderInfo = BG.Copy(BiaoGe.History[FB][DT].leaderInfo)
                    end
                    break
                end
            end
            if BiaoGe.lastFrame == "FB" then
                BG.FBMainFrame:Show()
            end
            BG.UpdateAuctionLogFrame()
        end

        local bt = CreateFrame("Button", nil, BG.HistoryMainFrame)
        bt:SetPoint("TOPRIGHT", BG.History.DaoChuButton, "TOPLEFT", width_jiange, 0)
        bt:SetNormalFontObject(BG.FontGreen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        bt:SetText(L["应用"])
        bt:SetSize(bt:GetFontString():GetWidth(), 20)
        BG.SetTextHighlightTexture(bt)
        BG.History.YongButton = bt

        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_NONE")
            GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["应用表格"], 1, 1, 1, true)
            GameTooltip:AddLine(L["把该历史表格复制粘贴到当前表格，这样你可以编辑内容。"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        bt:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        bt:SetScript("OnClick", function(self)
            local FB = BG.FB1
            if not BGDEBUG and BG.BiaoGeHavedItem(FB) then
                StaticPopup_Show("YINGYONGBIAOGE")
                return
            end
            BG.SetBiaoGeFormHistory()
            BG.PlaySound(2)
        end)

        StaticPopupDialogs["YINGYONGBIAOGE"] = {
            text = L["确定应用表格？\n你当前的表格将被"] .. BG.STC_r1(L[" 替换 "]),
            button1 = L["是"],
            button2 = L["否"],
            OnCancel = function()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
        }
        StaticPopupDialogs["YINGYONGBIAOGE"].OnAccept = function()
            BG.SetBiaoGeFormHistory()
            BG.PlaySound(2)
        end
    end
    ------------------退出历史表格按键------------------
    do
        function BG.EscHistoryFrame()
            BG.FrameHide(0)
            BG.FBMainFrame:Show()
            BG.UpdateAuctionLogFrame()
            BG.PlaySound(1)
        end

        local bt = CreateFrame("Button", nil, BG.HistoryMainFrame)
        bt:SetPoint("TOPRIGHT", BG.History.YongButton, "TOPLEFT", width_jiange, 0)
        bt:SetNormalFontObject(BG.FontFen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        bt:SetText(L["返回"])
        bt:SetSize(bt:GetFontString():GetWidth(), 20)
        BG.SetTextHighlightTexture(bt)
        BG.History.EscButton = bt
        bt:SetScript("OnClick", BG.EscHistoryFrame)
    end
    ------------------改名------------------
    do
        local f = CreateFrame("Frame", nil, BG.History.List, "BackdropTemplate")
        f:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(0, 0, 0, 0.9)
        f:SetSize(250, 150)
        f:SetPoint("TOPRIGHT", BG.History.List, "TOPLEFT", -2, 0)
        f:SetFrameLevel(130)
        f:Hide()
        BG.History.GaiMingFrame = f
        f:SetScript("OnMouseDown", function(self)
        end)

        local text = f:CreateFontString() -- 标题
        text:SetPoint("TOP", BG.History.GaiMingFrame, "TOP", 0, -20)
        text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        text:SetTextColor(RGB("00BFFF"))
        BG.History.GaiMingBiaoTi = text

        local f = CreateFrame("Frame", nil, BG.History.GaiMingFrame, "BackdropTemplate")
        f:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(0, 0, 0, 0.2)
        f:SetSize(230, 60)
        f:SetPoint("TOPRIGHT", BG.History.GaiMingFrame, "TOPRIGHT", -10, -45)

        local edit = CreateFrame("EditBox", nil, f)
        edit:SetSize(f:GetWidth() - 10, f:GetHeight())
        edit:SetPoint("TOPLEFT", 5, -5)
        edit:SetAutoFocus(false)
        edit:EnableMouse(true)
        edit:SetMultiLine(true)
        edit:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
        edit.bg = f
        BG.History.GaiMingEdit1 = edit
        edit:SetScript("OnEscapePressed", function(self)
            BG.History.GaiMingFrame:Hide()
        end)
        f:SetScript("OnMouseDown", function(self)
            edit:SetFocus()
            edit:SetCursorPosition(strlen(edit:GetText()))
        end)

        local bt = BG.CreateButton(BG.History.GaiMingFrame)
        bt:SetSize(110, 25)
        bt:SetPoint("BOTTOMLEFT", BG.History.GaiMingFrame, "BOTTOMLEFT", 10, 15)
        bt:SetText(L["确定"])
        bt:SetScript("OnClick", function(self)
            local FB = BG.FB1
            local text = BG.History.GaiMingEdit1:GetText()
            if text ~= "" then
                for i, v in ipairs(BiaoGe.HistoryList[FB]) do
                    if i ~= BG.History.GaiMingNum then
                        if v[2] == text then
                            SendSystemMessage(BG.BG .. BG.STC_r1(L["不能使用该名字，因为跟其他历史表格重名！"]))
                            return
                        end
                    end
                end

                BiaoGe.HistoryList[FB][BG.History.GaiMingNum][2] = text
                BG.History.GaiMingFrame:Hide()
                BG.CreatHistoryListButton(FB)

                BG.PlaySound(1)
            end
        end)

        local bt = BG.CreateButton(BG.History.GaiMingFrame)
        bt:SetSize(110, 25)
        bt:SetPoint("BOTTOMRIGHT", BG.History.GaiMingFrame, "BOTTOMRIGHT", -10, 15)
        bt:SetText(L["取消"])
        bt:SetScript("OnClick", function(self)
            BG.History.GaiMingFrame:Hide()
            BG.PlaySound(1)
        end)
    end
end

------------------下拉框架的内容------------------
do
    local function FormatTitanRealmName(realmName)
        if type(realmName) ~= "string" then return realmName end
        local realm = realmName:match("^(时光[IVX]+)")
        if realm == "时光II" or realm == "时光III" or realm == "时光IV" or realm == "时光V" or realm == "时光VI" then
            return realm
        end
        return realmName
    end
    -- DT 为 HistoryList 条目的第一个值；按团队名单顺序返回首个匹配的角色名文本和职业。
    -- 没有匹配时返回 ""。
    local function GetHistoryPlayerName(FB, DT)
        FB = FB or BG.FB1
        if type(BiaoGe) ~= "table" or not FB or (type(DT) ~= "number" and type(DT) ~= "string") then
            return ""
        end
        local history = BiaoGe.History and BiaoGe.History[FB]
        local entry = history and (history[DT] or history[tonumber(DT)] or history[tostring(DT)])
        local raid = entry and entry.raidRoster
        if type(raid) ~= "table" or type(raid.roster) ~= "table" or type(BiaoGe.playerInfo) ~= "table" then
            return ""
        end

        local function NormalizeRealm(realm)
            if type(realm) ~= "string" then return end
            realm = realm:gsub("%s", ""):gsub("%-", "")
            realm = FormatTitanRealmName(realm)
            if realm ~= "" then return realm end
        end
        local function GetIdentity(name, defaultRealm)
            if type(name) ~= "string" or name == "" then return end
            local shortName, realm = name:match("^([^%-]+)%-(.+)$")
            shortName = shortName or name
            realm = NormalizeRealm(realm or defaultRealm)
            if realm then return shortName .. "-" .. realm, shortName, realm end
        end

        local charactersByName = {}
        local realms = BiaoGe.realmName or {}
        for serverID, characters in pairs(BiaoGe.playerInfo) do
            if type(characters) == "table" then
                local realm = realms[serverID] or realms[tonumber(serverID)] or realms[tostring(serverID)]
                for name, character in pairs(characters) do
                    local fullName = GetIdentity(name, realm)
                    if fullName and (not charactersByName[fullName] or not charactersByName[fullName].class) then
                        charactersByName[fullName] = {
                            class = type(character) == "table" and character.class or nil,
                        }
                    end
                end
            end
        end
        -- 无服务器后缀的历史成员名只使用记录中的服务器补全。
        for _, name in ipairs(raid.roster) do
            local fullName = GetIdentity(name, raid.realm)
            if fullName and charactersByName[fullName] then
                local text = fullName:gsub('%-', '\n')
                return text, charactersByName[fullName].class
            end
        end
        return ""
    end

    function BG.CreatHistoryListButton(FB)
        -- 按序号复用按钮，只在列表长度超过已有数量时创建。
        local buttonWidth = BG.History.List:GetWidth() - 40
        for i = 1, #BiaoGe.HistoryList[FB] do
            local bt = BG.History["ListButton" .. i]
            if not bt then
                bt = CreateFrame("Button", nil, BG.History.child, "BackdropTemplate")
                bt:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                })
                bt:SetBackdropColor(1, 1, 1, 0.1)
                if i == 1 then
                    bt:SetPoint("TOPLEFT", BG.History.child, "TOPLEFT", 10, -10)
                else
                    bt:SetPoint("TOPLEFT", BG.History["ListButton" .. i - 1], "BOTTOMLEFT", 0, -5)
                end
                bt:SetSize(buttonWidth, 40)
                bt:SetNormalFontObject(BG.FontBlue13)
                bt:SetDisabledFontObject(BG.FontWhite13)
                bt:SetHighlightFontObject(BG.FontWhite13)
                bt:SetText("" .. i .. ". " .. BiaoGe.HistoryList[FB][i][2])
                local t = bt:GetFontString()
                t:SetWidth(bt:GetWidth() - 10)
                t:SetPoint("LEFT", 3, 0)
                t:SetJustifyH("LEFT")
                BG.History["ListButton" .. i] = bt
                local tex2 = bt:CreateTexture(nil, "ARTWORK")
                tex2:SetAllPoints()
                tex2:SetColorTexture(RGB(BG.b1))
                bt:SetDisabledTexture(tex2)

                bt:HookScript("OnEnter", function(self)
                    bt:SetBackdropColor(RGB(BG.b1, 0.6))
                end)
                bt:HookScript("OnLeave", function(self)
                    bt:SetBackdropColor(1, 1, 1, 0.1)
                end)
                bt:SetScript("OnMouseUp", function(self, button)
                    local FB, i = self.FB, self.index
                    if not FB or not i or not BiaoGe.HistoryList[FB][i] then return end
                    BG.CreateFBUI(FB, "History")
                    BG.FrameHide(2)

                    if IsAltKeyDown() then
                        if button == "RightButton" then -- 删除
                            BG.PlaySound(1)
                            BG.DeleteHistory(FB, i)
                            BG.History.GaiMingFrame:Hide()
                            for b = 1, Maxb[FB] + 2 do
                                for i = 1, BG.GetMaxi(FB, b) do
                                    if BG.HistoryFrame[FB]["boss" .. b]["zhuangbei" .. i] then
                                        BG.HistoryFrame[FB]["boss" .. b]["zhuangbei" .. i]:SetText("")
                                        BG.HistoryFrame[FB]["boss" .. b]["maijia" .. i]:SetText("")
                                        BG.HistoryFrame[FB]["boss" .. b]["maijia" .. i]:SetTextColor(1, 1, 1)
                                        BG.HistoryFrame[FB]["boss" .. b]["jine" .. i]:SetText("")
                                        BG.HistoryFrame[FB]["boss" .. b]["guanzhu" .. i]:Hide()
                                        BG.HistoryFrame[FB]["boss" .. b]["qiankuan" .. i]:Hide()
                                    end
                                end
                            end
                            BG.History.Title:SetText(L["<历史表格>"] .. " ")
                            return
                        else -- 改名
                            BG.PlaySound(1)
                            BG.History.GaiMingNum = i
                            BG.History.GaiMingFrame:Show()
                            BG.History.GaiMingBiaoTi:SetText(format(L["你正在改名第 %s 个表格"], i))
                            BG.History.GaiMingEdit1:SetText(BiaoGe.HistoryList[FB][i][2])
                            BG.History.GaiMingEdit1:SetFocus()
                            BG.History.GaiMingEdit1:HighlightText()
                            return
                        end
                    end

                    do
                        for index = 1, #BiaoGe.HistoryList[FB] do
                            BG.History["ListButton" .. index]:Enable()
                        end
                        if self:IsEnabled() then
                            BG.PlaySound(1)
                        end
                        self:Disable()
                    end

                    BG.History.chooseNum = i
                    local DT = BiaoGe.HistoryList[FB][i][1]
                    for b = 1, Maxb[FB] + 2 do
                        if BiaoGe.History[FB][DT]["boss" .. b] then
                            for i = 1, BG.GetMaxi(FB, b) do
                                if BG.HistoryFrame[FB]["boss" .. b]["zhuangbei" .. i] then
                                    BG.HistoryFrame[FB]["boss" .. b]["zhuangbei" .. i]:SetText(BiaoGe.History[FB][DT]["boss" .. b]["zhuangbei" .. i] or "")
                                    BG.HistoryFrame[FB]["boss" .. b]["zhuangbei" .. i]:SetCursorPosition(0)
                                    BG.HistoryFrame[FB]["boss" .. b]["maijia" .. i]:SetText(BiaoGe.History[FB][DT]["boss" .. b]["maijia" .. i] or "")
                                    BG.HistoryFrame[FB]["boss" .. b]["maijia" .. i]:SetCursorPosition(0)
                                    if BiaoGe.History[FB][DT]["boss" .. b]["color" .. i] then
                                        BG.HistoryFrame[FB]["boss" .. b]["maijia" .. i]:SetTextColor(unpack(BiaoGe.History[FB][DT]["boss" .. b]["color" .. i]))
                                    end
                                    BG.HistoryFrame[FB]["boss" .. b]["jine" .. i]:SetText(BiaoGe.History[FB][DT]["boss" .. b]["jine" .. i] or "")

                                    if BiaoGe.History[FB][DT]["boss" .. b]["guanzhu" .. i] then
                                        BG.HistoryFrame[FB]["boss" .. b]["guanzhu" .. i]:Show()
                                    else
                                        BG.HistoryFrame[FB]["boss" .. b]["guanzhu" .. i]:Hide()
                                    end

                                    if BiaoGe.History[FB][DT]["boss" .. b]["qiankuan" .. i] then
                                        BG.HistoryFrame[FB]["boss" .. b]["qiankuan" .. i].qiankuan = BiaoGe.History[FB][DT]["boss" .. b]["qiankuan" .. i]
                                        BG.HistoryFrame[FB]["boss" .. b]["qiankuan" .. i]:Show()
                                    else
                                        BG.HistoryFrame[FB]["boss" .. b]["qiankuan" .. i]:Hide()
                                    end
                                end
                            end
                        end
                    end
                    BG.HistoryMainFrame:Show()

                    BG.History.Title:SetParent(BG["HistoryFrame" .. FB])
                    BG.History.Title:SetText(L["<历史表格>"] .. " " .. i)
                    BG.History.chooseNum = i

                    BG.UpdateAuctionLogFrame(BiaoGe.History[FB][DT].auctionLog)
                end)

                local playerName = bt:CreateFontString(nil, "OVERLAY")
                playerName:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                playerName:SetPoint("RIGHT", bt, "RIGHT", -5, 0)
                playerName:SetJustifyH("RIGHT")
                bt.playerName = playerName
            end
            bt.FB = FB
            bt.index = i
            bt:Enable()
            bt:SetBackdropColor(1, 1, 1, 0.1)
            bt:SetText("" .. i .. ". " .. BiaoGe.HistoryList[FB][i][2])
            local playerName, class = GetHistoryPlayerName(FB, BiaoGe.HistoryList[FB][i][1])
            bt.playerName:SetText(playerName)
            if class then
                local r, g, b = GetClassColor(class)
                bt.playerName:SetTextColor(r, g, b)
            else
                bt.playerName:SetTextColor(0.7, 0.7, 0.7)
            end
            bt:Show()
        end

        -- 保留多余按钮供下次复用，并清除旧的点击数据。
        local i = #BiaoGe.HistoryList[FB] + 1
        while BG.History["ListButton" .. i] do
            local bt = BG.History["ListButton" .. i]
            bt:Hide()
            bt:Disable()
            bt.FB = nil
            bt.index = nil
            bt.playerName:SetText("")
            i = i + 1
        end
    end

    function BG.DeleteHistory(FB, num)
        local FB = FB or BG.FB1
        for _date, value in pairs(BiaoGe.History[FB]) do
            if tonumber(_date) == tonumber(BiaoGe.HistoryList[FB][num][1]) then
                BiaoGe.History[FB][_date] = nil
                break
            end
        end
        table.remove(BiaoGe.HistoryList[FB], num)
        BG.History.chooseNum = nil
        BG.UpdateHistoryButton()
        BG.CreatHistoryListButton(FB)
        BG.UpdateAuctionLogFrame()
    end
end

------------------装备历史价格------------------
do
    local HEIGHT = 14
    local HEIGHT2 = 5
    BG.HistoryMoneyCache = {}
    BG.HistoryMoneyUpdateFrame = CreateFrame("Frame", nil, BG.MainFrame)

    function BG.GetHistoryMoney(itemID, FB, callback)
        local updateFrame = BG.HistoryMoneyUpdateFrame
        updateFrame:SetScript("OnUpdate", nil)
        FB = FB or BG.FB1
        local tbl = {}
        local db = BiaoGe
        local startI = 1
        local _startI = 1
        local oneTime = 5
        local allEnd = false
        local biaogeEnd = false
        local hasAccounts = false
        if BiaoGeAccounts and BiaoGeAccounts.HistoryList and BiaoGeAccounts.HistoryList[FB] then
            hasAccounts = true
        end

        local function AddDB(ii, isAccounts)
            local DT = db.HistoryList[FB][ii][1]
            if db.History[FB][DT] then
                local b = 1
                while db.History[FB][DT]["boss" .. b] do
                    for i = 1, BG.GetMaxi(FB, b) do
                        local zhuangbei = db.History[FB][DT]["boss" .. b]["zhuangbei" .. i]
                        local _itemID = GetItemID(zhuangbei)
                        if zhuangbei and _itemID then
                            local maijia = db.History[FB][DT]["boss" .. b]["maijia" .. i]
                            local color = db.History[FB][DT]["boss" .. b]["color" .. i]
                            local jine = db.History[FB][DT]["boss" .. b]["jine" .. i]
                            if _itemID == itemID and tonumber(jine) then
                                tinsert(tbl, {
                                    DT = tonumber(DT),
                                    item = zhuangbei,
                                    player = maijia or "",
                                    color = color or { 1, 1, 1 },
                                    money = tonumber(jine) or 0,
                                    isAccounts = isAccounts,
                                })
                            end
                        end
                    end
                    b = b + 1
                end
            end
        end
        updateFrame:SetScript("OnUpdate", function(self, elapsed)
            if allEnd then
                self:SetScript("OnUpdate", nil)
                BG.HistoryMoneyCache[itemID] = tbl
                callback(tbl)
                if BG.historyLastCallback and BG.historyLastCallback ~= callback then
                    BG.historyLastCallback(tbl)
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

    function BG.SetHistoryMoney(itemID, nowMoney, nowPlayer, nowR, nowG, nowB)
        if not BG.MainFrame:IsVisible() then return end
        if not itemID then return end
        local FB = BG.FB1
        if not BG.HistoryMoneyFrame then
            local f = CreateFrame("Frame", nil, BG.MainFrame, "BackdropTemplate")
            f:SetSize(300, 0)
            f:SetPoint("BOTTOMRIGHT", BG.MainFrame, "BOTTOMRIGHT", -3, 40)
            f:SetFrameLevel(118)
            f:Hide()
            f.buttons = {}
            BG.HistoryMoneyFrame = f
            f:SetScript("OnHide", function(self)
                BG.HistoryMoneyUpdateFrame:SetScript("OnUpdate", nil)
            end)

            f.bg = f:CreateTexture()
            f.bg:SetSize(f:GetWidth(), 0)
            f.bg:SetPoint("TOP")
            f.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
            f.bg:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0), CreateColor(0, 0, 0, 1))

            --标题（装备）
            local t = BG.HistoryMoneyFrame:CreateFontString()
            t:SetPoint("TOP", BG.HistoryMoneyFrame, "TOP", 3, -10)
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            BG.HistoryMoneyFrame.title = t
        end

        BG.HistoryMoneyFrame:Hide()
        for k, bt in pairs(BG.HistoryMoneyFrame.buttons) do
            bt:Hide()
            BG.HistoryMoneyFrame.buttons[k] = nil
        end

        local itemStackCount = select(8, GetItemInfo(itemID))
        if not itemStackCount or itemStackCount > 1 then return end

        local maxCount
        if nowMoney then
            maxCount = 14
        else
            maxCount = 15
        end

        BG.GetHistoryMoney(itemID, FB, function(tbl)
            if #tbl == 0 then
                return
            end

            sort(tbl, function(a, b)
                return a.DT > b.DT
            end)

            local _tbl = {}
            for i, v in ipairs(tbl) do
                if i > maxCount then break end
                tinsert(_tbl, v)
            end

            if nowMoney then
                if not tonumber(nowMoney) or tonumber(nowMoney) == 0 then
                    nowMoney = 0
                end
                local a = {
                    DT = 0,
                    item = "",
                    player = nowPlayer,
                    color = { nowR, nowG, nowB },
                    money = tonumber(nowMoney)
                }
                table.insert(_tbl, 1, a)
            end
            local maxJine -- 找到表格里最大的金额
            for i = 1, #_tbl do
                if maxJine == nil then
                    maxJine = _tbl[i].money
                end
                if maxJine < _tbl[i].money then
                    maxJine = _tbl[i].money
                end
            end
            local name, link, quality, level, _, _, _, _, _, Texture, _, typeID = GetItemInfo(itemID)
            if not link then return end
            BG.HistoryMoneyFrame.title:SetText(format(L["历史价格：%s%s(%s)"], (AddTexture(Texture) .. link), "|cff" .. "9370DB", level or ""))

            local down
            -- local color = {"00FFFF","00FFCC","00FF99","00FF66","00FF33","00FF00","00FF33","00FF66","00FF99","00FFCC"}   -- 绿色渐变
            -- local color = {"6600FF","3300FF","6633FF","3300CC","0033CC","3366FF","0033FF","0066FF","0099FF","00CCFF"}   -- 蓝色渐变
            local color = { (nowMoney and "00BFFF" or "33FFCC"), "00FFCC", "00FF99", "00FF66", "00FF33", "33FF66", "00CC33", "33CC00", "66FF33", "33FF00", "66FF00", "99FF00", "CCFF00", "CCFF33", "99CC00" } -- 蓝绿渐变
            for i = 1, #_tbl do
                local v = _tbl[i]
                local f = CreateFrame("Frame", nil, BG.HistoryMoneyFrame, "BackdropTemplate")
                f:SetBackdrop({
                    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                })
                f:SetBackdropColor(RGB(color[i], 1))
                if i == 1 then
                    f:SetPoint("TOPRIGHT", BG.HistoryMoneyFrame, "TOPRIGHT", -80, -40)
                else
                    f:SetPoint("TOPRIGHT", down, "BOTTOMRIGHT", 0, -HEIGHT2)
                end
                local widthPercent = v.money / maxJine
                local width
                if widthPercent == 0 then
                    width = 1
                else
                    width = (BG.HistoryMoneyFrame:GetWidth() - 220) * widthPercent + 60
                end
                f:SetSize(width, HEIGHT)
                down = f
                tinsert(BG.HistoryMoneyFrame.buttons, f)

                local t = f:CreateFontString() -- 日期
                t:SetPoint("LEFT", f, "RIGHT", 3, 0)
                t:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                t:SetTextColor(RGB(color[i]))
                if nowMoney and i == 1 then
                    t:SetText(L["当前"])
                else
                    local a = strsub(v.DT, 3, 4)
                    if a:sub(1, 1) == "0" then
                        a = a:sub(2, 2)
                    end
                    local b = strsub(v.DT, 5, 6)
                    if b:sub(1, 1) == "0" then
                        b = b:sub(2, 2)
                    end
                    t:SetText(a .. L["月"] .. b .. L["日"])
                end

                local t = f:CreateFontString() -- 金额
                t:SetPoint("RIGHT", f, "LEFT", -3, 0)
                t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                t:SetTextColor(RGB(color[i]))
                t:SetText(BG.FormatNumber(v.money, 2) .. (v.isAccounts and "*" or ""))

                local t = f:CreateFontString(nil, "OVERLAY") -- 买家
                t:SetPoint("RIGHT")
                t:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                t:SetTextColor(unpack(v.color))
                t:SetText(v.player)
            end

            local height = #_tbl * (HEIGHT + HEIGHT2) + 65
            BG.HistoryMoneyFrame:SetHeight(height)
            BG.HistoryMoneyFrame.bg:SetHeight(height + 50)
            BG.HistoryMoneyFrame:Show()
        end)
    end

    function BG.HideHistoryMoney()
        BG.HistoryMoneyUpdateFrame:SetScript("OnUpdate", nil)
        if BG.HistoryMoneyFrame then
            BG.HistoryMoneyFrame:Hide()
        end
    end
end
