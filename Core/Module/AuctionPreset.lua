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
local GetClassName = ns.GetClassName
local CreateLine = ns.CreateLine
local SendSystemMessage = ns.SendSystemMessage
local ver = ns.ver
local After = C_Timer.After
local player = UnitName("player")
local realmID = GetRealmID()

local pt = print

local function SetEditScript(edit)
    edit:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    edit:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            self:SetEnabled(false)
            self:SetText("")
        end
    end)
    edit:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            self:SetEnabled(true)
        end
    end)
end

BG.Init(function()
    BiaoGe.auctionPreset = BiaoGe.auctionPreset or {}
    BiaoGe.auctionPreset.OrderButtonID = BiaoGe.auctionPreset.OrderButtonID or 3
    BiaoGe.auctionPreset.Order = BiaoGe.auctionPreset.Order or 1
    for _, FB in ipairs(BG.FBtable) do
        BiaoGe.auctionPreset[FB] = BiaoGe.auctionPreset[FB] or {}
        BiaoGe.auctionPreset[FB].money = BiaoGe.auctionPreset[FB].money or {}
    end

    local mainFrame
    local db = {}
    local choose = {}
    local lastChoose
    local MAXBUTTONS = 20
    local MAXBYTES = 50
    local UpdateSetChooseButton

    local EquipLocs = {
        ["INVTYPE_HEAD"] = { "INVTYPE_HEAD" },
        ["INVTYPE_NECK"] = { "INVTYPE_NECK" },
        ["INVTYPE_SHOULDER"] = { "INVTYPE_SHOULDER" },
        ["INVTYPE_CLOAK"] = { "INVTYPE_CLOAK" },
        ["INVTYPE_CHEST"] = { "INVTYPE_CHEST", "INVTYPE_ROBE" },
        ["INVTYPE_WRIST"] = { "INVTYPE_WRIST" },
        ["INVTYPE_HAND"] = { "INVTYPE_HAND" },
        ["INVTYPE_WAIST"] = { "INVTYPE_WAIST" },
        ["INVTYPE_LEGS"] = { "INVTYPE_LEGS" },
        ["INVTYPE_FEET"] = { "INVTYPE_FEET" },
        ["INVTYPE_FINGER"] = { "INVTYPE_FINGER" },
        ["INVTYPE_TRINKET"] = { "INVTYPE_TRINKET" },
        ["TWO_HANDED"] = { "INVTYPE_2HWEAPON" },
        ["INVTYPE_WEAPON"] = { "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND" },
        ["INVTYPE_SHIELD"] = { "INVTYPE_SHIELD", "INVTYPE_HOLDABLE", "INVTYPE_WEAPONOFFHAND" },
        ["INVTYPE_RANGED"] = { "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT", "INVTYPE_THROWN", "INVTYPE_RELIC" },
        ["INVTYPE_OTHER"] = { "", "INVTYPE_NON_EQUIP_IGNORE" }

    }
    local fitlerTbl
    if BG.IsWLK then
        fitlerTbl = {
            { name = ITEM_MOD_STRENGTH_SHORT, key = "%+%C-" .. ITEM_MOD_STRENGTH_SHORT, },
            { name = SPEC_FRAME_PRIMARY_STAT_AGILITY, key = "%+%C-" .. SPEC_FRAME_PRIMARY_STAT_AGILITY, },
            { name = ITEM_MOD_INTELLECT_SHORT, key = "%+%C-" .. ITEM_MOD_INTELLECT_SHORT, },
            { name = ITEM_MOD_SPIRIT_SHORT, key = "%+%C-" .. ITEM_MOD_SPIRIT_SHORT, },
            { name = ITEM_MOD_MANA_REGENERATION:gsub("%%s", "x"), key = ITEM_MOD_MANA_REGENERATION, },
            { name = ITEM_MOD_ATTACK_POWER_SHORT, key = ITEM_MOD_ATTACK_POWER_SHORT },
            { name = ITEM_MOD_SPELL_POWER_SHORT, key = ITEM_MOD_SPELL_POWER_SHORT },
            { name = HIT_LCD, key = HIT_LCD },
            { name = STAT_HASTE, key = STAT_HASTE },
            { name = STAT_CRITICAL_STRIKE, key = STAT_CRITICAL_STRIKE },
            { name = STAT_EXPERTISE, key = STAT_EXPERTISE },
            { name = ITEM_MOD_ARMOR_PENETRATION_RATING:gsub("%%s", "x"), key = ITEM_MOD_ARMOR_PENETRATION_RATING },
            { name = STAT_CATEGORY_DEFENSE, key = STAT_CATEGORY_DEFENSE },
            { name = STAT_PARRY, key = STAT_PARRY },
            { name = STAT_DODGE, key = STAT_DODGE },
            { name = ITEM_MOD_BLOCK_RATING_SHORT, key = ITEM_MOD_BLOCK_RATING_SHORT },
            { name = ITEM_MOD_BLOCK_VALUE_SHORT, key = ITEM_MOD_BLOCK_VALUE_SHORT },
            { name = ITEM_SPELL_TRIGGER_ONPROC, key = ITEM_SPELL_TRIGGER_ONPROC },
        }
    elseif BG.IsCTM or BG.IsMOP then
        fitlerTbl = {
            { name = ITEM_MOD_STRENGTH_SHORT, key = "%+%C-" .. ITEM_MOD_STRENGTH_SHORT, },
            { name = SPEC_FRAME_PRIMARY_STAT_AGILITY, key = "%+%C-" .. SPEC_FRAME_PRIMARY_STAT_AGILITY, },
            { name = ITEM_MOD_INTELLECT_SHORT, key = "%+%C-" .. ITEM_MOD_INTELLECT_SHORT, },
            { name = ITEM_MOD_SPIRIT_SHORT, key = "%+%C-" .. ITEM_MOD_SPIRIT_SHORT, },
            { name = ITEM_MOD_ATTACK_POWER_SHORT, key = ITEM_MOD_ATTACK_POWER_SHORT },
            { name = ITEM_MOD_SPELL_POWER_SHORT, key = ITEM_MOD_SPELL_POWER_SHORT },
            { name = HIT_LCD, key = HIT_LCD },
            { name = STAT_HASTE, key = STAT_HASTE },
            { name = STAT_CRITICAL_STRIKE, key = STAT_CRITICAL_STRIKE },
            { name = STAT_EXPERTISE, key = STAT_EXPERTISE },
            { name = STAT_CATEGORY_DEFENSE, key = STAT_CATEGORY_DEFENSE },
            { name = STAT_PARRY, key = STAT_PARRY },
            { name = STAT_DODGE, key = STAT_DODGE },
            { name = ITEM_MOD_BLOCK_RATING_SHORT, key = ITEM_MOD_BLOCK_RATING_SHORT },
            { name = ITEM_MOD_BLOCK_VALUE_SHORT, key = ITEM_MOD_BLOCK_VALUE_SHORT },
        }
    end

    mainFrame = BG.AuctionPresetMainFrame

    -- UI
    do
        local BUTTONHEIGHT = 25
        local WIDTH = 10 + 27
        local HEIGHT = (MAXBUTTONS + 1) * BUTTONHEIGHT + 15
        local FONTSIZE = 15
        local titleWidth = 0
        local titleTbl = {
            { name = L["序号"], width = 40, color = "808080", JustifyH = "CENTER", Enable = false, fontSize = FONTSIZE - 2, },
            { name = L["等级"], width = 50, color = "FFFFFF", JustifyH = "CENTER", Enable = true, fontSize = FONTSIZE - 1, },
            { name = L["装备"], width = 160, color = "FFFFFF", JustifyH = "LEFT", Enable = true, noWrap = true },
            { name = L["起拍价"], width = 100, color = "FFFFFF", JustifyH = "LEFT", Enable = true, edit = true, money = true },
            { name = L["起拍语"], width = 100, color = "FFFFFF", JustifyH = "LEFT", Enable = true, edit = true, onEnter = L["起拍语会显示在你拍卖一个装备的团队消息后面。"] },
        }
        for i, v in ipairs(titleTbl) do
            WIDTH = WIDTH + v.width
            titleWidth = titleWidth + v.width
        end
        mainFrame.titlebuttons = {}
        mainFrame.buttons = {}
        local f, scroll, child, bar
        local GetDB, UpdateScrollFrame, UpdateScrollButtonState, GetButtonInfo, UpdateButtons
        local isInsert = {}
        local allItem = {}
        local dbOK
        local info = {}
        local CreateAllItemInfoCache, CheckItemInfo, CheckSameItem, Sort

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
            f:SetPoint("TOPLEFT", BG.MainFrame, "TOPLEFT", 10, -80)
            f:SetSize(WIDTH + 5, HEIGHT)
            f:EnableMouse(true)
            mainFrame.frame = f
            local first = true
            mainFrame:HookScript("OnShow", function(self)
                BG.After(first and 0.2 or 0, function()
                    mainFrame:UpdateAllFrame()
                    mainFrame:UpdateFilteFrame()
                end)
                first = nil
            end)

            scroll = CreateFrame("ScrollFrame", nil, f, BG.scrollTemplate) -- 滚动
            scroll:SetWidth(WIDTH - 27 + 5)
            scroll:SetHeight(BUTTONHEIGHT * MAXBUTTONS)
            scroll:SetPoint("TOPLEFT", 0, -12 - BUTTONHEIGHT)
            mainFrame.scroll = scroll
            bar = scroll.ScrollBar
            bar.scrollStep = 5
            BG.CreateSrollBarBackdrop(bar)
            bar:HookScript("OnValueChanged", function(self)
                self:SetScript("OnUpdate", function(self, t)
                    UpdateScrollFrame(true)
                    UpdateButtons()
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
                    local v = titleTbl[i]
                    if v.edit then
                        local edit = CreateFrame("EditBox", nil, mainFrame.buttons[ii][1], BG.editTemplate)
                        edit:SetSize(v.width - 5, BUTTONHEIGHT)
                        edit:SetPoint("LEFT", mainFrame.buttons[ii][i - 1], "RIGHT", 5, 0)
                        edit:SetAutoFocus(false)
                        if v.money then
                            edit:SetNumeric(true)
                        end
                        edit.isEdit = true
                        edit.isMoney = v.money
                        edit:SetMaxBytes(MAXBYTES)
                        edit.num = ii
                        mainFrame.buttons[ii][i] = edit
                        edit:SetScript("OnTextChanged", function(self)
                            if self.isMoney then
                                local num = tonumber(self:GetText())
                                if num and num == 0 then num = nil end
                                BiaoGe.auctionPreset[BG.FB1].money[self.itemID] = num
                            else
                                local t = self:GetText()
                                BiaoGe.auctionPreset[BG.FB1].money[self.itemID .. "tips"] = t ~= "" and t or nil
                            end
                        end)
                        edit:SetScript("OnEditFocusGained", function(self)
                            mainFrame.lastFocus = self
                            BG.lastfocus = self
                        end)
                        SetEditScript(edit)
                    else
                        local f = CreateFrame("Frame", nil, scroll)
                        f:SetSize(v.width, BUTTONHEIGHT)
                        if ii == 1 and i == 1 then
                            f:SetPoint("TOPLEFT", scroll, 10, 0)
                            f:SetParent(scroll)
                            f:Hide()
                        elseif i == 1 then
                            f:SetPoint("TOPLEFT", mainFrame.buttons[(ii - 1)][1], "BOTTOMLEFT", 0, 0)
                            f:SetParent(scroll)
                            f:Hide()
                        else
                            f:SetPoint("LEFT", mainFrame.buttons[ii][i - 1], "RIGHT", 0, 0)
                            f:SetParent(mainFrame.buttons[ii][1])
                        end
                        f.num = ii
                        mainFrame.buttons[ii][i] = f

                        f.Text = f:CreateFontString()
                        f.Text:SetFont(BIAOGE_TEXT_FONT, v.fontSize or FONTSIZE, "OUTLINE")
                        f.Text:SetPoint("CENTER")
                        f.Text:SetTextColor(RGB(v.color))
                        f.Text:SetJustifyH(v.JustifyH)
                        if v.noWrap then
                            f.Text:SetWidth(f:GetWidth() - 2)
                            f.Text:SetWordWrap(false)
                        end
                        BG.OnEnterDelay(f, function(self)
                            self.isEnter = true
                            for _ii, v in ipairs(mainFrame.buttons) do
                                mainFrame.buttons[_ii][1].ds:Hide()
                            end
                            mainFrame.buttons[ii][1].ds:Show()
                            if self.link then
                                GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                                GameTooltip:ClearLines()
                                -- GameTooltip:SetItemByID(self.itemID)
                                GameTooltip:SetHyperlink(self.link)
                            elseif self.onenter then
                                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                                GameTooltip:ClearLines()
                                GameTooltip:AddLine(self.onenter, 1, 1, 1, true)
                                GameTooltip:Show()
                            end
                        end, BG.itemOnEnterDelay)
                        BG.OnLeaveDelay(f, function(self)
                            self.isEnter = false
                            mainFrame.buttons[ii][1].ds:Hide()
                            GameTooltip:Hide()
                        end)
                        f:SetScript("OnMouseUp", function(self)
                            BG.PlaySound(1)
                            local bts = mainFrame.buttons[ii][1]
                            local dbNum = bts.dbNum
                            if IsControlKeyDown() then
                                choose[dbNum] = not choose[dbNum]
                                if choose[dbNum] then
                                    bts.tex:Show()
                                    lastChoose = dbNum
                                else
                                    choose[dbNum] = nil
                                    bts.tex:Hide()
                                end
                            elseif IsShiftKeyDown() then
                                if not next(choose) then
                                    if i == 3 then
                                        BG.InsertLink(self.link)
                                    end
                                elseif lastChoose then
                                    for i = lastChoose, dbNum, lastChoose < dbNum and 1 or -1 do
                                        choose[i] = true
                                    end
                                    UpdateButtons()
                                end
                            else
                                for _dbNum, v in pairs(choose) do
                                    if _dbNum ~= dbNum then
                                        choose[_dbNum] = nil
                                    end
                                end
                                for ii = 1, MAXBUTTONS do
                                    local bt = mainFrame.buttons[ii][1]
                                    bt.tex:Hide()
                                end
                                choose[dbNum] = not choose[dbNum]
                                if choose[dbNum] then
                                    bts.tex:Show()
                                    lastChoose = dbNum
                                else
                                    choose[dbNum] = nil
                                    bts.tex:Hide()
                                end
                            end
                            UpdateSetChooseButton()
                        end)
                    end
                end
                -- 装绑
                do
                    local parent = mainFrame.buttons[ii][3]
                    local f = CreateFrame("Frame", nil, parent)
                    f:SetSize(20, 20)
                    f:SetPoint("RIGHT", -2, 0)
                    f:Hide()
                    local tex = f:CreateTexture()
                    tex:SetSize(13, 12)
                    tex:SetPoint("CENTER")
                    tex:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
                    parent.bindTex = f
                    f:SetScript("OnEnter", function(self)
                        BiaoGeTooltip2:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 0)
                        BiaoGeTooltip2:ClearLines()
                        BiaoGeTooltip2:AddLine(L["装绑"], 1, 1, 1, true)
                        BiaoGeTooltip2:Show()
                        parent:GetScript("OnEnter")(parent)
                    end)
                    f:SetScript("OnLeave", function(self)
                        BiaoGeTooltip2:Hide()
                        parent:GetScript("OnLeave")(parent)
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

                -- 选中材质
                f.tex = f:CreateTexture()
                f.tex:SetPoint("TOPLEFT", 0, 0)
                f.tex:SetPoint("BOTTOMRIGHT", mainFrame.buttons[ii][#titleTbl], "BOTTOMRIGHT", 0, 0)
                f.tex:SetColorTexture(1, 1, 0, 0.5)
                f.tex:Hide()
            end
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
                    if BiaoGe.auctionPreset.OrderButtonID ~= self.id then
                        mainFrame.isnewsorter = true
                    end
                    if not mainFrame.isnewsorter then
                        BiaoGe.auctionPreset.Order = BiaoGe.auctionPreset.Order == 1 and 0 or 1
                    end
                    BiaoGe.auctionPreset.OrderButtonID = self.id

                    mainFrame:UpdateAllFrame()
                end)

                if v.onEnter then
                    bt:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(v.name, 1, 1, 1, true)
                        GameTooltip:AddLine(v.onEnter, 1, 0.82, 0, true)
                        GameTooltip:Show()
                    end)
                    bt:SetScript("OnLeave", GameTooltip_Hide)
                end
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
            t:SetText(L["没有符合当前过滤条件的装备。"])
            t:Hide()
            mainFrame.notText = t

            local t = mainFrame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("BOTTOM", mainFrame.frame, "TOP", 0, 1)
            mainFrame.topText = t
        end

        -- 刷新滚动框
        -- 历遍所有团本掉落的装备，缓存装备的数据
        do
            local function InsertToAllItem(itemID, other)
                local bossNum = other.bossNum
                local hard = other.hard
                if isInsert[itemID] then
                    isInsert[itemID].bossNum[bossNum] = true
                    isInsert[itemID].hard[hard] = true
                    return
                end
                isInsert[itemID] = {
                    itemID = itemID,
                    bossNum = {
                        [bossNum] = true
                    },
                    hard = {
                        [hard] = true
                    },
                }
            end
            local function SaveItemInfo()
                for k, v in pairs(isInsert) do tinsert(allItem, v) end
                local FB = BG.FB1
                local startI = 1
                local oneTime = 20
                local allCount = #allItem
                local cacheCount = 0
                local isDoing = true
                BG.OnUpdateTime(function(self, elapsed)
                    self.timeElapsed = self.timeElapsed + elapsed
                    if cacheCount >= allCount or self.timeElapsed >= 2 then
                        self:SetScript("OnUpdate", nil)
                        self:Hide()
                        -- 删除超出BOSS掉落的物品
                        local itemIDs = {}
                        for itemID in pairs(BiaoGe.auctionPreset[FB].money) do
                            if type(itemID) == "number" and not info[FB][itemID] and not FB:find("TOC") then
                                tinsert(itemIDs, itemID)
                            end
                        end
                        for _, itemID in pairs(itemIDs) do -- 删除超出BOSS掉落的物品
                            BiaoGe.auctionPreset[FB].money[itemID] = nil
                            BiaoGe.auctionPreset[FB].money[itemID .. "tips"] = nil
                        end
                        dbOK = true
                        return
                    elseif isDoing then
                        for ii = startI, startI + oneTime - 1 do
                            if allItem[ii] then
                                local itemID = allItem[ii].itemID
                                local bossNum = allItem[ii].bossNum
                                local hard = allItem[ii].hard
                                BG.OnItemLoad(itemID):ContinueOnItemLoad(function()
                                    local name, link, quality, level, _, _, _, _, EquipLoc, Texture,
                                    _, typeID, subclassID, bindType = GetItemInfo(itemID)
                                    local tooltipText = BG.GetTooltipTextLeftAll(itemID)
                                    info[FB][itemID] = {
                                        name = name,
                                        link = link,
                                        quality = quality,
                                        level = level,
                                        EquipLoc = EquipLoc,
                                        Texture = Texture,
                                        typeID = typeID,
                                        subclassID = subclassID,
                                        bindType = bindType,
                                        itemID = itemID,
                                        bossNum = bossNum, -- table
                                        hard = hard,       -- table
                                        tooltipText = tooltipText,
                                    }
                                    cacheCount = cacheCount + 1
                                end)
                            else
                                isDoing = false
                                break
                            end
                        end
                        startI = startI + oneTime
                    end
                end)
            end
            function CreateAllItemInfoCache()
                local FB = BG.FB1
                info[FB] = {}
                allItem = {}
                isInsert = {}
                -- 团本
                for _, hard in ipairs(BG.difficultyTable[FB]) do -- 历遍全部难度
                    if BG.Loot[FB][hard] and BG.Loot[FB][hard].boss1 then
                        -- BOSS掉落
                        local ii = 1
                        while BG.Loot[FB][hard]["boss" .. ii] do
                            if not (FB == "TOC" and ii == 7 and hard:find("H")) then
                                for i, itemID in ipairs(BG.Loot[FB][hard]["boss" .. ii]) do
                                    InsertToAllItem(itemID, {
                                        bossNum = ii,
                                        hard = hard,
                                    })
                                end
                            end
                            ii = ii + 1
                        end
                    end
                end
                SaveItemInfo()
            end
        end

        local matchStr = ITEM_CLASSES_ALLOWED:gsub("%%s", "(.+)")
        local tooltips = {}
        local function IsYesItem(v)
            local FB = BG.FB1
            local yes = false
            for hard, ok in pairs(BiaoGe.auctionPreset[FB].hard) do
                if ok == 1 then
                    for _hard in pairs(v.hard) do
                        if _hard == hard then
                            yes = true
                            break
                        end
                    end
                    if yes then break end
                end
            end
            if not yes then return end
            yes = nil
            for bossNum, ok in pairs(BiaoGe.auctionPreset[FB].bossNum) do
                if ok == 1 then
                    for _bossNum in pairs(v.bossNum) do
                        if _bossNum == bossNum then
                            yes = true
                            break
                        end
                    end
                    if yes then break end
                end
            end
            if not yes then return end
            yes = nil
            for equipLoc, ok in pairs(BiaoGe.auctionPreset[FB].equipLoc) do
                if ok == 1 then
                    for _, _EquipLoc in pairs(EquipLocs[equipLoc]) do
                        if _EquipLoc == v.EquipLoc then
                            yes = true
                            break
                        end
                    end
                    if yes then break end
                end
            end
            if not yes then return end
            if BiaoGe.auctionPreset[FB].attribute and next(BiaoGe.auctionPreset[FB].attribute) then
                yes = nil
                for attribute, ok in pairs(BiaoGe.auctionPreset[FB].attribute) do
                    if ok == 1 and v.tooltipText:match(attribute:gsub("%%s", "(.+)")) then
                        yes = true
                        break
                    end
                end
                if not yes then
                    return
                end
            end
            yes = nil
            for quality, ok in pairs(BiaoGe.auctionPreset[FB].quality) do
                if ok == 1 and quality == v.quality then
                    yes = true
                    break
                end
            end
            if not yes then return end
            yes = nil
            for bindType, ok in pairs(BiaoGe.auctionPreset[FB].bindType) do
                if ok == 1 and bindType == v.bindType then
                    yes = true
                    break
                end
            end
            if not yes then return end
            yes = nil
            local str = tooltips[v.itemID] or BG.GetTooltipTextLeftAll(v.itemID)
            tooltips[v.itemID] = str
            for classType, ok in pairs(BiaoGe.auctionPreset[FB].classType) do
                if ok == 1 then
                    if classType == "yes" and str:find(matchStr) then
                        yes = true
                        break
                    elseif classType == "no" and not str:find(matchStr) then
                        yes = true
                        break
                    end
                end
            end
            if not yes then return end
            yes = nil
            local money = BiaoGe.auctionPreset[FB].money[v.itemID] or 0
            for moneyType, ok in pairs(BiaoGe.auctionPreset[FB].moneyType) do
                if ok == 1 then
                    if moneyType == "yes" and money > 0 then
                        yes = true
                        break
                    elseif moneyType == "no" and money == 0 then
                        yes = true
                        break
                    end
                end
            end
            if not yes then return end
            yes = nil
            local name = BiaoGe.auctionPreset[FB].name.name
            if not name or v.name:find(name, nil, true) then
                yes = true
            end
            if not yes then return end
            yes = nil
            local level = BiaoGe.auctionPreset[FB].level.level1
            if not level or level == v.level then
                yes = true
            end
            if not yes then return end
            yes = nil
            local startMoney = BiaoGe.auctionPreset[FB].startMoney.startMoney1
            local money = BiaoGe.auctionPreset[FB].money[v.itemID]
            if not startMoney or (money and startMoney == money) then
                yes = true
            end
            if not yes then return end
            yes = nil
            local tips = BiaoGe.auctionPreset[FB].tips.tips1
            local tipsText = BiaoGe.auctionPreset[FB].money[v.itemID .. "tips"]
            if not tips or (tipsText and tips == tipsText) then
                yes = true
            end
            if not yes then return end
            return true
        end
        function GetDB()
            db = {}
            local FB = BG.FB1
            for _, v in pairs(info[FB]) do
                if IsYesItem(v) then
                    tinsert(db, BG.Copy(v))
                    db[#db].money = BiaoGe.auctionPreset[FB].money[db[#db].itemID] or 0
                    db[#db].tips = BiaoGe.auctionPreset[FB].money[db[#db].itemID .. "tips"] or ""
                end
            end
            sort(db, function(a, b)
                local tbl
                if BiaoGe.auctionPreset.OrderButtonID == 2 then -- 按装等排序
                    tbl = {
                        { key = "level" },
                        { key = "quality" },
                    }
                elseif BiaoGe.auctionPreset.OrderButtonID == 3 then -- 按装备品质排序
                    tbl = {
                        { key = "quality" },
                        { key = "level" },
                    }
                elseif BiaoGe.auctionPreset.OrderButtonID == 4 then -- 按起拍价
                    tbl = {
                        { key = "money" },
                        { key = "quality" },
                        { key = "level" },
                    }
                elseif BiaoGe.auctionPreset.OrderButtonID == 5 then -- 按起拍语
                    tbl = {
                        { key = "tips" },
                        { key = "money" },
                        { key = "quality" },
                        { key = "level" },
                    }
                end
                for _, v in ipairs(tbl) do
                    local key = v.key
                    if a[key] and b[key] then
                        if a[key] ~= b[key] then
                            if BiaoGe.auctionPreset.Order == 1 then
                                return a[key] > b[key]
                            else
                                return b[key] > a[key]
                            end
                        end
                    end
                end
                return false
            end)
        end

        function UpdateScrollFrame(notHide)
            GetDB()

            local sorter = mainFrame.sorter
            local bt = mainFrame.titlebuttons[BiaoGe.auctionPreset.OrderButtonID]
            sorter:SetParent(bt)
            sorter:ClearAllPoints()
            if bt.textJustifyH == "CENTER" then
                sorter:SetPoint("LEFT", bt, "CENTER", bt.textwidth / 2, 0)
            else
                sorter:SetPoint("LEFT", bt, "LEFT", bt.textwidth, 0)
            end
            if not mainFrame.isnewsorter then
                if BiaoGe.auctionPreset.Order == 1 then
                    sorter:SetTexCoord(0, 0.5, 0, 1)
                else
                    sorter:SetTexCoord(0, 0.5, 1, 0)
                end
            end

            local m = #db - MAXBUTTONS
            bar:SetMinMaxValues(0, max(0, m))
            if scroll.SetScrollExtent then
                scroll:SetScrollExtent(MAXBUTTONS, #db)
            end
            UpdateScrollButtonState()
            mainFrame.notText:SetShown(#db == 0)
            mainFrame.topText:SetText(format(L["%s件"], #db))
            if #db == 0 then
                mainFrame.topText:SetTextColor(.5, .5, .5)
            else
                mainFrame.topText:SetTextColor(1, 1, 1)
            end

            wipe(choose)
            lastChoose = nil
            UpdateSetChooseButton()

            if not notHide then
                mainFrame.importButton.bg:Hide()
                mainFrame.exportButton.bg:Hide()
            end
        end

        function UpdateScrollButtonState()
            if bar.ThumbButton then return end
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
            local money = v.money
            if money == 0 then money = nil end
            return {
                num,                             -- 序号
                v.level,                         -- 等级
                AddTexture(v.Texture) .. v.link, -- 装备
                money,                           -- 起拍价
                v.tips,                          -- 起拍语
            }, v.itemID, v.link, v.bindType == 2
        end

        function UpdateButtons(notClearFocus)
            if not notClearFocus and mainFrame.lastFocus then
                mainFrame.lastFocus:ClearFocus()
            end
            local value = floor(bar:GetValue()) or 0
            for ii = 1, MAXBUTTONS do
                local num = value + ii
                local tbl, itemID, link, isBOE = GetButtonInfo(num)
                if tbl then
                    mainFrame.buttons[ii][1]:Show()
                    for i = 1, #titleTbl do
                        local bt = mainFrame.buttons[ii][i]
                        if bt.isEdit then
                            bt:SetText(tbl[i] or "")
                        else
                            bt.Text:SetText(tbl[i])
                            bt.link = i == 3 and link
                            if bt.Text:IsTruncated() then
                                bt.onenter = tbl[i]
                            else
                                bt.onenter = nil
                            end
                        end
                        bt.itemID = itemID
                        bt.dbNum = num
                    end
                    mainFrame.buttons[ii][3].bindTex:SetShown(isBOE)
                    mainFrame.buttons[ii][1].tex:SetShown(choose[num])
                else
                    mainFrame.buttons[ii][1]:Hide()
                end
            end
            GameTooltip:Hide()
            BiaoGeTooltip2:Hide()
        end

        function mainFrame:UpdateAllFrame()
            if not self:IsVisible() then return end
            local FB = BG.FB1
            if not info[FB] then -- 如果还没缓存该副本，则先缓存
                dbOK = false
                local function CreateLoadingText()
                    local f = CreateFrame("Frame", nil, mainFrame.frame, "BackdropTemplate")
                    f:SetSize(1, 1)
                    f:SetPoint("TOP", 0, -42)
                    f:SetFrameLevel(110)
                    local t = f:CreateFontString()
                    t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                    t:SetPoint("TOP")
                    t:SetText(L["读取中..."])
                    return f
                end
                local t = CreateLoadingText()
                CreateAllItemInfoCache()
                BG.OnUpdateTime(function(self, elapsed)
                    if dbOK then
                        self:SetScript("OnUpdate", nil)
                        self:Hide()
                        t:Hide()
                        UpdateScrollFrame()
                        UpdateButtons()
                    end
                end)
            else -- 否则直接开始生成
                UpdateScrollFrame()
                UpdateButtons()
            end
        end

        hooksecurefunc(BG, "ClickFBbutton", function(FB)
            After(0.5, function()
                mainFrame:UpdateAllFrame()
                mainFrame:UpdateFilteFrame()
            end)
        end)
    end

    -- 设置价格
    do
        local function CreateUI(y, text, OnEnter, func, isNum)
            local bg = CreateFrame("Frame", nil, mainFrame)

            local t = bg:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOPLEFT", mainFrame.frame, "BOTTOMLEFT", 0, y)
            t:SetTextColor(1, 0.82, 0)
            t:SetText(text)

            local edit = CreateFrame("EditBox", nil, bg, BG.editTemplate)
            edit:SetSize(100, 20)
            edit:SetPoint("LEFT", t, "RIGHT", 10, 0)
            edit:SetAutoFocus(false)
            if isNum then
                edit:SetNumeric(true)
            end
            edit:SetMaxBytes(MAXBYTES)
            bg.edit = edit
            edit:SetScript("OnEditFocusGained", function(self)
                BG.lastfocus = self
                self.bt:Show()
                self:HighlightText()
            end)
            edit:SetScript("OnEditFocusLost", function(self)
                self.bt:Hide()
                self:ClearHighlightText()
            end)
            edit:SetScript("OnEnterPressed", function(self)
                self.bt:Click()
            end)
            edit:SetScript("OnMouseDown", function(self, enter)
                if enter == "RightButton" then
                    if not self:HasFocus() then
                        edit:SetEnabled(false)
                    end
                    edit:SetText("")
                end
            end)
            edit:SetScript("OnMouseUp", function(self, enter)
                if enter == "RightButton" then
                    edit:SetEnabled(true)
                end
            end)
            edit:SetScript("OnEnter", OnEnter)
            edit:SetScript("OnLeave", GameTooltip_Hide)

            local bt = BG.CreateButton(bg)
            bt:SetSize(60, 20)
            bt:SetPoint("LEFT", edit, "RIGHT", 5, 0)
            bt:SetText(L["确定"])
            bt:Hide()
            edit.bt = bt
            bt.edit = edit
            bt:SetScript("OnClick", func)

            local bt = BG.CreateButton(edit.bt)
            bt:SetSize(60, 20)
            bt:SetPoint("LEFT", edit.bt, "RIGHT", 5, 0)
            bt:SetText(L["取消"])
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                edit:ClearFocus()
            end)
            return bg
        end
        -- 起拍价
        do
            local function OnEnter(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["设置全部起拍价"], 1, 1, 1, true)
                GameTooltip:AddLine(format(L["把一共%s件装备设置为该起拍价。"], #db), 1, 0.82, 0, true)
                GameTooltip:Show()
            end
            local function OnClick(self)
                BG.PlaySound(1)
                local edit = self.edit
                edit:ClearFocus()
                local money = tonumber(edit:GetText())
                if money == 0 then
                    money = nil
                end
                local FB = BG.FB1
                for i, v in ipairs(db) do
                    BiaoGe.auctionPreset[FB].money[v.itemID] = money
                end
                mainFrame:UpdateAllFrame()
            end
            CreateUI(-20, L["设置全部起拍价："], OnEnter, OnClick, true)

            local function OnEnter(self)
                local bar = mainFrame.scroll.ScrollBar
                local value = floor(bar:GetValue()) or 0
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["设置本页起拍价"], 1, 1, 1, true)
                GameTooltip:AddLine(format(L["把序号%s-%s的装备设置为该起拍价。"], value + 1, value + MAXBUTTONS), 1, 0.82, 0, true)
                GameTooltip:Show()
            end
            local function OnClick(self)
                BG.PlaySound(1)
                local edit = self.edit
                edit:ClearFocus()
                local money = tonumber(edit:GetText())
                if money == 0 then
                    money = nil
                end
                local FB = BG.FB1
                local bar = mainFrame.scroll.ScrollBar
                local value = floor(bar:GetValue()) or 0
                for ii = 1, MAXBUTTONS do
                    local num = value + ii
                    local v = db[num]
                    if v then
                        BiaoGe.auctionPreset[FB].money[v.itemID] = money
                    end
                end
                mainFrame:UpdateAllFrame()
            end
            CreateUI(-45, L["设置本页起拍价："], OnEnter, OnClick, true)

            local function OnEnter(self)
                local bar = mainFrame.scroll.ScrollBar
                local value = floor(bar:GetValue()) or 0
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["设置已选起拍价"], 1, 1, 1, true)
                GameTooltip:AddLine(format(L["把当前选择的%s件装备设置为该起拍价。"], Size(choose)), 1, 0.82, 0, true)
                GameTooltip:Show()
            end
            local function OnClick(self)
                BG.PlaySound(1)
                local edit = self.edit
                local money = tonumber(edit:GetText())
                if money == 0 then
                    money = nil
                end
                local FB = BG.FB1
                for dbNum, v in pairs(choose) do
                    BiaoGe.auctionPreset[FB].money[db[dbNum].itemID] = money
                end
                mainFrame:UpdateAllFrame()
                edit:ClearFocus()
            end
            mainFrame.SetChooseButton = CreateUI(-70, L["设置已选起拍价："], OnEnter, OnClick, true)
            mainFrame.SetChooseButton:Hide()
            mainFrame.SetChooseButton.edit:HookScript("OnEditFocusLost", function(self)
                After(0, function()
                    if mainFrame.SetChooseButton2.edit:HasFocus() then return end
                    wipe(choose)
                    for ii = 1, MAXBUTTONS do
                        local bt = mainFrame.buttons[ii][1]
                        bt.tex:Hide()
                    end
                    UpdateSetChooseButton()
                end)
            end)
        end
        -- 起拍语
        do
            local function OnEnter(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["设置全部起拍语"], 1, 1, 1, true)
                GameTooltip:AddLine(format(L["把一共%s件装备设置为该起拍语。"], #db), 1, 0.82, 0, true)
                GameTooltip:Show()
            end
            local function OnClick(self)
                BG.PlaySound(1)
                local edit = self.edit
                edit:ClearFocus()
                local text = edit:GetText()
                if text == "" then
                    text = nil
                end
                local FB = BG.FB1
                for i, v in ipairs(db) do
                    BiaoGe.auctionPreset[FB].money[v.itemID .. "tips"] = text
                end
                mainFrame:UpdateAllFrame()
            end
            CreateUI(-100, L["设置全部起拍语："], OnEnter, OnClick)

            local function OnEnter(self)
                local bar = mainFrame.scroll.ScrollBar
                local value = floor(bar:GetValue()) or 0
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["设置本页起拍语"], 1, 1, 1, true)
                GameTooltip:AddLine(format(L["把序号%s-%s的装备设置为该起拍语。"], value + 1, value + MAXBUTTONS), 1, 0.82, 0, true)
                GameTooltip:Show()
            end
            local function OnClick(self)
                BG.PlaySound(1)
                local edit = self.edit
                edit:ClearFocus()
                local text = edit:GetText()
                if text == "" then
                    text = nil
                end
                local FB = BG.FB1
                local bar = mainFrame.scroll.ScrollBar
                local value = floor(bar:GetValue()) or 0
                for ii = 1, MAXBUTTONS do
                    local num = value + ii
                    local v = db[num]
                    if v then
                        BiaoGe.auctionPreset[FB].money[v.itemID .. "tips"] = text
                    end
                end
                mainFrame:UpdateAllFrame()
            end
            CreateUI(-125, L["设置本页起拍语："], OnEnter, OnClick)

            local function OnEnter(self)
                local bar = mainFrame.scroll.ScrollBar
                local value = floor(bar:GetValue()) or 0
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["设置已选起拍语"], 1, 1, 1, true)
                GameTooltip:AddLine(format(L["把当前选择的%s件装备设置为该起拍语。"], Size(choose)), 1, 0.82, 0, true)
                GameTooltip:Show()
            end
            local function OnClick(self)
                BG.PlaySound(1)
                local edit = self.edit
                local text = edit:GetText()
                if text == "" then
                    text = nil
                end
                local FB = BG.FB1
                for dbNum, v in pairs(choose) do
                    BiaoGe.auctionPreset[FB].money[db[dbNum].itemID .. "tips"] = text
                end
                mainFrame:UpdateAllFrame()
                edit:ClearFocus()
            end
            mainFrame.SetChooseButton2 = CreateUI(-150, L["设置已选起拍语："], OnEnter, OnClick)
            mainFrame.SetChooseButton2:Hide()
            mainFrame.SetChooseButton2.edit:HookScript("OnEditFocusLost", function(self)
                After(0, function()
                    if mainFrame.SetChooseButton.edit:HasFocus() then return end
                    wipe(choose)
                    for ii = 1, MAXBUTTONS do
                        local bt = mainFrame.buttons[ii][1]
                        bt.tex:Hide()
                    end
                    UpdateSetChooseButton()
                end)
            end)
        end

        function UpdateSetChooseButton()
            if next(choose) then
                mainFrame.SetChooseButton:Show()
                mainFrame.SetChooseButton2:Show()
                mainFrame.SetChooseButton.edit:SetFocus()
            else
                mainFrame.SetChooseButton:Hide()
                mainFrame.SetChooseButton2:Hide()
            end
        end
    end

    -- 过滤条件
    do
        local MAXWIDTH = 490
        local WIDTH = 100
        local CreateCheckButton, CreateEdit, CreateSetAllCheckButton
        do
            local function OnClick(self)
                BG.PlaySound(1)
                if self:GetChecked() then
                    if self.onlyChoose then
                        for i, bt in ipairs(self:GetParent().buttons) do
                            bt:SetChecked(false)
                            BiaoGe.auctionPreset[self.FB][bt.key][bt.key2] = nil
                        end
                        self:SetChecked(true)
                    end
                    BiaoGe.auctionPreset[self.FB][self.key][self.key2] = 1
                else
                    BiaoGe.auctionPreset[self.FB][self.key][self.key2] = nil
                end
                mainFrame:UpdateAllFrame()
            end
            local function OnEnter(self)
                if self.Text:IsTruncated() then
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(self.Text:GetText())
                    GameTooltip:Show()
                end
                -- if not self.ontext then return end
                -- GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                -- GameTooltip:ClearLines()
                -- if type(self.ontext) == "table" then
                --     for i, text in ipairs(self.ontext) do
                --         if i == 1 then
                --             GameTooltip:AddLine(text, 1, 1, 1, true)
                --         else
                --             GameTooltip:AddLine(text, 1, 0.82, 0, true)
                --         end
                --         GameTooltip:Show()
                --     end
                -- else
                --     GameTooltip:SetText(self.ontext)
                -- end
            end
            local function OnLeave(self)
                GameTooltip:Hide()
            end
            function CreateCheckButton(FB, key, key2, text, parent, onlyChoose)
                local bt = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
                bt:SetSize(30, 30)
                bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                bt.Text:SetText(text)
                if bt.Text:GetUnboundedStringWidth() > WIDTH then
                    bt.Text:SetWidth(WIDTH)
                    bt.Text:SetWordWrap(false)
                end
                bt.width = bt.Text:GetWidth()
                parent.width = parent.width + bt.Text:GetUnboundedStringWidth()
                bt:SetHitRectInsets(0, -bt.Text:GetWidth(), 0, 0)
                if #parent.buttons == 0 then
                    bt:SetPoint("TOPLEFT", 5, -5)
                else
                    bt:SetPoint("LEFT", parent.buttons[#parent.buttons], "RIGHT", parent.buttons[#parent.buttons].width + 5, 0)
                end
                if bt.Text:GetRight() > parent:GetRight() - 5 then
                    bt:ClearAllPoints()
                    bt:SetPoint("TOPLEFT", parent.buttons[parent.lastStart], "BOTTOMLEFT", 0, -5)
                    parent.lastStart = #parent.buttons + 1
                    parent.line = parent.line + 1
                end
                parent:SetHeight(parent.line * (bt:GetHeight() + 5) + 5)
                bt.FB = FB
                bt.key = key
                bt.key2 = key2
                bt.onlyChoose = onlyChoose
                tinsert(parent.buttons, bt)
                if BiaoGe.auctionPreset[FB][key][key2] == 1 then
                    bt:SetChecked(true)
                else
                    bt:SetChecked(false)
                end
                bt:SetScript("OnClick", OnClick)
                bt:SetScript("OnEnter", OnEnter)
                bt:SetScript("OnLeave", OnLeave)
                return bt
            end

            function CreateEdit(FB, key, key2, setNumeric, parent)
                local edit = CreateFrame("EditBox", nil, parent, BG.editTemplate)
                edit:SetSize(120, 20)
                edit:SetPoint("TOPLEFT", 15, -8)
                edit:SetText(BiaoGe.auctionPreset[FB][key][key2] or "")
                edit:SetAutoFocus(false)
                edit:SetNumeric(setNumeric)
                SetEditScript(edit)
                parent:SetHeight(36)
                edit:SetScript("OnTextChanged", function(self)
                    if setNumeric then
                        local num = tonumber(self:GetText())
                        if num == 0 then num = nil end
                        BiaoGe.auctionPreset[FB][key][key2] = num
                    else
                        local text = self:GetText()
                        if text == "" then text = nil end
                        BiaoGe.auctionPreset[FB][key][key2] = text
                    end
                    if self.canUpdate then
                        mainFrame:UpdateAllFrame()
                    end
                end)
                edit:SetScript("OnEditFocusGained", function(self)
                    -- mainFrame.lastFocus = self
                    BG.lastfocus = self
                    self.canUpdate = true
                end)
                edit:SetScript("OnEnterPressed", function(self)
                    self:ClearFocus()
                end)
                edit:SetScript("OnMouseDown", function(self, enter)
                    self.canUpdate = true
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
            end

            function CreateSetAllCheckButton(FB, parent)
                local bt = BG.CreateButton(parent)
                bt:SetPoint("LEFT", parent, "TOPRIGHT", 10, -18)
                bt:SetSize(75, 25)
                bt:SetText(L["全选"])
                local last = bt
                bt:SetScript("OnClick", function(self)
                    BG.PlaySound(1)
                    for i, bt in ipairs(parent.buttons) do
                        bt:SetChecked(true)
                        BiaoGe.auctionPreset[FB][bt.key][bt.key2] = 1
                    end
                    mainFrame:UpdateAllFrame()
                end)

                local bt = BG.CreateButton(parent)
                bt:SetPoint("LEFT", last, "RIGHT", 5, 0)
                bt:SetSize(75, 25)
                bt:SetText(L["取消全选"])
                bt:SetScript("OnClick", function(self)
                    BG.PlaySound(1)
                    for i, bt in ipairs(parent.buttons) do
                        bt:SetChecked(false)
                        BiaoGe.auctionPreset[FB][bt.key][bt.key2] = nil
                    end
                    mainFrame:UpdateAllFrame()
                end)
            end
        end

        local tbl = {
            {
                name = L["副本难度："],
                key = "hard",
                tbl = function(FB)
                    local tbl = {}
                    local names = {
                        N = L["普通"],
                        H = L["困难"],
                        M = L["史诗"],
                        N10 = L["10人|cff00BFFF普通"],
                        H10 = L["10人|cffff0000英雄"],
                        N25 = L["25人|cff00BFFF普通"],
                        H25 = L["25人|cffff0000英雄"],
                    }
                    for _, hard in ipairs(BG.difficultyTable[FB]) do
                        if BG.Loot[FB][hard] and BG.Loot[FB][hard].boss1 then
                            tinsert(tbl, 1, { key = hard, name = names[hard] })
                        end
                    end
                    return tbl
                end,
            },
            {
                name = L["掉落来源："],
                key = "bossNum",
                tbl = function(FB)
                    local tbl = {}
                    local b = 1
                    while BG.Boss[FB]["boss" .. b + 3] do
                        local name = BG.Boss[FB]["boss" .. b].name2
                        local color = BG.Boss[FB]["boss" .. b].color
                        tinsert(tbl, { key = b, name = "|cff" .. color .. name })
                        b = b + 1
                    end
                    return tbl
                end,
            },
            {
                name = L["装备部位："],
                key = "equipLoc",
                tbl = function()
                    return {
                        { name = INVTYPE_HEAD, key = "INVTYPE_HEAD", }, -- 头
                        { name = INVTYPE_NECK, key = "INVTYPE_NECK", }, -- 项链
                        { name = INVTYPE_SHOULDER, key = "INVTYPE_SHOULDER", }, -- 肩膀
                        { name = INVTYPE_CLOAK, key = "INVTYPE_CLOAK", }, -- 背
                        { name = INVTYPE_CHEST, key = "INVTYPE_CHEST", }, -- 胸
                        { name = INVTYPE_WRIST, key = "INVTYPE_WRIST", }, -- 手腕
                        { name = INVTYPE_HAND, key = "INVTYPE_HAND", }, -- 手
                        { name = INVTYPE_WAIST, key = "INVTYPE_WAIST", }, -- 腰带
                        { name = INVTYPE_LEGS, key = "INVTYPE_LEGS", }, -- 腿
                        { name = INVTYPE_FEET, key = "INVTYPE_FEET", }, -- 脚
                        { name = INVTYPE_FINGER, key = "INVTYPE_FINGER", }, -- 戒指
                        { name = INVTYPE_TRINKET, key = "INVTYPE_TRINKET", }, -- 饰品
                        { name = TWO_HANDED, key = "TWO_HANDED", }, -- 双手
                        { name = INVTYPE_WEAPON, key = "INVTYPE_WEAPON", }, -- 单手
                        { name = INVTYPE_SHIELD, key = "INVTYPE_SHIELD", }, -- 副手
                        { name = INVTYPE_RANGED, key = "INVTYPE_RANGED", }, -- 远程
                        { name = L["其他"], key = "INVTYPE_OTHER", }, -- 其他
                    }
                end,
            },
            {
                name = L["装备品质："],
                key = "quality",
                tbl = function()
                    return {
                        { name = "|cffffffff" .. ITEM_QUALITY1_DESC, key = 1, },
                        { name = "|cff1eff00" .. ITEM_QUALITY2_DESC, key = 2, },
                        { name = "|cff0070dd" .. ITEM_QUALITY3_DESC, key = 3, },
                        { name = "|cffa335ee" .. ITEM_QUALITY4_DESC, key = 4, },
                        { name = "|cffff8000" .. ITEM_QUALITY5_DESC, key = 5, },
                    }
                end,
            },
            {
                name = L["绑定类型："],
                key = "bindType",
                tbl = function()
                    return {
                        { name = L["拾取绑定"], key = 1, },
                        { name = L["装备绑定"], key = 2, },
                        { name = L["使用绑定"], key = 3, },
                        { name = L["不绑定"], key = 0, },
                    }
                end,
            },
            {
                name = L["职业限制："],
                key = "classType",
                tbl = function()
                    return {
                        { name = L["有职业限制"], key = "yes", },
                        { name = L["无职业限制"], key = "no", },
                    }
                end,
            },
            {
                name = L["价格类型："],
                key = "moneyType",
                tbl = function()
                    return {
                        { name = L["已预设起拍价"], key = "yes", },
                        { name = L["未预设起拍价"], key = "no", },
                    }
                end,
            },
            {
                name = L["装备名字："],
                key = "name",
                edit = true,
                tbl = function()
                    return {
                        { edit = true, key = "name", }
                    }
                end,
            },
            {
                name = L["装备等级："],
                key = "level",
                edit = true,
                tbl = function()
                    return {
                        { edit = true, key = "level1", setNumeric = true }
                    }
                end,
            },
            {
                name = L["起拍价："],
                key = "startMoney",
                edit = true,
                tbl = function()
                    return {
                        { edit = true, key = "startMoney1", setNumeric = true }
                    }
                end,
            },
            {
                name = L["起拍语："],
                key = "tips",
                edit = true,
                tbl = function()
                    return {
                        { edit = true, key = "tips1", }
                    }
                end,
            },
        }
        if fitlerTbl then
            tinsert(tbl, 7, {
                name = L["装备属性：\n（单选）"],
                key = "attribute",
                onlyChoose = true,
                tbl = function()
                    return fitlerTbl
                end,
            })
        end

        for _, FB in ipairs(BG.FBtable) do
            mainFrame[FB] = CreateFrame("Frame", nil, mainFrame)
            mainFrame[FB]:Hide()
            mainFrame[FB].fitleFrames = {}
        end
        local function CreateUI(FB)
            for i, v in ipairs(tbl) do
                local f = CreateFrame("Frame", nil, mainFrame[FB], "BackdropTemplate")
                f:SetBackdrop({
                    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = 1,
                })
                f:SetBackdropBorderColor(1, 1, 1, .1)
                f:SetSize(MAXWIDTH, 30)
                if i == 1 then
                    f:SetPoint("TOPLEFT", mainFrame.frame, "TOPRIGHT", 110, 0)
                else
                    f:SetPoint("TOPLEFT", mainFrame[FB].fitleFrames[i - 1], "BOTTOMLEFT", 0, -5)
                end
                f.width = 0
                f.line = 1
                f.lastStart = 1
                f.buttons = {}
                tinsert(mainFrame[FB].fitleFrames, f)

                local t = f:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetPoint("RIGHT", f, "TOPLEFT", -5, -18)
                t:SetTextColor(1, 0.82, 0)
                t:SetText(v.name)
                t:SetJustifyH("RIGHT")

                for ii, vv in ipairs(v.tbl(FB)) do
                    BiaoGe.auctionPreset[FB][v.key] = BiaoGe.auctionPreset[FB][v.key] or {}
                    if vv.edit then
                        CreateEdit(FB, v.key, vv.key, vv.setNumeric, f)
                    else
                        if not v.onlyChoose then
                            BiaoGe.auctionPreset[FB][v.key][vv.key] = BiaoGe.auctionPreset[FB][v.key][vv.key] or 1
                        end
                        -- f.key2=f.key2 or {}
                        -- f.key2[]
                        CreateCheckButton(FB, v.key, vv.key, vv.name, f, v.onlyChoose)
                    end
                end
                if not v.edit and not v.onlyChoose then
                    CreateSetAllCheckButton(FB, f, v.key)
                end
            end
        end
        for _, FB in ipairs(BG.FBtable) do
            CreateUI(FB)
        end

        function mainFrame:UpdateFilteFrame()
            for _, FB in ipairs(BG.FBtable) do
                mainFrame[FB]:Hide()
            end
            mainFrame[BG.FB1]:Show()
        end
    end

    -- 导入导出
    do
        local function CreateScroll(bt)
            local frame, scroll, child
            local bg = CreateFrame("Frame", nil, bt, "BackdropTemplate")
            do
                bg:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = 1,
                })
                bg:SetBackdropColor(0, 0, 0, 0.8)
                bg:SetBackdropBorderColor(1, 1, 1, .6)
                bg:SetPoint("TOPRIGHT", BG.MainFrame, "TOPRIGHT", -20, -20)
                bg:SetSize(250, 250)
                bg:SetFrameLevel(130)
                bg:EnableMouse(true)
                bg:Hide()
                bt.bg = bg
                local t = bg:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetPoint("TOP", 0, -8)
                t:SetTextColor(1, 1, 1)
                t:SetText(bt:GetText())
            end

            frame = CreateFrame("Frame", nil, bg, "BackdropTemplate")
            do
                frame:SetBackdrop({
                    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = 1,
                })
                frame:SetBackdropBorderColor(1, 1, 1, 0.5)
                frame:SetPoint("TOPLEFT", 8, -28)
                frame:SetSize(bg:GetWidth() - 16, bg:GetHeight() - 70)
                scroll = CreateFrame("ScrollFrame", nil, frame, BG.scrollTemplate)
                scroll:SetPoint("TOPLEFT", 5, -4)
                scroll:SetPoint("BOTTOMRIGHT", -27, 4)
                bt.scroll = scroll
                BG.CreateSrollBarBackdrop(scroll.ScrollBar)
                BG.HookScrollBarShowOrHide(scroll)
                child = CreateFrame("EditBox", nil, scroll)
                child:SetWidth(scroll:GetWidth())
                child:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                child:SetMultiLine(true)
                child:SetAutoFocus(false)
                child:EnableMouse(true)
                bt.child = child
                scroll:SetScrollChild(child)
                child:SetScript("OnEscapePressed", function(self)
                    bg:Hide()
                end)
                scroll:SetScript("OnMouseDown", function(self)
                    child:SetFocus()
                end)
            end

            local bt = BG.CreateButton(bg)
            do
                bt:SetSize(110, 25)
                bt:SetPoint("BOTTOMRIGHT", -8, 10)
                bt:SetText(CANCEL)
                bt:SetScript("OnClick", function(self)
                    bg:Hide()
                end)
            end
        end

        local bt = CreateFrame("Button", nil, mainFrame)
        bt:SetPoint("TOPRIGHT", BG.MainFrame, "TOPRIGHT", -35, 4)
        bt:SetNormalFontObject(BG.FontGreen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        bt:SetText(L["导入价格"])
        bt:SetSize(bt:GetFontString():GetWidth(), 30)
        BG.SetTextHighlightTexture(bt)
        mainFrame.importButton = bt
        CreateScroll(bt)
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            if self.bg:IsVisible() then
                self.bg:Hide()
            else
                mainFrame.importButton.bg:Show()
                mainFrame.exportButton.bg:Hide()
                self.child:SetText("")
                self.child:SetFocus()
            end
        end)
        local _bt = BG.CreateButton(bt.bg)
        _bt:SetSize(110, 25)
        _bt:SetPoint("BOTTOMLEFT", 8, 10)
        _bt:SetText(OKAY)
        _bt:SetScript("OnClick", function(self)
            local text = bt.child:GetText()
            local FB = text:match("^(.+):")
            local yes
            for _, _FB in ipairs(BG.FBtable) do
                if FB == _FB then
                    yes = true
                    break
                end
            end
            if not yes then
                SendSystemMessage(format(BG.STC_r1(L["代码错误！识别失败！"])))
                BG.PlaySound(1)
                return
            end
            text = text:gsub("^.+:", "")
            if ns.IsBase64(text) then
                text = ns.Decode(text)
            else
                SendSystemMessage(format(BG.STC_r1(L["代码错误！识别失败！"])))
                BG.PlaySound(1)
                return
            end
            wipe(BiaoGe.auctionPreset[FB].money)
            local tbl1 = { strsplit(",", text) }
            tremove(tbl1, #tbl1)
            for _, v in ipairs(tbl1) do
                local itemID, money, tips = strsplit("-", v)
                itemID = tonumber(itemID)
                money = tonumber(money)
                if itemID and money then
                    BiaoGe.auctionPreset[FB].money[itemID] = money
                    BiaoGe.auctionPreset[FB].money[itemID .. "tips"] = tips ~= "" and tips or nil
                end
            end
            if FB ~= BG.FB1 then
                BG.ClickFBbutton(FB)
            else
                mainFrame:UpdateAllFrame()
            end
            SendSystemMessage(format(BG.STC_g1(L["预设价格导入成功：%s，一共导入%s个价格。"]), BG.GetFBinfo(FB, "localName"), #tbl1))
            bt.bg:Hide()
            BG.PlaySound(2)
        end)

        local bt = CreateFrame("Button", nil, mainFrame)
        bt:SetPoint("RIGHT", mainFrame.importButton, "LEFT", -7, 0)
        bt:SetNormalFontObject(BG.FontGreen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        bt:SetText(L["导出价格"])
        bt:SetSize(bt:GetFontString():GetWidth(), 30)
        BG.SetTextHighlightTexture(bt)
        mainFrame.exportButton = bt
        CreateScroll(bt)
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            if self.bg:IsVisible() then
                self.bg:Hide()
            else
                mainFrame.importButton.bg:Hide()
                mainFrame.exportButton.bg:Show()

                local FB = BG.FB1
                local text = ""
                for itemID, money in pairs(BiaoGe.auctionPreset[FB].money) do
                    if type(itemID) == "number" then
                        local tips = BiaoGe.auctionPreset[FB].money[itemID .. "tips"] or ""
                        text = text .. itemID .. "-" .. money .. "-" .. tips .. ","
                    end
                end
                self.child:SetText(FB .. ":" .. ns.Encode(text))
                self.child:SetFocus()
                self.child:HighlightText()
                self.child:SetCursorPosition(0)
            end
        end)
    end
end)
