if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L
local GetClassColor = ns.GetClassColor

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
local Round = ns.Round

local pt = print

local realmID = GetRealmID()

BG.Init(function()
    -- 牌子拾取增强
    if not BG.verLess2 then
        local text1, text2, text3
        if BG.IsRetail then
            text1 = CURRENCY_GAINED_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
            text2 = CURRENCY_GAINED:gsub("%%s", "(.+)")
        else
            text1 = LOOT_ITEM_PUSHED_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
            text2 = LOOT_ITEM_PUSHED_SELF:gsub("%%s", "(.+)")
        end
        local function func(self, event, msg, player, l, cs, t, flag, channelId, ...)
            if BiaoGe.options["showCurrencyCount"] ~= 1 then return end
            local link = strmatch(msg, text1)
            if not link then
                link = strmatch(msg, text2)
            end
            if link then
                local currencyID = link:match("currency:(%d+)")
                if currencyID then
                    local info = C_CurrencyInfo.GetCurrencyInfo(tonumber(currencyID))
                    local maxCount = info.maxQuantity
                    local count = info.quantity
                    local color = "00BFFF"
                    local isFull
                    local newMsg
                    if not info.useTotalEarnedForMaxQty and maxCount > 0 then -- （2500/4000）例如正义点数
                        if count >= maxCount then
                            isFull = true
                            color = "FF0000"
                        end
                        newMsg = format(L["|cff%s（|cffffffff%s|r/%s）|r"], color,
                            BG.FormatNumber(count), BG.FormatNumber(maxCount))
                    else
                        local weekText = ""
                        if info.useTotalEarnedForMaxQty and maxCount > 0 then -- MOP勇气点数
                            local totalEarned = info.totalEarned
                            if totalEarned >= maxCount then
                                isFull = true
                                color = "FF0000"
                            end
                            weekText = format(L["（总上限%s/%s）"],
                                BG.FormatNumber(totalEarned), BG.FormatNumber(maxCount))
                        end
                        local weekMax = info.maxWeeklyQuantity -- 时光服泰坦余烬
                        if weekMax and weekMax > 0 then
                            local weekCount = info.quantityEarnedThisWeek
                            weekText = format(L["（本周%s/%s）"],
                                BG.FormatNumber(weekCount), BG.FormatNumber(weekMax))
                            if weekCount >= weekMax then
                                isFull = true
                                color = "FF0000"
                            end
                        end
                        newMsg = format(L["|cff%s（|cffffffff%s|r）%s|r"], color, count, weekText)
                    end
                    if isFull then
                        BG.PlaySound("currencyfull")
                    end
                    return false, msg .. newMsg, player, l, cs, t, flag, channelId, ...
                end
            end
        end
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CURRENCY", func)
    end

    -- 更新集结号密语装等
    do
        local function GetPlayerAverageItemLevel()
            local _, avgLevel = GetAverageItemLevel()
            local avgLevel0 = Round(avgLevel, 0)
            if BG.isFullLevel and BG.MeetingHorn and BG.MeetingHorn.iLevelCheckButton then
                BG.MeetingHorn.iLevelCheckButton.Text:SetText(avgLevel0)
            end
        end

        local delay
        local again
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:SetScript("OnEvent", function(self, event, ...)
            if event == "PLAYER_ENTERING_WORLD" then
                self:UnregisterEvent("PLAYER_ENTERING_WORLD")
                delay = 3
                again = true
                BG.After(delay, function()
                    self:RegisterEvent("UNIT_INVENTORY_CHANGED")
                end)
            else
                delay = 1
            end
            self.t = 0
            self:SetScript("OnUpdate", function(_, t)
                self.t = self.t + t
                if self.t > delay then
                    self:SetScript("OnUpdate", nil)
                    GetPlayerAverageItemLevel()
                    if again then
                        again = nil
                        BG.After(5, function()
                            GetPlayerAverageItemLevel()
                        end)
                    end
                end
            end)
        end)
    end

    -- 一键排灵魂烘炉
    local holidayDungeonIDs = { 286, 285, 287, 288 } -- 火焰节、万圣节、美酒节、情人节
    if not BG.verLess2 then
        BiaoGe.lastChooseLFD = BiaoGe.lastChooseLFD or {}
        BiaoGe.lastChooseLFD[realmID] = BiaoGe.lastChooseLFD[realmID] or {}
        if BiaoGe.lastChooseLFD[realmID][BG.myName] and type(BiaoGe.lastChooseLFD[realmID][BG.myName]) ~= "table" then
            local type = BiaoGe.lastChooseLFD[realmID][BG.myName]
            BiaoGe.lastChooseLFD[realmID][BG.myName] = {
                type = type,
            }
        end
        BiaoGe.lastChooseLFD[realmID][BG.myName] = BiaoGe.lastChooseLFD[realmID][BG.myName] or {}
        BiaoGe.lastChooseLFD[realmID][BG.myName].dungeons = BiaoGe.lastChooseLFD[realmID][BG.myName].dungeons or {}

        local isOnClick

        local function OnClick(self)
            if self.type == "zhiding" then
                for i, id in ipairs(LFDDungeonList) do
                    if id < 0 then
                        LFGDungeonList_SetHeaderEnabled(1, id, false, LFDDungeonList, LFDHiddenByCollapseList)
                    end
                end
                LFGDungeonList_SetDungeonEnabled(self.dungeonID, true)
                LFDQueueFrame_SetType("specific")
                LFG_JoinDungeon(LE_LFG_CATEGORY_LFD, "specific", LFDDungeonList, LFDHiddenByCollapseList)
            elseif self.type == "jieri" then
                LFDQueueFrame_SetType(self.dungeonID)
                LFG_JoinDungeon(LE_LFG_CATEGORY_LFD, self.dungeonID, LFDDungeonList, LFDHiddenByCollapseList)
            end
            BG.PlaySound(1)
        end

        local function OnEnter(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
            GameTooltip:ClearLines()
            if self.dis then
                GameTooltip:AddLine(L["副本已锁定"], 1, 0, 0, true)
            else
                GameTooltip:AddLine(self.onEnterText, 1, 1, 1, true)
                GameTooltip:AddLine(BG.STC_dis(L["你可在插件设置-BiaoGe-其他功能里关闭这个功能"]), 1, 1, 1, true)
            end
            GameTooltip:Show()
        end

        local buttons = {}
        for i = 1, 2 do
            local bt = BG.CreateButton(PVEFrame)
            bt:SetSize(150, 23)
            bt:SetPoint("BOTTOMLEFT", 35, 5)
            if i == 1 then
                bt.type = "jieri"
                bt.tbl = holidayDungeonIDs
                -- bt.tbl = { 259 }           -- 燃烧的远征test
            elseif i == 2 then
                bt.type = "zhiding"
                if BG.IsWLK then
                    bt.tbl = { 2463, } --伽马灵魂烘炉。贝塔要塞2481（已删）
                    -- bt.tbl = { 136 }  -- 地狱火test
                else
                    bt.tbl = {}
                end
            end
            bt:Hide()
            bt:SetScript("OnClick", OnClick)
            bt:SetScript("OnEnter", OnEnter)
            bt:SetScript("OnLeave", GameTooltip_Hide)
            tinsert(buttons, bt)

            bt.disframe = CreateFrame("Frame", nil, bt)
            bt.disframe:SetAllPoints()
            bt.disframe.dis = true
            bt.disframe:SetScript("OnEnter", OnEnter)
            bt.disframe:SetScript("OnLeave", GameTooltip_Hide)
        end

        local function UpdateButtons()
            local isShowButton = {}
            for i = 1, 2 do
                buttons[i].name = nil
                for _, dungeonID in ipairs(buttons[i].tbl) do
                    local isAvailableForAll, isAvailableForPlayer, hideIfNotJoinable = IsLFGDungeonJoinable(dungeonID)
                    if isAvailableForPlayer then
                        local name = GetLFGDungeonInfo(dungeonID)
                        if dungeonID == 2481 then
                            name = L["贝塔"] .. name
                        end
                        buttons[i]:SetText(name)
                        buttons[i].onEnterText = format(L["一键指定%s"], name)
                        buttons[i].dungeonID = dungeonID
                        buttons[i].name = name
                        buttons[i]:Show()
                        tinsert(isShowButton, buttons[i])

                        local playerName, lockedReason, subReason1, subReason2, secondReasonID, secondReasonString = GetLFDLockInfo(dungeonID, 1)
                        if lockedReason ~= 0 then
                            buttons[i]:Disable()
                            buttons[i].disframe:Show()
                        else
                            buttons[i]:Enable()
                            buttons[i].disframe:Hide()
                        end
                        break
                    end
                end
                if not buttons[i].name then
                    buttons[i]:Hide()
                end
            end
            if #isShowButton == 1 then
                isShowButton[1]:SetSize(150, 23)
                isShowButton[1]:ClearAllPoints()
                isShowButton[1]:SetPoint("BOTTOMLEFT", 35, 5)
                BG.ButtonTextSetWordWrap(buttons[1])
            elseif #isShowButton == 2 then
                for i = 1, 2 do
                    buttons[i]:SetSize(90, 23)
                    buttons[i]:ClearAllPoints()
                    if i == 1 then
                        buttons[i]:SetPoint("BOTTOMLEFT", 15, 5)
                    else
                        buttons[i]:SetPoint("BOTTOMLEFT", 110, 5)
                    end
                    BG.ButtonTextSetWordWrap(buttons[i])
                end
            end
        end
        LFDQueueFrame:HookScript("OnShow", function(self)
            if BiaoGe.options["zhidingFB"] ~= 1 then
                for i, bt in ipairs(buttons) do
                    bt:Hide()
                end
                return
            end
            UpdateButtons()
            if BiaoGe.lastChooseLFD[realmID][BG.myName] then
                if BiaoGe.lastChooseLFD[realmID][BG.myName].type == "specific" then
                    LFDQueueFrame_SetType(BiaoGe.lastChooseLFD[realmID][BG.myName].type)
                    BG.After(0, function()
                        for i, id in ipairs(LFDDungeonList) do
                            if id < 0 then
                                LFGDungeonList_SetHeaderEnabled(1, id, false, LFDDungeonList, LFDHiddenByCollapseList)
                            end
                        end
                        for dungeonID, isChecked in pairs(BiaoGe.lastChooseLFD[realmID][BG.myName].dungeons) do
                            LFGDungeonList_SetDungeonEnabled(dungeonID, isChecked)
                        end
                        if LFDQueueFrameSpecificList_Update then
                            LFDQueueFrameSpecificList_Update()
                        end
                        LFDQueueFrame_UpdateRoleButtons()
                    end)
                else
                    for i = 1, GetNumRandomDungeons() do
                        local id, name = GetLFGRandomDungeonInfo(i)
                        local isAvailableForAll, isAvailableForPlayer, hideIfNotJoinable = IsLFGDungeonJoinable(id)
                        if isAvailableForPlayer then
                            if id == BiaoGe.lastChooseLFD[realmID][BG.myName].type then
                                LFDQueueFrame_SetType(BiaoGe.lastChooseLFD[realmID][BG.myName].type)
                                return
                            end
                        end
                    end
                end
            end
        end)
        hooksecurefunc("LFDQueueFrame_SetTypeInternal", function(value)
            -- pt(value)
            if PVEFrame:IsVisible() then
                BiaoGe.lastChooseLFD[realmID][BG.myName].type = value
            end
        end)

        hooksecurefunc("LFGDungeonList_SetDungeonEnabled", function(dungeonID, isChecked)
            -- pt(dungeonID)
            BG.After(0, function()
                if isOnClick then
                BiaoGe.lastChooseLFD[realmID][BG.myName].dungeons[dungeonID] = isChecked
                end
            end)
        end)
        hooksecurefunc("LFGDungeonListCheckButton_OnClick", function(button, category, dungeonList, hiddenByCollapseList)
            isOnClick = true
            BG.After(0.01, function()
                isOnClick = false
            end)
            -- local parent = button:GetParent();
            -- local dungeonID = parent.id;
            -- local isChecked = button:GetChecked();
        end)
    end
end)
