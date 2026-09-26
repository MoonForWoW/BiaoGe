if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L
local GetClassColor = ns.GetClassColor

local Size = ns.Size
local RGB = ns.RGB
local RGB_16 = ns.RGB_16
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local GetText_T = ns.GetText_T
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID

local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded
local GetLootMethod = GetLootMethod or C_PartyInfo.GetLootMethod

local Maxb = ns.Maxb

local pt = print
local realmID = GetRealmID()
local player = BG.myName

local myClassFileName = select(2, UnitClass('player'))
local r, g, b = GetClassRGB(nil, "player")

BG.Init2(function()
    local itemFucs = {}
    local unitFucs = {}
    -- 单位
    do
        -- 鼠标提示玩家的欠款和罚款
        do
            local fk = {}
            local qk = {}
            local function Get()
                if not IsInRaid(1) then return end
                local FB = BG.FB1
                fk = {}
                qk = {}
                BG.PairFBItem(function(item, buyer, money, b, i)
                    local name = buyer:GetText()
                    if name ~= '' then
                        fk[name] = fk[name] or 0
                        qk[name] = qk[name] or 0
                        if b == Maxb[FB] then
                            fk[name] = fk[name] + (tonumber(money:GetText()) or 0)
                        end
                        qk[name] = qk[name] + (tonumber(BiaoGe[FB]["boss" .. b]["qiankuan" .. i]) or 0)
                    end
                end)
            end
            C_Timer.NewTicker(2, Get)

            local function AddUnitInfo(self, unit, name)
                if BiaoGe.options["mouseFK"] ~= 1 then return end
                if not IsInRaid(1) then return end
                local fkMoney = fk[name] or 0
                local qkMoney = qk[name] or 0
                if fkMoney ~= 0 then
                    self:AddLine(L["罚款："] .. BG.STC_w1(BG.FormatNumber(fkMoney, 2)), 1, .82, 0)
                end
                if qkMoney ~= 0 then
                    self:AddLine(L["欠款："] .. BG.STC_w1(BG.FormatNumber(qkMoney, 2)), 1, .82, 0)
                end
                if fkMoney ~= 0 or qkMoney ~= 0 then
                    self:Show()
                end
            end
            tinsert(unitFucs, AddUnitInfo)
        end

        -- 星团长
        if BG.MeetingHornRegimentData then
            local function AddUnitInfo(self, unit, name)
                if BiaoGe.options["MeetingHorn_starRaidLeader"] ~= 1 then return end
                local currentLevel = BG.MeetingHornRegimentData[name]
                if not currentLevel then return end
                currentLevel = currentLevel.level
                -- local currentLevel = 5 -- test
                local nextText = _G["GameTooltipTextLeft1"]
                local str = nextText:GetText() or ''
                nextText:SetFormattedText('%s|T%s%s|t', str, BG.MeetingHornStarTexture(currentLevel), BG.MeetingHornGetCoords("tooltip"))
                self:Show()
            end
            tinsert(unitFucs, AddUnitInfo)
        end
    end

    -- 物品
    do
        -- 鼠标提示装备的历史价格区间
        do
            local function callback(itemID, maxJine, minJine, tooltip)
                BG.historyLastCallback = nil
                local name, link = tooltip:GetItem()
                if not link then return end
                if GetItemID(link) ~= itemID then return end
                for i = 1, tooltip:NumLines() do
                    local leftt = _G[tooltip:GetName() .. "TextLeft" .. i]
                    local rightt = _G[tooltip:GetName() .. "TextRight" .. i]
                    if leftt then
                        local lefttext = leftt:GetText()
                        local righttext = rightt:GetText()
                        if lefttext == (L["BiaoGe历史价格"]) and righttext == L["读取中"] then
                            if minJine and maxJine then
                                local text
                                if minJine == maxJine then
                                    text = minJine
                                else
                                    text = L["%s-%s"]:format(minJine, maxJine)
                                end
                                rightt:SetText(text .. " " .. AddTexture(237618))
                                tooltip:Show()
                            else
                                rightt:SetText(L["无"])
                            end
                            return
                        end
                    end
                end
            end
            local function GetMaxMinMoney(tbl)
                local maxJine, minJine
                if next(tbl) then
                    for i = 1, #tbl do
                        if not maxJine then
                            maxJine = tbl[i].money
                        end
                        if not minJine then
                            minJine = tbl[i].money
                        end
                        if maxJine < tbl[i].money then
                            maxJine = tbl[i].money
                        end
                        if minJine > tbl[i].money then
                            minJine = tbl[i].money
                        end
                    end
                end
                return maxJine, minJine
            end
            local function AddInfo(self, itemID, link, name)
                if not (BiaoGe.options["mouseHistoryMoney"] == 1 and IsInRaid(1)) then return end
                -- if not (BiaoGe.options["mouseHistoryMoney"] == 1) then return end
                if BG.HistoryMoneyCache[itemID] then
                    local maxJine, minJine = GetMaxMinMoney(BG.HistoryMoneyCache[itemID])
                    maxJine = BG.FormatNumber(maxJine, 2)
                    minJine = BG.FormatNumber(minJine, 2)
                    local text = ""
                    local moneyText
                    if minJine and maxJine then
                        if minJine == maxJine then
                            text = minJine
                        else
                            text = L["%s-%s"]:format(minJine, maxJine)
                        end
                        moneyText = text .. " " .. AddTexture(237618)
                    else
                        moneyText = L["无"]
                    end
                    self:AddDoubleLine(L["BiaoGe历史价格"], moneyText, 1, 0.82, 0, 1, 1, 1)
                else
                    self:AddDoubleLine(L["BiaoGe历史价格"], L["读取中"], 1, 0.82, 0, 1, 1, 1)
                    BG.historyLastCallback = function(tbl)
                        local maxJine, minJine = GetMaxMinMoney(tbl)
                        maxJine = BG.FormatNumber(maxJine, 2)
                        minJine = BG.FormatNumber(minJine, 2)
                        callback(itemID, maxJine, minJine, self)
                    end
                    BG.GetHistoryMoney(itemID, nil, BG.historyLastCallback)
                end
                self:Show()
            end
            tinsert(itemFucs, AddInfo)
        end

        -- 预设拍卖价格
        do
            local function AddInfo(self, itemID)
                if not IsAltKeyDown() then return end
                if not BiaoGe.auctionPreset then return end

                local tbl = {}
                for _, FB in pairs(BG.FBtable) do
                    if FB == BG.FB1 then
                        tinsert(tbl, 1, FB)
                    else
                        tinsert(tbl, FB)
                    end
                end
                for _, FB in ipairs(tbl) do
                    local preset = BiaoGe.auctionPreset[FB]
                    local money = preset and preset.money and preset.money[itemID]
                    if money then
                        self:AddLine(L["预设起拍价：|cffffffff"] .. BG.FormatNumber(money, 2), 1, 0.82, 0, true)
                        local tips = preset.money[itemID .. "tips"]
                        if tips then
                            self:AddLine(L["预设起拍语：|cffffffff"] .. tips, 1, 0.82, 0, true)
                        end
                        self:Show()
                        return
                    end
                end
            end
            tinsert(itemFucs, AddInfo)
        end

        -- 预设心理价格
        do
            local function AddInfo(self, itemID)
                if not BG.GetBestPrice then return end
                local money = BG.GetBestPrice(itemID)
                if not money then return end

                local tooltipName = self:GetName()
                local nextText = tooltipName and _G[tooltipName .. "TextLeft2"]
                if nextText then
                    local text = nextText:GetText() or ""
                    nextText:SetFormattedText("|cffFFD100%s%s|r\n%s", L["心理价格"], BG.FormatNumber(money, 2), text)
                    nextText:SetWidth(max(150, nextText:GetWidth() + 5))
                    self:Show()
                end
            end
            tinsert(itemFucs, AddInfo)
        end

        -- MOP在正义奖章和一袋岩石碎片里显示正义点数数量
        if BG.IsMOP then
            local itemIDs = {
                [247796] = 395,
                [256883] = 395,
                [248329] = 3350,
                [266272] = 3414,
                [276085] = 3416,
            }

            local function AddInfo(self, itemID, link, name)
                if BiaoGe.options["showCurrencyCount"] ~= 1 then return end
                local currency = itemIDs[itemID]
                if currency then
                    local info = C_CurrencyInfo.GetCurrencyInfo(currency)
                    local name = info.name
                    local count = info.quantity
                    local maxCount = info.maxQuantity
                    local tex = info.iconFileID
                    local quality = info.quality
                    local r, g, b = GetItemQualityColor(quality)
                    self:AddLine(" ")
                    self:AddLine("< BiaoGe >", 0, .75, 1)
                    if not info.useTotalEarnedForMaxQty then
                        self:AddDoubleLine(AddTexture(tex) .. name, BG.FormatNumber(count) .. "/" .. BG.FormatNumber(maxCount), r, g, b, 1, 1, 1)
                    else
                        local totalEarned = info.totalEarned
                        self:AddDoubleLine(AddTexture(tex) .. name,
                            format(L["%s(总上限:%s/%s)"], count, BG.FormatNumber(totalEarned), BG.FormatNumber(maxCount)), r, g, b, 1, 1, 1)
                    end
                    self:Show()
                    return
                end
            end
            tinsert(itemFucs, AddInfo)
        end

        -- 背包提示已拍未交易
        local function SetBagItem(self, b, i)
            if not BG.ImMLorLeader() then return end
            local info = C_Container.GetContainerItemInfo(b, i)
            if not info then return end
            local FB = BG.FB1
            if type(BiaoGe[FB].auctionLog) ~= "table" then return end
            local notBound
            if not info.isBound then
                notBound = true
            else
                for i = 1, self:NumLines() do
                    local tx = _G["GameTooltipTextLeft" .. i]:GetText()
                    if tx then
                        local time = tx:match(BIND_TRADE_TIME_REMAINING:gsub("%%s", "(.+)"))
                        if time then
                            notBound = true
                            break
                        end
                    end
                    i = i + 1
                end
            end
            if notBound then
                local trade = {}
                local notrade = {}
                for _, v in pairs(BiaoGe[FB].auctionLog) do
                    if v.type == 1 and BG.IsSameItem(info.hyperlink, v.zhuangbei) then
                        tinsert(v.trade and trade or notrade, v)
                    end
                end
                if next(trade) or next(notrade) then
                    self:AddLine(" ")
                    for _, v in ipairs(trade) do
                        local text = BG.FormatNumber(v.jine, 2) .. "(|c" .. select(4, GetClassColor(v.class)) .. v.maijia .. "|r)"
                        self:AddDoubleLine(L["已拍已交易"], text, 0, 1, 0)
                    end
                    for _, v in ipairs(notrade) do
                        local text = BG.FormatNumber(v.jine, 2) .. "(|c" .. select(4, GetClassColor(v.class)) .. v.maijia .. "|r)"
                        self:AddDoubleLine(L["已拍未交易"], text, 1, 0, 0)
                    end
                    self:Show()
                end
            end
        end
        hooksecurefunc(GameTooltip, "SetBagItem", SetBagItem)

        -- 表格/背包高亮对应物品
        do
            local i = 1
            while _G["ChatFrame" .. i] do
                _G["ChatFrame" .. i]:HookScript("OnHyperlinkEnter", function(self, link, text)
                    BG.Show_AllHighlight(link, "chat")
                end)
                _G["ChatFrame" .. i]:HookScript("OnHyperlinkLeave", BG.Hide_AllHighlight)
                i = i + 1
            end

            if IsAddOnLoaded("Bagnon") then
                BG.After(1, function()
                    local i = 1
                    while _G["BagnonContainerItem" .. i] do
                        local bag = _G["BagnonContainerItem" .. i]
                        if BG.IsNewUI then
                            bag:HookScript("OnLeave", GameTooltip_Hide)
                        else
                            bag:HookScript("OnLeave", ContainerFrameItemButton_OnLeave)
                        end
                        i = i + 1
                    end
                end)
            end

            local link
            local dalayFrame = CreateFrame("Frame")
            dalayFrame.t = 0
            dalayFrame:Hide()
            local function OnUpdate(self, t)
                self.t = self.t + t
                if self.t >= .1 then
                    self:Hide()
                    if link then
                        BG.Show_AllHighlight(link, "bag")
                    end
                end
            end
            local function OnHide()
                dalayFrame:Hide()
                BG.Hide_AllHighlight()
            end
            dalayFrame:SetScript('OnUpdate', OnUpdate)

            local function OnEnter(self, button)
                local b = self:GetParent():GetID()
                local i = self:GetID()
                link = C_Container.GetContainerItemLink(b, i)
                dalayFrame.t = 0
                dalayFrame:Show()
            end
            hooksecurefunc("ContainerFrameItemButton_OnEnter", OnEnter)
            if BG.IsNewUI then
                hooksecurefunc("GameTooltip_Hide", OnHide)
            else
                hooksecurefunc("ContainerFrameItemButton_OnLeave", OnHide)
            end
        end
    end

    -- 执行
    do
        local function UnitGo(self)
            if InCombatLockdown() then return end
            if BG.InBoss() then return end
            local _, unit = self:GetUnit()
            if BG.IsSecret(unit) then return end
            if not unit or not UnitIsPlayer(unit) then return end
            local name = BG.GN(unit)
            for _, fuc in ipairs(unitFucs) do
                fuc(self, unit, name)
            end
        end
        if BG.IsNewUI then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, UnitGo)
        else
            GameTooltip:HookScript("OnTooltipSetUnit", UnitGo)
        end

        local function ItemGo(self)
            if self ~= GameTooltip then return end
            local name, link = self:GetItem()
            if not link then return end
            local itemID = GetItemID(link)
            if not itemID then return end
            itemID = BG.GetLeiTingItem(itemID)
            for _, fuc in ipairs(itemFucs) do
                fuc(self, itemID, link, name)
            end
        end
        if BG.IsNewUI then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ItemGo)
        else
            GameTooltip:HookScript("OnTooltipSetItem", ItemGo)
        end
    end
end)
