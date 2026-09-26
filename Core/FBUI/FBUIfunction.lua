local _, ns = ...
if BG.IsBlackListPlayer then return end

local LibBG = ns.LibBG
local L = ns.L

local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
local Size = ns.Size
local RGB = ns.RGB
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local Maxt = ns.Maxt
local Maxb = ns.Maxb
local BossNum = ns.BossNum
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID

local pt = print
local RealmId = GetRealmID()
local player = BG.myName

local p = {}
BG.Frame.p = p
local preWidget
local framedown
local frameright
local red, greed, blue = 1, 1, 1

------------------结算工资------------------
function BG.GetTotalIncome(FB)
    local FB = FB or BG.FB1
    local sum = 0
    for b = 1, Maxb[FB] do
        for i = 1, BG.GetMaxi(FB, b) do
            if BG.Frame[FB]["boss" .. b]["jine" .. i] then
                sum = sum + (tonumber(BG.Frame[FB]["boss" .. b]["jine" .. i]:GetText()) or 0)
            end
        end
    end
    return sum
end

function BG.GetTotalExpenditure(FB)
    local FB = FB or BG.FB1
    local sum = 0
    local b = Maxb[FB] + 1
    for i = 1, BG.GetMaxi(FB, b) do
        if BG.Frame[FB]["boss" .. b]["jine" .. i] then
            sum = sum + (tonumber(BG.Frame[FB]["boss" .. b]["jine" .. i]:GetText()) or 0)
        end
    end
    return sum
end

