if BG.IsBlackListPlayer then return end

local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
local Size = ns.Size
local RGB = ns.RGB
local RGB_16 = ns.RGB_16
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local GetText_T = ns.GetText_T
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID

local Maxb = ns.Maxb

local pt = print

local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded

BG.Init(function()
    local lastBt
    local hight = 25
    local delayTime = .2

    -- 角色总览
    do
        local bt = CreateFrame("Button", nil, BG.MainFrame)
        bt:SetSize(20, hight)
        if lastBt then
            bt:SetPoint("RIGHT", lastBt, "LEFT", -10, 0)
        else
            bt:SetPoint("BOTTOMRIGHT", -20, 1)
        end
        bt:SetNormalFontObject(BG.FontYellow13)
        bt:SetHighlightFontObject(BG.FontWhite13)
        bt:SetText("|A:GarrMission_ClassIcon-" .. string.lower(select(2, UnitClass("player"))) .. ":0:0|a" .. L["角色总览"])
        -- bt:SetText("|A:classicon-" .. string.lower(select(2, UnitClass("player"))) .. ":0:0|a" .. L["角色总览"])
        bt:SetWidth(bt:GetFontString():GetStringWidth())
        BG.ButtonRoleOverview = bt
        lastBt = bt
        BG.OnEnterDelay(bt, function(self)
            if ZL and ZL.SetFBCD then
                ZL.SetFBCD(self)
            else
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["错误"], 1, 0, 0, true)
                GameTooltip:AddLine(L["需要安装ZongLan插件才能使用角色总览功能，可在各平台免费下载。"], 1, 0.82, 0, true)
                GameTooltip:Show()
            end
        end)
        BG.OnLeaveDelay(bt, function(self)
            if ZL and ZL.FBCDFrame and not ZL.FBCDFrame.click then
                ZL.FBCDFrame:Hide()
            end
            GameTooltip:Hide()
        end)
        bt:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then
                if ZL and ZL.SetFBCD then
                    ZL.SetFBCD(nil, nil, true)
                end
            elseif button == "RightButton" then
                if ZL and ZL.OpenOption then
                    ZL.OpenOption()
                    BG.MainFrame:Hide()
                end
            end
            BG.PlaySound(1)
        end)
    end

    -- 爱发电
    --[=[     do
        local bt = CreateFrame("Button", nil, BG.MainFrame)
        bt:SetSize(20, hight)
        if lastBt then
            bt:SetPoint("RIGHT", lastBt, "LEFT", -10, 0)
        else
            bt:SetPoint("BOTTOMRIGHT", -10, 1)
        end
        bt:SetNormalFontObject(BG.FontYellow13)
        bt:SetHighlightFontObject(BG.FontWhite13)
        bt:SetText(AddTexture(ns.Interface .. "Media\\icon\\AFD") .. L["爱发电"])
        bt:SetWidth(bt:GetFontString():GetStringWidth())
        bt.texts = {}
        bt.w = 50
        BG.ButtonAFD = bt
        lastBt = bt

        local function AddText(self, tbl, r, g, b)
            local f = self.frame
            local w = self.w
            local text
            if type(tbl) == "table" then
                local same = {}
                local remove = {}
                for i = 1, #tbl do
                    if tbl[i]:find(realmName, 1, true) then
                        tbl[i] = BG.STC_g1(tbl[i])
                    end
                    if not same[tbl[i]] then
                        same[tbl[i]] = true
                    else
                        remove[i] = true
                    end
                end
                for k, v in pairs(remove) do
                    tremove(tbl, k)
                end
                text = table.concat(tbl, BG.STC_dis("，"))
            else
                text = tbl
            end

            local t = self.child:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetText(text)
            t:SetWidth(f:GetWidth() - w * 3)
            if not next(self.texts) then
                t:SetPoint("TOPLEFT", 20, -20)
            else
                t:SetPoint("TOPLEFT", self.texts[#self.texts], "BOTTOMLEFT", 0, -15)
            end
            t:SetJustifyH("LEFT")
            t:SetTextColor(r, g, b)
            t:SetText(text)
            tinsert(self.texts, t)
        end
        BG.OnEnterDelay(bt, function(self)
            wipe(self.texts)
            local w, h = BG.MainFrame:GetWidth(), BG.MainFrame:GetHeight() - 50
            local f, child = BG.CreateScrollFrame(self, w, h)
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            f:SetBackdropColor(0, 0, 0, .9)
            f:SetPoint("TOPLEFT", BG.MainFrame, "TOPLEFT", 0, -20)
            f:SetFrameLevel(320)
            f:EnableMouse(false)
            self.frame = f
            self.child = child
            AddText(self, L["感谢以下玩家的发电："], 1, 1, 1)
            AddText(self, AFDtbl_360, 1, .82, 0)
            AddText(self, AFDtbl_180, 1, .82, 0)
            AddText(self, AFDtbl_90, 1, .82, 0)
            AddText(self, AFDtbl_30, 1, .82, 0)
        end)
        BG.OnLeaveDelay(bt, function(self)
            if self.frame then
                self.frame:Hide()
            end
            GameTooltip:Hide()
            BiaoGeTooltip2:Hide()
        end)
    end ]=]

    -- 网易DD
    --[[     do
        local bt = CreateFrame("Button", nil, BG.MainFrame)
        bt:SetSize(20, hight)
        if lastBt then
            bt:SetPoint("RIGHT", lastBt, "LEFT", -10, 0)
        else
            bt:SetPoint("BOTTOMRIGHT", -10, 1)
        end
        bt:SetNormalFontObject(BG.FontYellow13)
        bt:SetHighlightFontObject(BG.FontWhite13)
        bt:SetText(AddTexture("DD") .. L["网易DD"])
        bt:SetWidth(bt:GetFontString():GetStringWidth())
        BG.ButtonDD = bt
        lastBt = bt

        BG.OnEnterDelay(bt, function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
            GameTooltip:AddLine(L["官方插件平台"], 1, 1, 1, true)
            GameTooltip:AddLine(L["集插件管理、配置分享、云端备份、团队语音于一体。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(L["你可以在这里更新BiaoGe插件。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(L["（点击复制网址）"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        BG.OnLeaveDelay(bt, GameTooltip_Hide)
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
            ChatEdit_ChooseBoxForSend():SetText("https://dd.163.com/?utm_source=112231")
            ChatEdit_ChooseBoxForSend():HighlightText()
        end)
    end ]]

    -- 新手盒子
    --[[     do
        local bt = CreateFrame("Button", nil, BG.MainFrame)
        bt:SetSize(20, hight)
        if lastBt then
            bt:SetPoint("RIGHT", lastBt, "LEFT", -10, 0)
        else
            bt:SetPoint("BOTTOMRIGHT", -10, 1)
        end
        bt:SetNormalFontObject(BG.FontYellow13)
        bt:SetHighlightFontObject(BG.FontWhite13)
        bt:SetText(AddTexture("BOX") .. L["新手盒子"])
        bt:SetWidth(bt:GetFontString():GetStringWidth())
        BG.ButtonBOX = bt
        lastBt = bt

        BG.OnEnterDelay(bt, function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
            GameTooltip:AddLine(L["集插件管理、配置分享、云端备份、游戏攻略、游戏工具于一体。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(L["你可以在这里更新BiaoGe插件。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(L["（点击复制网址）"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        BG.OnLeaveDelay(bt, GameTooltip_Hide)
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
            ChatEdit_ChooseBoxForSend():SetText("https://www.wclbox.com/")
            ChatEdit_ChooseBoxForSend():HighlightText()
        end)
    end ]]

    -- 提交BUG
    do
        local bt = CreateFrame("Button", nil, BG.MainFrame)
        bt:SetSize(20, hight)
        if lastBt then
            bt:SetPoint("RIGHT", lastBt, "LEFT", -10, 0)
        else
            bt:SetPoint("BOTTOMRIGHT", -10, 1)
        end
        bt:SetNormalFontObject(BG.FontYellow13)
        bt:SetHighlightFontObject(BG.FontWhite13)
        bt.title = AddTexture(ns.Interface .. "Media\\icon\\icon") .. L["QQ群"]
        bt.title2 = AddTexture(ns.Interface .. "Media\\icon\\icon") .. L["有报错！"]
        bt:SetText(bt.title)
        bt:SetWidth(bt:GetFontString():GetStringWidth())
        BG.ButtonBug = bt
        lastBt = bt

        BG.OnEnterDelay(bt, function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["BiaoGe沟通交流群"], 1, 1, 1, true)
            GameTooltip:AddLine(L["Q群："] .. "322785325", 1, 0.82, 0, true)
            GameTooltip:AddLine(L["密码："] .. "金团表格", 1, 0.82, 0, true)
            GameTooltip:AddLine(L["（点击复制Q群）"], 1, 0.82, 0, true)
            GameTooltip:Show()

            if self.hasError then
                local e = self.errors
                local gameVer = GetBuildInfo()
                if BG.IsVanilla_Sod then
                    gameVer = gameVer .. " sod"
                end
                BiaoGeTooltip2:SetOwner(GameTooltip, "ANCHOR_TOPLEFT", 0, 0)
                BiaoGeTooltip2:ClearLines()
                BiaoGeTooltip2:AddLine(L["报错"], 1, 0, 0, true)
                BiaoGeTooltip2:AddLine(L["请你把该报错截图发给作者"], 1, 0.82, 0, true)
                BiaoGeTooltip2:AddLine(L["版本："] .. BG.ver, 1, 0.82, 0, true)
                BiaoGeTooltip2:AddLine(L["游戏："] .. gameVer, 1, 0.82, 0, true)
                BiaoGeTooltip2:AddLine(L["时间："] .. (type(e.time) == "number" and date("%m-%d %H:%M:%S", e.time) or e.time), 1, 0.82, 0, true)
                BiaoGeTooltip2:AddLine(L["错误："] .. e.counter .. "x " .. e.message, .5, .5, .5, true)
                if e.stack then
                    BiaoGeTooltip2:AddLine(L["栈："] .. e.stack, .5, .5, .5, true)
                end
                BiaoGeTooltip2:Show()
            end
        end, delayTime)
        BG.OnLeaveDelay(bt, function(self)
            GameTooltip:Hide()
            BiaoGeTooltip2:Hide()
        end)
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
            ChatEdit_ChooseBoxForSend():SetText("322785325")
            ChatEdit_ChooseBoxForSend():HighlightText()
        end)
        bt:SetScript("OnShow", function(self)
            BG.After(1, function()
                if BugGrabberDB and BugGrabberDB.errors then
                    for i, e in next, BugGrabberDB.errors do
                        if BugGrabberDB.session == e.session and type(e.message) == "string"
                            and e.message:find("BiaoGe") and not e.message:find("BiaoGeAI")
                            and not e.message:find("ADDON_ACTION_FORBIDDEN") and not e.message:find("ADDON_ACTION_BLOCKED") then
                            self.hasError = true
                            self.errors = {
                                time = e.time,
                                message = e.message,
                                stack = e.stack,
                                locals = e.locals,
                                counter = e.counter,
                            }
                            self:SetNormalFontObject(BG.FontRed13)
                            self:SetText(self.title2)
                            self:SetScript("OnShow", nil)
                            BG.MainFrame.ErrorText:SetText(L["插件加载错误，请查看右下角的红字报错，把报错内容截图发给作者，谢谢。（Q群：322785325，密码：金团表格）"])
                            break
                        end
                    end
                end
            end)
        end)
    end

    -- 时光徽章价格
    do
        BiaoGe.marketPrice = BiaoGe.marketPrice or {}
        local saveCD = 60 * 60 * 3
        local saveMaxCount = 20
        local outTime = 90 * 86400
        for i = #BiaoGe.marketPrice, 1, -1 do
            if GetServerTime() - BiaoGe.marketPrice[i].time > outTime then
                tremove(BiaoGe.marketPrice, i)
            end
        end

        local function CreateHistoryFrame(self)
            if not self.currentPrice then return end
            local titleWidth = 130
            local barWidth = 200
            local priceWidth = 100
            local frameWidth = titleWidth + barWidth + priceWidth + 20
            local barHeight = 18
            local _max, _min = 0, 0
            for i, v in ipairs(BiaoGe.marketPrice) do
                _max = max(v.price, _max)
                _min = min(v.price, _min)
            end
            local f = CreateFrame("Frame", nil, BG.MainFrame, "BackdropTemplate")
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            f:SetBackdropColor(0, 0, 0, 0.8)
            f:SetBackdropBorderColor(1, 1, 1, .5)
            f:SetSize(500, 300)
            f:SetPoint("BOTTOM", self, "TOP", 0, 0)
            f:SetFrameStrata("HIGH")
            f:SetClampedToScreen(true)
            f.buttons = {}
            self.frame = f
            local toptitle = f:CreateFontString()
            toptitle:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            toptitle:SetPoint("TOP", f, "TOP", 0, -5)
            toptitle:SetTextColor(0, .75, 1)
            toptitle:SetText(AddTexture(1120721) .. L["时光徽章历史价格"])

            local function CreateBar(i, v, isNow)
                local title = f:CreateFontString()
                title:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                title:SetSize(titleWidth, barHeight)
                if next(f.buttons) then
                    title:SetPoint("TOPLEFT", f.buttons[i - 1], "BOTTOMLEFT", 0, 0)
                else
                    title:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -30)
                end
                title:SetTextColor(1, 1, 1)
                title:SetText(isNow and L["现在"] or date("%m-%d %H:%M", v.time))
                title:SetJustifyH("RIGHT")
                title:SetWordWrap(false)
                tinsert(f.buttons, title)

                local bar = CreateFrame("Frame", nil, f, "BackdropTemplate")
                bar:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                })
                bar:SetBackdropColor(1, 1, 0, .8)
                bar:SetPoint("LEFT", title, "RIGHT", 5, 0)
                local widthPercent = v.price / _max
                if widthPercent ~= 1 then
                    widthPercent = widthPercent * widthPercent
                end
                local width
                if widthPercent == 0 then
                    width = 5
                else
                    width = barWidth * widthPercent
                end
                bar:SetSize(width, 14)

                local price = f:CreateFontString()
                price:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                price:SetSize(priceWidth, 20)
                price:SetPoint("LEFT", bar, "RIGHT", 5, 0)
                price:SetTextColor(1, 0.82, 0)
                price:SetText(GetMoneyString(v.price, true))
                price:SetJustifyH("LEFT")
                price:SetWordWrap(false)
            end
            for i, v in ipairs(BiaoGe.marketPrice) do
                CreateBar(i, v)
            end
            CreateBar(#BiaoGe.marketPrice + 1, { price = self.currentPrice or 0 }, true)

            local text
            local moneyTitle, money
            if not BG.IsTW then
                moneyTitle = "¥"
                money = 90
            else
                moneyTitle = "HK$"
                money = 150
            end
            local m1 = self.currentPrice / money / 10000
            m1 = floor(m1) * 10000
            text = moneyTitle .. "1 = " .. GetMoneyString(m1, true)
            local m2 = money / (self.currentPrice / 10000)
            if BG.IsRetail then
                m2 = format("%.6f", m2)
            else
                m2 = format("%.4f", m2)
            end
            text = text .. "   " .. GetMoneyString(10000, true) .. " = " .. m2 .. moneyTitle
            local bottomText = f:CreateFontString()
            bottomText:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
            bottomText:SetPoint("BOTTOM", f, "BOTTOM", 0, 8)
            bottomText:SetTextColor(1, .85, 0)
            bottomText:SetText(text)

            f:SetSize(frameWidth, (#f.buttons + 1) * barHeight + 40)
        end

        local bt = CreateFrame("Button", nil, BG.MainFrame)
        bt:SetSize(1, 20)
        if lastBt then
            bt:SetPoint("RIGHT", lastBt, "LEFT", -10, 0)
        else
            bt:SetPoint("BOTTOMRIGHT", -10, 1)
        end
        bt:SetNormalFontObject(BG.FontYellow13)
        bt:SetHighlightFontObject(BG.FontWhite13)
        BG.OnEnterDelay(bt, CreateHistoryFrame, delayTime)
        BG.OnLeaveDelay(bt, function(self)
            if self.frame then
                self.frame:Hide()
            end
        end)
        BG.ButtonToken = bt
        lastBt = bt

        local function SavePrice(currentPrice)
            if not next(BiaoGe.marketPrice) or
                GetServerTime() - BiaoGe.marketPrice[#BiaoGe.marketPrice].time > saveCD then
                tinsert(BiaoGe.marketPrice, {
                    time = GetServerTime(),
                    price = currentPrice,
                })
                if #BiaoGe.marketPrice > saveMaxCount then
                    for i = #BiaoGe.marketPrice - saveMaxCount, 1, -1 do
                        tremove(BiaoGe.marketPrice, i)
                    end
                end
            end
        end
        local function OnTokenMarketPriceUpdated(event, result)
            local currentPrice = C_WowTokenPublic.GetCurrentMarketPrice()
            if currentPrice then
                SavePrice(currentPrice)
                bt.currentPrice = currentPrice
                bt:SetText(AddTexture(1120721) .. BG.FormatNumber(currentPrice / 1e4, 0))
                bt:SetWidth(bt:GetFontString():GetWidth())
            else
                bt:SetText("")
                bt:SetWidth(1)
            end
        end
        BG.RegisterEvent("TOKEN_MARKET_PRICE_UPDATED", OnTokenMarketPriceUpdated)

        BG.Init2(function()
            C_Timer.After(2, function()
                C_WowTokenPublic.UpdateMarketPrice()
                OnTokenMarketPriceUpdated()
            end)
        end)
        C_Timer.NewTicker(60, function()
            C_WowTokenPublic.UpdateMarketPrice()
        end)
    end

    -- 在线玩家数
    if BG.IsTW and not BG.IsForever then
        BG.Init2(function()
            if not IsAddOnLoaded("Blizzard_Communities") then
                UIParentLoadAddOn("Blizzard_Communities")
            end
        end)

        local World = LOOK_FOR_GROUP

        local function GetFactionName()
            if UnitFactionGroup("player") == "Alliance" then
                return FACTION_ALLIANCE
            else
                return FACTION_HORDE
            end
        end
        local function OnEnter(self)
            self.isOnEnter = true
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(format(L["%s在线人数"], GetFactionName()), 1, 1, 1, true)
            if self.count then
                GameTooltip:AddLine(self.count .. L["人"] .. format(L["（获取时间：%s）"], self.time), 1, 0.82, 0, true)
            else
                local yes
                local channels = { GetChannelList() }
                for i = 1, #channels, 3 do
                    if channels[i + 1] == World then
                        yes = true
                        break
                    end
                end
                if yes then
                    GameTooltip:AddLine(L["未刷新"], 0.5, 0.5, 0.5, true)
                else
                    GameTooltip:AddLine(format(L["你未加入%s，无法获取在线人数。"], World), 0.5, 0.5, 0.5, true)
                end
            end
            GameTooltip:AddLine(L["<点击刷新>"], 0, 1, 0, true)

            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(format(L["数据来源："]), 1, 1, 1, true)
            GameTooltip:AddLine(format(L["%s在线人数"], World), 1, 0.82, 0, true)
            GameTooltip:Show()
        end
        local function OnLeave(self)
            self.isOnEnter = false
            GameTooltip:Hide()
        end

        local bt = CreateFrame("Button", nil, BG.MainFrame)
        bt:SetSize(1, 20)
        if lastBt then
            bt:SetPoint("RIGHT", lastBt, "LEFT", -10, 0)
        else
            bt:SetPoint("BOTTOMRIGHT", -10, 1)
        end
        bt:SetNormalFontObject(BG.FontWhite13)
        bt:SetText(AddTexture(135994) .. L["待刷新"])
        bt:GetFontString():SetPoint("LEFT")
        bt:SetWidth(bt:GetFontString():GetWidth())
        bt.channel = World
        BG.OnEnterDelay(bt, OnEnter, 0)
        BG.OnLeaveDelay(bt, OnLeave)
        bt:SetScript("OnClick", function(self)
            BG.GetChannelMemberCount(self.channel)
            BG.PlaySound(1)
        end)
        BG.ButtonOnLineCount = bt
        lastBt = bt

        function BG.GetChannelMemberCount(channelName)
            local channels = { GetChannelList() }
            for i = 1, #channels, 3 do
                if channels[i + 1] == channelName then
                    if ChannelFrame:IsShown() then
                        HideUIPanel(ChannelFrame)
                    end
                    ChannelFrame.targetChannel = channelName
                    ShowUIPanel(ChannelFrame)
                    return
                end
            end
        end

        hooksecurefunc(ChannelFrame.ChannelList, 'AddChannelButtonInternal', function(_, channelbt, _, name, _, channelID)
            if name == ChannelFrame.targetChannel then
                BG.After(0.3, function()
                    ChannelFrame.ChannelList:SetSelectedChannel(channelbt)
                    BG.After(1, function()
                        local _, _, _, _, count = GetChannelDisplayInfo(channelbt.channelID)
                        if count then
                            bt.count = count
                            local m, s = GetGameTime()
                            s = format("%02d", s)
                            bt.time = m .. ":" .. s
                            bt:SetText(AddTexture(135994) .. count .. L["人"])
                            bt:GetFontString():SetPoint("LEFT")
                            bt:SetWidth(bt:GetFontString():GetWidth())
                            if bt.isOnEnter then
                                OnEnter(bt)
                            end
                        end
                        for k, bt in ipairs(ChannelFrame.ChannelList.buttons) do
                            if bt.name == CHANNEL_CATEGORY_WORLD then
                                ChannelFrame.ChannelList:SetSelectedChannel(bt)
                                return
                            end
                        end
                    end)
                end)
                ChannelFrame.targetChannel = nil
                HideUIPanel(ChannelFrame)
            end
        end)
    end
end)
