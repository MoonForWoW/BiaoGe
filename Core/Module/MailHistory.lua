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
local ver = ns.ver
local After = C_Timer.After
local player = UnitName("player")
local realmID = GetRealmID()
local realmName = BG.realmName
local SendSystemMessage = BG.SendSystemMessage
local pt = print

local mailFrameMaxButton = 15
local mailFrameButtonHeight = 32

local function CreateLine(parent, y, width, height, color, alpha)
    local line = parent:CreateLine()
    line:SetColorTexture(RGB(color or "808080", alpha or 1))
    line:SetStartPoint("BOTTOMLEFT", 0, y)
    line:SetEndPoint("BOTTOMLEFT", width, y)
    line:SetThickness(height or 1.5)
    return line
end

local function AddIconByLink(link)
    local icon = select(5, GetItemInfoInstant(link))
    return AddTexture(icon)
end

local function CreateCheckButton(name, text, parent, ontext)
    local button = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    button:SetSize(30, 30)
    button.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    button.Text:SetText(text)
    button:SetHitRectInsets(0, -button.Text:GetWidth(), 0, 0)
    button.name = name
    button.ontext = ontext
    BG.options["button" .. name] = button
    button:SetChecked(BiaoGe.options[name] == 1)
    button:SetScript("OnClick", function(self)
        BiaoGe.options[self.name] = self:GetChecked() and 1 or 0
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
            GameTooltip:Show()
        else
            GameTooltip:SetText(self.ontext)
        end
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnShow", function(self)
        self:SetChecked(BiaoGe.options[self.name] == 1)
    end)
    return button
end

local function EnsureCurrentCharacter()
    local mailHistory = BiaoGe.mailHistory
    mailHistory[realmID] = mailHistory[realmID] or {}
    mailHistory[realmID][player] = mailHistory[realmID][player] or {
        name = player,
        realmID = realmID,
        info = {},
    }
    mailHistory[realmID][player].class = select(2, UnitClass("player"))
    mailHistory[realmID][player].level = UnitLevel("player")
end