function BG.GetNetIncome(FB)
    local FB = FB or BG.FB1
    local totalIncome = tonumber(BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine1"]:GetText()) or 0
    local expenditure = tonumber(BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine2"]:GetText()) or 0
    return totalIncome - expenditure
end

function BG.GetWages(FB)
    local FB = FB or BG.FB1
    local netIncome = tonumber(BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine3"]:GetText()) or 0
    local num = tonumber(BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine4"]:GetText()) or 0
    local wages
    if BiaoGe.options["moLing"] == 1 then
        wages = math.modf(netIncome / num)
    else
        wages = format("%.2f", netIncome / num)
    end
    return wages
end

local function HighlightBiaoGeSameItems(itemID, self)
    local tbl = {}
    local FB = BG.FB1
    for b = 1, Maxb[FB] do
        for i = 1, BG.GetMaxi(FB, b) do
            local zb = BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]
            local jine = BG.Frame[FB]["boss" .. b]["jine" .. i]
            if zb then
                if itemID == GetItemID(zb:GetText()) then
                    tinsert(tbl, { zb = zb, jine = jine })
                end
            end
        end
    end
    if #tbl > 1 then
        local frame
        for i, v in ipairs(tbl) do
            frame = BG.CreateHighlightFrame(v.zb, nil, { 1, 0, 0, }, 4)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", v.zb, "TOPLEFT", 0, 0)
            frame:SetPoint("BOTTOMRIGHT", v.jine, "BOTTOMRIGHT", 0, 0)
        end
        local t = frame:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 20, "OUTLINE")
        t:SetPoint("RIGHT", self, "RIGHT", -2, 0)
        t:SetTextColor(1, 0, 0)
        t:SetText(#tbl)
    end
    tbl = nil
end

function BG.UpdateZhiChuPercent(zhuangbei, jine)
    local FB = BG.FB1
    zhuangbei:SetTextColor(0, 1, 0)
    jine:SetTextColor(0, 1, 0)
    zhuangbei.hasPercent = false
    jine.hasPercent = false
    if BiaoGe.options["zhichuPercent"] ~= 1 then return end

    local num = tonumber(zhuangbei:GetText():match("(%d+%.-%d-)%%"))
    if num then
        local text = floor(BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine1"]:GetText() * num * 0.01)
        if text == 0 then text = "" end
        jine:SetText(text)
        zhuangbei:SetTextColor(RGB("008000"))
        jine:SetTextColor(RGB("008000"))
        zhuangbei.hasPercent = num
        jine.hasPercent = num

        if zhuangbei.isEnter then
            zhuangbei:GetScript("OnEnter")(zhuangbei)
        end
        if jine.isEnter then
            jine:GetScript("OnEnter")(jine)
        end
        return
    end
    if zhuangbei.isEnter or jine.isEnter then
        GameTooltip:Hide()
    end
end

function BG.UpdateZhiChuMan(zhuangbei, jine)
    zhuangbei.hasMan = nil
    jine.hasMan = nil
    local num = tonumber(zhuangbei:GetText():match("(%d+)人"))
    if num and num ~= 0 then
        local money = tonumber(jine:GetText()) or 0
        local tbl = {
            num = num,
            money = money,
            avg = floor(money / num),
        }
        zhuangbei.hasMan = tbl
        jine.hasMan = tbl

        if zhuangbei.isEnter then
            zhuangbei:GetScript("OnEnter")(zhuangbei)
        end
        if jine.isEnter then
            jine:GetScript("OnEnter")(jine)
        end
        return
    end
    if zhuangbei.isEnter or jine.isEnter then
        GameTooltip:Hide()
    end
end

local function OnEnterZhiChuPercent(self)
    if self.hasPercent or self.hasMan then
        if BG.ButtonIsInRight(self) then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        end
        GameTooltip:ClearLines()
    end
    if self.hasPercent then
        GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
        GameTooltip:AddLine(format(L["该支出项含有百分比|cff00ff00（%s%%）|r，正在自动计算支出金额。"], self.hasPercent), 1, 0.82, 0, true)
        GameTooltip:AddLine(L["你可以通过删除支出项的百分比符号来取消自动计算，或者在表格设置里关闭该项功能。"], 0.5, 0.5, 0.5, true)
        if not self.hasMan then
            GameTooltip:Show()
        end
    end
    if self.hasMan then
        if self.hasPercent then
            GameTooltip:AddLine(" ", 1, 1, 1, true)
        end
        local money = self.hasMan.money
        local num = self.hasMan.num
        local avg = self.hasMan.avg
        GameTooltip:AddLine(L["该支出项含有人数"], 1, 1, 1, true)
        GameTooltip:AddLine(format(L["支出：%s"], money), 1, 0.82, 0, true)
        GameTooltip:AddLine(format(L["人数：%s人"], num), 1, 0.82, 0, true)
        GameTooltip:AddLine(format(L["每人：|cff00ff00%s|r"], avg), 1, 0.82, 0, true)
        GameTooltip:Show()
    end
end

local function ShowTardeHighLightItem(self)
    local b = self.bossnum
    local i = self.i
    local FB = BG.FB1
    local tradeInfo = BG.GetGeZiTardeInfo(FB, b, i)
    if tradeInfo then
        for _, v in ipairs(tradeInfo) do
            for b = 1, Maxb[FB] do
                for i = 1, BG.GetMaxi(FB, b) do
                    local zb = BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]
                    local jine = BG.Frame[FB]["boss" .. b]["jine" .. i]
                    if zb and FB == v.FB and b == v.b and i == v.i then
                        local f = BG.CreateHighlightFrame(zb, nil, { 0, 1, 0, 0.5 }, 4)
                        f:ClearAllPoints()
                        f:SetPoint("TOPLEFT", zb, "TOPLEFT", 0, 0)
                        f:SetPoint("BOTTOMRIGHT", jine, "BOTTOMRIGHT", 0, 0)
                        local t = f:CreateFontString()
                        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                        t:SetPoint("LEFT", jine, "RIGHT", 2, 0)
                        t:SetTextColor(0, 1, 0)
                        t:SetText(L["打包交易"])
                    end
                end
            end
        end
    end
end

local function UpdateCancelDelete(self, FB, b, i, type)
    if self:GetText() == "" then return end
    BG.cancelDelete = {}
    BG.cancelDelete.type = type
    BG.cancelDelete.bt = self
    BG.cancelDelete.FB = FB
    BG.cancelDelete.b = b
    BG.cancelDelete.i = i
    BG.cancelDelete.text = self:GetText()
    if type == "zhuangbei" then
        BG.cancelDelete.loot = BG.Copy(BiaoGe[FB]["boss" .. b]["loot" .. i])
        BG.cancelDelete.guanzhu = BiaoGe[FB]["boss" .. b]["guanzhu" .. i]
    elseif type == "maijia" then
        for k, v in pairs(BG.playerClass) do
            BG.cancelDelete[k] = BiaoGe[FB]["boss" .. b][k .. i]
        end
    elseif type == "jine" then
    end
    BG.ButtonCancelDelete:Show()
    if BG.ButtonCancelDelete.OnUpdate then
        BG.ButtonCancelDelete.OnUpdate:SetScript("OnUpdate", nil)
    end
    BG.ButtonCancelDelete.OnUpdate = BG.OnUpdateTime(function(self, elapsed)
        self.timeElapsed = self.timeElapsed + elapsed
        if self.timeElapsed >= 5 then
            self:SetScript("OnUpdate", nil)
            BG.ButtonCancelDelete:Hide()
        end
    end)
end

------------------标题------------------
function BG.FBTitleUI(FB, t)
    local fontsize = 15
    local parent = BG["Frame" .. FB]
    local version = parent:CreateFontString()
    if t == 1 then
        version:SetPoint("TOPLEFT", BG.MainFrame, "TOPLEFT", 13, -60)
    else
        version:SetPoint("TOPLEFT", frameright, "TOPLEFT", 100, 0)
    end
    version:SetFont(BIAOGE_TEXT_FONT, fontsize, "OUTLINE")
    version:SetTextColor(RGB(BG.y2))
    version:SetText(L["  项目"])
    preWidget = version

    local version = parent:CreateFontString()
    version:SetPoint("TOPLEFT", preWidget, "TOPLEFT", 70, 0)
    version:SetFont(BIAOGE_TEXT_FONT, fontsize, "OUTLINE")
    version:SetTextColor(RGB(BG.y2))
    version:SetText(BG.fakuanIsFirst[FB] and t == Maxt[FB] and L["事由"] or L["装备"])
    preWidget = version
    p.preWidget0 = version

    local version = parent:CreateFontString()
    version:SetPoint("TOPLEFT", preWidget, "TOPLEFT", BG.zhuangbeiWidth + 5, 0)
    version:SetFont(BIAOGE_TEXT_FONT, fontsize, "OUTLINE")
    version:SetTextColor(RGB(BG.y2))
    version:SetText(BG.fakuanIsFirst[FB] and t == Maxt[FB] and L["罚款人"] or L["买家"])
    preWidget = version

    local version = parent:CreateFontString()
    version:SetPoint("TOPLEFT", preWidget, "TOPLEFT", BG.maijiaWidth + 5, 0)
    version:SetFont(BIAOGE_TEXT_FONT, fontsize, "OUTLINE")
    version:SetTextColor(RGB(BG.y2))
    version:SetText(L["金额"])
    preWidget = version
    frameright = version
end

------------------装备------------------
function BG.AddHText(FB, itemText, itemID, bt)
    if FB == "ULD" and not itemText:match("H$") then
        for _, num in ipairs({ 10, 20 }) do
            for _, _itemID in ipairs(BG.Loot.ULD["Hard" .. num]) do
                if itemID == _itemID then
                    bt:SetText(itemText .. "H")
                    return true
                end
            end
        end
    elseif FB == "ICC" and not itemText:match("H$") then
        if itemID == 52030 or itemID == 52029 or itemID == 52028 then
            bt:SetText(itemText .. "H")
            return true
        end
    end
end

local updateFrame = CreateFrame("Frame")
local function OnTextChanged(self)
    local FB = self.FB
    local t = self.t
    local b = self.b
    local i = self.i
    local bossnum = self.bossnum
    local itemText = self:GetText()
    local itemID = GetItemID(itemText)
    if itemID then
        BG.OnItemLoad(itemText):ContinueOnItemLoad(function()
            local name, link, quality, level, _, _, _, _, _, Texture,
            _, typeID, _, bindType = GetItemInfo(itemText)
            BG.AddHText(FB, itemText, itemID, self)
            self.icon:SetTexture(Texture)
            BiaoGe[FB]["boss" .. bossnum]["itemLevel" .. i] = level
            BiaoGe[FB]["boss" .. bossnum]["bindOnEquip" .. i] = bindType == 2 and true or nil
            BG.BindOnEquip(self, bindType)
            BG.LevelText(self, level, typeID)
            BG.IsHave(self)
        end)
    else
        self.icon:SetTexture(nil)
        BiaoGe[FB]["boss" .. bossnum]["itemLevel" .. i] = nil
        BiaoGe[FB]["boss" .. bossnum]["bindOnEquip" .. i] = nil
        BG.BindOnEquip(self)
        BG.LevelText(self)
        BG.IsHave(self)
    end

    BG.UpdateFilter(self)

    if bossnum ~= Maxb[FB] and bossnum ~= Maxb[FB] + 1 and bossnum ~= Maxb[FB] + 2 then
        BG.DuiZhangFrame[FB]["boss" .. bossnum]["zhuangbei" .. i]:SetText(itemText)
        BG.DuiZhangFrame[FB]["boss" .. bossnum]["zhuangbei" .. i]:SetCursorPosition(0)
    end

    if itemText ~= "" then
        BiaoGe[FB]["boss" .. bossnum]["zhuangbei" .. i] = itemText
    else
        BiaoGe[FB]["boss" .. bossnum]["zhuangbei" .. i] = nil
        BiaoGe[FB]["boss" .. bossnum]["guanzhu" .. i] = nil
        BG.Frame[FB]["boss" .. bossnum]["guanzhu" .. i]:Hide()
        BiaoGe[FB]["boss" .. bossnum]["loot" .. i] = nil
    end

    -- 支出百分比
    if bossnum == Maxb[FB] + 1 then
        local jine = BG.Frame[FB]["boss" .. Maxb[FB] + 1]["jine" .. i]
        BG.UpdateZhiChuPercent(self, jine)
        BG.UpdateZhiChuMan(self, jine)
    end

    -- 更新未拍
    if BiaoGe.options.auctionLogChoose == 4 or BiaoGe.options.auctionLogChoose == 7 then
        updateFrame.t = 0
        updateFrame:SetScript("OnUpdate", function(self, t)
            self.t = self.t + t
            if self.t >= 0.1 then
                BG.UpdateAuctionLogFrame(nil, true)
                updateFrame:SetScript("OnUpdate", nil)
            end
        end)
    end
end
function BG.FBZhuangBeiUI(FB, t, b, bb, i, ii, scrollFrame)
    local parent = scrollFrame or BG["Frame" .. FB]
    local bossnum = BossNum(FB, b, t)
    local bt = CreateFrame("EditBox", nil, parent, BG.editTemplate)
    if bossnum <= Maxb[FB] then
        bt:SetSize(BG.zhuangbeiWidth, 20)
    else
        bt:SetSize(BG.zhuangbeiWidth2, 20)
    end
    bt:SetFrameLevel(110)
    if BG.zaxiang[FB] and bossnum == Maxb[FB] - 1 and i == BG.zaxiang[FB].i then
        bt:SetPoint("TOPLEFT", frameright, "TOPLEFT", 170, -18)
    else
        if scrollFrame and i == 1 then
            bt:SetPoint("TOPLEFT", scrollFrame, 5, 0)
        elseif b > 1 and i == 1 then
            bt:SetPoint("TOPLEFT", framedown, "BOTTOMLEFT", 0, BG.IsBigFB(FB) and -15 or -20)
        else
            if BG.zaxiang[FB] and bossnum == Maxb[FB] and i == 1 then
                bt:SetPoint("TOPLEFT", framedown, "BOTTOMLEFT", 0, BG.IsBigFB(FB) and -15 or -20)
            else
                bt:SetPoint("TOPLEFT", p["preWidget" .. i - 1], "BOTTOMLEFT", 0, BG.IsBigFB(FB) and 0 or -3)
            end
        end
    end
    bt:SetAutoFocus(false)
    BG.SetEditStickyFocus(bt)
    bt.FB = FB
    bt.bossnum = bossnum
    bt.t = t
    bt.b = b
    bt.i = i
    bt.type = "zhuangbei"
    bt.icon = bt:CreateTexture(nil, 'ARTWORK')
    bt.icon:SetPoint('LEFT', -22, 0)
    bt.icon:SetSize(16, 16)
    if BiaoGe[FB]["boss" .. bossnum]["zhuangbei" .. i] then
        if BiaoGe[FB]["boss" .. bossnum]["zhuangbei" .. i] ~= "" then
            bt:SetText(BiaoGe[FB]["boss" .. bossnum]["zhuangbei" .. i])
            bt:SetCursorPosition(0)
        else
            BiaoGe[FB]["boss" .. bossnum]["zhuangbei" .. i] = nil
        end
    end
    BG.Frame[FB]["boss" .. bossnum]["zhuangbei" .. i] = bt
    preWidget = bt
    p["preWidget" .. i] = bt
    framedown = p["preWidget" .. ii]
    --创建关注按钮
    bt.guanzhu = BG.CreateGuanZhuButton(bt, "biaoge")
    BG.Frame[FB]["boss" .. bossnum]["guanzhu" .. i] = bt.guanzhu

    if bt.bossnum == Maxb[FB] + 1 then
        BG.After(0, function()
            local jine = BG.Frame[FB]["boss" .. Maxb[FB] + 1]["jine" .. i]
            BG.UpdateZhiChuPercent(bt, jine)
            BG.UpdateZhiChuMan(bt, jine)
        end)
    end

    -- 内容改变时
    bt:SetScript("OnTextChanged", OnTextChanged)
    -- 鼠标按下时
    bt:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" and not IsAltKeyDown() and self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei" .. i] then
            UpdateCancelDelete(self, FB, bossnum, i, self.type)
            self:SetEnabled(false)
            self:SetText("")
            BG.Hide_AllHighlight()
            if BG.lastfocus then
                BG.lastfocus:ClearFocus()
            end
            return
        end
        if IsAltKeyDown() and IsControlKeyDown() and IsShiftKeyDown() and self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei" .. i] then
            self:SetEnabled(false)
            bt:ClearFocus()
            if BG.lastfocus then
                BG.lastfocus:ClearFocus()
            end
            BG.JiaoHuan(bt, FB, b, i, t)
            return
        end
        if BG.IsSetBestPriceKeyDown(button == "RightButton") and self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei" .. i] then
            if self:GetText() ~= "" then
                self:SetEnabled(false)
                bt:ClearFocus()
                if BG.lastfocus then
                    BG.lastfocus:ClearFocus()
                end
                BG.SetBestPrice(self:GetText(), self)
            end
            return
        end
        if IsShiftKeyDown() then
            if self:GetText() ~= "" then
                self:SetEnabled(false)
                bt:ClearFocus()
                BG.InsertLink(self:GetText())
            end
            return
        end
        if IsAltKeyDown() and self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei" .. i] and self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei" .. i] then
            if self:GetText() ~= "" then
                self:SetEnabled(false)
                bt:ClearFocus()
                if BG.lastfocus then
                    BG.lastfocus:ClearFocus()
                end
                if BG.IsML then -- 开始拍卖
                    local link = self:GetText()
                    BG.StartAuction(link, self, nil, nil, button == "RightButton")
                else -- 关注装备
                    if button ~= "RightButton" then
                        BG.SetGuanZhu(bt, 1)
                    end
                end
            end
            return
        end
        if IsControlKeyDown() then
            if self:GetText() ~= "" then
                self:SetEnabled(false)
                BG.GoToItemLib(self)
            end
            return
        end
    end)
    bt:SetScript("OnMouseUp", function(self, enter)
        if self:IsEnabled() then
            local infoType, itemID, itemLink = GetCursorInfo()
            if infoType == "item" then
                self:SetText(itemLink)
                self:ClearFocus()
                ClearCursor()
                if BG.FrameZhuangbeiList then
                    BG.FrameZhuangbeiList:Hide()
                end
                return
            end
        end
        if self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei" .. i] then
            self:SetEnabled(true)
        end
        if enter == "RightButton" and self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei" .. i] then
            self:SetEnabled(true)
        end
    end)
    -- 鼠标悬停在装备时
    BG.OnEnterDelay(bt, function(self)
        self.isEnter = true
        if bossnum ~= Maxb[FB] + 2 or (bossnum == Maxb[FB] + 2 and i == 4) then
            BG.FrameDs[FB .. 1]["boss" .. bossnum]["ds" .. i]:Show()
        end
        if not tonumber(self:GetText()) then
            local link = self:GetText()
            local itemID = GetItemID(link)
            BG.Show_AllHighlight(link, "biaoge")
            if itemID then
                if not BG.IsHideTooltipKeyDown() then
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
                    GameTooltip:AddLine(L['< 按住CTRL+SHIFT隐藏此界面 >'], 0, 1, 0, true)
                    GameTooltip:Show()
                    BG.SetZUGSetTooltip(itemID, point)
                end

                local _r, _g, _b = BG.Frame[FB]["boss" .. bossnum]["maijia" .. i]:GetTextColor()
                BG.SetHistoryMoney(
                    itemID,
                    BG.Frame[FB]["boss" .. bossnum]["jine" .. i]:GetText(),
                    BG.Frame[FB]["boss" .. bossnum]["maijia" .. i]:GetText(),
                    _r, _g, _b
                )

                HighlightBiaoGeSameItems(itemID, self)

                BG.DressUpLastButton = self
                if IsAltKeyDown() and IsControlKeyDown() then
                    SetCursor(nil)
                elseif IsControlKeyDown() and not IsShiftKeyDown() then
                    SetCursor("Interface/Cursor/Inspect")
                    BG.DressUp()
                elseif IsAltKeyDown() then
                    if BG.IsML then
                        if BiaoGe.options["autoAuctionStart"] == 1 then
                            SetCursor("interface/cursor/repair")
                        end
                    else
                        SetCursor("interface/cursor/quest")
                    end
                end
                BG.canShowTrunToItemLibCursor = true
                if BG.IsML then
                    BG.canShowStartAuctionCursor = true
                else
                    BG.canShowHopeCursor = true
                end
            end
        end
        OnEnterZhiChuPercent(self)
    end, BG.itemOnEnterDelay)
    BG.OnLeaveDelay(bt, function(self)
        self.isEnter = false
        BG.FrameDs[FB .. 1]["boss" .. bossnum]["ds" .. i]:Hide()
        GameTooltip:Hide()
        BG.HideHistoryMoney()
        BG.Hide_AllHighlight()
        SetCursor(nil)
        BG.canShowTrunToItemLibCursor = false
        BG.canShowStartAuctionCursor = false
        BG.canShowHopeCursor = false
        if BG.DressUpFrame then
            BG.DressUpFrame:Hide()
        end
        BG.DressUpLastButton = nil
    end)
    -- 获得光标时
    bt:SetScript("OnEditFocusGained", function(self)
        BG.FrameHide(1)
        self:HighlightText()
        BG.lastfocuszhuangbei = self
        BG.lastfocus = self

        local infoType, itemID, itemLink = GetCursorInfo()
        if infoType ~= "item" then -- 如果鼠标拿着物品则不会显示装备下拉列表
            BG.SetListzhuangbei(self)
        end

        if BG.Frame[FB]["boss" .. bossnum]["zhuangbei" .. i + 1] then
            BG.lastfocuszhuangbei2 = BG.Frame[FB]["boss" .. bossnum]["zhuangbei" .. i + 1]
        else
            BG.lastfocuszhuangbei2 = nil
        end
        BG.FrameDs[FB .. 2]["boss" .. bossnum]["ds" .. i]:Show()
    end)
    -- 失去光标时
    bt:SetScript("OnEditFocusLost", function(self)
        self:ClearHighlightText()
        BG.FrameDs[FB .. 2]["boss" .. bossnum]["ds" .. i]:Hide()
    end)
    -- 按TAB跳转右边
    bt:SetScript("OnTabPressed", function(self)
        local b = bossnum
        if BG.Frame[FB]["boss" .. b]["maijia" .. i]:IsVisible() then
            BG.Frame[FB]["boss" .. b]["maijia" .. i]:SetFocus()
        else
            BG.Frame[FB]["boss" .. b]["jine" .. i]:SetFocus()
        end
    end)
    -- 按ENTER
    bt:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if BG.FrameZhuangbeiList then
            BG.FrameZhuangbeiList:Hide()
        end
    end)
    -- 按箭头跳转
    bt:SetScript("OnKeyDown", function(self, enter)
        local bb = b
        local tt = t
        local b = bossnum
        if not IsModifierKeyDown() then
            if enter == "UP" then -- 上↑
                if BG.Frame[FB]["boss" .. b]["zhuangbei" .. i - 1] then
                    BG.Frame[FB]["boss" .. b]["zhuangbei" .. i - 1]:SetFocus()
                else
                    local b = b
                    if b == 1 then
                        b = Maxb[FB] + 2
                    end
                    local i
                    for ii = BG.GetMaxi(FB, b), 1, -1 do
                        if BG.Frame[FB]["boss" .. b - 1]["zhuangbei" .. ii] then
                            i = ii
                            break
                        end
                    end
                    BG.Frame[FB]["boss" .. b - 1]["zhuangbei" .. i]:SetFocus()
                end
            elseif enter == "DOWN" then -- 下↓
                if BG.Frame[FB]["boss" .. b]["zhuangbei" .. i + 1] then
                    BG.Frame[FB]["boss" .. b]["zhuangbei" .. i + 1]:SetFocus()
                else
                    local b = b
                    if b == Maxb[FB] + 1 then
                        b = 0
                    end
                    BG.Frame[FB]["boss" .. b + 1]["zhuangbei" .. 1]:SetFocus()
                end
                -- elseif enter == "LEFT" then  -- 左←
                --     BG.Frame[FB]["boss" .. b]["jine" .. i]:SetFocus()
                -- elseif enter == "RIGHT" then -- 右→
                --     if BG.Frame[FB]["boss" .. b]["maijia" .. i]:IsVisible() then
                --         BG.Frame[FB]["boss" .. b]["maijia" .. i]:SetFocus()
                --     else
                --         BG.Frame[FB]["boss" .. b]["jine" .. i]:SetFocus()
                --     end
            end
        else
            if enter == "UP" then -- 上↑
                local b = b
                if b == 1 then
                    b = Maxb[FB] + 2
                end
                if BG.Frame[FB]["boss" .. b - 1]["zhuangbei" .. i] then
                    BG.Frame[FB]["boss" .. b - 1]["zhuangbei" .. i]:SetFocus()
                else
                    local i
                    for ii = BG.GetMaxi(FB, b), 1, -1 do
                        if BG.Frame[FB]["boss" .. b - 1]["zhuangbei" .. ii] then
                            i = ii
                            break
                        end
                    end
                    BG.Frame[FB]["boss" .. b - 1]["zhuangbei" .. i]:SetFocus()
                end
            elseif enter == "DOWN" then -- 下↓
                local b = b
                if b == Maxb[FB] + 1 then
                    b = 0
                end
                if BG.Frame[FB]["boss" .. b + 1]["zhuangbei" .. i] then
                    BG.Frame[FB]["boss" .. b + 1]["zhuangbei" .. i]:SetFocus()
                else
                    local i
                    for ii = BG.GetMaxi(FB, b), 1, -1 do
                        if BG.Frame[FB]["boss" .. b + 1]["zhuangbei" .. ii] then
                            i = ii
                            break
                        end
                    end
                    BG.Frame[FB]["boss" .. b + 1]["zhuangbei" .. i]:SetFocus()
                end
            end
        end
    end)
    -- 按ESC退出
    bt:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        if BG.FrameZhuangbeiList then
            BG.FrameZhuangbeiList:Hide()
        end
    end)
    -- 复原按钮为可点击
    if bt ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei" .. i] then
        bt:SetScript("OnShow", function(self)
            bt:Enable()
        end)
    end
