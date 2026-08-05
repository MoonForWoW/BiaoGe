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
local ver = ns.ver
local After = C_Timer.After
local player = UnitName("player")
local realmID = GetRealmID()
local pt = print

local tradeFrameMaxButton = 15
local tradeFrameButtonHeight = 32

local function CreateLine(parent, y, width, height, color, alpha)
    local line = parent:CreateLine()
    line:SetColorTexture(RGB(color or "808080", alpha or 1))
    line:SetStartPoint("BOTTOMLEFT", 0, y)
    line:SetEndPoint("BOTTOMLEFT", width, y)
    line:SetThickness(height or 1.5)
    return line
end

local SendSystemMessage = BG.SendSystemMessage

local function AddIconByLink(link)
    local icon = select(5, GetItemInfoInstant(link))
    return AddTexture(icon)
end

local function EnsureCurrentCharacter()
    local tradeHistory = BiaoGe.tradeHistory
    tradeHistory[realmID] = tradeHistory[realmID] or {}
    tradeHistory[realmID][player] = tradeHistory[realmID][player] or {
        name = player,
        realmID = realmID,
        info = {},
    }
    tradeHistory[realmID][player].class = select(2, UnitClass("player"))
    tradeHistory[realmID][player].level = UnitLevel("player")
end

local function RoadTrade()
    local mainFrame
    local trade = {}

    -- 交易事件
    do
        local function GetTradeInfo()
            trade = {
                time = GetServerTime(),
                zone = GetZoneText(),
                beforeMoney = GetMoney(),
                playerName = UnitName("player"),
                targetName = UnitName("NPC"),
                playerClass = select(2, UnitClass("player")),
                targetClass = select(2, UnitClass("NPC")),
                playermoney = GetPlayerTradeMoney(),
                targetmoney = GetTargetTradeMoney(),
                playeritems = {},
                targetitems = {},
            }
            for i = 1, 7 do
                local link = GetTradePlayerItemLink(i)
                local name, texture, quantity, quality, isUsable, enchant = GetTradePlayerItemInfo(i)
                if link then
                    trade.playeritems[i] = { name = name, item = link, count = quantity, quality = quality, }
                end

                local link = GetTradeTargetItemLink(i)
                local name, texture, quantity, quality, isUsable, enchant = GetTradeTargetItemInfo(i)
                if link then
                    trade.targetitems[i] = { name = name, item = link, count = quantity, quality = quality, }
                end
            end
        end

        local target
        local success
        local logo = "BiaoGe: "
        local f = CreateFrame("Frame")
        f:RegisterEvent("TRADE_ACCEPT_UPDATE")
        f:RegisterEvent("UI_INFO_MESSAGE")
        f:RegisterEvent("TRADE_CLOSED")
        f:RegisterEvent("TRADE_SHOW")
        f:SetScript("OnEvent", function(self, event, ...)
            if event == "TRADE_ACCEPT_UPDATE" then
                local playerAccepted, targetAccepted = ...
                if playerAccepted == 1 or targetAccepted == 1 then
                    GetTradeInfo()
                end
            elseif event == "UI_INFO_MESSAGE" then
                local _, text = ...
                if text == ERR_TRADE_COMPLETE then
                    success = true
                    if not trade.time then
                        GetTradeInfo()
                    end
                    local record = BG.Copy(trade)
                    tinsert(BiaoGe.tradeHistory[realmID][player].info, record)
                    After(.5, function()
                        record.afterMoney = GetMoney()
                        if BG.TradeHistoryMainFrame.frame:IsVisible() then
                            BG.UpdateTradeHistoryScrollFrame()
                        end
                    end)

                    if BiaoGe.options.tradeSuccessSound == 1 then
                        BG.PlaySound("tradeSuccess")
                    end
                    if BiaoGe.options.tradeMSG == 1 and BiaoGe.options.tradeMSG_success == 1 then
                        local channel = BiaoGe.options["tradeMSG_channel"]
                        if channel ~= "WHISPER" then
                            if IsInRaid(1) then
                                channel = "RAID"
                            elseif IsInGroup(1) then
                                channel = "PARTY"
                            else
                                return
                            end
                        end

                        local msg = ""
                        local giveText = ""
                        local playermoneyText = ""
                        local playeritemText = ""
                        local money = floor(trade.playermoney / 1e4)
                        if money ~= 0 then
                            playermoneyText = money .. "g"
                        end
                        for i = 1, 6 do
                            local v = trade.playeritems[i]
                            if v then
                                local countText = ""
                                if v.count > 1 then
                                    countText = "x" .. v.count
                                end
                                playeritemText = playeritemText .. v.item .. countText
                            end
                        end
                        if playermoneyText ~= "" and playeritemText ~= "" then
                            playermoneyText = playermoneyText .. " "
                        end
                        giveText = playermoneyText .. playeritemText
                        if giveText ~= "" then
                            giveText = L["(交出)"] .. giveText
                        end

                        local getText = ""
                        local targetmoneyText = ""
                        local targetitemText = ""
                        local money = floor(trade.targetmoney / 1e4)
                        if money ~= 0 then
                            targetmoneyText = money .. "g"
                        end
                        for i = 1, 6 do
                            local v = trade.targetitems[i]
                            if v then
                                local countText = ""
                                if v.count > 1 then
                                    countText = "x" .. v.count
                                end
                                targetitemText = targetitemText .. v.item .. countText
                            end
                        end
                        if targetmoneyText ~= "" and targetitemText ~= "" then
                            targetmoneyText = targetmoneyText .. " "
                        end
                        getText = targetmoneyText .. targetitemText
                        if getText ~= "" then
                            getText = L["(收到)"] .. getText
                        end

                        if giveText ~= "" and getText ~= "" then
                            msg = giveText .. L["，"] .. getText
                        else
                            msg = giveText .. getText
                        end

                        SendChatMessage(logo .. format(L["与<%s>交易成功！%s"], channel == "WHISPER" and L["你"] or target, msg), channel, nil, target)
                    end
                elseif text == ERR_TRADE_CANCELLED or text == ERR_TRADE_BAG_FULL or text == ERR_TRADE_TARGET_BAG_FULL then
                end
            elseif event == "TRADE_SHOW" then
                success = false
                target = UnitName("NPC")
            elseif event == "TRADE_CLOSED" then
                After(0, function()
                    if not success and target then
                        if BiaoGe.options.tradeFalseSound == 1 then
                            BG.PlaySound("tradeFalse")
                        end
                        if BiaoGe.options.tradeMSG == 1 and BiaoGe.options.tradeMSG_false == 1 then
                            local channel = BiaoGe.options["tradeMSG_channel"]
                            if channel ~= "WHISPER" then
                                if IsInRaid(1) then
                                    channel = "RAID"
                                elseif IsInGroup(1) then
                                    channel = "PARTY"
                                else
                                    return
                                end
                            end
                            SendChatMessage(logo .. format(L["与<%s>交易失败！"], channel == "WHISPER" and L["你"] or target),
                                channel, nil, target)
                        end
                    end
                end)
            end
        end)
    end

    mainFrame = BG.TradeHistoryMainFrame

    -- UI
    do
        local mainFrame = BG.TradeHistoryMainFrame
        local choose = {
            realmID = realmID,
            player = player,
        }
        if BiaoGe.tradeHistory.isChooseRealm == 1 then choose = { realmID = realmID, } end
        local BUTTONHEIGHT = tradeFrameButtonHeight
        local MAXBUTTONS = tradeFrameMaxButton
        local WIDTH = 10 + 27
        local HEIGHT = (MAXBUTTONS + 1) * BUTTONHEIGHT + 15
        local FONTSIZE = 14
        local titleWidth = 0
        local db = {}
        local titlebuttons = {}
        local buttons = {}
        local dropDown
        local titleTbl = {
            { name = L["序号"], width = 40, color = "808080", JustifyH = "CENTER", Enable = false, fontSize = FONTSIZE - 2, },
            { name = L["时间"], width = 70, color = "FFFFFF", JustifyH = "CENTER", Enable = true, fontSize = FONTSIZE - 2, },
            { name = L["地点"], width = 70, color = "FFFFFF", JustifyH = "CENTER", Enable = true, fontSize = FONTSIZE - 1, },
            { name = L["角色"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = false },
            { name = L["交易对象"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = false },
            { name = L["交出"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = false, fontSize = FONTSIZE - 1, },
            { name = L["收到"], width = 90, color = "FFFFFF", JustifyH = "CENTER", Enable = false, fontSize = FONTSIZE - 1, },
            { name = L["交易前财产"], width = 100, color = "FFFFFF", JustifyH = "CENTER", Enable = false, fontSize = FONTSIZE - 1, },
            { name = L["交易后财产"], width = 100, color = "FFFFFF", JustifyH = "CENTER", Enable = false, fontSize = FONTSIZE - 1, },
        }
        for i, v in ipairs(titleTbl) do
            WIDTH = WIDTH + v.width
            titleWidth = titleWidth + v.width
        end

        local f, scroll, child, bar
        local GetDB, UpdateScrollFrame, UpdateScrollButtonState, GetButtonInfo, UpdateButtons
        local updateFrame = CreateFrame("Frame")
        local StartTime, StopTime
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
                UpdateScrollFrame()
                UpdateButtons()
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
                buttons[ii] = {}
                for i = 1, #titleTbl do
                    local f = CreateFrame("Frame", nil, scroll)
                    f:SetSize(titleTbl[i].width, BUTTONHEIGHT)
                    if ii == 1 and i == 1 then
                        f:SetPoint("TOPLEFT", scroll, 10, 0)
                        f:SetParent(scroll)
                    elseif i == 1 then
                        f:SetPoint("TOPLEFT", buttons[(ii - 1)][1], "BOTTOMLEFT", 0, 0)
                        f:SetParent(scroll)
                    else
                        f:SetPoint("LEFT", buttons[ii][i - 1], "RIGHT", 0, 0)
                        f:SetParent(buttons[ii][1])
                    end
                    f.num = ii
                    buttons[ii][i] = f

                    f.Text = f:CreateFontString()
                    f.Text:SetFont(BIAOGE_TEXT_FONT, titleTbl[i].fontSize or FONTSIZE, "OUTLINE")
                    f.Text:SetPoint("CENTER")
                    f.Text:SetTextColor(RGB(titleTbl[i].color))
                    f.Text:SetJustifyH(titleTbl[i].JustifyH)
                    f.Text:SetWidth(f:GetWidth() - 2)
                    f.Text:SetHeight(f:GetHeight())

                    f:SetScript("OnEnter", function(self)
                        mainFrame.frame.lastButtonNum = self.num
                        for _ii, v in ipairs(buttons) do
                            buttons[_ii][1].ds:Hide()
                        end

                        buttons[ii][1].ds:Show()
                        if self.onenter then
                            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                            GameTooltip:ClearLines()
                            GameTooltip:AddLine(self.onenter, 1, 1, 1, true)
                            GameTooltip:Show()
                        end
                        BG.ShowTradeHistoryInfo(self)
                        StopTime()
                    end)
                    f:SetScript("OnLeave", function(self)
                        buttons[ii][1].ds:Hide()
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
                                -- text = BG.STC_dis("(" .. tbl[1] .. ")") .. " " .. tbl[4],
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
                                    tremove(BiaoGe.tradeHistory[realmID][player].info, i)
                                    UpdateScrollFrame()
                                    UpdateButtons()
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
                CreateLine(buttons[ii][1], 0, titleWidth, 1, nil, 0.2)

                -- 底色材质
                local f = buttons[ii][1]
                f.ds = f:CreateTexture()
                f.ds:SetPoint("TOPLEFT", 0, 0)
                f.ds:SetPoint("BOTTOMRIGHT", buttons[ii][#titleTbl], "BOTTOMRIGHT", 0, 0)
                f.ds:SetColorTexture(1, 1, 1, 0.1)
                f.ds:Hide()
            end
        end
        -- 删除记录
        do
            local function DeleteTradeData()
                local time = GetServerTime()
                for realmID in pairs(BiaoGe.tradeHistory) do
                    if type(BiaoGe.tradeHistory[realmID]) == "table" then
                        for player in pairs(BiaoGe.tradeHistory[realmID]) do
                            for i = #BiaoGe.tradeHistory[realmID][player].info, 1, -1 do
                                local v = BiaoGe.tradeHistory[realmID][player].info[i]
                                if BiaoGe.tradeHistory.saveDuration > 0 and time - (v.time or 0) > 86400 * BiaoGe.tradeHistory.saveDuration then
                                    tremove(BiaoGe.tradeHistory[realmID][player].info, i)
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
                if v.day == BiaoGe.tradeHistory.saveDuration then
                    LibBG:UIDropDownMenu_SetText(dropDown, v.text)
                    break
                end
            end
            BG.dropDownToggle(dropDown)
            LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
                for i, v in ipairs(BG.saveDays) do
                    local info = LibBG:UIDropDownMenu_CreateInfo()
                    info.text = v.text
                    if v.day == BiaoGe.tradeHistory.saveDuration then
                        info.checked = true
                    end
                    info.func = function()
                        BiaoGe.tradeHistory.saveDuration = v.day
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
            dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
            dropDown:SetPoint("LEFT", text, "RIGHT", -15, -3)
            LibBG:UIDropDownMenu_SetWidth(dropDown, 180)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
            BG.dropDownToggle(dropDown)
            mainFrame.dropDown = dropDown
            if BiaoGe.tradeHistory.isChooseRealm == 1 then
                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[realmID] or realmID) .. " - " .. L["全部角色"]))
            else
                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[realmID] or realmID) .. " - ") .. SetClassCFF(player, "player"))
            end

            LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
                for _realmID, v in pairs(BiaoGe.tradeHistory) do
                    if type(v) == "table" then
                        if next(BiaoGe.tradeHistory[_realmID]) then
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
                                BiaoGe.tradeHistory.isChooseRealm = 1
                                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[_realmID] or _realmID) .. " - " .. L["全部角色"]))
                                UpdateScrollFrame()
                                UpdateButtons()
                            end
                            LibBG:UIDropDownMenu_AddButton(info)
                        end

                        for _, v in pairs(BiaoGe.tradeHistory[_realmID]) do
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
                                BiaoGe.tradeHistory.isChooseRealm = 0
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
                    if L_DropDownList1.dropdown ~= mainFrame.dropDown then return end
                    if not button.deleteTradePlayer then
                        local bt = CreateFrame("Button", nil, button)
                        bt:SetSize(15, 15)
                        bt:SetPoint("RIGHT", -2, 0)
                        bt:SetNormalTexture("interface/raidframe/readycheck-notready")
                        bt:SetHighlightTexture("interface/raidframe/readycheck-notready")
                        bt:RegisterForClicks("AnyUp")
                        bt.num = i
                        bt:Hide()
                        button.deleteTradePlayer = bt
                        bt:SetScript("OnClick", function(self)
                            dropDown.realmID, dropDown.player = strsplit("-", button.arg1)
                            dropDown.realmID = tonumber(dropDown.realmID)
                            dropDown.colorPlayer = button.arg2
                            LibBG:CloseDropDownMenus()
                            StaticPopup_Show("BiaoGe_DeleteTradeHistoryPlayer", dropDown.colorPlayer)
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
                        if bt.deleteTradePlayer then
                            bt.deleteTradePlayer:Hide()
                        end
                    end
                    if button.arg1 then
                        button.deleteTradePlayer:Show()
                    end
                end)
                button:HookScript("OnLeave", function()
                    if L_DropDownList1.dropdown ~= mainFrame.dropDown then return end
                    button.isOnEnter = false
                    After(0, function()
                        if not button.isOnEnter then
                            button.deleteTradePlayer:Hide()
                        end
                    end)
                end)
            end
            StaticPopupDialogs["BiaoGe_DeleteTradeHistoryPlayer"] = {
                text = L["确认删除%s的交易记录？"],
                button1 = L["是"],
                button2 = L["否"],
                OnAccept = function()
                    LibBG:ToggleDropDownMenu(nil, nil, mainFrame.dropDown)
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
                    BiaoGe.tradeHistory[_realmID][_player] = nil
                    if _realmID == realmID and _player == player then
                        EnsureCurrentCharacter()
                    end
                    BG.UpdateTradeHistoryScrollFrame()
                    SendSystemMessage(format(L["已删除%s的交易记录。"], dropDown.colorPlayer))
                end,
                OnCancel = function()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
        end
        -- 搜索
        do
            local edit = CreateFrame("EditBox", nil, f, BG.editSearchTemplate)
            edit:SetSize(150, 22)
            edit:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -5)
            edit.Instructions:SetText(L["搜索交易对象"])
            mainFrame.serachEdit = edit
            BG.SetEditBaseClass(edit)
            edit:HookScript("OnTextChanged", function(self)
                BG.UpdateTradeHistoryScrollFrame()
            end)
            edit:HookScript("OnEditFocusGained", function(self)
                BG.lastfocus = self
                if BG.GetVerNum(BG.ver) >= 12820 then
                    BG.SetListmaijia(self, true, nil, nil, true)
                end
            end)
            edit:HookScript("OnEditFocusLost", function(self)
                if BG.FrameMaijiaList then BG.FrameMaijiaList:Hide() end
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
                    bt:SetPoint("LEFT", titlebuttons[i - 1], "RIGHT", 0, 0)
                    bt:SetParent(titlebuttons[i - 1])
                end
                bt:SetNormalFontObject(BG["FontWhite" .. FONTSIZE])
                bt:SetText(titleTbl[i].name)
                bt.textwidth = bt:GetFontString():GetStringWidth()
                bt.textJustifyH = titleTbl[i].JustifyH
                bt.sortOrder = 1
                bt.id = i
                bt:SetHighlightTexture("Interface/PaperDollInfoFrame/UI-Character-Tab-Highlight")
                bt:SetEnabled(v.Enable)
                tinsert(titlebuttons, bt)

                bt.Text = bt:GetFontString()
                bt.Text:SetJustifyH(titleTbl[i].JustifyH)
                bt.Text:SetWidth(bt:GetWidth())
                bt.Text:SetWordWrap(false)

                bt:SetScript("OnClick", function(self)
                    BG.PlaySound(1)
                    mainFrame.isnewsorter = nil
                    if BiaoGe.tradeHistory.OrderButtonID ~= self.id then
                        mainFrame.isnewsorter = true
                    end
                    if not mainFrame.isnewsorter then
                        BiaoGe.tradeHistory.Order = BiaoGe.tradeHistory.Order == 1 and 0 or 1
                    end
                    BiaoGe.tradeHistory.OrderButtonID = self.id

                    UpdateScrollFrame()
                    UpdateButtons()
                end)
            end
            CreateLine(titlebuttons[1], 0, titleWidth)
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
            t:SetText(L["该角色没有交易记录。"])
            mainFrame.notText = t
        end

        -- 刷新滚动框
        local function SearchText(v)
            local searchText = mainFrame.serachEdit:GetText()
            if searchText == "" then
                return true
            end
            if v.targetName and v.targetName:find(searchText, 1, true) then
                return true
            end
        end
        function GetDB()
            local realmID = choose.realmID
            local playerTbl = {}
            wipe(db)
            if choose.player then
                playerTbl = { choose.player }
            else
                for player, v in pairs(BiaoGe.tradeHistory[realmID]) do
                    tinsert(playerTbl, player)
                end
            end

            for _, player in pairs(playerTbl) do
                for i, v in ipairs(BiaoGe.tradeHistory[realmID][player].info) do
                    if SearchText(v) then
                        tinsert(db, BG.Copy(v))
                        db[#db].i = i
                        db[#db].player = player
                    end
                end
            end

            sort(db, function(a, b)
                if BiaoGe.tradeHistory.OrderButtonID == 2 then -- 按时间
                    local key = "time"
                    if a[key] and b[key] then
                        if a[key] ~= b[key] then
                            if BiaoGe.tradeHistory.Order == 1 then
                                return a[key] > b[key]
                            else
                                return b[key] > a[key]
                            end
                        end
                    end
                elseif BiaoGe.tradeHistory.OrderButtonID == 3 then -- 按地点
                    local key = "zone"
                    if a[key] and b[key] then
                        if a[key] ~= b[key] then
                            if BiaoGe.tradeHistory.Order == 1 then
                                return a[key] > b[key]
                            else
                                return b[key] > a[key]
                            end
                        else
                            local key = "time"
                            if a[key] and b[key] then
                                if a[key] ~= b[key] then
                                    if BiaoGe.tradeHistory.Order == 1 then
                                        return a[key] > b[key]
                                    else
                                        return b[key] > a[key]
                                    end
                                end
                            end
                        end
                    end
                end
                return false
            end)
        end

        function UpdateScrollFrame()
            GetDB()

            local sorter = mainFrame.sorter
            local bt = titlebuttons[BiaoGe.tradeHistory.OrderButtonID]
            sorter:SetParent(bt)
            sorter:ClearAllPoints()
            if bt.textJustifyH == "CENTER" then
                sorter:SetPoint("LEFT", bt, "CENTER", bt.textwidth / 2, 0)
            else
                sorter:SetPoint("LEFT", bt, "LEFT", bt.textwidth, 0)
            end
            if not mainFrame.isnewsorter then
                if BiaoGe.tradeHistory.Order == 1 then
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

            local playerItemText = ""
            local count = 0
            local item
            for i = 1, 6 do
                if v.playeritems[i] then
                    count = count + 1
                    local countText = ""
                    item = AddIconByLink(v.playeritems[i].item) .. v.playeritems[i].item .. countText
                end
            end
            if count == 1 then
                playerItemText = item
            elseif count > 1 then
                playerItemText = "|A:ParagonReputation_Bag:0:0|a" .. "x" .. count
            end
            local playerMoneyText = ""
            local money = v.playermoney
            if money > 0 then
                playerMoneyText = GetMoneyString(money, true)
            end
            local playerSplit = ""
            if playerItemText ~= "" and playerMoneyText ~= "" then
                playerSplit = ", "
            end

            local targetItemText = ""
            local count = 0
            local item
            for i = 1, 6 do
                if v.targetitems[i] then
                    count = count + 1
                    local countText = ""
                    item = AddIconByLink(v.targetitems[i].item) .. v.targetitems[i].item .. countText
                end
            end
            if count == 1 then
                targetItemText = item
            elseif count > 1 then
                targetItemText = "|A:ParagonReputation_Bag:0:0|a" .. "x" .. count
            end
            local targetMoneyText = ""
            local money = v.targetmoney
            if money > 0 then
                targetMoneyText = GetMoneyString(money, true)
            end
            local targetSplit = ""
            if targetItemText ~= "" and targetMoneyText ~= "" then
                targetSplit = ", "
            end
            return {
                num, -- 序号
                date("%m-%d\n%H:%M", v.time), -- 时间
                v.zone, -- 地点
                "|c" .. select(4, GetClassColor(v.playerClass)) .. v.playerName .. "|r", -- 角色
                "|c" .. select(4, GetClassColor(v.targetClass)) .. v.targetName .. "|r", -- 交易对象
                playerItemText .. playerSplit .. playerMoneyText, -- 交出
                targetItemText .. targetSplit .. targetMoneyText, -- 收到
                GetMoneyString(floor(v.beforeMoney / 1e4) * 10000, true), -- 交易前财产
                v.afterMoney and GetMoneyString(floor(v.afterMoney / 1e4) * 10000, true) or L["读取中"], -- 交易后财产
            }
        end

        function UpdateButtons()
            local value = floor(bar:GetValue()) or 0
            for ii = 1, MAXBUTTONS do
                local num = value + ii
                local tbl = GetButtonInfo(num)
                for i = 1, #titleTbl do
                    if tbl then
                        buttons[ii][i].Text:SetText(tbl[i])
                        buttons[ii][i].dbNum = num
                        if buttons[ii][i].Text:IsTruncated() then
                            buttons[ii][i].onenter = tbl[i]
                        else
                            buttons[ii][i].onenter = nil
                        end
                        buttons[ii][i]:Show()
                    else
                        buttons[ii][i]:Hide()
                    end
                end
            end
            GameTooltip:Hide()
        end

        function BG.UpdateTradeHistoryScrollFrame()
            UpdateScrollFrame()
            UpdateButtons()
        end

        -- 交易详细框
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

            -- UI
            do
                local WIDTH = 120
                local ICON_WIDTH = 30

                local frame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
                frame:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = 1,
                })
                frame:SetBackdropColor(0, 0, 0, 0.4)
                frame:SetBackdropBorderColor(1, 1, 1, .8)
                frame:SetPoint("TOPLEFT", mainFrame.frame, "TOPRIGHT", 2, 0)
                frame:SetSize(WIDTH * 2 + 30, 310)
                frame:Hide()
                mainFrame.infoFrame = frame
                frame:HookScript("OnEnter", function(self)
                    StopTime()
                    local num = mainFrame.frame.lastButtonNum
                    buttons[num][1].ds:Show()
                end)
                frame:HookScript("OnLeave", StartTime)
                frame:HookScript("OnHide", function(self)
                    local num = mainFrame.frame.lastButtonNum
                    buttons[num][1].ds:Hide()
                end)

                frame.timeText = frame:CreateFontString()
                frame.timeText:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                frame.timeText:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 2, 2)
                frame.timeText:SetTextColor(1, 1, 1)

                local function CreateButton(type)
                    -- 名字
                    local t = frame:CreateFontString()
                    t:SetFont(BIAOGE_TEXT_FONT, 16, "OUTLINE")
                    if type == "player" then
                        t:SetPoint("TOPLEFT", 10, -10)
                    else
                        t:SetPoint("TOPLEFT", frame.playerNameText, "TOPRIGHT", 10, 0)
                    end
                    t:SetWidth(WIDTH)
                    t:SetJustifyH("LEFT")
                    t:SetWordWrap(false)
                    frame[type .. "NameText"] = t
                    -- 金钱
                    local f = CreateFrame("Frame", nil, frame, "BackdropTemplate")
                    f:SetBackdrop({
                        bgFile = "Interface/ChatFrame/ChatFrameBackground",
                    })
                    f:SetBackdropColor(0, 0, 0, 0.5)
                    f:SetSize(WIDTH, 22)
                    f:SetPoint("TOPLEFT", frame[type .. "NameText"], "BOTTOMLEFT", 0, -5)
                    local t = f:CreateFontString()
                    t:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                    t:SetAllPoints()
                    t:SetJustifyH("LEFT")
                    frame[type .. "MoneyText"] = t
                    -- 物品
                    for i = 1, 7 do
                        local itemFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
                        itemFrame:SetBackdrop({
                            bgFile = "Interface/ChatFrame/ChatFrameBackground",
                            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                            edgeSize = 1,
                        })
                        itemFrame:SetBackdropColor(0, 0, 0, 0)
                        itemFrame:SetBackdropBorderColor(1, 1, 1, .4)
                        itemFrame:SetSize(ICON_WIDTH, ICON_WIDTH)
                        if i == 1 then
                            itemFrame:SetPoint("TOPLEFT", frame[type .. "MoneyText"], "BOTTOMLEFT", 0, -10)
                        else
                            itemFrame:SetPoint("TOPLEFT", frame[type .. "item" .. (i - 1)], "BOTTOMLEFT", 0, i == 7 and -15 or -2)
                        end
                        frame[type .. "item" .. i] = itemFrame
                        itemFrame:HookScript("OnEnter", function(self)
                            StopTime()
                            local num = mainFrame.frame.lastButtonNum
                            buttons[num][1].ds:Show()
                            if itemFrame.link then
                                GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
                                GameTooltip:ClearLines()
                                GameTooltip:SetHyperlink(itemFrame.link)
                            end
                        end)
                        itemFrame:HookScript("OnLeave", function(self)
                            GameTooltip:Hide()
                            StartTime()
                        end)

                        itemFrame.icon = itemFrame:CreateTexture(nil, "BACKGROUND")
                        itemFrame.icon:SetAllPoints()
                        itemFrame.icon:SetTexCoord(.07, .93, .07, .93)

                        itemFrame.count = itemFrame:CreateFontString()
                        itemFrame.count:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                        itemFrame.count:SetPoint("BOTTOMRIGHT", -1, 1)

                        itemFrame.level = itemFrame:CreateFontString()
                        itemFrame.level:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
                        itemFrame.level:SetPoint("BOTTOM", 1, 1)

                        local nameFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
                        nameFrame:SetBackdrop({
                            bgFile = "Interface/ChatFrame/ChatFrameBackground",
                        })
                        nameFrame:SetBackdropColor(.5, .5, .5, 0.1)
                        nameFrame:SetSize(WIDTH - ICON_WIDTH - 2, ICON_WIDTH)
                        nameFrame:SetPoint("LEFT", itemFrame, "RIGHT", 2, 0)
                        itemFrame.name = nameFrame:CreateFontString()
                        itemFrame.name:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                        itemFrame.name:SetAllPoints()
                        itemFrame.name:SetJustifyH("LEFT")
                        nameFrame:HookScript("OnEnter", function(self)
                            StopTime()
                            local num = mainFrame.frame.lastButtonNum
                            buttons[num][1].ds:Show()
                        end)
                        nameFrame:HookScript("OnLeave", StartTime)
                    end
                end
                CreateButton("player")
                CreateButton("target")
            end

            function BG.ShowTradeHistoryInfo(self)
                local num = self.dbNum
                local v = db[num]
                local frame = mainFrame.infoFrame
                frame.timeText:SetText(date("%y/%m/%d %H:%M", v.time))
                local function Set(type, num)
                    local v = db[num]
                    frame[type .. "NameText"]:SetText(v[type .. "Name"])
                    local r, g, b = .5, .5, .5
                    if v[type .. "Class"] then
                        r, g, b = GetClassColor(v[type .. "Class"])
                    end
                    frame[type .. "NameText"]:SetTextColor(r, g, b)
                    if v[type .. "money"] == 0 then
                        frame[type .. "MoneyText"]:SetText("")
                    else
                        frame[type .. "MoneyText"]:SetText(GetMoneyString(v[type .. "money"], true))
                    end
                    for i = 1, 7 do
                        local vv = v[type .. "items"][i]
                        local itemFrame = frame[type .. "item" .. i]
                        if vv then
                            local r, g, b = GetItemQualityColor(vv.quality)
                            local iconID, typeID = select(5, GetItemInfoInstant(vv.item))
                            itemFrame.link = vv.item
                            itemFrame.itemID = GetItemID(vv.item)
                            itemFrame:SetBackdropBorderColor(r, g, b, 1)
                            itemFrame.icon:SetTexture(iconID)
                            itemFrame.count:SetText(vv.count > 1 and vv.count or "")
                            itemFrame.name:SetText(vv.name)
                            itemFrame.name:SetTextColor(r, g, b)
                            itemFrame.level:SetText("")
                            if typeID == 2 or typeID == 4 then
                                local link = vv.item
                                local item = Item:CreateFromItemLink(link)
                                item:ContinueOnItemLoad(function()
                                    if itemFrame.link == link then
                                        local level = select(4, GetItemInfo(link))
                                        if level then
                                            itemFrame.level:SetText(level)
                                        end
                                    end
                                end)
                            end
                        else
                            itemFrame.link = nil
                            itemFrame.itemID = nil
                            itemFrame:SetBackdropBorderColor(1, 1, 1, .4)
                            itemFrame.icon:SetTexture(nil)
                            itemFrame.name:SetText("")
                            itemFrame.count:SetText("")
                            itemFrame.level:SetText("")
                        end
                    end
                end
                Set("player", num)
                Set("target", num)
                mainFrame.infoFrame:Show()
            end
        end
    end

    -- 跳转到其他功能设置
    do
        local bt = BG.CreateButton(BG.TradeHistoryMainFrame)
        bt:SetSize(150, 25)
        bt:SetPoint("TOPLEFT", BG.TradeHistoryMainFrame.frame, "BOTTOMLEFT", 0, -5)
        bt:SetText(L["交易选项设置"])
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            BG.OpenOption()
            if BG.ButtonOptions_others then
                BG.ButtonOptions_others:Click()
            end
        end)
    end
end

BG.Init(function()
    BiaoGe.tradeHistory = BiaoGe.tradeHistory or {}
    local tradeHistory = BiaoGe.tradeHistory
    tradeHistory.saveDuration = tradeHistory.saveDuration or 30
    tradeHistory.OrderButtonID = tradeHistory.OrderButtonID or 2
    tradeHistory.Order = tradeHistory.Order or 1
    tradeHistory.isChooseRealm = tradeHistory.isChooseRealm or 1
    EnsureCurrentCharacter()

    if BiaoGe.disabledModules["TradeHistory"] then return end

    RoadTrade()
end)