local function RoadMail()
    local mainFrame

    -- 记录邮件
    do
        -- 寄出
        do
            local info
            local sentRecord
            local function Reset()
                info = {
                    giveMoney = 0,
                    getMoney = 0,
                    giveItem = {},
                    getItem = {},
                    type = "send1",
                }
            end
            Reset()

            hooksecurefunc("SetSendMailMoney", function(money)
                info.type = "send1"
                if GetMoney() >= money then
                    info.giveMoney = money
                else
                    info.giveMoney = 0
                end
            end)
            hooksecurefunc("SetSendMailCOD", function(money)
                if money > 0 then
                    info.type = "send2"
                    if GetMoney() >= money then
                        info.giveMoney = money
                    else
                        info.giveMoney = 0
                    end
                else
                    info.type = "send1"
                end
            end)
            hooksecurefunc("SendMail", function(name, title, text)
                info.name = name
                info.title = title
                info.text = text
                info.beforeMoney = GetMoney()
            end)

            local f = CreateFrame("Frame")
            f:RegisterEvent("MAIL_SEND_INFO_UPDATE")
            f:RegisterEvent("UI_INFO_MESSAGE")
            f:RegisterEvent("MAIL_SHOW")
            f:SetScript("OnEvent", function(self, event, ...)
                if event == "MAIL_SEND_INFO_UPDATE" then
                    wipe(info.giveItem)
                    for i = 1, ATTACHMENTS_MAX_SEND do
                        local name, itemID, texture, count, quality = GetSendMailItem(i)
                        if name then
                            tinsert(info.giveItem, {
                                itemID = itemID,
                                link = GetSendMailItemLink(i),
                                count = count,
                                quality = quality,
                            })
                        end
                    end
                elseif event == "UI_INFO_MESSAGE" then
                    local _, message = ...
                    if message == ERR_MAIL_SENT then
                        self:RegisterEvent("PLAYER_MONEY")
                        info.time = GetServerTime()
                        sentRecord = BG.Copy(info)
                        tinsert(BiaoGe.mailHistory[realmID][player].info, sentRecord)
                        -- 更新物品缓存
                        local player, realm = BG.SPN(info.name)
                        if not realm then
                            realm = realmName
                        end
                        local realmID
                        for _realmID, _realmName in pairs(BiaoGe.realmName) do
                            if realm == _realmName then
                                realmID = _realmID
                                break
                            end
                        end
                        if player and realmID then
                            if BiaoGe.playerInfo[realmID] and BiaoGe.playerInfo[realmID][player] then
                                BiaoGe.bag = BiaoGe.bag or {}
                                BiaoGe.bag[realmID] = BiaoGe.bag[realmID] or {}
                                BiaoGe.bag[realmID][player] = BiaoGe.bag[realmID][player] or {}
                                BiaoGe.bag[realmID][player].mail = BiaoGe.bag[realmID][player].mail or {}
                                for i, v in ipairs(info.giveItem) do
                                    local itemID = v.itemID
                                    BiaoGe.bag[realmID][player].mail[itemID] =
                                        (BiaoGe.bag[realmID][player].mail[itemID] or 0) + v.count
                                end
                            end
                        end
                        -- 重置
                        Reset()
                        mainFrame:UpdateAllFrame()
                    end
                elseif event == "MAIL_SHOW" then
                    Reset()
                elseif event == "PLAYER_MONEY" then
                    self:UnregisterEvent("PLAYER_MONEY")
                    if sentRecord then
                        sentRecord.afterMoney = GetMoney()
                        sentRecord = nil
                    end
                end
            end)
        end

        -- 收件
        do
            -- new
            local tbl_noRead = {}
            local tbl_isRead = {}
            local last

            local function GetBodyText(mailIndex, bodyText, isInvoice)
                if isInvoice then
                    local invoiceType, itemName, playerName, bid, buyout, deposit, consignment,
                    moneyDelay, etaHour, etaMin, count, commerceAuction = GetInboxInvoiceInfo(mailIndex)
                    if not (playerName) then return bodyText end
                    local t = ""
                    local buyMode;
                    if (bid == buyout) then
                        buyMode = "(" .. BUYOUT .. ")";
                    else
                        buyMode = "(" .. HIGH_BIDDER .. ")";
                    end
                    if (count and count > 1) then
                        itemName = format(AUCTION_MAIL_ITEM_STACK, itemName, count);
                    end
                    if (invoiceType == "buyer") then
                        t = t .. BG.STC_y2(ITEM_PURCHASED_COLON) .. " " .. itemName .. "  " .. buyMode .. "\n"
                        t = t .. BG.STC_y2(SOLD_BY_COLON) .. " " .. playerName .. "\n"
                        t = t .. BG.STC_y2(AMOUNT_PAID_COLON) .. GetMoneyString(bid) .. "\n"
                    elseif (invoiceType == "seller") then
                        t = t .. BG.STC_y2(ITEM_SOLD_COLON) .. " " .. itemName .. "\n"
                        t = t .. BG.STC_y2(PURCHASED_BY_COLON) .. " " .. playerName .. "  " .. buyMode .. "\n"
                        t = t .. BG.STC_y2(SALE_PRICE_COLON) .. GetMoneyString(bid) .. "\n"                                    -- 售价
                        t = t .. BG.STC_y2(DEPOSIT_COLON) .. BG.STC_g1(" + ") .. GetMoneyString(deposit) .. "\n"               -- 保管费
                        t = t .. BG.STC_y2(AUCTION_HOUSE_CUT_COLON) .. BG.STC_r1(" - ") .. GetMoneyString(consignment) .. "\n" -- 拍卖费
                        t = t .. BG.STC_y2(AMOUNT_RECEIVED_COLON) .. GetMoneyString(bid + deposit - consignment) .. "\n"       -- 收款金额
                    end
                    return t
                else
                    return bodyText
                end
            end

            local function GetMailInfo(mailIndex, wasRead, hasItem, daysLeft, sender, subject, money, CODAmount)
                local bodyText = ""
                local _, isInvoice
                if wasRead then
                    bodyText, _, _, _, isInvoice = GetInboxText(mailIndex)
                    bodyText = GetBodyText(mailIndex, bodyText, isInvoice)
                end
                local getItem = {}
                local itemText = ""
                if hasItem then
                    for itemIndex = 1, ATTACHMENTS_MAX_RECEIVE do
                        local name, itemID, texture, count, quality = GetInboxItem(mailIndex, itemIndex)
                        if name then
                            tinsert(getItem, {
                                itemID = itemID,
                                link = GetInboxItemLink(mailIndex, itemIndex),
                                count = count,
                                quality = quality,
                            })
                            itemText = itemText .. itemID .. "x" .. count .. " "
                        end
                    end
                end
                return {
                    id = mailIndex,
                    daysLeft = daysLeft,
                    name = sender,
                    title = subject,
                    text = bodyText,
                    type = CODAmount > 0 and "take2" or "take1",
                    getMoney = money,
                    giveMoney = CODAmount,
                    getItem = getItem,
                    giveItem = {},
                    itemText = itemText,
                }
            end

            local function IsSame(vv, v)
                if vv.daysLeft == v.daysLeft and
                    vv.name == v.name and
                    vv.title == v.title and
                    vv.type == v.type and
                    vv.getMoney == v.getMoney and
                    vv.giveMoney == v.giveMoney and
                    vv.itemText == v.itemText
                then
                    return true
                end
            end

            local function SaveMail(v)
                v.time = GetServerTime()
                v.id = nil
                v.daysLeft = nil
                v.itemText = nil
                tinsert(BiaoGe.mailHistory[realmID][player].info, BG.Copy(v))
                mainFrame:UpdateAllFrame()
            end

            hooksecurefunc("AutoLootMailItem", function(mailIndex)
                GetInboxText(mailIndex)
            end)

            BG.RegisterEvent("MAIL_INBOX_UPDATE", function(self, event)
                tbl_noRead = {}
                tbl_isRead = {}
                for mailIndex = 1, GetInboxNumItems() do
                    local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft,
                    hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(mailIndex)
                    if wasRead then
                        tinsert(tbl_isRead, GetMailInfo(mailIndex, wasRead, hasItem, daysLeft, sender, subject, money, CODAmount))
                    else
                        tinsert(tbl_noRead, GetMailInfo(mailIndex, wasRead, hasItem, daysLeft, sender, subject, money, CODAmount))
                    end
                end
                -- 检查当前已读邮件和上一次未读邮件，如果有相同的邮件，则保存
                if last then
                    for _, vv in ipairs(last) do
                        for i = #tbl_isRead, 1, -1 do
                            local v = tbl_isRead[i]
                            if IsSame(v, vv) then
                                SaveMail(v)
                                tremove(tbl_isRead, i) -- 移除该已读邮件，避免重复保存
                                break
                            end
                        end
                    end
                end
                last = tbl_noRead
            end)
        end
    end

    mainFrame = BG.MailHistoryMainFrame

    -- UI
    local db = {}
    local updateFrame = CreateFrame("Frame")
    local StartTime, StopTime, ShowInfo
    do
        mainFrame.typeTbl = {
            all = L["全部"],
            send1 = BG.STC_b1(L["发件"]),
            send2 = BG.STC_b1(L["发件(到付)"]),
            take1 = BG.STC_g1(L["收件"]),
            take2 = BG.STC_g1(L["收件(到付)"]),
        }
        local choose = {
            realmID = realmID,
            player = player,
        }
        if BiaoGe.mailHistory.isChooseRealm == 1 then choose = { realmID = realmID, } end
        local BUTTONHEIGHT = mailFrameButtonHeight
        local MAXBUTTONS = mailFrameMaxButton
        local WIDTH = 10 + 27
        local HEIGHT = (MAXBUTTONS + 1) * BUTTONHEIGHT + 15
        local FONTSIZE = 14
        local titleWidth = 0
        local titleTbl = {
            { name = L["序号"], width = 40, color = "808080", JustifyH = "CENTER", Enable = false, fontSize = FONTSIZE - 2, },
            { name = L["时间"], width = 70, color = "FFFFFF", JustifyH = "CENTER", Enable = true, fontSize = FONTSIZE - 2, },
            { name = L["类型"], width = 70, color = "FFFFFF", JustifyH = "CENTER", Enable = false },
            { name = L["角色"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = false },
            { name = L["邮件对象"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = false },
            { name = L["主题"], width = 100, color = "FFFFFF", JustifyH = "CENTER", Enable = false, fontSize = FONTSIZE - 1, },
            { name = L["发送"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = false, fontSize = FONTSIZE - 1, },
            { name = L["收到"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = false, fontSize = FONTSIZE - 1, },
            { name = L["邮寄前财产"], width = 100, color = "FFFFFF", JustifyH = "CENTER", Enable = false, fontSize = FONTSIZE - 1, },
            { name = L["邮寄后财产"], width = 100, color = "FFFFFF", JustifyH = "CENTER", Enable = false, fontSize = FONTSIZE - 1, },
        }
        for i, v in ipairs(titleTbl) do
            WIDTH = WIDTH + v.width
            titleWidth = titleWidth + v.width
        end
        mainFrame.titlebuttons = {}
        mainFrame.buttons = {}
        local f, scroll, child, bar
        local GetDB, UpdateScrollFrame, UpdateScrollButtonState, GetButtonInfo, UpdateButtons
        -- 框体
        do
            f = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            f:SetBackdropColor(0, 0, 0, 0.4)
            f:SetBackdropBorderColor(1, 1, 1, .8)
            f:SetPoint("TOPLEFT", BG.MainFrame, "TOPLEFT", 10, -65)
            f:SetSize(WIDTH + 5, HEIGHT)
            f:EnableMouse(true)
            mainFrame.frame = f
            f:SetScript("OnShow", function(self)
                mainFrame:UpdateAllFrame()
            end)

            scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate") -- 滚动
            scroll:SetWidth(WIDTH - 27 + 5)
            scroll:SetHeight(BUTTONHEIGHT * MAXBUTTONS)
            scroll:SetPoint("TOPLEFT", 0, -12 - BUTTONHEIGHT)
            bar = scroll.ScrollBar
            bar.scrollStep = 5
            BG.CreateSrollBarBackdrop(bar)
            bar:SetScript("OnValueChanged", function(self)
                self:SetScript("OnUpdate", function(self, t)
                    UpdateButtons()
                    UpdateScrollButtonState()
                    mainFrame.infoFrame:Hide()
                    self:SetScript("OnUpdate", nil)
                end)
            end)

            child = CreateFrame("Frame", nil, f) -- 子框架
            child:SetWidth(scroll:GetWidth())
            child:SetHeight(scroll:GetHeight())
            scroll:SetScrollChild(child)

            for ii = 1, MAXBUTTONS do
                mainFrame.buttons[ii] = {}
                for i = 1, #titleTbl do
                    local f = CreateFrame("Frame", nil, scroll)
                    f:SetSize(titleTbl[i].width, BUTTONHEIGHT)
                    if ii == 1 and i == 1 then
                        f:SetPoint("TOPLEFT", scroll, 10, 0)
                        f:SetParent(scroll)
                    elseif i == 1 then
                        f:SetPoint("TOPLEFT", mainFrame.buttons[(ii - 1)][1], "BOTTOMLEFT", 0, 0)
                        f:SetParent(scroll)
                    else
                        f:SetPoint("LEFT", mainFrame.buttons[ii][i - 1], "RIGHT", 0, 0)
                        f:SetParent(mainFrame.buttons[ii][1])
                    end
                    f.num = ii
                    mainFrame.buttons[ii][i] = f

                    f.Text = f:CreateFontString()
                    f.Text:SetFont(BIAOGE_TEXT_FONT, titleTbl[i].fontSize or FONTSIZE, "OUTLINE")
                    f.Text:SetPoint("CENTER")
                    f.Text:SetTextColor(RGB(titleTbl[i].color))
                    f.Text:SetJustifyH(titleTbl[i].JustifyH)
                    f.Text:SetWidth(f:GetWidth() - 2)
                    f.Text:SetHeight(f:GetHeight())
                    -- f.Text:SetWordWrap(false)

                    f:SetScript("OnEnter", function(self)
                        mainFrame.frame.lastButtonNum = self.num
                        for _ii, v in ipairs(mainFrame.buttons) do
                            mainFrame.buttons[_ii][1].ds:Hide()
                        end

                        mainFrame.buttons[ii][1].ds:Show()
                        if self.onenter then
                            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                            GameTooltip:ClearLines()
                            GameTooltip:AddLine(self.onenter, 1, 1, 1, true)
                            GameTooltip:Show()
                        end
                        ShowInfo(self)
                        StopTime()
                    end)
                    f:SetScript("OnLeave", function(self)
                        mainFrame.buttons[ii][1].ds:Hide()
                        GameTooltip:Hide()
                        StartTime()
                    end)
                    f:SetScript("OnMouseUp", function(self, button)
                        if button ~= "RightButton" then return end
                        local value = floor(bar:GetValue()) or 0
                        local num = value + ii
                        local tbl = GetButtonInfo(num)

                        local menu = {
                            {
                                text = tbl[4],
                                isTitle = true,
                                notCheckable = true,
                            },
                            {
                                text = "   ",
                                isTitle = true,
                                notCheckable = true,
                            },
                            {
                                text = L["删除该条记录"],
                                notCheckable = true,
                                func = function()
                                    local i = db[num].i
                                    local player = db[num].player
                                    local realmID = choose.realmID
                                    tremove(BiaoGe.mailHistory[realmID][player].info, i)
                                    mainFrame:UpdateAllFrame()
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
                        BG.PlaySound(1)
                    end)
                end
                CreateLine(mainFrame.buttons[ii][1], 0, titleWidth, 1, nil, 0.2)

                -- 底色材质
                local f = mainFrame.buttons[ii][1]
                f.ds = f:CreateTexture()
                f.ds:SetPoint("TOPLEFT", 0, 0)
                f.ds:SetPoint("BOTTOMRIGHT", mainFrame.buttons[ii][#titleTbl], "BOTTOMRIGHT", 0, 0)
                f.ds:SetColorTexture(1, 1, 1, 0.1)
                f.ds:Hide()
            end
        end
        -- 保存时长
        do
            local function DeleteTradeData()
                local time = GetServerTime()
                for realmID in pairs(BiaoGe.mailHistory) do
                    if type(BiaoGe.mailHistory[realmID]) == "table" then
                        for player in pairs(BiaoGe.mailHistory[realmID]) do
                            for i = #BiaoGe.mailHistory[realmID][player].info, 1, -1 do
                                local v = BiaoGe.mailHistory[realmID][player].info[i]
                                if BiaoGe.mailHistory.saveDuration > 0 and time - (v.time or 0) > 86400 * BiaoGe.mailHistory.saveDuration then
                                    tremove(BiaoGe.mailHistory[realmID][player].info, i)
                                end
                            end
                        end
                    end
                end
            end
            DeleteTradeData()

            local text = mainFrame:CreateFontString()
            text:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 260, 10)
            text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            text:SetTextColor(RGB(BG.y2))
            text:SetText(L["保存时长："])
            local dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
            dropDown:SetPoint("LEFT", text, "RIGHT", -15, -3)
            LibBG:UIDropDownMenu_SetWidth(dropDown, 80)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
            for i, v in ipairs(BG.saveDays) do
                if v.day == BiaoGe.mailHistory.saveDuration then
                    LibBG:UIDropDownMenu_SetText(dropDown, v.text)
                    break
                end
            end
            BG.dropDownToggle(dropDown)
            LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
                for i, v in ipairs(BG.saveDays) do
                    local info = LibBG:UIDropDownMenu_CreateInfo()
                    info.text = v.text
                    if v.day == BiaoGe.mailHistory.saveDuration then
                        info.checked = true
                    end
                    info.func = function()
                        BiaoGe.mailHistory.saveDuration = v.day
                        DeleteTradeData()
                        LibBG:UIDropDownMenu_SetText(dropDown, v.text)
                        UpdateScrollFrame()
                        UpdateButtons()
                    end
                    LibBG:UIDropDownMenu_AddButton(info)
                end
            end)
        end
        -- 选择角色
        do
            local text = mainFrame:CreateFontString()
            text:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 10)
            text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            text:SetTextColor(RGB(BG.y2))
            text:SetText(L["角色："])
            local dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
            dropDown:SetPoint("LEFT", text, "RIGHT", -15, -3)
            LibBG:UIDropDownMenu_SetWidth(dropDown, 180)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
            BG.dropDownToggle(dropDown)
            mainFrame.dropDown1 = dropDown
            if BiaoGe.mailHistory.isChooseRealm == 1 then
                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[realmID] or realmID) .. " - " .. L["全部角色"]))
            else
                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[realmID] or realmID) .. " - ") .. SetClassCFF(player, "player"))
            end

            LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
                for _realmID, v in pairs(BiaoGe.mailHistory) do
                    if type(v) == "table" then
                        if next(BiaoGe.mailHistory[_realmID]) then
                            local info = LibBG:UIDropDownMenu_CreateInfo()
                            info.text = BG.STC_y2(BiaoGe.realmName[_realmID] or _realmID)
                            if not choose.player and _realmID == choose.realmID then
                                info.checked = true
                            end
                            info.func = function()
                                choose = {
                                    realmID = _realmID,
                                    player = nil,
                                }
                                BiaoGe.mailHistory.isChooseRealm = 1
                                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[_realmID] or _realmID) .. " - " .. L["全部角色"]))
                                UpdateScrollFrame()
                                UpdateButtons()
                            end
                            LibBG:UIDropDownMenu_AddButton(info)
                        end

                        for _, v in pairs(BiaoGe.mailHistory[_realmID]) do
                            local info = LibBG:UIDropDownMenu_CreateInfo()
                            local playerName = "|c" .. select(4, GetClassColor(v.class)) .. v.name
                            info.text = "  " .. playerName .. (v.level and " (" .. v.level .. ")" or "")
                            info.arg1 = v.realmID .. "-" .. v.name
                            info.arg2 = "|cffFFD100" .. (BiaoGe.realmName[_realmID] or _realmID)
                                .. "-|r|c" .. select(4, GetClassColor(v.class)) .. v.name .. "|r"
                            if v.name == choose.player and v.realmID == choose.realmID then
                                info.checked = true
                            end
                            info.func = function()
                                choose = {
                                    realmID = v.realmID,
                                    player = v.name,
                                }
                                BiaoGe.mailHistory.isChooseRealm = 0
                                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[v.realmID] or v.realmID) .. " - ") .. playerName)
                                UpdateScrollFrame()
                                UpdateButtons()
                            end
                            LibBG:UIDropDownMenu_AddButton(info)
                        end
                    end
                end
            end)

            -- 删除角色
            for i = 1, L_UIDROPDOWNMENU_MAXBUTTONS do
                local button = _G["L_DropDownList1Button" .. i]
                button:HookScript("OnEnter", function()
                    if L_DropDownList1.dropdown ~= mainFrame.dropDown1 then return end
                    if not button.deleteMailPlayer then
                        local bt = CreateFrame("Button", nil, button)
                        bt:SetSize(15, 15)
                        bt:SetPoint("RIGHT", -2, 0)
                        bt:SetNormalTexture("interface/raidframe/readycheck-notready")
                        bt:SetHighlightTexture("interface/raidframe/readycheck-notready")
                        bt:RegisterForClicks("AnyUp")
                        bt.num = i
                        bt:Hide()
                        button.deleteMailPlayer = bt
                        bt:SetScript("OnClick", function(self)
                            dropDown.realmID, dropDown.player = strsplit("-", button.arg1)
                            dropDown.realmID = tonumber(dropDown.realmID)
                            dropDown.colorPlayer = button.arg2
                            LibBG:CloseDropDownMenus()
                            StaticPopup_Show("BiaoGe_DeleteMailHistoryPlayer", dropDown.colorPlayer)
                        end)
                        bt:SetScript("OnEnter", function(self)
                            button.isOnEnter = true
                            LibBG:UIDropDownMenu_StopCounting(self:GetParent():GetParent())
                            button.Highlight:Show()
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                            GameTooltip:ClearLines()
                            GameTooltip:AddLine(L["删除该角色"], 1, 1, 1, true)
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
                        if bt.deleteMailPlayer then
                            bt.deleteMailPlayer:Hide()
                        end
                    end
                    if button.arg1 then
                        button.deleteMailPlayer:Show()
                    end
                end)
                button:HookScript("OnLeave", function()
                    if L_DropDownList1.dropdown ~= mainFrame.dropDown1 then return end
                    button.isOnEnter = false
                    After(0, function()
                        if not button.isOnEnter then
                            button.deleteMailPlayer:Hide()
                        end
                    end)
                end)
            end
            StaticPopupDialogs["BiaoGe_DeleteMailHistoryPlayer"] = {
                text = L["确认删除%s的邮件记录？"],
                button1 = L["是"],
                button2 = L["否"],
                OnAccept = function()
                    LibBG:ToggleDropDownMenu(nil, nil, mainFrame.dropDown1)
                    for i = 1, _G['L_DropDownList1'].numButtons do
                        local button = _G["L_DropDownList1Button" .. i]
                        if button.arg1 then
                            local _realmID, _player = strsplit("-", button.arg1)
                            _realmID = tonumber(_realmID)
                            if _realmID == realmID and _player == player then
                                button:Click()
                                break
                            end
                        end
                    end
                    local _realmID, _player = dropDown.realmID, dropDown.player
                    BiaoGe.mailHistory[_realmID][_player] = nil
                    if _realmID == realmID and _player == player then
                        EnsureCurrentCharacter()
                    end
                    mainFrame:UpdateAllFrame()
                    SendSystemMessage(format(L["已删除%s的邮件记录。"], dropDown.colorPlayer))
                end,
                OnCancel = function()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
        end
        -- 邮件类型
        do
            local dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
            dropDown:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 14, -2)
            LibBG:UIDropDownMenu_SetWidth(dropDown, 120)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
            BG.dropDownToggle(dropDown)
            mainFrame.dropDown2 = dropDown
            local text = dropDown:CreateFontString()
            text:SetPoint("RIGHT", dropDown, "LEFT", 15, 3)
            text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            text:SetTextColor(RGB(BG.y2))
            text:SetText(L["邮件类型："])
            LibBG:UIDropDownMenu_SetText(dropDown, mainFrame.typeTbl[BiaoGe.mailHistory.type])

            local function Init(type, count)
                local info = LibBG:UIDropDownMenu_CreateInfo()
                info.text = mainFrame.typeTbl[type] .. BG.STC_dis("  (" .. count .. ")")
                info.checked = BiaoGe.mailHistory.type == type
                info.func = function()
                    BiaoGe.mailHistory.type = type
                    LibBG:UIDropDownMenu_SetText(dropDown, mainFrame.typeTbl[BiaoGe.mailHistory.type])
                    mainFrame:UpdateAllFrame()
                end
                LibBG:UIDropDownMenu_AddButton(info)
            end
            LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
                local tbl = {
                    send1 = 0,
                    send2 = 0,
                    take1 = 0,
                    take2 = 0,
                }
                local realmID = choose.realmID
                local playerTbl = {}
                if choose.player then
                    playerTbl = { choose.player }
                else
                    for player, v in pairs(BiaoGe.mailHistory[realmID]) do
                        tinsert(playerTbl, player)
                    end
                end
                for _, player in pairs(playerTbl) do
                    for i, v in ipairs(BiaoGe.mailHistory[realmID][player].info) do
                        if tbl[v.type] then
                            tbl[v.type] = tbl[v.type] + 1
                        end
                    end
                end
                Init("all", tbl.send1 + tbl.send2 + tbl.take1 + tbl.take2)
                Init("send1", tbl.send1)
                Init("send2", tbl.send2)
                Init("take1", tbl.take1)
                Init("take2", tbl.take2)
            end)
        end
        -- 标题
        do
            for i, v in ipairs(titleTbl) do
                local bt = CreateFrame("Button", nil, f, "BackdropTemplate")
                bt:SetSize(titleTbl[i].width, BUTTONHEIGHT)
                if i == 1 then
                    bt:SetPoint("TOPLEFT", 10, -10)
                else
                    bt:SetPoint("LEFT", mainFrame.titlebuttons[i - 1], "RIGHT", 0, 0)
                    bt:SetParent(mainFrame.titlebuttons[i - 1])
                end
                bt:SetNormalFontObject(BG["FontWhite" .. FONTSIZE])
                bt:SetText(titleTbl[i].name)
                bt.textwidth = bt:GetFontString():GetStringWidth()
                bt.textJustifyH = titleTbl[i].JustifyH
                bt.sortOrder = 1
                bt.id = i
                bt:SetHighlightTexture("Interface/PaperDollInfoFrame/UI-Character-Tab-Highlight")
                bt:SetEnabled(v.Enable)
                tinsert(mainFrame.titlebuttons, bt)

                bt.Text = bt:GetFontString()
                bt.Text:SetJustifyH(titleTbl[i].JustifyH)
                bt.Text:SetWidth(bt:GetWidth())
                bt.Text:SetWordWrap(false)

                bt:SetScript("OnClick", function(self)
                    BG.PlaySound(1)
                    mainFrame.isnewsorter = nil
                    if BiaoGe.mailHistory.OrderButtonID ~= self.id then
                        mainFrame.isnewsorter = true
                    end
                    if not mainFrame.isnewsorter then
                        BiaoGe.mailHistory.Order = BiaoGe.mailHistory.Order == 1 and 0 or 1
                    end
                    BiaoGe.mailHistory.OrderButtonID = self.id
                    UpdateScrollFrame()
                    UpdateButtons()
                end)
            end
            CreateLine(mainFrame.titlebuttons[1], 0, titleWidth)
            -- 排序材质
            local sorter = mainFrame:CreateTexture(nil, "OVERLAY")
            sorter:SetSize(8, 8)
            sorter:SetTexture("Interface/Buttons/ui-sortarrow")
            mainFrame.sorter = sorter
            -- 提示
            local t = scroll:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOP", 0, -5)
            t:SetTextColor(.5, .5, .5)
            t:SetText(L["该角色没有该类型的邮件记录。"])
            mainFrame.notText = t
        end

        -- 刷新滚动框
        function GetDB()
            local realmID = choose.realmID
            local playerTbl = {}
            wipe(db)
            if choose.player then
                playerTbl = { choose.player }
            else
                for player, v in pairs(BiaoGe.mailHistory[realmID]) do
                    tinsert(playerTbl, player)
                end
            end

            local type = BiaoGe.mailHistory.type
            for _, player in pairs(playerTbl) do
                if BiaoGe.mailHistory[realmID][player] then
                    for i, v in ipairs(BiaoGe.mailHistory[realmID][player].info) do
                        if not v.name then
                            v.name = UNKNOWN
                        end
                        if type == "all" or v.type == type then
                            if BiaoGe.options["showEmptyMail"] == 1 or
                                not (v.getMoney == 0 and v.giveMoney == 0 and not next(v.getItem) and not next(v.giveItem))
                            then
                                if v.name:find(BUTTON_LAG_AUCTIONHOUSE) then
                                    if BiaoGe.options["showAuctionMail"] == 1 then
                                        local tbl = BiaoGe.mailHistory[realmID][player]
                                        tinsert(db, BG.Copy(v))
                                        db[#db].i = i
                                        db[#db].player = tbl.name
                                        db[#db].colorplayer = "|c" .. select(4, GetClassColor(tbl.class)) .. tbl.name .. "|r"
                                    end
                                else
                                    local tbl = BiaoGe.mailHistory[realmID][player]
                                    tinsert(db, BG.Copy(v))
                                    db[#db].i = i
                                    db[#db].player = tbl.name
                                    db[#db].colorplayer = "|c" .. select(4, GetClassColor(tbl.class)) .. tbl.name .. "|r"
                                end
                            end
                        end
                    end
                end
            end
            -- 拍卖行邮件合并
            if BiaoGe.options["showAuctionMail"] == 1 and BiaoGe.options["togetherAuctionMail"] == 1 then
                local tbl = {}
                for i = #db, 1, -1 do
                    local v = db[i]
                    if not next(tbl) then
                        if v.name:find(BUTTON_LAG_AUCTIONHOUSE) then
                            tbl = BG.Copy(v)
                            tremove(db, i)
                        end
                    else
                        if v.name:find(BUTTON_LAG_AUCTIONHOUSE) and v.player == tbl.player then
                            if not tbl.text:find(MAIL_SUBJECT_LABEL) then
                                tbl.text = BG.STC_y2(MAIL_SUBJECT_LABEL) .. tbl.title .. "\n" .. tbl.text
                            end
                            tbl.text = tbl.text .. "\n" .. BG.STC_y2(MAIL_SUBJECT_LABEL) .. v.title .. "\n" .. v.text
                            local count = tbl.title:match(L["%((%d+)个邮件合并%)"]) or 1
                            tbl.title = format(BG.STC_y1(L["(%s个邮件合并)"]), count + 1)
                            tbl.getMoney = tbl.getMoney + v.getMoney
                            for _, vv in ipairs(v.getItem) do
                                tinsert(tbl.getItem, BG.Copy(vv))
                            end
                            tremove(db, i)
                        else
                            tinsert(db, tbl)
                            tbl = {}
                        end
                    end
                end
                if next(tbl) then
                    tinsert(db, tbl)
                end
            end

            sort(db, function(a, b)
                if BiaoGe.mailHistory.OrderButtonID == 2 then -- 按时间
                    local key = "time"
                    if a[key] and b[key] then
                        if a[key] ~= b[key] then
                            if BiaoGe.mailHistory.Order == 1 then
                                return a[key] > b[key]
                            else
                                return b[key] > a[key]
                            end
                        end
                    end
                end
                local key = "title"
                if a[key] and b[key] then
                    if a[key] ~= b[key] then
                        if BiaoGe.mailHistory.Order == 1 then
                            return a[key] > b[key]
                        else
                            return b[key] > a[key]
                        end
                    end
                end
                return false
            end)
        end

        function UpdateScrollFrame()
            GetDB()

            local sorter = mainFrame.sorter
            local bt = mainFrame.titlebuttons[BiaoGe.mailHistory.OrderButtonID]
            sorter:SetParent(bt)
            sorter:ClearAllPoints()
            if bt.textJustifyH == "CENTER" then
                sorter:SetPoint("LEFT", bt, "CENTER", bt.textwidth / 2, 0)
            else
                sorter:SetPoint("LEFT", bt, "LEFT", bt.textwidth, 0)
            end
            if not mainFrame.isnewsorter then
                if BiaoGe.mailHistory.Order == 1 then
                    sorter:SetTexCoord(0, 0.5, 0, 1)
                else
                    sorter:SetTexCoord(0, 0.5, 1, 0)
                end
            end

            local m = #db - MAXBUTTONS
            bar:SetMinMaxValues(0, max(0, m))
            UpdateScrollButtonState()

            mainFrame.notText:SetShown(#db == 0)
        end

        function UpdateScrollButtonState()
            local currValue = bar:GetValue();
            local scrollDownButton = bar.ScrollDownButton or _G[bar:GetName() .. "ScrollDownButton"];
            local scrollUpButton = bar.ScrollUpButton or _G[bar:GetName() .. "ScrollUpButton"];
            scrollUpButton:Enable();
            scrollDownButton:Enable();
            local minVal, maxVal = bar:GetMinMaxValues();
            if (currValue >= maxVal) then
                if (scrollDownButton) then
                    scrollDownButton:Disable()
                end
            end
            if (currValue <= minVal) then
                if (scrollUpButton) then
                    scrollUpButton:Disable();
                end
            end
        end

        function GetButtonInfo(num)
            local v = db[num]
            if not v then return end

            local targetText = v.name
            if targetText:find(BUTTON_LAG_AUCTIONHOUSE) then
                targetText = BG.STC_y1(targetText)
            end

            local giveItemText = ""
            local count = #v.giveItem
            if count == 1 then
                giveItemText = AddIconByLink(v.giveItem[1].link) .. v.giveItem[1].link
            elseif count > 1 then
                giveItemText = "|A:ParagonReputation_Bag:0:0|a" .. "x" .. count
            end
            local giveMoneyText = ""
            local money = v.giveMoney
            if money > 0 then
                giveMoneyText = GetMoneyString(money, true)
            end
            local giveSplit = ""
            if giveItemText ~= "" and giveMoneyText ~= "" then
                giveSplit = ", "
            end

            local getItemText = ""
            local count = #v.getItem
            if count == 1 then
                getItemText = AddIconByLink(v.getItem[1].link) .. v.getItem[1].link
            elseif count > 1 then
                getItemText = "|A:ParagonReputation_Bag:0:0|a" .. "x" .. count
            end
            local getMoneyText = ""
            local money = v.getMoney
            if money > 0 then
                getMoneyText = GetMoneyString(money, true)
            end
            local getSplit = ""
            if getItemText ~= "" and getMoneyText ~= "" then
                getSplit = ", "
            end

            return {
                num,                                                                              -- 序号
                date("%m-%d %H:%M", v.time),                                                      -- 时间
                mainFrame.typeTbl[v.type],                                                        -- 类型
                v.colorplayer,                                                                    -- 角色
                targetText,                                                                       -- 邮寄对象
                v.title,                                                                          -- 主题
                giveItemText .. giveSplit .. giveMoneyText,                                       -- 发送
                getItemText .. getSplit .. getMoneyText,                                          -- 收到
                v.beforeMoney and GetMoneyString(floor(v.beforeMoney / 1e4) * 10000, true) or "", -- 邮寄前财产
                v.afterMoney and GetMoneyString(floor(v.afterMoney / 1e4) * 10000, true) or "",   -- 邮寄后财产
            }
        end

        function UpdateButtons()
            local value = floor(bar:GetValue()) or 0
            for ii = 1, MAXBUTTONS do
                local num = value + ii
                local tbl = GetButtonInfo(num)
                for i = 1, #titleTbl do
                    if tbl then
                        mainFrame.buttons[ii][i].Text:SetText(tbl[i])
                        mainFrame.buttons[ii][i].dbNum = num
                        if mainFrame.buttons[ii][i].Text:IsTruncated() then
                            mainFrame.buttons[ii][i].onenter = tbl[i]
                        else
                            mainFrame.buttons[ii][i].onenter = nil
                        end
                        mainFrame.buttons[ii][i]:Show()
                    else
                        mainFrame.buttons[ii][i]:Hide()
                    end
                end
            end
            GameTooltip:Hide()
        end

        function mainFrame:UpdateAllFrame()
            if not self:IsVisible() then return end
            UpdateScrollFrame()
            UpdateButtons()
        end
    end

    -- 邮件详细框
    do
        function StartTime()
            updateFrame.elapsed = 0
            updateFrame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = self.elapsed + elapsed
                if self.elapsed >= .5 then
                    self:SetScript("OnUpdate", nil)
                    mainFrame.infoFrame:Hide()
                end
            end)
        end

        function StopTime()
            updateFrame.elapsed = 0
            updateFrame:SetScript("OnUpdate", nil)
        end

        local frame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
        frame:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 1,
        })
        frame:SetBackdropColor(0, 0, 0, 0.4)
        frame:SetBackdropBorderColor(1, 1, 1, .8)
        frame:SetPoint("TOPLEFT", mainFrame.frame, "TOPRIGHT", 2, 0)
        frame:SetSize(320, 350)
        frame:Hide()
        mainFrame.infoFrame = frame
        frame:HookScript("OnEnter", function(self)
            StopTime()
            local num = mainFrame.frame.lastButtonNum
            mainFrame.buttons[num][1].ds:Show()
        end)
        frame:HookScript("OnLeave", StartTime)
        frame:HookScript("OnHide", function(self)
            local num = mainFrame.frame.lastButtonNum
            mainFrame.buttons[num][1].ds:Hide()
        end)

        frame.timeText = frame:CreateFontString()
        frame.timeText:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
        frame.timeText:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 2, 2)
        frame.timeText:SetTextColor(1, 1, 1)

        -- 各种文本
        do
            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOP", 0, -5)
            t:SetJustifyH("RIGHT")
            frame.typeText = t
            frame.line = frame:CreateLine()
            frame.line:SetColorTexture(1, 1, 1, .8)
            frame.line:SetStartPoint("TOPLEFT", 1, -23)
            frame.line:SetEndPoint("TOPRIGHT", -1, -23)
            frame.line:SetThickness(1)

            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPRIGHT", frame, "TOPLEFT", 80, -35)
            t:SetJustifyH("RIGHT")
            t:SetTextColor(1, .82, 0)
            frame.nameText1 = t
            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("LEFT", frame.nameText1, "RIGHT", 5, -0)
            t:SetJustifyH("LEFT")
            frame.nameText2 = t
            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPRIGHT", frame.nameText1, "BOTTOMRIGHT", 0, -10)
            t:SetJustifyH("RIGHT")
            t:SetText(MAIL_SUBJECT_LABEL)
            t:SetTextColor(1, .82, 0)
            frame.titleText1 = t
            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("LEFT", frame.titleText1, "RIGHT", 5, -0)
            t:SetJustifyH("LEFT")
            t:SetWidth(frame:GetWidth() - select(4, frame.nameText1:GetPoint()) - 20)
            t:SetWordWrap(false)
            frame.titleText2 = t

            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPRIGHT", frame.titleText1, "BOTTOMRIGHT", 0, -10)
            t:SetTextColor(1, 0.82, 0)
            t:SetText(L["内容："])
            t:SetJustifyH("RIGHT")
            frame.textText1 = t
            local f = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            f:SetBackdropColor(0, 0, 0, 0.5)
            f:SetBackdropBorderColor(1, 1, 1, 0.6)
            f:SetSize(215, 120)
            f:SetPoint("TOPLEFT", frame.textText1, "TOPRIGHT", 5, 0)
            frame.textbg = f
            local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
            scroll:SetWidth(f:GetWidth() - 10)
            scroll:SetHeight(f:GetHeight() - 10)
            scroll:SetPoint("CENTER")
            BG.CreateSrollBarBackdrop(scroll.ScrollBar)
            BG.HookScrollBarShowOrHide(scroll, true)
            local edit = CreateFrame("EditBox", nil, f)
            edit:SetWidth(scroll:GetWidth())
            edit:SetAutoFocus(false)
            edit:EnableMouse(false)
            edit:SetTextInsets(0, 0, 0, 0)
            edit:SetMultiLine(true)
            edit:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
            frame.textText2 = edit
            scroll:SetScrollChild(edit)

            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPRIGHT", frame.textText1, "BOTTOMRIGHT", 0, -0 - frame.textbg:GetHeight())
            t:SetJustifyH("RIGHT")
            t:SetTextColor(1, .82, 0)
            frame.moneyText1 = t
            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("LEFT", frame.moneyText1, "RIGHT", 5, -0)
            t:SetJustifyH("LEFT")
            t:SetWidth(frame:GetWidth() - select(4, frame.nameText1:GetPoint()) - 20)
            t:SetWordWrap(false)
            frame.moneyText2 = t
        end

        -- 物品框
        do
            local t = frame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPRIGHT", frame.moneyText1, "BOTTOMRIGHT", 0, -10)
            t:SetJustifyH("RIGHT")
            t:SetTextColor(1, .82, 0)
            frame.itemText = t

            local f = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            f:SetBackdropColor(0, 0, 0, 0.5)
            f:SetBackdropBorderColor(1, 1, 1, 0.6)
            f:SetSize(frame.textbg:GetWidth(), 85)
            f:SetPoint("TOPLEFT", frame.itemText, "TOPRIGHT", 5, 0)
            frame.itembg = f
            local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate") -- 滚动
            scroll:SetWidth(f:GetWidth())
            scroll:SetHeight(f:GetHeight() - 4)
            scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -2)
            f.scroll = scroll
            BG.CreateSrollBarBackdrop(scroll.ScrollBar)
            BG.HookScrollBarShowOrHide(scroll, true)
            local child = CreateFrame("Frame", nil, scroll) -- 子框架
            child:SetWidth(scroll:GetWidth())
            child:SetHeight(scroll:GetHeight())
            scroll:SetScrollChild(child)
            frame.itemframe = child
            frame.buttons = {}
        end

        function ShowInfo(self)
            local num = self.dbNum
            local v = db[num]
            local frame = mainFrame.infoFrame
            local type
            local r, g, b
            if v.type:find("send") then
                type = "send"
                r, g, b = RGB(BG.b1)
            else
                type = "take"
                r, g, b = 0, 1, 0
            end
            frame.timeText:SetText(date("%y/%m/%d %H:%M", v.time))
            frame:SetBackdropBorderColor(r, g, b, .8)
            frame:SetBackdropColor(r, g, b, 0.05)
            frame.line:SetColorTexture(r, g, b, .8)
            frame.textbg:SetBackdropBorderColor(r, g, b, .8)
            frame.textbg:SetBackdropColor(r, g, b, 0.05)
            frame.itembg:SetBackdropBorderColor(r, g, b, .8)
            frame.itembg:SetBackdropColor(r, g, b, 0.05)

            frame.typeText:SetText(mainFrame.typeTbl[v.type])
            frame.nameText1:SetText(type == "send" and MAIL_TO_LABEL or FROM)
            local targetText = v.name
            if v.name:find(BUTTON_LAG_AUCTIONHOUSE) then
                targetText = BG.STC_y1(targetText)
            end
            frame.nameText2:SetText(targetText)
            frame.titleText2:SetText(v.title or "")
            frame.textText2:SetText(v.text or "")

            if v.giveMoney == 0 and v.getMoney == 0 then
                frame.moneyText1:Hide()
                frame.moneyText2:Hide()
            else
                frame.moneyText1:Show()
                frame.moneyText2:Show()

                local money = v.giveMoney == 0 and v.getMoney or v.giveMoney
                local moneyText = ""
                if v.type == "send1" then
                    moneyText = L["发送金额："]
                elseif v.type == "send2" then
                    moneyText = L["付款取信："]
                elseif v.type == "take1" then
                    moneyText = L["收到金额："]
                elseif v.type == "take2" then
                    moneyText = L["支出金额："]
                end
                frame.moneyText1:SetText(moneyText)
                frame.moneyText2:SetText(GetMoneyString(money, true))
            end

            -- 物品
            if #v.giveItem == 0 and #v.getItem == 0 then
                frame.itemText:Hide()
                frame.itembg:Hide()
            else
                for i, bt in ipairs(frame.buttons) do
                    bt:Hide()
                end
                wipe(frame.buttons)
                frame.itemText:Show()
                frame.itembg:Show()
                if type == "send" then
                    frame.itemText:SetText(L["发送物品："])
                else
                    frame.itemText:SetText(L["收到物品："])
                end
                local db = #v.giveItem == 0 and v.getItem or v.giveItem

                local function CreateButton(i)
                    local v = db[i]
                    local r, g, b
                    local a = 1
                    if v.quality then
                        r, g, b = GetItemQualityColor(v.quality)
                    else
                        r, g, b = 1, 1, 1
                        a = 0
                    end
                    local bt = CreateFrame("Frame", nil, frame.itemframe, "BackdropTemplate")
                    bt:SetBackdrop({
                        edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                        edgeSize = 1,
                    })
                    bt:SetBackdropBorderColor(r, g, b, a)
                    bt:SetSize(30, 30)
                    if i == 1 then
                        bt:SetPoint("TOPLEFT", frame.itemframe, "TOPLEFT", 5, -3)
                    elseif (i - 1) % 6 == 0 then
                        bt:SetPoint("TOPLEFT", frame.buttons[i - 6], "BOTTOMLEFT", 0, -5)
                    else
                        bt:SetPoint("TOPLEFT", frame.buttons[i - 1], "TOPRIGHT", 5, 0)
                    end
                    bt.itemID = v.itemID
                    bt.link = v.link
                    tinsert(frame.buttons, bt)
                    bt:HookScript("OnEnter", function(self)
                        StopTime()
                        local num = mainFrame.frame.lastButtonNum
                        mainFrame.buttons[num][1].ds:Show()
                        GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
                        GameTooltip:ClearLines()
                        GameTooltip:SetHyperlink(bt.link)
                    end)
                    bt:HookScript("OnLeave", function(self)
                        GameTooltip:Hide()
                        StartTime()
                    end)

                    bt.icon = bt:CreateTexture(nil, "BACKGROUND")
                    bt.icon:SetAllPoints()
                    bt.icon:SetTexCoord(.07, .93, .07, .93)
                    bt.icon:SetTexture(select(5, GetItemInfoInstant(bt.itemID)))

                    if v.count > 1 then
                        bt.count = bt:CreateFontString()
                        bt.count:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                        bt.count:SetPoint("BOTTOMRIGHT", -1, 1)
                        bt.count:SetText(v.count)
                    end

                    local typeID = select(6, GetItemInfoInstant(v.itemID))
                    if typeID == 2 or typeID == 4 then
                        local link = v.link
                        local item = Item:CreateFromItemLink(link)
                        item:ContinueOnItemLoad(function()
                            local level = select(4, GetItemInfo(link))
                            if level then
                                bt.level = bt:CreateFontString()
                                bt.level:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
                                bt.level:SetPoint("BOTTOM", 1, 1)
                                bt.level:SetText(level)
                            end
                        end)
                    end
                end

                for i, v in ipairs(db) do
                    CreateButton(i)
                end
            end

            mainFrame.infoFrame:Show()
        end
    end

    -- 选项
    do
        local mainFrame = BG.MailHistoryMainFrame
        local last
        -- 显示拍卖行邮件
        do
            local name = "showAuctionMail"
            BG.options[name .. "reset"] = 1
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["显示拍卖行邮件"]
            local ontext
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint("TOPLEFT", mainFrame.frame, "BOTTOMLEFT", 0, -10)
            mainFrame.optionsButton_showAuctionMail = bt
            last = bt
            bt:HookScript("OnClick", function(self)
                local name1 = "togetherAuctionMail"
                if self:GetChecked() then
                    BG.options["button" .. name1]:Show()
                else
                    BG.options["button" .. name1]:Hide()
                end
                mainFrame:UpdateAllFrame()
            end)
        end
        -- 合并相邻的拍卖行邮件
        do
            local name = "togetherAuctionMail"
            BG.options[name .. "reset"] = 0
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["合并相邻的拍卖行邮件"]
            local ontext = {
                text,
                L["相邻的拍卖行邮件会被合并显示为一个邮件，节省空间。"],
            }
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint("TOPLEFT", last, "BOTTOMRIGHT", 0, 0)
            last = bt
            bt:HookScript("OnClick", function(self)
                mainFrame:UpdateAllFrame()
            end)
            if BiaoGe.options["showAuctionMail"] ~= 1 then
                bt:Hide()
            end
        end
        -- 显示空邮件
        do
            local name = "showEmptyMail"
            BG.options[name .. "reset"] = 1
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["显示空邮件"]
            local ontext = {
                text,
                L["没有附件的邮件，也会被显示。"],
            }
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint("TOPLEFT", mainFrame.optionsButton_showAuctionMail, "BOTTOMLEFT", 0, -30)
            last = bt
            bt:HookScript("OnClick", function(self)
                mainFrame:UpdateAllFrame()
            end)
        end
    end
end

BG.Init(function()
    BiaoGe.mailHistory = BiaoGe.mailHistory or {}
    local mailHistory = BiaoGe.mailHistory
    mailHistory.saveDuration = mailHistory.saveDuration or 30
    mailHistory.OrderButtonID = mailHistory.OrderButtonID or 2
    mailHistory.Order = mailHistory.Order or 1
    mailHistory.type = mailHistory.type or "all"
    if mailHistory.type ~= "all" and mailHistory.type ~= "send1" and mailHistory.type ~= "send2"
        and mailHistory.type ~= "take1" and mailHistory.type ~= "take2"
    then
        mailHistory.type = "all"
    end
    mailHistory.isChooseRealm = mailHistory.isChooseRealm or 1
    EnsureCurrentCharacter()

    RoadMail()
end)