end

------------------买家------------------
local buyerMixin = {}
function buyerMixin:Clear()
    local FB = self.FB
    local b = self.bossnum
    local i = self.i
    local type = self.type
    BiaoGe[FB]["boss" .. b][type .. i] = nil
    for k, v in pairs(BG.playerClass) do
        BiaoGe[FB]["boss" .. b][k .. i] = nil
    end
    if self:GetText() ~= "" then
        self:SetText("")
    end
    self:SetTextColor(1, 1, 1)
end

function BG.FBMaiJiaUI(FB, t, b, bb, i, ii)
    local bt = CreateFrame("EditBox", nil, BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i],
        BG.editTemplate)
    bt:SetSize(BG.maijiaWidth, 20)
    bt:SetPoint("TOPLEFT", preWidget, "TOPRIGHT", 5, 0)
    bt:SetFrameLevel(110)
    bt:SetAutoFocus(false)
    BG.SetEditStickyFocus(bt)
    bt.FB = FB
    bt.bossnum = BossNum(FB, b, t)
    bt.t = t
    bt.b = b
    bt.i = i
    bt.type = "maijia"
    BG.SetMixin(bt, buyerMixin)
    local color = BiaoGe[FB]["boss" .. BossNum(FB, b, t)]["color" .. i]
    if color then
        if not (color[1] == 1 and color[2] == 1 and color[3] == 1) then
            bt:SetTextColor(unpack(color))
        else
            color = nil
        end
    end
    if BiaoGe[FB]["boss" .. BossNum(FB, b, t)]["maijia" .. i] then
        if BiaoGe[FB]["boss" .. BossNum(FB, b, t)]["maijia" .. i] ~= "" then
            bt:SetText(BiaoGe[FB]["boss" .. BossNum(FB, b, t)]["maijia" .. i])
            bt:SetCursorPosition(0)
        else
            BiaoGe[FB]["boss" .. BossNum(FB, b, t)]["maijia" .. i] = nil
        end
    end
    if BossNum(FB, b, t) <= Maxb[FB] then
        preWidget = bt
    else
        bt:Hide()
    end
    BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["maijia" .. i] = bt
    -- 当内容改变时
    bt:SetScript("OnTextChanged", function(self)
        if bt:GetText() ~= "" then
            BiaoGe[FB]["boss" .. BossNum(FB, b, t)]["maijia" .. i] = self:GetText()         -- 储存文本
            BiaoGe[FB]["boss" .. BossNum(FB, b, t)]["color" .. i] = { self:GetTextColor() } -- 储存颜色
        else
            BiaoGe[FB]["boss" .. BossNum(FB, b, t)]["maijia" .. i] = nil
            for k, v in pairs(BG.playerClass) do
                BiaoGe[FB]["boss" .. BossNum(FB, b, t)][k .. i] = nil
            end
            self:SetTextColor(1, 1, 1)
        end
    end)

    bt:SetScript("OnMouseDown", function(self, enter)
        if enter == "RightButton" and self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["maijia" .. i] then
            UpdateCancelDelete(self, FB, BossNum(FB, b, t), i, self.type)
            self:SetEnabled(false)
            self:SetText("")
            if BG.lastfocus then
                BG.lastfocus:ClearFocus()
            end
            return
        end
        if IsAltKeyDown() and IsControlKeyDown() and IsShiftKeyDown() and self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["maijia" .. i] then
            self:SetEnabled(false)
            bt:ClearFocus()
            if BG.lastfocus then
                BG.lastfocus:ClearFocus()
            end
            BG.JiaoHuan(bt, FB, b, i, t)
            return
        end
    end)
    bt:SetScript("OnMouseUp", function(self, enter)
        if self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["maijia" .. i] then
            self:SetEnabled(true)
        end
        if enter == "RightButton" and self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["maijia" .. i] then
            self:SetEnabled(true)
        end
    end)
    -- 悬停鼠标时
    bt:SetScript("OnEnter", function(self) -- 底色
        if BossNum(FB, b, t) ~= Maxb[FB] + 2 or (BossNum(FB, b, t) == Maxb[FB] + 2 and i == 4) then
            BG.FrameDs[FB .. 1]["boss" .. BossNum(FB, b, t)]["ds" .. i]:Show()
        end
    end)
    bt:SetScript("OnLeave", function(self)
        BG.FrameDs[FB .. 1]["boss" .. BossNum(FB, b, t)]["ds" .. i]:Hide()
    end)
    -- 获得光标时
    bt:SetScript("OnEditFocusGained", function(self)
        BG.FrameHide(1)
        bt:HighlightText()
        BG.lastfocus = self
        BG.maijiaButton = self
        BG.SetListmaijia(self)
        BG.FrameDs[FB .. 2]["boss" .. BossNum(FB, b, t)]["ds" .. i]:Show() -- 底色
        if BG.FrameAuctionMSGbg then
            BG.FrameAuctionMSG.item = BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i]:GetText()
            if BiaoGe.options["auctionChatHoldNew"] == 1 then
                BG.FrameAuctionMSG:ScrollToBottom()
            end
            if BiaoGe.options["auctionChat"] == 1 then
                BG.FrameAuctionMSGbg:Show()
            else
                BG.FrameAuctionMSGbg:Hide()
            end
            BG.FrameAuctionMSGbg:SetParent(BG.FrameMaijiaList)
            BG.FrameAuctionMSGbg:ClearAllPoints()
            BG.FrameAuctionMSGbg:SetPoint("TOPRIGHT", BG.FrameMaijiaList, "TOPLEFT", 2, 0)
        end
    end)
    -- 失去光标时
    bt:SetScript("OnEditFocusLost", function(self)
        self:ClearHighlightText()
        BG.FrameDs[FB .. 2]["boss" .. BossNum(FB, b, t)]["ds" .. i]:Hide()
    end)
    -- 按TAB跳转右边
    bt:SetScript("OnTabPressed", function(self)
        local b = BossNum(FB, b, t)
        BG.Frame[FB]["boss" .. b]["jine" .. i]:SetFocus()
    end)
    -- 按ENTER
    bt:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if BG.FrameMaijiaList then
            BG.FrameMaijiaList:Hide()
        end
    end)
    -- 按箭头跳转
    bt:SetScript("OnKeyDown", function(self, enter)
        local b = BossNum(FB, b, t)
        if not IsModifierKeyDown() then
            if enter == "UP" then -- 上↑
                if BG.Frame[FB]["boss" .. b]["maijia" .. i - 1] then
                    BG.Frame[FB]["boss" .. b]["maijia" .. i - 1]:SetFocus()
                else
                    local b = b
                    if b == 1 then
                        b = Maxb[FB] + 1
                    end
                    local i
                    for ii = BG.GetMaxi(FB, b), 1, -1 do
                        if BG.Frame[FB]["boss" .. b - 1]["maijia" .. ii] then
                            i = ii
                            break
                        end
                    end
                    BG.Frame[FB]["boss" .. b - 1]["maijia" .. i]:SetFocus()
                end
            elseif enter == "DOWN" then -- 下↓
                if BG.Frame[FB]["boss" .. b]["maijia" .. i + 1] then
                    BG.Frame[FB]["boss" .. b]["maijia" .. i + 1]:SetFocus()
                else
                    local b = b
                    if b == Maxb[FB] then
                        b = 0
                    end
                    BG.Frame[FB]["boss" .. b + 1]["maijia" .. 1]:SetFocus()
                end
            elseif enter == "LEFT" then  -- 左←
                BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]:SetFocus()
            elseif enter == "RIGHT" then -- 右→
                BG.Frame[FB]["boss" .. b]["jine" .. i]:SetFocus()
            end
        else
            if enter == "UP" then -- 上↑
                local b = b
                if b == 1 then
                    b = Maxb[FB] + 1
                end
                if BG.Frame[FB]["boss" .. b - 1]["maijia" .. i] then
                    BG.Frame[FB]["boss" .. b - 1]["maijia" .. i]:SetFocus()
                else
                    local i
                    for ii = BG.GetMaxi(FB, b), 1, -1 do
                        if BG.Frame[FB]["boss" .. b - 1]["maijia" .. ii] then
                            i = ii
                            break
                        end
                    end
                    BG.Frame[FB]["boss" .. b - 1]["maijia" .. i]:SetFocus()
                end
            elseif enter == "DOWN" then -- 下↓
                local b = b
                if b == Maxb[FB] then
                    b = 0
                end
                if BG.Frame[FB]["boss" .. b + 1]["maijia" .. i] then
                    BG.Frame[FB]["boss" .. b + 1]["maijia" .. i]:SetFocus()
                else
                    local i
                    for ii = BG.GetMaxi(FB, b), 1, -1 do
                        if BG.Frame[FB]["boss" .. b + 1]["maijia" .. ii] then
                            i = ii
                            break
                        end
                    end
                    BG.Frame[FB]["boss" .. b + 1]["maijia" .. i]:SetFocus()
                end
            end
        end
    end)
    -- 按ESC退出
    bt:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        if BG.FrameMaijiaList then
            BG.FrameMaijiaList:Hide()
        end
    end)
