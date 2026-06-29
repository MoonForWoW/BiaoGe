if BG.IsBlackListPlayer then return end
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
local GetItemID = ns.GetItemID

local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded
local GetLootMethod = GetLootMethod or C_PartyInfo.GetLootMethod

local Maxb = ns.Maxb

local pt = print
local realmID = GetRealmID()
local player = BG.playerName

local myClassFileName = select(2, UnitClass('player'))
local r, g, b = GetClassRGB(nil, "player")

BG.Init2(function()
    local itemFucs = {}
    local unitFucs = {}

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

        local function AddUnitInfo(self)
            if BG.InBoss() then return end
            if BiaoGe.options["mouseFK"] ~= 1 then return end
            if not IsInRaid(1) or InCombatLockdown() then return end
            local _, unit = self:GetUnit()
            if BG.IsSecret(unit) then return end
            if not unit or not UnitIsPlayer(unit) then return end
            local name = BG.GN(unit)
            local fkMoney = fk[name] or 0
            local qkMoney = qk[name] or 0
            if fkMoney ~= 0 then
                GameTooltip:AddLine(L["罚款："] .. BG.STC_w1(BG.FormatNumber(fkMoney, 2)), 1, .82, 0)
            end
            if qkMoney ~= 0 then
                GameTooltip:AddLine(L["欠款："] .. BG.STC_w1(BG.FormatNumber(qkMoney, 2)), 1, .82, 0)
            end
            if fkMoney ~= 0 or qkMoney ~= 0 then
                GameTooltip:Show()
            end
        end
        tinsert(unitFucs, AddUnitInfo)
    end

    -- 星团长
    if BG.MeetingHornRegimentData then
        local function AddUnitInfo(self)
            if BG.InBoss() then return end
            if BiaoGe.options["MeetingHorn_starRaidLeader"] ~= 1 then return end
            if InCombatLockdown() then return end
            local _, unit = self:GetUnit()
            if BG.IsSecret(unit) then return end
            if not unit or not UnitIsPlayer(unit) then return end
            local name = BG.GN(unit)
            local currentLevel = BG.MeetingHornRegimentData[name]
            if not currentLevel then return end
            currentLevel = currentLevel.level
            -- local currentLevel = 1 -- test
            local nameNum
            local ii = 1
            while _G["GameTooltipTextLeft" .. ii] do
                local text = _G["GameTooltipTextLeft" .. ii]:GetText()
                if text and text:find(name) then
                    nameNum = ii
                    break
                end
                ii = ii + 1
            end
            if not nameNum then return end
            local nextText = _G["GameTooltipTextLeft" .. nameNum + 1]
            if nextText and nextText:GetText() then
                nextText:SetText("|T" .. BG.MeetingHornStarTexture(currentLevel) .. BG.MeetingHornGetCoords("tooltip") .. "|t\n" .. nextText:GetText())
                nextText:SetWidth(nextText:GetWidth() + 2)
            end
            GameTooltip:Show()
        end
        tinsert(unitFucs, AddUnitInfo)
    end

    -- 鼠标提示装备的历史价格区间
    do
        local function callback(itemID, maxJine, minJine, tooltip)
            BG.historyLastCallback = nil
            local _itemID
            if TooltipUtil then
                _itemID = select(3, TooltipUtil.GetDisplayedItem(tooltip))
            else
                local name, link = tooltip:GetItem()
                if not link then return end
                _itemID = GetItemID(link)
            end
            if _itemID ~= itemID then return end
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
        local function SetTooltipText(itemID, tooltip)
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
                tooltip:AddDoubleLine(L["BiaoGe历史价格"], moneyText, 1, 0.82, 0, 1, 1, 1)
            else
                tooltip:AddDoubleLine(L["BiaoGe历史价格"], L["读取中"], 1, 0.82, 0, 1, 1, 1)
                BG.historyLastCallback = function(tbl)
                    local maxJine, minJine = GetMaxMinMoney(tbl)
                    maxJine = BG.FormatNumber(maxJine, 2)
                    minJine = BG.FormatNumber(minJine, 2)
                    callback(itemID, maxJine, minJine, tooltip)
                end
                BG.GetHistoryMoney(itemID, nil, BG.historyLastCallback)
            end
            tooltip:Show()
        end

        local function AddInfo(self, data)
            if BiaoGe.options["mouseHistoryMoney"] == 1 and IsInRaid(1) then
                local itemID
                if TooltipUtil then
                    itemID = select(3, TooltipUtil.GetDisplayedItem(self))
                else
                    local name, link = self:GetItem()
                    if not link then return end
                    itemID = GetItemID(link)
                end
                if not itemID then return end
                SetTooltipText(itemID, self)
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
        }

        local function AddInfo(self)
            if BiaoGe.options["showCurrencyCount"] ~= 1 then return end
            local name, link = self:GetItem()
            if not link then return end
            local itemID = GetItemID(link)
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
            for i = 1, GameTooltip:NumLines() do
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
                GameTooltip:AddLine(" ")
                for _, v in ipairs(trade) do
                    local text = BG.FormatNumber(v.jine, 2) .. "(|c" .. select(4, GetClassColor(v.class)) .. v.maijia .. "|r)"
                    GameTooltip:AddDoubleLine(L["已拍已交易"], text, 0, 1, 0)
                end
                for _, v in ipairs(notrade) do
                    local text = BG.FormatNumber(v.jine, 2) .. "(|c" .. select(4, GetClassColor(v.class)) .. v.maijia .. "|r)"
                    GameTooltip:AddDoubleLine(L["已拍未交易"], text, 1, 0, 0)
                end
                GameTooltip:Show()
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
                    if BG.IsRetail then
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
        if BG.IsRetail then
            hooksecurefunc("GameTooltip_Hide", OnHide)
        else
            hooksecurefunc("ContainerFrameItemButton_OnLeave", OnHide)
        end
    end

    -- 执行
    do
        local function ItemGo(self)
            for _, fuc in ipairs(itemFucs) do
                fuc(self)
            end
        end
        if BG.IsRetail then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ItemGo)
        else
            GameTooltip:HookScript("OnTooltipSetItem", ItemGo)
        end

        local function UnitGo(self)
            for _, fuc in ipairs(unitFucs) do
                fuc(self)
            end
        end
        if BG.IsRetail then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, UnitGo)
        else
            GameTooltip:HookScript("OnTooltipSetUnit", UnitGo)
        end
    end
end)
