if BG.IsBlackListPlayer then return end
local AddonName, ns = ...
local LibBG = ns.LibBG
local L = ns.L

local pt = print
local After = C_Timer.After
local _auctionID_ = "auctionID"

BG.Init(function()
    local FONT = BIAOGE_TEXT_FONT or STANDARD_TEXT_FONT
    local aura = BGA.aura_env

    local function IsAnonymousMoneyValid(f, money)
        money = tonumber(money)
        local currentMoney = tonumber(f.money) or 0
        if not money then return false end
        if f.start then return money >= currentMoney end
        for _, v in ipairs(aura.MiniMoneyTbl) do
            if not v[1] or currentMoney < v[1] then
                return money - currentMoney >= (v[3] or 0)
            end
        end
        return money > currentMoney
    end

    local function CreateMenuItem(menuFrame, text, onClickFuc)
        local bt = CreateFrame("Button", nil, menuFrame)
        bt:SetNormalFontObject(BGA.FontWhite15)
        bt:SetText(text)
        local fontString = bt:GetFontString()
        local width = fontString:GetWidth() + 30
        fontString:SetJustifyH("LEFT")
        bt:SetSize(width, 20)
        bt:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 0, -(#menuFrame.buttons * 20 + 10))
        bt.owner = menuFrame.owner
        tinsert(menuFrame.buttons, bt)
        menuFrame:SetHeight(#menuFrame.buttons * 20 + 20)
        menuFrame:SetWidth(max(width, menuFrame:GetWidth() or 0))
        if onClickFuc then
            fontString:SetTextColor(1, 1, 1)
            bt:SetScript("OnClick", function(self)
                onClickFuc(self)
                menuFrame:Hide()
            end)
            local tex = bt:CreateTexture()
            tex:SetAllPoints()
            tex:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
            tex:SetVertexColor(1, .82, 0)
            bt:SetHighlightTexture(tex)
        else
            fontString:SetTextColor(1, .82, 0)
            bt:Disable()
        end
        return bt
    end
    function aura.ShowMenu(self)
        local f = self.owner
        if f.menuFrame and f.menuFrame:IsVisible() then
            f.menuFrame:Hide()
            return
        end
        if not f.menuFrame then
            local menuFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
            menuFrame:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 16,
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            menuFrame:SetBackdropColor(0, 0, 0, 1)
            menuFrame:SetBackdropBorderColor(1, 1, 1, 1)
            menuFrame:SetFrameLevel(f:GetFrameLevel() + 20)
            menuFrame:SetPoint('BOTTOM', self, 'TOP', 0, -1)
            menuFrame:EnableMouse(true)
            menuFrame:SetClampedToScreen(true)
            menuFrame.buttons = {}
            menuFrame.owner = f
            f.menuFrame = menuFrame
            menuFrame:SetScript("OnUpdate", function()
                if not self:IsMouseOver() and not menuFrame:IsMouseOver() then
                    menuFrame:Hide()
                end
            end)
        end
        f.menuFrame:Show()
        for i = #f.menuFrame.buttons, 1, -1 do
            local bt = f.menuFrame.buttons[i]
            bt:Hide()
            bt:SetParent(nil)
            tremove(f.menuFrame.buttons, i)
        end
        CreateMenuItem(f.menuFrame, L["更多操作"])
        CreateMenuItem(f.menuFrame, L["取消拍卖"], aura.Cancel_OnClick)
        CreateMenuItem(f.menuFrame, f.isPaused and L["恢复拍卖"] or L["暂停拍卖"], aura.Pause_OnClick)
        for i, bt in ipairs(f.menuFrame.buttons) do
            local w = f.menuFrame:GetWidth()
            bt:SetWidth(w)
            bt:GetFontString():SetWidth(w - 30)
        end
    end

    -- 创建拍卖界面
    function aura.CreateAuction(auctionID, itemID, money, duration, player, mod, link, resetThreshold, isGen2)
        for _, f in pairs(BGA.Frames) do
            if f[_auctionID_] == auctionID then
                return
            end
        end

        local name, link, quality, level, _, itemType, itemSubType, _, itemEquipLoc, Texture,
        _, classID, subclassID, bindType = GetItemInfo(link or itemID)
        local AuctionFrame

        mod = isGen2 and mod or "normal"

        -- 主界面
        do
            local f = CreateFrame("Frame", nil, BGA.AuctionMainFrame, "BackdropTemplate")
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = aura.edgeSize,
            })
            f:SetBackdropColor(unpack(aura.backdropColor))
            f:SetBackdropBorderColor(unpack(aura.backdropBorderColor))
            f:SetSize(aura.WIDTH, aura.HEIGHT)
            if #BGA.Frames == 0 then
                f:SetPoint("TOP")
                f.num = 1
            else
                for i = 1, aura.maxNumFrame do
                    if not BGA.Frames[i] then
                        f.num = i
                        f:SetPoint("TOP", 0, -aura.GetFrameTotolHeight(f.num))
                        break
                    end
                end
            end
            f:EnableMouse(true)
            f[_auctionID_] = auctionID
            f.itemID = itemID
            f.link = link
            f.mod = mod
            f.logs = {}
            f.resetThreshold = resetThreshold
            f.isGen2 = isGen2
            f.monyStr = {}
            f.playerStr = {}
            f.winnerInfo = {}
            AuctionFrame = f
            BGA.Frames[f.num] = f
            f:SetScript("OnMouseUp", function(self)
                local mainFrame = BGA.AuctionMainFrame
                mainFrame:StopMovingOrSizing()
                if BiaoGe and BiaoGe.point then
                    BiaoGe.point.Auction = { mainFrame:GetPoint(1) }
                end
                mainFrame:SetScript("OnUpdate", nil)
            end)

            f:SetScript("OnMouseDown", function(self)
                if aura.lastFocus then
                    aura.lastFocus:ClearFocus()
                end
                if BiaoGe and BiaoGe.options and BiaoGe.options.auctionMoveByShift == 1
                    and not IsShiftKeyDown() then
                    return
                end
                local mainFrame = BGA.AuctionMainFrame
                mainFrame:StartMoving()
                mainFrame.time = 0
                mainFrame:SetScript("OnUpdate", function(self, time)
                    mainFrame.time = mainFrame.time + time
                    if mainFrame.time >= 0.2 then
                        mainFrame.time = 0
                        for _, f in pairs(BGA.Frames) do
                            if f.itemFrame.isOnEnter then
                                GameTooltip:Hide()
                                f.itemFrame:GetScript("OnEnter")(f.itemFrame)
                            end
                            if f.autoFrame:IsVisible() then
                                f.autoFrame:GetScript("OnShow")(f.autoFrame)
                            end
                        end
                    end
                end)
            end)

            f.cantClickFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
            f.cantClickFrame:SetAllPoints()
            f.cantClickFrame:SetFrameLevel(200)
            f.cantClickFrame:EnableMouse(true)
            After(.6, function()
                f.cantClickFrame:Hide()
            end)

            f.updateFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
            f.updateFrame:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
            })
            f.updateFrame:SetBackdropColor(1, 1, 1, .4)
            f.updateFrame:SetAllPoints()
            f.updateFrame:SetFrameLevel(150)
            f.updateFrame.alpha = .5
            f.updateFrame.totalTime = .4
            f.updateFrame:Hide()
            f.updateFrame:SetScript("OnShow", function(self)
                self.time = 0
                self:SetScript("OnUpdate", function(self, time)
                    self.time = self.time + time
                    local alpha = self.alpha - self.time / self.totalTime * self.alpha
                    if alpha < 0 then alpha = 0 end
                    self:SetAlpha(alpha)
                    f.autoFrame.updateFrame:SetAlpha(alpha)
                    if self:GetAlpha() <= 0 then
                        self:SetScript("OnUpdate", nil)
                        self:Hide()
                        f.autoFrame.updateFrame:Hide()
                    end
                end)
            end)
        end
        -- 自动出价
        do
            local f = CreateFrame("Frame", nil, AuctionFrame, "BackdropTemplate")
            do
                f:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = aura.edgeSize,
                })
                f:SetBackdropColor(unpack(aura.backdropColor))
                f:SetBackdropBorderColor(unpack(aura.backdropBorderColor))
                f:SetSize(120, 73)
                f:EnableMouse(true)
                f:Hide()
                f.owner = AuctionFrame
                AuctionFrame.autoFrame = f
                f:SetScript("OnShow", function(self)
                    f:ClearAllPoints()
                    if aura.IsRight(self) then
                        f:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMLEFT", 2, 0)
                    else
                        f:SetPoint("BOTTOMLEFT", AuctionFrame, "BOTTOMRIGHT", -2, 0)
                    end
                end)
                f:SetScript("OnMouseUp", function(self)
                    AuctionFrame:GetScript("OnMouseUp")(BGA.AuctionMainFrame)
                end)
                f:SetScript("OnMouseDown", function(self)
                    AuctionFrame:GetScript("OnMouseDown")(BGA.AuctionMainFrame)
                end)

                AuctionFrame.cantClickFrame.autoFrame = CreateFrame("Frame", nil, AuctionFrame.cantClickFrame, "BackdropTemplate")
                AuctionFrame.cantClickFrame.autoFrame:SetPoint("TOPLEFT", f, 0, 0)
                AuctionFrame.cantClickFrame.autoFrame:SetPoint("BOTTOMRIGHT", f, 0, 0)
                AuctionFrame.cantClickFrame.autoFrame:EnableMouse(true)
                After(.6, function()
                    AuctionFrame.cantClickFrame.autoFrame:Hide()
                end)

                f.updateFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
                f.updateFrame:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                })
                f.updateFrame:SetBackdropColor(1, 1, 1, .3)
                f.updateFrame:SetAllPoints()
                f.updateFrame:SetFrameLevel(150)
                f.updateFrame:Hide()
            end

            local t = f:CreateFontString()
            do
                t:SetFont(FONT, 15, "OUTLINE")
                t:SetPoint("TOP", 0, -8)
                t:SetTextColor(1, 0.82, 0)
                t:SetText(L["设置心理价格"])
                AuctionFrame.autoTitleText = t
            end

            local edit = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
            -- local edit = CreateFrame("EditBox", nil, f, "BackdropTemplate")
            do
                aura.SetEditBg(edit)
                edit:SetSize(f:GetWidth() - 30, 20)
                edit:SetPoint("BOTTOM", 2, 27)
                edit:SetAutoFocus(false)
                edit:SetNumeric(true)
                edit:SetMaxLetters(8)
                edit.owner = AuctionFrame
                edit.alpha = .3
                AuctionFrame.autoMoney = 0
                AuctionFrame.autoMoneyEdit = edit
                edit:SetScript("OnTextChanged", aura.Auto_OnTextChanged)
                edit:SetScript("OnEnterPressed", aura.AutoButton_OnClick)
                edit:SetScript("OnEnter", aura.AutoEdit_OnEnter)
                edit:SetScript("OnLeave", aura.OnLeave)
                edit:SetScript("OnEditFocusGained", aura.OnEditFocusGained)

                local f = CreateFrame("Frame", nil, edit)
                f:SetPoint("RIGHT", 12, 2)
                f:SetSize(25, 25)
                f:Hide()
                AuctionFrame.isAutoTex = f
                local tex = f:CreateTexture()
                tex:SetAllPoints()
                tex:SetTexture("interface/raidframe/readycheck-ready")
                tex:SetAlpha(1)
            end

            local bt = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
            do
                bt:SetPoint("BOTTOM", 0, 5)
                bt:SetSize(f:GetWidth() - 20, 22)
                bt:SetText(L["开启自动出价"])
                bt:Disable()
                bt.owner = AuctionFrame
                AuctionFrame.autoButton = bt
                bt:SetScript("OnClick", aura.AutoButton_OnClick)

                local disf = CreateFrame("Frame", nil, AuctionFrame.autoButton)
                disf:SetAllPoints()
                disf:Hide()
                disf.dis = true
                disf.owner = AuctionFrame
                disf:SetScript("OnEnter", aura.AutoButton_OnEnter)
                disf:SetScript("OnLeave", GameTooltip_Hide)
                AuctionFrame.autoButton.disf = disf
            end

            AuctionFrame.autoSendDelayFrame = CreateFrame("Frame", nil, AuctionFrame)
        end
        -- 操作
        do
            -- 折叠
            do
                local bt = CreateFrame("Button", nil, AuctionFrame)
                bt:SetNormalFontObject(BGA.FontGreen15)
                bt:SetHighlightFontObject(BGA.FontWhite15)
                bt:SetDisabledFontObject(BGA.FontDis15)
                bt:SetPoint("TOPRIGHT", -aura.edgeSize - 1, -2)
                bt:SetText(L["折叠"])
                bt:SetSize(bt:GetFontString():GetWidth(), 18)
                bt:SetFrameLevel(bt:GetParent():GetFrameLevel() + 15)
                bt:RegisterForClicks("AnyUp")
                bt.owner = AuctionFrame
                bt:SetScript("OnClick", aura.Hide_OnClick)
                bt:SetScript("OnEnter", aura.Hide_OnEnter)
                bt:SetScript("OnLeave", aura.OnLeave)
                AuctionFrame.hide = bt
            end

            -- 记录
            do
                local bt = CreateFrame("Button", nil, AuctionFrame)
                bt:SetNormalFontObject(BGA.FontGreen15)
                bt:SetHighlightFontObject(BGA.FontWhite15)
                bt:SetDisabledFontObject(BGA.FontDis15)
                bt:SetPoint("TOPLEFT", aura.edgeSize + 1, -2)
                bt:SetText(L["记录"])
                bt:SetSize(bt:GetFontString():GetWidth(), 18)
                bt.owner = AuctionFrame
                AuctionFrame.logTextButton = bt
                bt:SetScript("OnEnter", aura.LogTextButton_OnEnter)
                bt:SetScript("OnLeave", aura.OnLeave)
            end

            -- 取消拍卖
            do
                local bt = CreateFrame("Button", nil, AuctionFrame)
                bt:SetNormalFontObject(BGA.FontGreen15)
                bt:SetHighlightFontObject(BGA.FontWhite15)
                bt:SetDisabledFontObject(BGA.FontDis15)
                bt.owner = AuctionFrame
                AuctionFrame.cancelButton = bt
                bt:SetScript("OnClick", aura.Cancel_OnClick)
            end

            -- 暂停拍卖
            if AuctionFrame.isGen2 then
                local bt = CreateFrame("Button", nil, AuctionFrame)
                bt:SetNormalFontObject(BGA.FontGreen15)
                bt:SetHighlightFontObject(BGA.FontWhite15)
                bt:SetDisabledFontObject(BGA.FontDis15)
                bt:SetPoint("TOP", AuctionFrame, "TOPLEFT", aura.WIDTH / 10 * 5, -2)
                bt.owner = AuctionFrame
                AuctionFrame.puaseButton = bt
                bt:SetScript("OnClick", aura.Pause_OnClick)
            end

            -- 自动出价
            do
                local bt = CreateFrame("Button", nil, AuctionFrame)
                bt:SetNormalFontObject(BGA.FontGreen15)
                bt:SetHighlightFontObject(BGA.FontWhite15)
                bt:SetDisabledFontObject(BGA.FontDis15)
                bt.offset = aura.WIDTH / 10 * 6.4
                bt.owner = AuctionFrame
                AuctionFrame.autoTextButton = bt
                bt:SetScript("OnClick", aura.AutoText_OnClick)
            end
            aura.UpdateButtonState(AuctionFrame)
        end
        -- 装备显示
        do
            local f = CreateFrame("Frame", nil, AuctionFrame, "BackdropTemplate")
            f:SetPoint("TOPLEFT", f:GetParent(), "TOPLEFT", aura.edgeSize + 1, -AuctionFrame.hide:GetHeight() - 3)
            f:SetPoint("BOTTOMRIGHT", f:GetParent(), "TOPRIGHT", -aura.edgeSize, -55)
            f:SetFrameLevel(f:GetParent():GetFrameLevel() + 10)
            f.owner = AuctionFrame
            f.itemID = itemID
            f.link = link
            f:SetScript("OnEnter", aura.itemOnEnter)
            f:SetScript("OnLeave", aura.itemOnLeave)
            f:SetScript("OnMouseUp", function(self)
                AuctionFrame:GetScript("OnMouseUp")(BGA.AuctionMainFrame)
            end)
            f:SetScript("OnMouseDown", function(self)
                if IsShiftKeyDown() then
                    if not GetCurrentKeyBoardFocus() then
                        ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
                    end
                    ChatEdit_InsertLink(link)
                elseif IsControlKeyDown() then
                    DressUpItemLink(link)
                else
                    AuctionFrame:GetScript("OnMouseDown")(BGA.AuctionMainFrame)
                end
            end)
            AuctionFrame.itemFrame = f
            local f2 = CreateFrame("Frame", nil, f)
            AuctionFrame.itemFrame2 = f2
            -- 黑色背景
            local tex = f:CreateTexture(nil, "BACKGROUND")
            tex:SetAllPoints()
            tex:SetColorTexture(0, 0, 0, 0.5)
            AuctionFrame.itemFrame.bg = tex
            -- 图标
            local r, g, b = GetItemQualityColor(quality)
            local ftex = CreateFrame("Frame", nil, f, "BackdropTemplate")
            ftex:SetBackdrop({
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 2,
            })
            ftex:SetBackdropBorderColor(r, g, b, 1)
            ftex:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
            ftex:SetPoint("BOTTOMRIGHT", f, "TOPLEFT", f:GetHeight(), -f:GetHeight())
            ftex.tex = ftex:CreateTexture(nil, "BACKGROUND")
            ftex.tex:SetAllPoints()
            ftex.tex:SetTexture(Texture)
            ftex.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
            ftex.color = { r, g, b }
            AuctionFrame.itemFrame.iconFrame = ftex
            -- 装备等级
            local t = f2:CreateFontString()
            t:SetFont(FONT, 12, "OUTLINE")
            t:SetPoint("BOTTOM", ftex, "BOTTOM", 0, 1)
            t:SetText(level)
            t:SetTextColor(r, g, b)
            AuctionFrame.itemFrame.levelText = t
            -- 装绑
            if bindType == 2 then
                local t = f2:CreateFontString()
                t:SetFont(FONT, 11, "OUTLINE")
                t:SetPoint("TOP", ftex, 0, -2)
                t:SetText(L["装绑"])
                t:SetTextColor(0, 1, 0)
                AuctionFrame.itemFrame.bindTypeText = t
            end
            -- 装备名称
            local t = f:CreateFontString()
            t:SetFont(FONT, 15, "OUTLINE")
            t:SetPoint("TOPLEFT", ftex, "TOPRIGHT", 2, -2)
            t:SetWidth(f:GetWidth() - f:GetHeight() - 50)
            t:SetText(link:gsub("%[", ""):gsub("%]", ""))
            t:SetJustifyH("LEFT")
            t:SetWordWrap(false)
            AuctionFrame.itemFrame.itemNameText = t
            -- 已有
            if BG and BG.GetItemCount and BG.GetItemCount(itemID) ~= 0 or GetItemCount(itemID, true) ~= 0 then
                local tex = f2:CreateTexture(nil, 'ARTWORK')
                tex:SetSize(15, 15)
                tex:SetPoint('LEFT', t, 'LEFT', t:GetWrappedWidth(), 0)
                tex:SetTexture("interface/raidframe/readycheck-ready")
                local tex = ftex:CreateTexture(nil, 'ARTWORK')
                tex:SetAllPoints()
                tex:SetTexture("interface/raidframe/readycheck-ready")
                AuctionFrame.itemFrame.havedTex = tex
            end
            -- 装备类型
            local t = f2:CreateFontString()
            t:SetFont(FONT, 12, "OUTLINE")
            t:SetPoint("BOTTOMLEFT", ftex, "BOTTOMRIGHT", 2, 2)
            t:SetHeight(13)
            t:SetWidth(AuctionFrame.itemFrame.itemNameText:GetWidth())
            local classText = BG and BG.GetTooltipClassText and BG.GetTooltipClassText(itemID) or ""
            if _G[itemEquipLoc] then
                if classID == 2 then
                    t:SetText(itemSubType .. "  " .. classText)
                else
                    t:SetText(_G[itemEquipLoc] .. " " .. itemSubType .. "  " .. classText)
                end
            else
                t:SetText(classText)
            end
            t:SetJustifyH("LEFT")
            AuctionFrame.itemFrame.itemTypeText = t

            -- 倒计时条
            local s = CreateFrame("StatusBar", nil, f)
            s:SetPoint("TOPLEFT", ftex, "TOPRIGHT", 0, 0)
            s:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
            s:SetFrameLevel(s:GetParent():GetFrameLevel())
            s:SetStatusBarTexture("Interface/ChatFrame/ChatFrameBackground")
            s:SetStatusBarColor(1, 1, 0, 0.6)
            s:SetMinMaxValues(0, 1000)
            s.owner = AuctionFrame
            AuctionFrame.bar = s

            -- 剩余时间
            local remainingTime = f2:CreateFontString()
            remainingTime:SetFont(FONT, 15, "OUTLINE")
            remainingTime:SetPoint("RIGHT", f, "RIGHT", -5, 0)
            remainingTime:SetTextColor(1, 1, 1)
            AuctionFrame.remainingTime = remainingTime
        end
        -- 价格
        do
            local textwidth = 190
            local buttonwidth = 25
            local height = 22
            -- 当前价格
            local f = CreateFrame("Frame", nil, AuctionFrame)
            f:SetSize(textwidth, 20)
            f:SetPoint("TOPLEFT", AuctionFrame.itemFrame, "BOTTOMLEFT", 3, -3)
            f:SetFrameLevel(f:GetParent():GetFrameLevel() + 11)
            f:SetScript("OnMouseDown", aura.currentMoney_OnMouseDown)
            f:SetScript("OnMouseUp", aura.currentMoney_OnMouseUp)
            f.owner = AuctionFrame
            local t = f:CreateFontString()
            t:SetFont(FONT, 14, "OUTLINE")
            t:SetAllPoints()
            t:SetJustifyH("LEFT")
            if player and player ~= "" then
                t:SetText(L["|cffFFD100当前价格：|r"] .. aura.FormatNumber(money))
                AuctionFrame.start = false
            else
                t:SetText(L["|cffFFD100起拍价：|r"] .. aura.FormatNumber(money))
                AuctionFrame.start = true
            end
            local currentMoneyFrame = f
            AuctionFrame.currentMoneyFrame = f
            AuctionFrame.currentMoneyText = t
            AuctionFrame.money = money
            -- 出价最高者
            local f = CreateFrame("Frame", nil, currentMoneyFrame)
            f:SetSize(textwidth, height)
            f:SetPoint("TOPLEFT", currentMoneyFrame, "BOTTOMLEFT", 0, 0)
            local t = f:CreateFontString()
            t:SetFont(FONT, 14, "OUTLINE")
            t:SetAllPoints()
            t:SetJustifyH("LEFT")
            if player then
                AuctionFrame.player = player
                AuctionFrame.colorplayer = aura.SetClassCFF(player)
            end
            if player and player ~= "" then
                if player == aura.GN() then
                    t:SetText(L["|cffFFD100出价最高者：|r"] .. "|cff" .. aura.GREEN1 .. L[">> 你 <<"])
                    AuctionFrame:SetBackdropColor(unpack(aura.backdropColor_IsMe))
                    AuctionFrame:SetBackdropBorderColor(unpack(aura.backdropBorderColor_IsMe))
                    AuctionFrame.autoFrame:SetBackdropColor(unpack(aura.backdropColor_IsMe))
                    AuctionFrame.autoFrame:SetBackdropBorderColor(unpack(aura.backdropBorderColor_IsMe))
                else
                    if mod == "anonymous" then
                        t:SetText(L["|cffFFD100出价最高者：|r"] .. L["別人(匿名)"])
                    else
                        t:SetText(L["|cffFFD100出价最高者：|r"] .. AuctionFrame.colorplayer)
                    end
                    AuctionFrame:SetBackdropColor(unpack(aura.backdropColor))
                    AuctionFrame:SetBackdropBorderColor(unpack(aura.backdropBorderColor))
                    AuctionFrame.autoFrame:SetBackdropColor(unpack(aura.backdropColor))
                    AuctionFrame.autoFrame:SetBackdropBorderColor(unpack(aura.backdropBorderColor))
                end
            elseif mod == "anonymous" then
                t:SetText(L["|cffFFD100< 匿名模式 >|r"])
            end
            AuctionFrame.topMoneyFrame = f
            AuctionFrame.topMoneyText = t

            -- 输入框
            local edit = CreateFrame("EditBox", nil, currentMoneyFrame, "InputBoxTemplate")
            -- local edit = CreateFrame("EditBox", nil, currentMoneyFrame, "BackdropTemplate")
            aura.SetEditBg(edit)
            edit:SetSize(AuctionFrame:GetRight() - currentMoneyFrame:GetRight() - 3, 20)
            edit:SetPoint("TOPLEFT", currentMoneyFrame, "TOPRIGHT", 0, 0)
            edit:SetAutoFocus(false)
            edit:SetNumeric(true)
            edit:SetText(money)
            edit:SetMaxLetters(8)
            edit.owner = AuctionFrame
            edit:SetScript("OnTextChanged", aura.myMoney_OnTextChanged)
            edit:SetScript("OnEnterPressed", aura.SendMyMoney_OnClick)
            edit:SetScript("OnMouseWheel", aura.myMoney_OnMouseWheel)
            edit:SetScript("OnEnter", aura.myMoney_OnEnter)
            edit:SetScript("OnLeave", aura.OnLeave)
            edit:SetScript("OnEditFocusGained", aura.OnEditFocusGained)
            AuctionFrame.myMoneyEdit = edit
            -- 减
            local bt = CreateFrame("Button", nil, edit, "UIPanelButtonTemplate")
            bt:SetSize(buttonwidth, 22)
            bt:SetPoint("TOPLEFT", edit, "BOTTOMLEFT", -5, 0)
            bt:SetNormalFontObject(BGA.FontGold18)
            bt:SetDisabledFontObject(BGA.FontDis18)
            bt.owner = AuctionFrame
            bt.edit = edit
            bt._type = "-"
            bt:SetText(bt._type)
            bt:SetScript("OnMouseDown", aura.JiaJian_OnMouseDown)
            bt:SetScript("OnMouseUp", aura.JiaJian_OnMouseUp)
            bt:SetScript("OnClick", aura.JiaJian_OnClick)
            bt:SetScript("OnEnter", aura.JiaJian_OnEnter)
            bt:SetScript("OnLeave", aura.OnLeave)
            AuctionFrame.ButtonJian = bt
            -- 加
            local bt = CreateFrame("Button", nil, edit, "UIPanelButtonTemplate")
            bt:SetSize(buttonwidth, 22)
            bt:SetPoint("LEFT", AuctionFrame.ButtonJian, "RIGHT", 0, 0)
            bt:SetNormalFontObject(BGA.FontGold18)
            bt:SetDisabledFontObject(BGA.FontDis18)
            bt.owner = AuctionFrame
            bt.edit = edit
            bt._type = "+"
            bt:SetText(bt._type)
            bt:SetScript("OnMouseDown", aura.JiaJian_OnMouseDown)
            bt:SetScript("OnMouseUp", aura.JiaJian_OnMouseUp)
            bt:SetScript("OnClick", aura.JiaJian_OnClick)
            bt:SetScript("OnEnter", aura.JiaJian_OnEnter)
            bt:SetScript("OnLeave", aura.OnLeave)
            AuctionFrame.ButtonJia = bt
            -- 出价
            local bt = CreateFrame("Button", nil, edit, "UIPanelButtonTemplate")
            bt:SetPoint("TOPLEFT", AuctionFrame.ButtonJia, "TOPRIGHT", 0, 0)
            bt:SetPoint("BOTTOMRIGHT", edit, "BOTTOMRIGHT", 0, -height)
            bt:SetText(L["出价"])
            bt.owner = AuctionFrame
            bt.edit = edit
            bt.itemID = itemID
            AuctionFrame.ButtonSendMyMoney = bt
            bt:SetScript("OnClick", aura.SendMyMoney_OnClick)

            local f = CreateFrame("Frame", nil, bt)
            f:SetAllPoints()
            f:Hide()
            f.dis = true
            f.owner = AuctionFrame
            f:SetScript("OnEnter", aura.SendMyMoney_OnEnter)
            f:SetScript("OnLeave", GameTooltip_Hide)
            AuctionFrame.disf = f
            bt.disf = f

            aura.myMoney_OnTextChanged(AuctionFrame.myMoneyEdit)
        end

        aura.anim(AuctionFrame)
        aura.Auctioning(AuctionFrame, duration)

        if BG and BG.HookCreateAuction then
            BG.HookCreateAuction(AuctionFrame)
        end
    end

    -- 主界面
    do
        local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        f:SetSize(aura.WIDTH, aura.HEIGHT)
        if BiaoGe and BiaoGe.options and BiaoGe.options.autoAuctionFrameLevel then
            f:SetFrameStrata(BiaoGe.options.autoAuctionFrameLevel)
        else
            f:SetFrameStrata('HIGH')
        end
        f:SetClampedToScreen(true)
        f:SetFrameLevel(100)
        f:SetToplevel(true)
        f:SetMovable(true)
        f:SetScale(BiaoGe and BiaoGe.options and BiaoGe.options["autoAuctionScale"] or 0.9)
        BGA.AuctionMainFrame = f

        if BiaoGe and BiaoGe.point and BiaoGe.point.Auction then
            BiaoGe.point.Auction[2] = nil
            f:SetPoint(unpack(BiaoGe.point.Auction))
        else
            f:SetPoint("TOPRIGHT", -100, -200)
        end
    end

    local function GetTipsText(link)
        local tipsText = ""
        if BiaoGe.auctionPreset then
            local tbl = {}
            for _, FB in pairs(BG.FBtable) do
                if FB == BG.FB1 then
                    tinsert(tbl, 1, FB)
                else
                    tinsert(tbl, FB)
                end
            end
            local itemID = GetItemInfoInstant(link)
            for _, FB in ipairs(tbl) do
                local preset = BiaoGe.auctionPreset[FB]
                local text = preset and preset.money and preset.money[itemID .. "tips"]
                if text then
                    tipsText = " " .. L["团长："] .. text
                    break
                end
            end
        end
        return tipsText
    end
    --[[
1、我出价时，随机给2个团员私发出价消息，给自己名字生成一个随机字符作为代号。AnonymousMoney^auctionID^money^playerStr
2、这2个团员广播到大团。AnonymousMoney^auctionID^money^playerStr
3、大团收到这两条消息后，判定出价有效。记录玩家名playerStr
4、我和那2个团员倒计时结束后，发送AnonymousEnd^auctionID^玩家名
5、大团收到两条消息后，判定结束有效，显示结果


1、玩家A出价时，随机给两名团员B、C私发出价消息
2、B、C收到消息后匿名广播到大团，消息为只会说有人对某个装备出价多少
3、大团收到这两条相同的消息后（必须收到两条才算有效），判定出价有效，全团刷新该装备的价格
4、有其他人出价时，重复1-3步骤
4、拍卖倒计时为0时，A、B、C发送消息认领结果，消息为这件装备为A竞拍所得
5、大团收到两条相同的消息后（实际有三条消息，但只要有两条就算有效），判定结果有效，公布竞拍获胜者A
]]

    local function Event(self, event, ...)
        if event == "CHAT_MSG_ADDON" then
            local prefix, msg, distType, _, sender = ...
            local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10
            local isGen2
            if prefix == aura.AddonChannel then
                arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 = strsplit(",", msg, 8)
            elseif prefix:match(aura.AddonChannel2) then
                arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 = strsplit("^", msg)
                isGen2 = true
            end
            if not arg1 then return end
            -- pt(sender, msg)
            if arg1 == "StartAuction" and distType == "RAID" then
                local auctionID = tonumber(arg2)
                local itemID = tonumber(arg3)
                local money = tonumber(arg4)
                local duration = tonumber(arg5)
                local player = arg6
                local mod = arg7
                local link = arg8 ~= '' and arg8 or nil
                local resetThreshold = isGen2 and tonumber(arg9) or aura.REPEAT_TIME
                BG.OnItemLoad(link or itemID):ContinueOnItemLoad(function()
                    aura.CreateAuction(auctionID, itemID, money, duration, player, mod, link, resetThreshold, isGen2)
                    if aura.IsRaidLeader() then
                        local _, link = GetItemInfo(link or itemID)
                        local msg = format(L["{rt1}拍卖开始{rt1} %s 起拍价：%s"], link, money)
                        local tipsText = securecall(GetTipsText, link)
                        if tipsText then
                            if strlen(msg .. tipsText) < 255 then
                                msg = msg .. tipsText
                            end
                        end
                        SendChatMessage(msg, "RAID_WARNING")
                    end
                end)
            elseif arg1 == "CancelAuction" and distType == "RAID" then
                local auctionID = tonumber(arg2)
                for _, f in pairs(BGA.Frames) do
                    if f[_auctionID_] == auctionID and not f.IsEnd then
                        aura.SetEndState(f, L["拍卖取消"], 1, 0, 0)
                        if f.IsSmallWindow then
                            f.currentMoneyText:SetText("|cffFF0000" .. L["拍卖取消"])
                        end
                        if aura.IsRaidLeader() then
                            SendChatMessage(format(L["{rt7}拍卖取消{rt7} %s"], f.link), "RAID")
                        end
                        if BG and BG.AuctionWAEnd then
                            BG.AuctionWAEnd(3, f.link, f.player, f.money)
                        end

                        After(aura.HIDEFRAME_TIME, function()
                            aura.UpdateFrame(f)
                        end)
                        return
                    end
                end
            elseif arg1 == "PauseAuction" and distType == "RAID" then
                -- 暂停拍卖对所有相同ID的物品同时生效
                local itemID = tonumber(arg2)
                for _, f in pairs(BGA.Frames) do
                    if f.itemID == itemID and f.isGen2 and not f.IsEnd then
                        aura.PauseAuction(f)
                    end
                end
            elseif arg1 == "ResumeAuction" and distType == "RAID" then
                -- 恢复拍卖对所有相同ID的物品同时生效
                local itemID = tonumber(arg2)
                for _, f in pairs(BGA.Frames) do
                    if f.itemID == itemID and f.isGen2 and not f.IsEnd then
                        aura.ResumeAuction(f)
                    end
                end
            elseif arg1 == "SendMyMoney" and distType == "RAID" then
                local auctionID = tonumber(arg2)
                local money = tonumber(arg3)
                for _, f in pairs(BGA.Frames) do
                    if not f.IsEnd and not f.isPaused and f.mod ~= 'anonymous' and f[_auctionID_] == auctionID then
                        if f.start and money >= f.money or money > f.money then
                            aura.SetMoney(f, money, sender)
                        end
                        return
                    end
                end
            elseif arg1 == "VersionCheck" and distType == "RAID" then
                C_ChatInfo.SendAddonMessage(aura.AddonChannel, "MyVer" .. "," .. aura.ver, "RAID")
            elseif arg1 == "AnonymousWhisperMyMoney" and distType == "WHISPER" and UnitInRaid(sender) then
                local auctionID = tonumber(arg2)
                local money = tonumber(arg3)
                local playerID = arg4
                for _, f in pairs(BGA.Frames) do
                    if not f.IsEnd and not f.isPaused and f.mod == 'anonymous' and f[_auctionID_] == auctionID then
                        if IsAnonymousMoneyValid(f, money) then
                            local oldSender = f.playerStr[playerID]
                            if oldSender and oldSender ~= sender then return end
                            if f.player and f.player == playerID then return end
                            f._relayCD = f._relayCD or {}
                            local key = auctionID .. "-" .. sender
                            local now = GetTimePreciseSec()
                            if f._relayCD[key] and now - f._relayCD[key] < 0.3 then return end
                            f._relayCD[key] = now
                            f.playerStr[playerID] = sender
                            aura.SendAnonymousMessage(f, 'AnonymousSendMyMoney', auctionID, money, playerID)
                        end
                        return
                    end
                end
            elseif arg1 == "AnonymousSendMyMoney" and distType == "RAID" then
                local auctionID = tonumber(arg2)
                local money = tonumber(arg3)
                local playerID = arg4
                for _, f in pairs(BGA.Frames) do
                    if not f.IsEnd and not f.isPaused and f.mod == 'anonymous' and f[_auctionID_] == auctionID then
                        if f.start and money >= f.money or money > f.money then
                            f.monyStr[msg] = f.monyStr[msg] or { sender = {}, count = 0 }
                            if f.monyStr[msg].sender[sender] then return end
                            f.monyStr[msg].sender[sender] = true
                            f.monyStr[msg].count = f.monyStr[msg].count + 1
                            if f.monyStr[msg].count >= aura.GetAnonymousMinMan() then
                                wipe(f.winnerInfo)
                                wipe(f.monyStr)
                                aura.SetMoney(f, money, playerID)
                            end
                        end
                        return
                    end
                end
            elseif arg1 == "AnonymousWinner" and distType == "RAID" then
                local auctionID = tonumber(arg2)
                local winner = arg3
                for _, f in pairs(BGA.Frames) do
                    if f.mod == 'anonymous' and f[_auctionID_] == auctionID and winner and winner ~= "" then
                        f.winnerInfo[sender] = { winner = aura.GSN(winner), t = GetTimePreciseSec() }
                        return
                    end
                end
            end
        elseif event == "GROUP_ROSTER_UPDATE" then
            local canSend = aura.canSend()
            After(0.5, function()
                aura.UpdateRaidRosterInfo(canSend)
            end)
        elseif event == "PLAYER_ENTERING_WORLD" then
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            After(2, function()
                aura.UpdateRaidRosterInfo()
            end)
        elseif event == "MODIFIER_STATE_CHANGED" then
            local mod, type = ...
            if (mod == "LCTRL" or mod == "RCTRL") then
                if type == 1 then
                    if aura.itemIsOnEnter then
                        SetCursor("Interface/Cursor/Inspect")
                    end
                else
                    SetCursor(nil)
                end
            end
        elseif event == "CHAT_MSG_RAID_LEADER" then
            local msg = ...
            if aura.IsSecret(msg) then return end
            local zhuangbei, maijia, jine
            zhuangbei, maijia, jine = msg:match("{rt6}拍卖成功{rt6} (.-) (.-) (.+)")
            if not (zhuangbei and maijia and jine) then
                zhuangbei, maijia, jine = msg:match("{rt6}拍賣成功{rt6} (.-) (.-) (.+)")
            end
            if not (zhuangbei and maijia and jine) then
                zhuangbei, maijia, jine = msg:match("{rt6}Auction Successful{rt6} (.-) (.-) (.+)")
            end
            if (zhuangbei and maijia and jine) then
                return
            end

            zhuangbei = msg:match("{rt7}流拍{rt7} (.+)")
            if not zhuangbei then
                zhuangbei = msg:match("^{rt7}Auction Failed{rt7} (.+)$")
            end
            if zhuangbei then
                return
            end
        end
    end

    BGA.Event = CreateFrame("Frame")
    BGA.Event:RegisterEvent("CHAT_MSG_ADDON")
    BGA.Event:RegisterEvent("GROUP_ROSTER_UPDATE")
    BGA.Event:RegisterEvent("PLAYER_ENTERING_WORLD")
    BGA.Event:RegisterEvent("MODIFIER_STATE_CHANGED")
    BGA.Event:RegisterEvent("CHAT_MSG_RAID_LEADER")
    BGA.Event:SetScript("OnEvent", Event)
end)