end

------------------金额------------------
local moneyMixin = {}
function moneyMixin:Clear()
    local FB = self.FB
    local b = self.bossnum
    local i = self.i
    local type = self.type
    BiaoGe[FB]["boss" .. b][type .. i] = nil
    if self:GetText() ~= "" then
        self:SetText("")
    end
end

function moneyMixin:ClearQK()
    local FB = self.FB
    local b = self.bossnum
    local i = self.i
    BiaoGe[FB]["boss" .. b]["qiankuan" .. i] = nil
    self.QKButton:Hide()
end

function BG.FBJinEUI(FB, t, b, bb, i, ii)
    local bt = CreateFrame("EditBox", nil, BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i],
        BG.editTemplate)
    bt:SetSize(BG.jineWidth, 20)
    bt:SetPoint("TOPLEFT", preWidget, "TOPRIGHT", 5, 0)
    bt:SetFrameLevel(110)
    bt:SetAutoFocus(false)
    BG.SetEditStickyFocus(bt)
    bt.FB = FB
    bt.bossnum = BossNum(FB, b, t)
    bt.t = t
    bt.b = b
    bt.i = i
    bt.type = "jine"
    BG.SetMixin(bt, moneyMixin)
    if BiaoGe[FB]["boss" .. BossNum(FB, b, t)]["jine" .. i] then
        if BiaoGe[FB]["boss" .. BossNum(FB, b, t)]["jine" .. i] ~= "" then
            bt:SetText(BiaoGe[FB]["boss" .. BossNum(FB, b, t)]["jine" .. i])
        else
            BiaoGe[FB]["boss" .. BossNum(FB, b, t)]["jine" .. i] = nil
        end
    end
    preWidget = bt
    BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["jine" .. i] = bt
    -- 创建欠款按钮
    local QKButton = BG.CreateQiankuanButton(bt, "biaoge")
    BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["qiankuan" .. i] = QKButton
    bt.QKButton = QKButton

    -- 当内容改变时
    bt:SetScript("OnTextChanged", function(self)
        local bossnum = self.bossnum

        if self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. 4] then
            BG.UpdateTwo0(self)
        end

        if bossnum ~= Maxb[FB] and bossnum ~= Maxb[FB] + 1 and bossnum ~= Maxb[FB] + 2 then
            BG.DuiZhangFrame[FB]["boss" .. BossNum(FB, b, t)]["myjine" .. i]:SetText(self:GetText())
        end

        if bt:GetText() ~= "" then
            BiaoGe[FB]["boss" .. BossNum(FB, b, t)]["jine" .. i] = bt:GetText() -- 储存文本
        else
            BiaoGe[FB]["boss" .. BossNum(FB, b, t)]["jine" .. i] = nil
        end
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine1"]:SetText(BG.GetTotalIncome())      -- 计算总收入
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine2"]:SetText(BG.GetTotalExpenditure()) -- 计算总支出
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine3"]:SetText(BG.GetNetIncome())        -- 计算净收入
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine5"]:SetText(BG.GetWages())            -- 计算人均工资

        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine1"]:SetCursorPosition(0)
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine2"]:SetCursorPosition(0)
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine3"]:SetCursorPosition(0)
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine5"]:SetCursorPosition(0)

        -- 罚款同步欠款
        if bossnum == Maxb[FB] and self:HasFocus() then
            BG.FrameQianKuanEdit:SetText(self:GetText())
        end

        -- 支出百分比
        if bossnum == Maxb[FB] + 1 then
            local zhuangbei = BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei" .. i]
            BG.UpdateZhiChuPercent(zhuangbei, self)
            BG.UpdateZhiChuMan(zhuangbei, self)
        end
        if self == BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine1"] then
            for i = 1, BG.GetMaxi(FB, Maxb[FB] + 1) do
                local zhuangbei = BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei" .. i]
                local jine = BG.Frame[FB]["boss" .. Maxb[FB] + 1]["jine" .. i]
                if zhuangbei then
                    BG.UpdateZhiChuPercent(zhuangbei, jine)
                end
            end
        end
    end)
    bt:SetScript("OnMouseDown", function(self, enter)
        if enter == "RightButton" and self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. i] then
            UpdateCancelDelete(self, FB, BossNum(FB, b, t), i, self.type)
            BG.FrameHide(1)
            self:SetEnabled(false)
            self:SetText("")
            return
        end
        if IsAltKeyDown() and IsControlKeyDown() and IsShiftKeyDown() and self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. i] then
            self:SetEnabled(false)
            bt:ClearFocus()
            if BG.lastfocus then
                BG.lastfocus:ClearFocus()
            end
            BG.JiaoHuan(bt, FB, b, i, t)
            return
        end
    end)
    bt:SetScript("OnMouseUp", function(self, enter)
        if self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. i] then
            self:SetEnabled(true)
        end
        if enter == "RightButton" and self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. i] then
            self:SetEnabled(true)
        end
    end)
    -- 悬停鼠标时
    bt:SetScript("OnEnter", function(self) -- 底色
        self.isEnter = true
        if BossNum(FB, b, t) ~= Maxb[FB] + 2 or (BossNum(FB, b, t) == Maxb[FB] + 2 and i == 4) then
            BG.FrameDs[FB .. 1]["boss" .. BossNum(FB, b, t)]["ds" .. i]:Show()
        end
        OnEnterZhiChuPercent(self)
        ShowTardeHighLightItem(self)
    end)
    bt:SetScript("OnLeave", function(self)
        self.isEnter = false
        BG.FrameDs[FB .. 1]["boss" .. BossNum(FB, b, t)]["ds" .. i]:Hide()
        GameTooltip:Hide()
        BG.Hide_AllHighlight()
    end)
    -- 获得光标时
    bt:SetScript("OnEditFocusGained", function(self)
        BG.FrameHide(1)
        bt:HighlightText()
        BG.lastfocus = self
        BG.maijiaButton = BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["maijia" .. i]
        BG.FrameDs[FB .. 2]["boss" .. BossNum(FB, b, t)]["ds" .. i]:Show() -- 底色
        if self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 1]["jine" .. i] and self ~= BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. i] then
            BG.SetListjine(self, FB, BossNum(FB, b, t), i)
            BG.CreateNumFrame(BG.FrameJineList)
        end
        if BG.FrameAuctionMSGbg then
            BG.FrameAuctionMSG.item = BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i]:GetText()
            if BiaoGe.options["auctionChatHoldNew"] == 1 then
                BG.FrameAuctionMSG:ScrollToBottom()
            end
            if BiaoGe.options["auctionChat"] == 1 then
                BG.FrameAuctionMSGbg:Show()
            else
                BG.FrameAuctionMSGbg:Hide()
            end
            BG.FrameAuctionMSGbg:SetParent(BG.FrameJineList)
            BG.FrameAuctionMSGbg:ClearAllPoints()
            BG.FrameAuctionMSGbg:SetPoint("TOPRIGHT", BG.FrameJineList, "TOPLEFT", 2, 0)
        end
    end)
    -- 失去光标时
    bt:SetScript("OnEditFocusLost", function(self)
        self:ClearHighlightText()
        BG.FrameDs[FB .. 2]["boss" .. BossNum(FB, b, t)]["ds" .. i]:Hide()
        -- if BG.FrameNumFrame then
        --     BG.FrameNumFrame:Hide()
        -- end
    end)
    -- 按TAB跳转下一行的装备
    bt:SetScript("OnTabPressed", function(self)
        local b = BossNum(FB, b, t)
        if BG.Frame[FB]["boss" .. b]["zhuangbei" .. i + 1] then
            BG.Frame[FB]["boss" .. b]["zhuangbei" .. i + 1]:SetFocus()
        elseif b + 1 ~= Maxb[FB] + 2 then
            BG.Frame[FB]["boss" .. b + 1]["zhuangbei" .. 1]:SetFocus()
        end
    end)
    -- 按ENTER
    bt:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if BG.FrameJineList then
            BG.FrameJineList:Hide()
        end
    end)
    -- 按ESC退出
    bt:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        if BG.FrameJineList then
            BG.FrameJineList:Hide()
        end
        -- BG.FramePaiMaiMsg:Hide()
    end)
    -- 按箭头跳转
    bt:SetScript("OnKeyDown", function(self, enter)
        local b = BossNum(FB, b, t)
        if not IsModifierKeyDown() then
            if enter == "UP" then -- 上↑
                if BG.Frame[FB]["boss" .. b]["jine" .. i - 1] then
                    BG.Frame[FB]["boss" .. b]["jine" .. i - 1]:SetFocus()
                else
                    local b = b
                    if b == 1 then
                        b = Maxb[FB] + 2
                    end
                    local i
                    for ii = BG.GetMaxi(FB, b), 1, -1 do
                        if BG.Frame[FB]["boss" .. b - 1]["jine" .. ii] then
                            i = ii
                            break
                        end
                    end
                    BG.Frame[FB]["boss" .. b - 1]["jine" .. i]:SetFocus()
                end
            elseif enter == "DOWN" then -- 下↓
                if BG.Frame[FB]["boss" .. b]["jine" .. i + 1] then
                    BG.Frame[FB]["boss" .. b]["jine" .. i + 1]:SetFocus()
                else
                    local b = b
                    if b == Maxb[FB] + 1 then
                        b = 0
                    end
                    BG.Frame[FB]["boss" .. b + 1]["jine" .. 1]:SetFocus()
                end
            elseif enter == "LEFT" then -- 左←
                if BG.Frame[FB]["boss" .. b]["maijia" .. i]:IsVisible() then
                    BG.Frame[FB]["boss" .. b]["maijia" .. i]:SetFocus()
                else
                    BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]:SetFocus()
                end
            elseif enter == "RIGHT" then -- 右→
                BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]:SetFocus()
            end
        else
            if enter == "UP" then -- 上↑
                local b = b
                if b == 1 then
                    b = Maxb[FB] + 2
                end
                if BG.Frame[FB]["boss" .. b - 1]["jine" .. i] then
                    BG.Frame[FB]["boss" .. b - 1]["jine" .. i]:SetFocus()
                else
                    local i
                    for ii = BG.GetMaxi(FB, b), 1, -1 do
                        if BG.Frame[FB]["boss" .. b - 1]["jine" .. ii] then
                            i = ii
                            break
                        end
                    end
                    BG.Frame[FB]["boss" .. b - 1]["jine" .. i]:SetFocus()
                end
            elseif enter == "DOWN" then -- 下↓
                local b = b
                if b == Maxb[FB] + 1 then
                    b = 0
                end
                if BG.Frame[FB]["boss" .. b + 1]["jine" .. i] then
                    BG.Frame[FB]["boss" .. b + 1]["jine" .. i]:SetFocus()
                else
                    local i
                    for ii = BG.GetMaxi(FB, b), 1, -1 do
                        if BG.Frame[FB]["boss" .. b + 1]["jine" .. ii] then
                            i = ii
                            break
                        end
                    end
                    BG.Frame[FB]["boss" .. b + 1]["jine" .. i]:SetFocus()
                end
            end
        end
    end)
end

------------------BOSS名字------------------
function BG.SetBossNamePoint(FB, boss, f)
    local text = f.text
    if ns.enUS then
        text:SetRotation(math.pi / 2)
        local strWidth = text:GetWidth()   -- 原文本宽度（旋转后变为高度）
        local strHeight = text:GetHeight() -- 原文本高度（旋转后变为宽度）
        local frameWidth = strHeight + 2
        local frameHeight = strWidth + 2
        if f then
            f:SetSize(frameWidth, frameHeight)
            text:SetPoint("CENTER", f, "CENTER", -5 - 8 * BG.Boss[FB]["boss" .. boss].nCount, -10)
        end
    else
        text:SetPoint("CENTER")
        f:SetSize(text:GetStringWidth() - 5, text:GetStringHeight())
    end
end

------------------支出模版------------------
local SetExpenditureTemplateBossName
do
    local expenditureTemplateFrame

    local function GetExpenditureTemplateDB()
        if type(BiaoGe.expenditureTemplate) ~= "table" then
            BiaoGe.expenditureTemplate = {}
        end
        local db = BiaoGe.expenditureTemplate
        if type(db.template) ~= "table" then
            db.template = {}
        end
        if #db.template == 0 then
            db.template[1] = {
                name = L["模版1"],
                detail = {},
            }
        end
        for i, template in ipairs(db.template) do
            if type(template) ~= "table" then
                db.template[i] = {
                    name = L["模版"] .. i,
                    detail = {},
                }
            else
                template.name = type(template.name) == "string" and template.name ~= "" and template.name or L["模版"] .. i
                template.detail = type(template.detail) == "table" and template.detail or {}
            end
        end
        db.lastChoose = tonumber(db.lastChoose) or 1
        db.lastChoose = max(1, min(floor(db.lastChoose), #db.template))
        return db
    end

    local function UseExpenditureTemplate(FB, choose)
        local db = GetExpenditureTemplateDB()
        local template = db.template[choose]
        if not template then return end

        local boss = Maxb[FB] + 1
        for i = 1, 20 do
            local name = BG.Frame[FB]["boss" .. boss]["zhuangbei" .. i]
            if name then
                name:SetText(template.detail["name" .. i] or "")
                local money = BG.Frame[FB]["boss" .. boss]["jine" .. i]
                money:SetText(template.detail["money" .. i] or "")
            end
        end
        BG.PlaySound(2)
    end

    local function ParseExpenditureTemplates(text)
        if not ns.IsBase64(text) then return end
        local ok, decoded = pcall(ns.Decode, text)
        if not ok or type(decoded) ~= "string" then return end

        local templates = {}
        decoded = decoded .. "^^"
        for templateName, detailStr in decoded:gmatch("([^@]+)@@([^%^]*)%^%^") do
            if templateName ~= "" then
                local template = {
                    name = templateName,
                    detail = {},
                }
                for i, name, money in detailStr:gmatch("(.-)¦(.-)¦(.-)&&") do
                    i = tonumber(i)
                    if i and i >= 1 and i <= 20 and (name ~= "" or money ~= "") then
                        template.detail["name" .. i] = name ~= "" and name or nil
                        template.detail["money" .. i] = money ~= "" and money or nil
                    end
                end
                tinsert(templates, template)
            end
        end
        if #templates > 0 then
            return templates
        end
    end

    local function CreateExpenditureTemplateFrame(anchor)
        local db = GetExpenditureTemplateDB()
        local mainFrame = CreateFrame("Frame", nil, BG.FBMainFrame, "BackdropTemplate")
        mainFrame:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 1,
        })
        mainFrame:SetBackdropColor(0, 0, 0, 0.9)
        mainFrame:SetBackdropBorderColor(1, 1, 1, .8)
        mainFrame:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -5, 0)
        mainFrame:SetFrameStrata("HIGH")
        mainFrame:SetClampedToScreen(true)
        mainFrame:SetFrameLevel(200)
        mainFrame:SetSize(430, 250)
        mainFrame:EnableMouse(true)
        mainFrame:SetMovable(true)
        mainFrame:Hide()
        mainFrame:SetScript("OnMouseUp", function(self)
            self:StopMovingOrSizing()
        end)
        mainFrame:SetScript("OnMouseDown", function(self)
            self:StartMoving()
        end)
        mainFrame.CloseButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
        mainFrame.CloseButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 2, 2)
        expenditureTemplateFrame = mainFrame
        BG.expenditureTemplateFrame = mainFrame

        local dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
        dropDown:SetPoint("TOPLEFT", -5, -7)
        LibBG:UIDropDownMenu_SetWidth(dropDown, 80)
        LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
        BG.dropDownToggle(dropDown)
        dropDown:SetScale(.95)
        mainFrame.dropDown = dropDown

        local function UpdateDropDownText()
            local pay = GetExpenditureTemplateDB()
            LibBG:UIDropDownMenu_SetText(dropDown, pay.template[pay.lastChoose].name)
        end

        local function UpdatePayText()
            local pay = GetExpenditureTemplateDB()
            local detail = pay.template[pay.lastChoose].detail
            for i = 1, 20 do
                mainFrame.Buttons["name" .. i]:SetText(detail["name" .. i] or "")
                mainFrame.Buttons["money" .. i]:SetText(detail["money" .. i] or "")
            end
        end
        mainFrame.UpdatePayText = UpdatePayText

        LibBG:UIDropDownMenu_Initialize(dropDown, function()
            local pay = GetExpenditureTemplateDB()
            for i, template in ipairs(pay.template) do
                local index = i
                local info = LibBG:UIDropDownMenu_CreateInfo()
                info.text = template.name
                info.checked = pay.lastChoose == index
                info.func = function()
                    pay.lastChoose = index
                    UpdateDropDownText()
                    UpdatePayText()
                end
                LibBG:UIDropDownMenu_AddButton(info)
            end
        end)

        local scroll = CreateFrame("ScrollFrame", nil, mainFrame, BG.scrollTemplate)
        scroll:SetWidth(mainFrame:GetWidth() - 35)
        scroll:SetHeight(mainFrame:GetHeight() - 60)
        scroll:SetPoint("TOPLEFT", 10, -55)
        BG.CreateSrollBarBackdrop(scroll.ScrollBar)
        BG.HookScrollBarShowOrHide(scroll)
        local child = CreateFrame("Frame", nil, scroll)
        child:SetSize(1, 1)
        scroll:SetScrollChild(child)

        mainFrame.Buttons = {}
        local function OnTextChanged(self)
            local pay = GetExpenditureTemplateDB()
            local text = self:GetText()
            local newText = text:gsub("¦", ""):gsub("%^", "")
            if self.kind == "money" then
                newText = newText:gsub("&&", "")
            end
            if newText ~= text then
                self:SetText(newText)
                return
            end
            pay.template[pay.lastChoose].detail[self.key] = text ~= "" and text or nil
        end
        local function OnTabPressed(self)
            local nextKey
            if self.kind == "name" then
                nextKey = "money" .. self.index
            elseif mainFrame.Buttons["name" .. (self.index + 1)] then
                nextKey = "name" .. (self.index + 1)
            end
            if nextKey then
                mainFrame.Buttons[nextKey]:SetFocus()
            end
        end
        local function OnKeyDown(self, key)
            local target
            if key == "UP" then
                target = mainFrame.Buttons[self.kind .. (self.index - 1)]
            elseif key == "DOWN" then
                target = mainFrame.Buttons[self.kind .. (self.index + 1)]
            elseif key == "LEFT" or key == "RIGHT" then
                local kind = self.kind == "name" and "money" or "name"
                target = mainFrame.Buttons[kind .. self.index]
            end
            if target then
                target:SetFocus()
            end
        end
        local function OnMouseDown(self, button)
            if button == "RightButton" then
                self:SetEnabled(false)
                self:SetText("")
            end
        end
        local function OnMouseUp(self)
            self:SetEnabled(true)
        end

        for i = 1, 20 do
            local name = CreateFrame("EditBox", nil, child, BG.editTemplate)
            name:SetSize(295, 20)
            name:SetAutoFocus(false)
            name:SetTextColor(0, 1, 0)
            name.kind = "name"
            name.index = i
            name.key = "name" .. i
            if i == 1 then
                name:SetPoint("TOPLEFT", 5, 0)
            else
                name:SetPoint("TOPLEFT", mainFrame.Buttons["name" .. (i - 1)], "BOTTOMLEFT")
            end
            mainFrame.Buttons[name.key] = name

            local money = CreateFrame("EditBox", nil, child, BG.editTemplate)
            money:SetSize(90, 20)
            money:SetAutoFocus(false)
            money:SetTextColor(0, 1, 0)
            money.kind = "money"
            money.index = i
            money.key = "money" .. i
            money:SetPoint("LEFT", name, "RIGHT", 5, 0)
            mainFrame.Buttons[money.key] = money

            for _, edit in ipairs({ name, money }) do
                edit:SetScript("OnTextChanged", OnTextChanged)
                edit:SetScript("OnEnterPressed", function(self)
                    self:ClearFocus()
                end)
                edit:SetScript("OnTabPressed", OnTabPressed)
                edit:SetScript("OnKeyDown", OnKeyDown)
                edit:SetScript("OnMouseDown", OnMouseDown)
                edit:SetScript("OnMouseUp", OnMouseUp)
            end
        end

        local title = scroll:CreateFontString()
        title:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        title:SetPoint("BOTTOMLEFT", scroll, "TOPLEFT", 5, 2)
        title:SetTextColor(1, .82, 0)
        title:SetText(L["支出项"])
        local moneyTitle = scroll:CreateFontString()
        moneyTitle:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        moneyTitle:SetPoint("BOTTOMLEFT", scroll, "TOPLEFT", 300, 2)
        moneyTitle:SetTextColor(1, .82, 0)
        moneyTitle:SetText(L["金额"])

        local function CreateTopButton(text, relative)
            local button = BG.CreateButton(mainFrame)
            button:SetSize(40, 25)
            button:SetPoint("LEFT", relative, "RIGHT", relative == dropDown and -5 or 1, relative == dropDown and 3 or 0)
            button:SetText(text)
            return button
        end

        mainFrame.newButton = CreateTopButton(L["新增"], dropDown)
        mainFrame.newButton:SetScript("OnClick", function()
            BG.PlaySound(1)
            local pay = GetExpenditureTemplateDB()
            local count = #pay.template + 1
            tinsert(pay.template, {
                name = L["模版"] .. count,
                detail = {},
            })
            pay.lastChoose = count
            UpdateDropDownText()
            UpdatePayText()
            mainFrame.deleteButton:UpdateState()
        end)

        mainFrame.copyButton = CreateTopButton(L["复制"], mainFrame.newButton)
        mainFrame.copyButton:SetScript("OnClick", function()
            BG.PlaySound(2)
            local pay = GetExpenditureTemplateDB()
            local source = pay.template[pay.lastChoose]
            local copy = {
                name = source.name .. L["复制"],
                detail = {},
            }
            for key, value in pairs(source.detail) do
                copy.detail[key] = value
            end
            tinsert(pay.template, copy)
            pay.lastChoose = #pay.template
            UpdateDropDownText()
            UpdatePayText()
            mainFrame.deleteButton:UpdateState()
        end)

        mainFrame.deleteButton = CreateTopButton(L["删除"], mainFrame.copyButton)
        mainFrame.deleteButton:SetScript("OnClick", function(self)
            local pay = GetExpenditureTemplateDB()
            local choose = pay.lastChoose
            StaticPopupDialogs["BiaoGe_ExpenditureTemplateDelete"] = {
                text = L["确认删除\"%s\"？"],
                button1 = L["是"],
                button2 = L["否"],
                OnAccept = function()
                    tremove(pay.template, choose)
                    pay.lastChoose = min(choose, #pay.template)
                    UpdateDropDownText()
                    UpdatePayText()
                    self:UpdateState()
                    LibBG:CloseDropDownMenus()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            StaticPopup_Show("BiaoGe_ExpenditureTemplateDelete", pay.template[choose].name)
        end)
        function mainFrame.deleteButton:UpdateState()
            self:SetEnabled(#GetExpenditureTemplateDB().template > 1)
        end

        mainFrame.changeButton = CreateTopButton(L["改名"], mainFrame.deleteButton)
        mainFrame.changeButton:SetScript("OnClick", function()
            local pay = GetExpenditureTemplateDB()
            StaticPopupDialogs["BiaoGe_ExpenditureTemplateRename"] = {
                text = L["正在更改\"%s\"的名字"],
                button1 = L["是"],
                button2 = L["否"],
                hasEditBox = true,
                editBoxWidth = 230,
                OnAccept = function(self)
                    local edit = self.EditBox or self.editBox
                    local text = edit:GetText():gsub("@", "")
                    if text ~= "" then
                        pay.template[pay.lastChoose].name = text
                        UpdateDropDownText()
                    end
                end,
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
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            local name = pay.template[pay.lastChoose].name
            StaticPopup_Show("BiaoGe_ExpenditureTemplateRename", name, nil, name)
        end)

        mainFrame.useButton = CreateTopButton(L["使用"], mainFrame.changeButton)
        mainFrame.useButton:SetScript("OnClick", function()
            UseExpenditureTemplate(mainFrame.FB, GetExpenditureTemplateDB().lastChoose)
        end)

        local function ShowExportImportPopup(titleText, descText, initialText, isImport)
            if mainFrame.exportImportPopup then
                mainFrame.exportImportPopup:Hide()
            end
            local popup = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
            mainFrame.exportImportPopup = popup
            popup:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            popup:SetBackdropColor(0, 0, 0, .9)
            popup:SetBackdropBorderColor(1, 1, 1, .8)
            popup:SetSize(310, mainFrame:GetHeight())
            popup:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", 1, 0)
            popup:EnableMouse(true)
            popup:SetFrameStrata("HIGH")
            popup:SetFrameLevel(mainFrame:GetFrameLevel() + 10)

            local titleTextFS = popup:CreateFontString()
            titleTextFS:SetPoint("TOP", 0, -10)
            titleTextFS:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            titleTextFS:SetTextColor(1, .82, 0)
            titleTextFS:SetText(titleText)
            local descTextFS = popup:CreateFontString()
            descTextFS:SetPoint("TOPLEFT", 10, -35)
            descTextFS:SetPoint("TOPRIGHT", -10, -35)
            descTextFS:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
            descTextFS:SetJustifyH("LEFT")
            descTextFS:SetText(descText)

            local editBG = CreateFrame("Frame", nil, popup, "BackdropTemplate")
            editBG:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            editBG:SetBackdropColor(0, 0, 0, .5)
            editBG:SetBackdropBorderColor(1, 1, 1, .5)
            editBG:SetPoint("TOPLEFT", 10, -55)
            editBG:SetPoint("BOTTOMRIGHT", -10, 45)
            local editScroll = CreateFrame("ScrollFrame", nil, editBG, BG.scrollTemplate)
            editScroll:SetPoint("TOPLEFT", 3, -2)
            editScroll:SetPoint("BOTTOMRIGHT", -24, 2)
            BG.CreateSrollBarBackdrop(editScroll.ScrollBar)
            BG.HookScrollBarShowOrHide(editScroll)
            local edit = CreateFrame("EditBox", nil, editScroll)
            edit:SetMultiLine(true)
            edit:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
            edit:SetWidth(editScroll:GetWidth())
            edit:SetText(initialText)
            edit:SetAutoFocus(false)
            BG.SetEditBaseClass(edit)
            editScroll:SetScrollChild(edit)
            popup:SetScript("OnMouseDown", function()
                edit:SetFocus()
            end)
            if not isImport then
                edit:SetScript("OnEditFocusGained", function(self)
                    self:HighlightText()
                end)
            end
            edit:SetFocus()

            if isImport then
                local clearCheck = CreateFrame("CheckButton", nil, popup, "UICheckButtonTemplate")
                clearCheck:SetPoint("BOTTOMLEFT", 12, 40)
                clearCheck.text:SetText(L["导入时清空现有模板"])
                clearCheck.text:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                clearCheck:SetChecked(GetExpenditureTemplateDB().importClearExisting)
                clearCheck:SetFrameLevel(popup:GetFrameLevel() + 5)
                clearCheck:SetScript("OnClick", function(self)
                    GetExpenditureTemplateDB().importClearExisting = self:GetChecked()
                end)

                local confirm = BG.CreateButton(popup)
                confirm:SetSize(80, 22)
                confirm:SetPoint("BOTTOM", -45, 12)
                confirm:SetText(L["确认导入"])
                confirm:SetScript("OnClick", function()
                    local templates = ParseExpenditureTemplates(edit:GetText())
                    if not templates then
                        BG.SendSystemMessage(L["未发现有效的模版数据或格式不正确。"])
                        return
                    end
                    local pay = GetExpenditureTemplateDB()
                    if clearCheck:GetChecked() then
                        pay.template = templates
                    else
                        for _, template in ipairs(templates) do
                            tinsert(pay.template, template)
                        end
                    end
                    pay.lastChoose = #pay.template
                    UpdateDropDownText()
                    UpdatePayText()
                    mainFrame.deleteButton:UpdateState()
                    BG.SendSystemMessage(format(L["成功导入%d个模版。"], #templates))
                    BG.PlaySound(2)
                    popup:Hide()
                end)

                local cancel = BG.CreateButton(popup)
                cancel:SetSize(80, 22)
                cancel:SetPoint("LEFT", confirm, "RIGHT", 10, 0)
                cancel:SetText(CANCEL)
                cancel:SetScript("OnClick", function()
                    popup:Hide()
                end)
            else
                local close = BG.CreateButton(popup)
                close:SetSize(80, 22)
                close:SetPoint("BOTTOM", 0, 12)
                close:SetText(CLOSE)
                close:SetScript("OnClick", function()
                    popup:Hide()
                end)
            end
        end

        mainFrame.exportButton = CreateTopButton(L["导出"], mainFrame.useButton)
        mainFrame.exportButton:SetScript("OnClick", function()
            BG.PlaySound(1)
            local data = {}
            for _, template in ipairs(GetExpenditureTemplateDB().template) do
                local details = {}
                for i = 1, 20 do
                    local name = template.detail["name" .. i]
                    local money = template.detail["money" .. i]
                    if name or money then
                        tinsert(details, format("%s¦%s¦%s&&", i, name or "", money or ""))
                    end
                end
                tinsert(data, format("%s@@%s", template.name, table.concat(details)))
            end
            if #data == 0 then
                BG.SendSystemMessage(L["模版为空，无数据可导出。"])
                return
            end
            ShowExportImportPopup(L["导出模版"], L["复制下方文本并保存"], ns.Encode(table.concat(data, "^^")), false)
        end)

        mainFrame.importButton = CreateTopButton(L["导入"], mainFrame.exportButton)
        mainFrame.importButton:SetScript("OnClick", function()
            BG.PlaySound(1)
            ShowExportImportPopup(L["导入模版"], L["粘贴之前导出的文本"], "", true)
        end)

        UpdateDropDownText()
        UpdatePayText()
        mainFrame.deleteButton:UpdateState()
        return mainFrame
    end

    local function OpenExpenditureTemplateFrame(anchor, FB)
        local mainFrame = expenditureTemplateFrame or CreateExpenditureTemplateFrame(anchor)
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -5, 0)
        mainFrame.FB = FB
        mainFrame.UpdatePayText()
        mainFrame:Show()
    end

    SetExpenditureTemplateBossName = function(FB, f)
        f:SetScript("OnMouseUp", function(self, button)
            if button == "RightButton" then
                local menu = {
                    {
                        text = L["支出模版"],
                        isTitle = true,
                        notCheckable = true,
                    },
                    {
                        text = L["管理模版"],
                        notCheckable = true,
                        func = function()
                            OpenExpenditureTemplateFrame(f, FB)
                        end,
                    },
                    {
                        text = "   ",
                        isTitle = true,
                        notCheckable = true,
                    },
                }
                local pay = GetExpenditureTemplateDB()
                for i, template in ipairs(pay.template) do
                    local index = i
                    tinsert(menu, {
                        text = L["使用："] .. template.name,
                        notCheckable = true,
                        func = function()
                            UseExpenditureTemplate(FB, index)
                        end,
                    })
                end
                tinsert(menu, {
                    text = "   ",
                    isTitle = true,
                    notCheckable = true,
                })
                tinsert(menu, {
                    text = CANCEL,
                    notCheckable = true,
                    func = LibBG.CloseDropDownMenus,
                })
                LibBG:EasyMenu(menu, BG.dropDown, f, f:GetWidth(), f:GetHeight(), "MENU", 2)
                GameTooltip:Hide()
            end
            local onMouseUp = BG.MainFrame:GetScript("OnMouseUp")
            if onMouseUp then
                onMouseUp(BG.MainFrame)
            end
        end)
        f:SetScript("OnMouseDown", function()
            local onMouseDown = BG.MainFrame:GetScript("OnMouseDown")
            if onMouseDown then
                onMouseDown(BG.MainFrame)
            end
        end)
        f:SetScript("OnEnter", function()
            GameTooltip:SetOwner(f, "ANCHOR_RIGHT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["支出"], 0, 1, 0)
            GameTooltip:AddLine(AddTexture("RIGHT") .. L["打开支出模版菜单"], 1, .82, 0)
            GameTooltip:Show()
            f.text:SetTextColor(1, 1, 1)
        end)
        f:SetScript("OnLeave", function()
            GameTooltip:Hide()
            f.text:SetTextColor(RGB(BG.Boss[FB]["boss" .. (Maxb[FB] + 1)].color))
        end)
    end
end

------------------罚款增强------------------
local SetFineEnhancementBossName
do
    local function ClearFine(FB)
        local boss = Maxb[FB]
        for i = 1, BG.Maxi + 10 do
            local frames = BG.Frame[FB]["boss" .. boss]
            if frames["zhuangbei" .. i] then
                frames["zhuangbei" .. i]:SetText("")
                frames["maijia" .. i]:SetText("")
                frames["jine" .. i]:SetText("")
                if frames["qiankuan" .. i] then
                    frames["qiankuan" .. i]:Hide()
                end
                if frames["guanzhu" .. i] then
                    frames["guanzhu" .. i]:Hide()
                end
            end

            local data = BiaoGe[FB]["boss" .. boss]
            data["zhuangbei" .. i] = nil
            data["maijia" .. i] = nil
            data["jine" .. i] = nil
            data["qiankuan" .. i] = nil
            data["guanzhu" .. i] = nil
            data["color" .. i] = nil
            data["loot" .. i] = nil
            data["itemLevel" .. i] = nil
            data["bindOnEquip" .. i] = nil
            for class in pairs(BG.playerClass) do
                data[class .. i] = nil
            end

            local duiZhangFB = BG.DuiZhangFrame and BG.DuiZhangFrame[FB]
            local duiZhangBoss = duiZhangFB and duiZhangFB["boss" .. boss]
            if duiZhangBoss and duiZhangBoss["zhuangbei" .. i] then
                duiZhangBoss["zhuangbei" .. i]:SetText("")
                duiZhangBoss["myjine" .. i]:SetText("")
            end
        end

        local frames = BG.Frame[FB]["boss" .. boss]
        if frames.time then
            frames.time:SetText("")
        end
        local data = BiaoGe[FB]["boss" .. boss]
        data.time = nil
        data.difficultyID = nil
    end

    local function MergeFine(FB)
        local boss = Maxb[FB]
        local merged = {}
        local withoutPlayer = {}

        for i = 1, BG.Maxi + 10 do
            local frames = BG.Frame[FB]["boss" .. boss]
            local nameFrame = frames["zhuangbei" .. i]
            if nameFrame then
                local description = nameFrame:GetText()
                local playerFrame = frames["maijia" .. i]
                local playerName = playerFrame:GetText()
                local money = tonumber(frames["jine" .. i]:GetText()) or 0
                local debt = tonumber(BiaoGe[FB]["boss" .. boss]["qiankuan" .. i]) or 0
                local color = { playerFrame:GetTextColor() }

                if playerName ~= "" then
                    local record = merged[playerName]
                    if not record then
                        merged[playerName] = {
                            description = description,
                            playerName = playerName,
                            money = money,
                            debt = debt,
                            color = color,
                        }
                    else
                        if description ~= "" and description ~= L["罚款"] then
                            record.description = record.description .. " " .. description
                        end
                        record.money = record.money + money
                        record.debt = record.debt + debt
                    end
                elseif description ~= "" or money ~= 0 or debt ~= 0 then
                    tinsert(withoutPlayer, {
                        description = description,
                        playerName = "",
                        money = money,
                        debt = debt,
                        color = color,
                    })
                end
            end
        end

        local records = {}
        for _, record in pairs(merged) do
            tinsert(records, record)
        end
        sort(records, function(a, b)
            if a.money == b.money then
                return a.playerName < b.playerName
            end
            return a.money > b.money
        end)
        for _, record in ipairs(withoutPlayer) do
            tinsert(records, record)
        end

        ClearFine(FB)
        for index, record in ipairs(records) do
            local frames = BG.Frame[FB]["boss" .. boss]
            local nameFrame = frames["zhuangbei" .. index]
            if not nameFrame then break end

            local playerFrame = frames["maijia" .. index]
            local moneyFrame = frames["jine" .. index]
            local money = record.money ~= 0 and record.money or ""
            nameFrame:SetText(record.description)
            playerFrame:SetText(record.playerName)
            playerFrame:SetTextColor(unpack(record.color))
            moneyFrame:SetText(money)

            local data = BiaoGe[FB]["boss" .. boss]
            data["zhuangbei" .. index] = record.description
            data["maijia" .. index] = record.playerName
            data["jine" .. index] = money
            data["color" .. index] = record.playerName ~= "" and record.color or nil
            if record.debt ~= 0 then
                data["qiankuan" .. index] = record.debt
                if frames["qiankuan" .. index] then
                    frames["qiankuan" .. index]:Show()
                end
            end
        end
        BG.PlaySound(2)
    end

    local function ShowClearFineDialog(FB)
        local dialogName = "BiaoGe_ClearFine"
        StaticPopupDialogs[dialogName] = {
            text = L["确定清空全部罚款？"],
            button1 = L["是"],
            button2 = L["否"],
            OnAccept = function()
                ClearFine(FB)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
        }
        StaticPopup_Show(dialogName)
    end

    SetFineEnhancementBossName = function(FB, f)
        f:SetScript("OnMouseUp", function(self, button)
            if button == "RightButton" then
                local menu = {
                    {
                        text = L["罚款"],
                        isTitle = true,
                        notCheckable = true,
                    },
                    {
                        text = L["合并罚款"],
                        notCheckable = true,
                        tooltipTitle = L["合并罚款"],
                        tooltipText = L["把相同玩家的多项罚款合并为一项，罚款内容、罚款金额和欠款都会合并一起。"],
                        tooltipOnButton = true,
                        func = function()
                            MergeFine(FB)
                        end,
                    },
                    {
                        text = L["清空罚款"],
                        notCheckable = true,
                        func = function()
                            ShowClearFineDialog(FB)
                        end,
                    },
                    {
                        text = "   ",
                        isTitle = true,
                        notCheckable = true,
                    },
                    {
                        text = CANCEL,
                        notCheckable = true,
                        func = LibBG.CloseDropDownMenus,
                    },
                }
                LibBG:EasyMenu(menu, BG.dropDown, f, f:GetWidth(), f:GetHeight(), "MENU", 2)
                GameTooltip:Hide()
            end
            local onMouseUp = BG.MainFrame:GetScript("OnMouseUp")
            if onMouseUp then
                onMouseUp(BG.MainFrame)
            end
        end)
        f:SetScript("OnMouseDown", function()
            local onMouseDown = BG.MainFrame:GetScript("OnMouseDown")
            if onMouseDown then
                onMouseDown(BG.MainFrame)
            end
        end)
        f:SetScript("OnEnter", function()
            GameTooltip:SetOwner(f, "ANCHOR_RIGHT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["罚款"], 0, 1, 0)
            GameTooltip:AddLine(AddTexture("RIGHT") .. L["打开罚款菜单"], 1, .82, 0)
            GameTooltip:Show()
            f.text:SetTextColor(1, 1, 1)
        end)
        f:SetScript("OnLeave", function()
            GameTooltip:Hide()
            f.text:SetTextColor(RGB(BG.Boss[FB]["boss" .. Maxb[FB]].color))
        end)
    end
end

function BG.BossNameUI(FB, t, b, bb, i, ii, frameName)
    local fontsize = 14
    local boss = BossNum(FB, b, t)
    local f = CreateFrame("Frame", nil, BG[frameName .. FB])
    if frameName and BG[frameName .. FB]["scrollFrame" .. boss] then
        f:SetPoint("TOP", BG[frameName .. FB]["scrollFrame" .. boss].owner, "TOPLEFT", -40, -2)
    else
        f:SetPoint("TOP", BG[frameName][FB]["boss" .. boss].zhuangbei1, "TOPLEFT", -45, -2)
    end
    f:SetSize(15, 40)
    f.text = f:CreateFontString()
    f.text:SetFont(BIAOGE_TEXT_FONT, fontsize, "OUTLINE")
    f.text:SetTextColor(RGB(BG.Boss[FB]["boss" .. boss].color))
    if frameName == "DuiZhangFrame" then
        if boss == Maxb[FB] then
            f.text:SetText(BG.STC_r1(BG.FormatBossName(L["我漏记的装备"])))
        elseif boss == Maxb[FB] + 1 then
            f.text:SetText(BG.STC_g1(BG.FormatBossName(L["总结"])))
        else
            f.text:SetText(BG.Boss[FB]["boss" .. boss].name)
        end
    else
        f.text:SetText(BG.Boss[FB]["boss" .. boss].name)
    end
    BG.SetBossNamePoint(FB, boss, f)
    BG[frameName][FB]["boss" .. boss].bossName = f
    if frameName == "Frame" and boss <= Maxb[FB] - 1 then
        f:SetWidth(25)
        f:SetScript("OnMouseUp", function(self)
            local preset = BiaoGe.auctionPreset and BiaoGe.auctionPreset[FB]
            if BG.IsML and IsAltKeyDown() and preset and preset.money and not self.auctionPresetCD then
                self.auctionPresetCD = true
                BG.After(0.5, function()
                    self.auctionPresetCD = nil
                end)
                BG.PlaySound(1)

                local items = {}
                for i = 1, BG.Maxi do
                    local item = BG.Frame[FB]["boss" .. boss]["zhuangbei" .. i]
                    if item then
                        local link = item:GetText()
                        local itemID = BG.GetLeiTingItem(GetItemID(link))
                        if itemID and preset.money[itemID] then
                            tinsert(items, { link, item })
                        end
                    end
                end
                for index, item in ipairs(items) do
                    local link, anchor = item[1], item[2]
                    BG.After(index - 1, function()
                        BG.StartAuction(link, anchor, nil, nil, true, true)
                    end)
                end
            end

            if FB == "ICC" and boss <= Maxb[FB] - 2 and IsShiftKeyDown() then
                BG.ClickTabButton(BG.BossMainFrameTabNum)
                for i, v in ipairs(BG["BossTabButtons" .. FB]) do
                    v:Enable()
                    v.spellScrollFrame:Hide()
                    v.classScrollFrame:Hide()
                end
                BG["BossTabButtons" .. FB][boss]:Disable()
                BG["BossTabButtons" .. FB][boss].spellScrollFrame:Show()
                BG["BossTabButtons" .. FB][boss].classScrollFrame:Show()
                BiaoGe.BossFrame[FB].lastFrame = boss
                BG.PlaySound(1)
            end
            BG.MainFrame:GetScript("OnMouseUp")(BG.MainFrame)
        end)
        f:SetScript("OnMouseDown", function(self)
            BG.MainFrame:GetScript("OnMouseDown")(BG.MainFrame)
        end)
        f:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
            GameTooltip:ClearLines()
            local showTooltip
            local preset = BiaoGe.auctionPreset and BiaoGe.auctionPreset[FB]
            if BG.IsML and preset and preset.money then
                showTooltip = true
                GameTooltip:AddLine("|cff" .. BG.Boss[FB]["boss" .. boss].color .. BG.Boss[FB]["boss" .. boss].name2 .. RR)
                GameTooltip:AddLine(L["ALT+点击：按预设价全部开拍"], 1, .82, 0)
                local hasItem
                for i = 1, BG.Maxi do
                    local item = BG.Frame[FB]["boss" .. boss]["zhuangbei" .. i]
                    if item then
                        local link = item:GetText()
                        local itemID = BG.GetLeiTingItem(GetItemID(link))
                        if itemID then
                            hasItem = true
                            local icon = select(5, GetItemInfoInstant(itemID))
                            local money = preset.money[itemID]
                            if money then
                                GameTooltip:AddLine(AddTexture(icon) .. link .. L["："] .. money)
                            else
                                GameTooltip:AddLine(AddTexture(icon) .. link .. L["："] .. BG.STC_r1(L["没有预设价"]))
                            end
                        end
                    end
                end
                if not hasItem then
                    GameTooltip:AddLine(BG.STC_r1(L["装备栏是空的"]))
                end
            end
            if FB == "ICC" and boss <= Maxb[FB] - 2 then
                if not showTooltip then
                    GameTooltip:AddLine("|cff" .. BG.Boss[FB]["boss" .. boss].color .. BG.Boss[FB]["boss" .. boss].name2 .. RR)
                end
                showTooltip = true
                GameTooltip:AddLine(L["SHIFT+点击：查看该BOSS攻略"], 1, .82, 0)
            end
            if showTooltip then
                GameTooltip:Show()
                f.text:SetTextColor(1, 1, 1)
            end
        end)
        f:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            f.text:SetTextColor(RGB(BG.Boss[FB]["boss" .. boss].color))
        end)
    elseif frameName == "Frame" and boss == Maxb[FB] then
        SetFineEnhancementBossName(FB, f)
    elseif frameName == "Frame" and boss == Maxb[FB] + 1 then
        SetExpenditureTemplateBossName(FB, f)
    end

    if not ns.enUS and BG[frameName][FB]["boss" .. boss] == BG[frameName][FB]["boss" .. Maxb[FB] + 2] then
        local f = CreateFrame("Frame", nil, BG[frameName .. FB])
        f:SetPoint("BOTTOM", BG[frameName][FB]["boss" .. Maxb[FB] + 2].zhuangbei5, "BOTTOMLEFT", -45, 7)
        f.text = f:CreateFontString()
        f.text:SetFont(BIAOGE_TEXT_FONT, fontsize, "OUTLINE")
        f.text:SetTextColor(RGB("00BFFF"))
        f.text:SetText(L["工\n资"])
        BG.SetBossNamePoint(FB, boss, f)
    end
end

------------------底色材质------------------
function BG.FBDiSeUI(FB, t, b, bb, i, ii)
    -- 先做底色材质1（鼠标悬停的）
    local textrue = BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i]:CreateTexture()
    textrue:SetPoint("TOPLEFT", BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i], "TOPLEFT", -4, -2)
    textrue:SetPoint("BOTTOMRIGHT", BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["jine" .. i], "BOTTOMRIGHT", -2, 0)
    textrue:SetColorTexture(red, greed, blue, BG.onEnterAlpha)
    textrue:Hide()
    BG.FrameDs[FB .. 1]["boss" .. BossNum(FB, b, t)]["ds" .. i] = textrue

    -- 底色材质2（点击框体后）
    local textrue = BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i]:CreateTexture()
    textrue:SetPoint("TOPLEFT", BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i], "TOPLEFT", -4, -2)
    textrue:SetPoint("BOTTOMRIGHT", BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["jine" .. i], "BOTTOMRIGHT", -2, 0)
    textrue:SetColorTexture(red, greed, blue, BG.onEnterAlpha)
    textrue:Hide()
    BG.FrameDs[FB .. 2]["boss" .. BossNum(FB, b, t)]["ds" .. i] = textrue

    -- 底色材质3（团长发的装备高亮）
    local textrue = BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i]:CreateTexture()
    textrue:SetPoint("TOPLEFT", BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i], "TOPLEFT", -4, -2)
    textrue:SetPoint("BOTTOMRIGHT", BG.Frame[FB]["boss" .. BossNum(FB, b, t)]["jine" .. i], "BOTTOMRIGHT", -2, 0)
    textrue:SetColorTexture(1, 1, 0, BG.highLightAlpha)
    textrue:Hide()
    BG.FrameDs[FB .. 3]["boss" .. BossNum(FB, b, t)]["ds" .. i] = textrue
end

------------------支出、总览、工资------------------
function BG.FBZhiChuZongLanGongZiUI(FB)
    -- 初始化支出内容
    if not BiaoGe[FB]["boss" .. Maxb[FB] + 1]["zhuangbei1"] then
        BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei1"]:SetText(L["T补贴"])
    end
    if not BiaoGe[FB]["boss" .. Maxb[FB] + 1]["zhuangbei2"] then
        BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei2"]:SetText(L["N补贴"])
    end
    if not BiaoGe[FB]["boss" .. Maxb[FB] + 1]["zhuangbei3"] then
        BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei3"]:SetText(L["DPS补贴"])
    end
    if BG.IsWLK then
        if not BiaoGe[FB]["boss" .. Maxb[FB] + 1]["zhuangbei4"] then
            BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei4"]:SetText(L["放鱼补贴"])
        end
    end
    -- 设置支出颜色：绿
    for i = 1, BG.GetMaxi(FB, Maxb[FB] + 1), 1 do
        if BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei" .. i] then
            BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei" .. i]:SetTextColor(RGB("00FF00"))
            BG.Frame[FB]["boss" .. Maxb[FB] + 1]["jine" .. i]:SetTextColor(RGB("00FF00"))
        end
    end

    -- 总览和工资
    BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei1"]:SetScript("OnTextChanged", function(self)
        self:SetText(L["总收入"])
        BiaoGe[FB]["boss" .. Maxb[FB] + 2]["zhuangbei1"] = self:GetText()
    end)
    BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei2"]:SetScript("OnTextChanged", function(self)
        self:SetText(L["总支出"])
        BiaoGe[FB]["boss" .. Maxb[FB] + 2]["zhuangbei2"] = self:GetText()
    end)
    BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei3"]:SetScript("OnTextChanged", function(self)
        self:SetText(L["净收入"])
        BiaoGe[FB]["boss" .. Maxb[FB] + 2]["zhuangbei3"] = self:GetText()
    end)
    BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei4"]:SetScript("OnTextChanged", function(self)
        self:SetText(L["分钱人数"])
        BiaoGe[FB]["boss" .. Maxb[FB] + 2]["zhuangbei4"] = self:GetText()
    end)
    BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei5"]:SetScript("OnTextChanged", function(self)
        self:SetText(L["人均工资"])
        BiaoGe[FB]["boss" .. Maxb[FB] + 2]["zhuangbei5"] = self:GetText()
    end)
    if BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine4"]:GetText() == "" then
        if BG.IsVanilla then
            BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine4"]:SetText(BG.GetFBinfo(FB, "maxplayers") or "40")
        else
            BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine4"]:SetText(BG.GetFBinfo(FB, "maxplayers") or "25")
        end
    end
    for i = 1, 5, 1 do
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei" .. i]:SetEnabled(false)
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["maijia" .. i]:SetEnabled(false)
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. i]:SetEnabled(false)
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. i]:SetCursorPosition(0)
    end
    BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine4"]:SetEnabled(true)
    -- 设置总览颜色：粉
    for i = 1, 3, 1 do
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei" .. i]:SetTextColor(RGB("EE82EE"))
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. i]:SetTextColor(RGB("EE82EE"))
    end
    -- 设置工资颜色：蓝
    for i = 4, 5, 1 do
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei" .. i]:SetTextColor(RGB("00BFFF"))
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. i]:SetTextColor(RGB("00BFFF"))
    end
    -- 设置工资人数的鼠标提示
    local function OnEnter(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
        GameTooltip:ClearLines()
        GameTooltip:SetText(L["人数可自行修改"])
    end
    BG.Frame[FB]["boss" .. Maxb[FB] + 2]["zhuangbei4"]:HookScript("OnEnter", OnEnter)
    BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine4"]:HookScript("OnEnter", OnEnter)

    -- 修复默认支出名称
    local b = Maxb[FB] + 1
    for i = 1, BG.GetMaxi(FB, b) do
        local zb = BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]
        if zb then
            zb:SetText(zb:GetText():gsub(L["坦克补贴"], L["T补贴"]))
            zb:SetText(zb:GetText():gsub(L["治疗补贴"], L["N补贴"]))
            zb:SetText(zb:GetText():gsub(L["输出补贴"], L["DPS补贴"]))
        end
    end
end
