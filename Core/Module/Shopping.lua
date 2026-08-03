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
local GetClassName = ns.GetClassName
local CreateLine = ns.CreateLine
local SendSystemMessage = ns.SendSystemMessage
local ver = ns.ver
local After = C_Timer.After
local player = UnitName("player")
local realmID = GetRealmID()

local pt = print
local RealmID = GetRealmID()

local classItems = {}
for _, v in ipairs(BG.shoppingDB) do
    for _, itemID in ipairs(v.itemID) do
        classItems[itemID] = v.icon
    end
end
BG.shoppingDB = nil

BG.Init(function()
    BiaoGe.showShopping = BiaoGe.showShopping or 0
end)

BG.Init2(function()
    local mainFrameWidth = 640
    local filterHeight = 30
    local buttonHeight = 45
    local buttonWidth = 153
    local slotTextWidth = 70
    local btScale = 0.9
    local MAX_MONEY_DISPLAY_WIDTH = 120
    local itemCountShow = 5
    local step = 570

    local slots = {
        { name = INVTYPE_HEAD, name2 = "INVTYPE_HEAD", key = { "INVTYPE_HEAD" } },                                                                 -- 头
        { name = INVTYPE_NECK, name2 = "INVTYPE_NECK", key = { "INVTYPE_NECK" } },                                                                 -- 项链
        { name = INVTYPE_SHOULDER, name2 = "INVTYPE_SHOULDER", key = { "INVTYPE_SHOULDER" } },                                                     -- 肩膀
        { name = INVTYPE_CLOAK, name2 = "INVTYPE_CLOAK", key = { "INVTYPE_CLOAK" } },                                                              -- 背
        { name = INVTYPE_CHEST, name2 = "INVTYPE_CHEST", key = { "INVTYPE_CHEST", "INVTYPE_ROBE" } },                                              -- 胸
        { name = INVTYPE_WRIST, name2 = "INVTYPE_WRIST", key = { "INVTYPE_WRIST" } },                                                              -- 手腕
        { name = INVTYPE_HAND, name2 = "INVTYPE_HAND", key = { "INVTYPE_HAND" } },                                                                 -- 手
        { name = INVTYPE_WAIST, name2 = "INVTYPE_WAIST", key = { "INVTYPE_WAIST" } },                                                              -- 腰带
        { name = INVTYPE_LEGS, name2 = "INVTYPE_LEGS", key = { "INVTYPE_LEGS" } },                                                                 -- 腿
        { name = INVTYPE_FEET, name2 = "INVTYPE_FEET", key = { "INVTYPE_FEET" } },                                                                 -- 脚
        { name = INVTYPE_FINGER, name2 = "INVTYPE_FINGER", key = { "INVTYPE_FINGER" } },                                                           -- 戒指
        { name = INVTYPE_TRINKET, name2 = "INVTYPE_TRINKET", key = { "INVTYPE_TRINKET" } },                                                        -- 饰品
        { name = TWO_HANDED, name2 = "TWO_HANDED", key = { "INVTYPE_2HWEAPON" } },                                                                 -- 双手
        { name = INVTYPE_WEAPON, name2 = "INVTYPE_WEAPON", key = { "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND" } },                                 -- 单手
        { name = INVTYPE_SHIELD, name2 = "INVTYPE_SHIELD", key = { "INVTYPE_SHIELD", "INVTYPE_HOLDABLE", "INVTYPE_WEAPONOFFHAND" } },              -- 副手
        { name = INVTYPE_RANGED, name2 = "INVTYPE_RANGED", key = { "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT", "INVTYPE_THROWN", "INVTYPE_RELIC" } }, -- 远程
        { name = L["职业相关"], name2 = L["职业相关"], key = {} },
        { name = L["其他"], name2 = L["其他"], key = {} },
    }

    local mainFrame = CreateFrame("Frame", nil, MerchantFrame, "BackdropTemplate")
    do
        do
            mainFrame:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            mainFrame:SetBackdropColor(0, 0, 0, 0.8)
            mainFrame:SetBackdropBorderColor(1, 1, 1, BG.borderAlpha)
            mainFrame:SetSize(mainFrameWidth, 500)
            mainFrame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 2, 0)
            mainFrame:EnableMouse(true)
            mainFrame:Hide()
            mainFrame.slots = {}
            mainFrame.slotTexts = {}
            mainFrame.buttons = {}
            mainFrame.CloseButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
            mainFrame.CloseButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 5, 5)
            mainFrame.CloseButton:HookScript("OnClick", function()
                BiaoGe.showShopping = 0
            end)
            local l = mainFrame:CreateLine()
            l:SetColorTexture(1, 1, 1, BG.borderAlpha)
            l:SetStartPoint("TOPLEFT", 1, -21)
            l:SetEndPoint("TOPRIGHT", -1, -21)
            l:SetThickness(1)
            mainFrame.titleText = mainFrame:CreateFontString()
            mainFrame.titleText:SetPoint("TOP", 0, -2)
            mainFrame.titleText:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            mainFrame.titleText:SetText(L["商品总览"])
            mainFrame:SetScript("OnShow", function(self)
            end)
            mainFrame:SetScript("OnHide", function(self)
            end)
            mainFrame:SetScript("OnEvent", function(self, event, ...)
            end)
        end

        local function CreateHorizontalScrollFrameWithTemplate()
            -- 1. 创建基础滚动框（使用内置模板）
            local scrollFrame = CreateFrame("ScrollFrame", "BGMerchantItemScrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
            scrollFrame:SetPoint("TOPLEFT", slotTextWidth, -20 - filterHeight)
            scrollFrame:SetPoint("BOTTOMRIGHT", -5, 0)

            -- 5. 创建内容框
            local scrollChild = CreateFrame("Frame", nil, scrollFrame)
            scrollFrame:SetScrollChild(scrollChild)
            scrollChild:SetPoint("CENTER")
            scrollChild:SetSize(1, 1)
            scrollFrame.child = scrollChild

            -- 2. 获取模板自带的滚动条并改造为横向
            local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
            scrollBar:Hide()
            scrollBar:ClearAllPoints()
            scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMLEFT", 15, 3)
            scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -15, 3)
            scrollBar:SetHeight(16)
            scrollBar:SetOrientation("HORIZONTAL")
            scrollBar.scrollStep = step
            BG.CreateSrollBarBackdrop(scrollBar)

            -- 3. 修复滚动条箭头（旋转+启用+位置）
            local upButton = _G[scrollBar:GetName() .. "ScrollUpButton"]     -- 左箭头（原上箭头）
            local downButton = _G[scrollBar:GetName() .. "ScrollDownButton"] -- 右箭头（原下箭头）
            upButton:GetNormalTexture():SetRotation(math.rad(90))            -- 上箭头→左箭头（逆时针90度）
            upButton:GetPushedTexture():SetRotation(math.rad(90))
            upButton:GetDisabledTexture():SetRotation(math.rad(90))
            upButton:GetHighlightTexture():SetRotation(math.rad(90))
            downButton:GetNormalTexture():SetRotation(math.rad(90)) -- 下箭头→右箭头（顺时针90度）
            downButton:GetPushedTexture():SetRotation(math.rad(90))
            downButton:GetDisabledTexture():SetRotation(math.rad(90))
            downButton:GetHighlightTexture():SetRotation(math.rad(90))
            upButton:ClearAllPoints()
            upButton:SetPoint("LEFT", scrollBar, "LEFT", -16, 1)
            upButton:SetSize(16, 16)
            downButton:ClearAllPoints()
            downButton:SetPoint("RIGHT", scrollBar, "RIGHT", 16, 1)
            downButton:SetSize(16, 16)

            -- 关键：启用箭头按钮（模板默认可能禁用）
            upButton:Enable()
            downButton:Enable()

            -- 4. 修复箭头点击逻辑+状态同步
            local function UpdateArrowStates()
                local currentX = scrollFrame:GetHorizontalScroll()
                local maxX = scrollFrame:GetHorizontalScrollRange()
                -- 左箭头：滚动到最左侧时禁用
                if currentX <= 0 then
                    upButton:Disable()
                else
                    upButton:Enable()
                end
                -- 右箭头：滚动到最右侧时禁用
                if currentX >= maxX then
                    downButton:Disable()
                else
                    downButton:Enable()
                end
            end

            -- 左箭头点击（左移）
            upButton:SetScript("OnClick", function()
                local current = scrollFrame:GetHorizontalScroll()
                local new = math.max(0, current - 50)
                scrollFrame:SetHorizontalScroll(new)
                UpdateArrowStates() -- 点击后更新状态
            end)

            -- 右箭头点击（右移）
            downButton:SetScript("OnClick", function()
                local current = scrollFrame:GetHorizontalScroll()
                local maxX = scrollFrame:GetHorizontalScrollRange()
                local new = math.min(maxX, current + 50)
                scrollFrame:SetHorizontalScroll(new)
                UpdateArrowStates() -- 点击后更新状态
            end)

            -- 7. 同步滚动条与滚动位置+箭头状态
            scrollFrame:SetScript("OnScrollRangeChanged", function(self, xRange, yRange)
                scrollBar:SetMinMaxValues(0, xRange)
                scrollBar:SetValue(self:GetHorizontalScroll())
                UpdateArrowStates() -- 范围变化时更新状态

                if xRange <= 8 then
                    self.ScrollBar:Hide()
                else
                    self.ScrollBar:Show()
                end
            end)

            scrollBar:SetScript("OnValueChanged", function(self, value)
                scrollFrame:SetHorizontalScroll(value)
                UpdateArrowStates() -- 滚动条拖动时更新状态
            end)

            scrollFrame:SetScript("OnHorizontalScroll", function(self, value)
                scrollBar:SetValue(value)
                UpdateArrowStates() -- 滚动时更新状态
            end)

            -- 8. 鼠标滚轮支持+状态同步
            scrollFrame:SetScript("OnMouseWheel", function(self, delta)
                local currentX = self:GetHorizontalScroll()
                local maxX = self:GetHorizontalScrollRange()
                local newX = currentX - delta * step
                newX = math.max(0, math.min(newX, maxX))
                self:SetHorizontalScroll(newX)
                UpdateArrowStates() -- 滚轮后更新状态
            end)

            -- 初始化箭头状态
            UpdateArrowStates()

            return scrollFrame, scrollChild
        end

        local scroll, child = CreateHorizontalScrollFrameWithTemplate()
        mainFrame.scroll = scroll
        mainFrame.child = child

        local Buttons = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
        do
            Buttons:SetPoint("TOP", 10, -25)
            Buttons:SetSize(0, 30)
            Buttons.type = 3
            mainFrame.filterButtons = Buttons
            tinsert(BG.filterClassButtons, Buttons)

            local t = Buttons:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetText(L["装备过滤："])
            t:SetTextColor(1, 0.82, 0)
            t:SetPoint("RIGHT", Buttons, "LEFT", -10, 0)
            BG.CreateFilterClassButtons(Buttons)
        end
    end

    local bt = BG.CreateButton(MerchantFrame)
    do
        bt:SetPoint("TOPRIGHT", -10, -30)
        bt:SetText(L["商品总览"])
        bt:SetSize(100, 25)
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            if mainFrame:IsVisible() then
                BiaoGe.showShopping = 0
                mainFrame:Hide()
            else
                BiaoGe.showShopping = 1
                BG.UpdateMerchantFrame(true)
            end
        end)
        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
            GameTooltip:AddLine(L["把商品按装备部位进行排列，并且可以自定义过滤。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(L["该功能仅对销售装备的商人生效。"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        bt:SetScript("OnLeave", GameTooltip_Hide)
    end

    local function CreateButton(slotFrame, ii, i)
        local id = ii .. "/" .. i
        local bt = CreateFrame("Frame", "BGMerchantItem" .. id, slotFrame, "MerchantItemTemplate")
        bt:SetPoint("LEFT", (buttonWidth + 5) * (i - 1), -4)
        bt:SetScale(btScale)
        bt:Hide()
        bt.id = id
        local tex = bt.ItemButton:CreateTexture(nil, "OVERLAY")
        tex:SetPoint("BOTTOM", 0, -5)
        tex:SetSize(45, 45)
        tex:SetTexture("interface/raidframe/readycheck-ready")
        tex:Hide()
        bt.havedTex = tex
        local t = bt.ItemButton:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
        t:SetPoint("BOTTOM", 0, 0)
        bt.levelText = t
        local f = CreateFrame("Frame", nil, bt.ItemButton, "BackdropTemplate")
        f:SetBackdrop({
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 1,
        })
        f:SetBackdropBorderColor(1, 1, 1, .6)
        f:SetPoint("TOPLEFT", 0, 0)
        f:SetSize(20, 20)
        f:Hide()
        bt.classFrame = f
        local tex = f:CreateTexture(nil, "BACKGROUND")
        tex:SetAllPoints()
        bt.classTex = tex
        local t = bt.ItemButton:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
        t:SetPoint("TOP", 0, -2)
        t:SetTextColor(0, 1, 0)
        t:SetText(L["装绑"])
        bt.boeText = t
        local SlotTexture = _G[bt:GetName() .. "SlotTexture"]
        SlotTexture:Hide()
        local nameFrame = _G[bt:GetName() .. "NameFrame"]
        nameFrame:SetHeight(72)
        nameFrame:ClearAllPoints()
        nameFrame:SetPoint("LEFT", SlotTexture, "RIGHT", -9, -12)
        local Name = _G[bt:GetName() .. "Name"]
        Name:ClearAllPoints()
        Name:SetPoint("LEFT", SlotTexture, "RIGHT", -5, 11)
        Name:SetWordWrap(false)
        tinsert(slotFrame.buttons, bt)
        return bt
    end

    for ii, v in ipairs(slots) do
        local slotFrame = CreateFrame("Frame", nil, mainFrame.child, "BackdropTemplate")
        slotFrame:SetSize(mainFrameWidth - 100, buttonHeight)
        slotFrame.buttons = {}
        slotFrame.num = 1
        slotFrame.name = v.name
        tinsert(mainFrame.slots, slotFrame)

        for i = 1, 10 do
            CreateButton(slotFrame, ii, i)
        end
    end

    local function Filter(itemLink)
        local itemID, _, _, EquipLoc, _, typeID, subclassID = GetItemInfoInstant(itemLink)
        local num = BiaoGe.FilterClassItemDB[RealmID][player].chooseID
        if itemID and num then
            if BG.FilterAll(itemID, typeID, EquipLoc, subclassID) then
                return true
            end
        end
    end
    local function GetButtonIndex(slotIndex)
        local slotFrame = mainFrame.slots[slotIndex]
        local btIndex = 1
        while true do
            local bt = slotFrame.buttons[btIndex]
            if not bt then
                bt = CreateButton(slotFrame, slotIndex, btIndex)
            end
            if not bt:IsShown() then
                bt:Show()
                slotFrame:Show()
                return bt
            end
            btIndex = btIndex + 1
        end
    end
    local function GetButtonByEquipLoc(equipLoc, itemLink, itemID, quality)
        if equipLoc and not equipLoc:find("_NON_") then
            if quality >= 2 then -- 紫装数量
                mainFrame.equipLocCount = mainFrame.equipLocCount + 1
            end
            if Filter(itemLink) then return end
            for i, v in ipairs(slots) do
                for _, _equipLoc in ipairs(v.key) do
                    if equipLoc == _equipLoc then
                        return GetButtonIndex(i)
                    end
                end
            end
        end
        if itemID and BG.GetTooltipTextLeftAll(itemID):find(CLASS) then
            return GetButtonIndex(#slots - 1)
        else
            return GetButtonIndex(#slots)
        end
    end
    local function UpdateLevelText(bt)
        local typeID = bt.ItemButton.typeID
        local quality = bt.ItemButton.quality
        local level = bt.ItemButton.level
        if (typeID == 2 or typeID == 4) and quality > 1 and level > 1 then
            local r, g, b = GetItemQualityColor(quality)
            bt.levelText:SetText(level)
            bt.levelText:SetTextColor(r, g, b)
        else
            bt.levelText:SetText("")
        end
    end
    local function UpdateHaveTex(bt)
        local typeID = bt.ItemButton.typeID
        local quality = bt.ItemButton.quality
        local level = bt.ItemButton.level
        local itemID = bt.ItemButton.itemID
        if (typeID == 2 or typeID == 4) and quality > 1 and level > 1
            and GetItemCount(itemID, true) > 0 then
            bt.havedTex:Show()
        else
            bt.havedTex:Hide()
        end
    end
    local function UpdateBOEText(bt)
        bt.boeText:SetShown(bt.ItemButton.bindType == 2)
    end
    local function UpdateClassTex(bt)
        local itemID = bt.ItemButton.itemID
        if classItems[itemID] then
            bt.classFrame:Show()
            bt.classTex:SetTexture(classItems[itemID])
        else
            bt.classFrame:Hide()
            bt.classTex:SetTexture(nil)
        end
    end
    local function UpdateAllHaveTex()
        for k, slotFrame in pairs(mainFrame.slots) do
            for k, bt in pairs(slotFrame.buttons) do
                if bt:IsVisible() then
                    UpdateHaveTex(bt)
                end
            end
        end
    end
    local function ResetFrame()
        mainFrame.equipLocCount = 0
        mainFrame:Hide()
        for k, slotFrame in pairs(mainFrame.slots) do
            slotFrame:Hide()
            for k, bt in pairs(slotFrame.buttons) do
                bt:Hide()
            end
        end
        for i = #mainFrame.slotTexts, 1, -1 do
            mainFrame.slotTexts[i]:Hide()
            tremove(mainFrame.slotTexts, i)
        end
    end
    local function MerchantFrame_UpdateAltCurrency(index, indexOnPage, canAfford)
        local itemCount = GetMerchantItemCostInfo(index);
        local frameName = "BGMerchantItem" .. indexOnPage .. "AltCurrencyFrame";
        local usedCurrencies = 0;
        local width = 0;

        -- update Alt Currency Frame with itemValues
        if (itemCount > 0) then
            for i = 1, MAX_ITEM_COST do
                local itemTexture, itemValue, itemLink = GetMerchantItemCostItem(index, i);
                if (itemTexture) then
                    usedCurrencies = usedCurrencies + 1;
                    local button = _G[frameName .. "Item" .. usedCurrencies];
                    button.index = index;
                    button.item = i;
                    button.itemLink = itemLink;
                    AltCurrencyFrame_Update(frameName .. "Item" .. usedCurrencies, itemTexture, itemValue, canAfford);
                    width = width + button:GetWidth();
                    if (usedCurrencies > 1) then
                        -- button spacing;
                        width = width + 4;
                    end
                    button:Show();
                end
            end
            for i = usedCurrencies + 1, MAX_ITEM_COST do
                _G[frameName .. "Item" .. i]:Hide();
            end
        else
            for i = 1, MAX_ITEM_COST do
                _G[frameName .. "Item" .. i]:Hide();
            end
        end
        return width;
    end

    -- 主函数
    local function UpdateMerchantInfo(setValue)
        local name, texture, price, stackCount, numAvailable, isPurchasable, isUsable, extendedCost, currencyID;
        for index = 1, GetMerchantNumItems() do
            local itemLink = GetMerchantItemLink(index)
            if itemLink then
                local equipLoc, _, typeID, bindType
                local quality, level
                local r, g, b = 1, .82, 0
                local itemID = GetMerchantItemID(index)
                if itemID then
                    equipLoc, _, typeID = select(4, GetItemInfoInstant(itemID))
                    local _info = { GetItemInfo(itemLink) }
                    quality = _info[3]
                    level = _info[4]
                    bindType = _info[14]
                    r, g, b = GetItemQualityColor(quality)
                end
                local merchantButton = GetButtonByEquipLoc(equipLoc, itemLink, itemID, quality)
                if merchantButton then
                    local btName = merchantButton:GetName()
                    local itemButton = _G[btName .. "ItemButton"]
                    local merchantMoney = _G[btName .. "MoneyFrame"]
                    local merchantAltCurrency = _G[btName .. "AltCurrencyFrame"]
                    local nameText = _G[btName .. "Name"]
                    local btID = merchantButton.id

                    name, texture, price, stackCount, numAvailable,
                    isPurchasable, isUsable, extendedCost, currencyID = GetMerchantItemInfo(index);
                    if (currencyID) then
                        name, texture, numAvailable = CurrencyContainerUtil.GetCurrencyContainerInfo(currencyID, numAvailable, name, texture, nil);
                    end

                    local canAfford = CanAffordMerchantItem(index);
                    nameText:SetText(name);
                    nameText:SetTextColor(r, g, b);
                    SetItemButtonCount(itemButton, stackCount);
                    SetItemButtonStock(itemButton, numAvailable);
                    SetItemButtonTexture(itemButton, texture);

                    itemButton.name = name;
                    itemButton.link = GetMerchantItemLink(index);
                    itemButton.texture = texture;
                    itemButton.itemID = itemID
                    itemButton.typeID = typeID
                    itemButton.level = level
                    itemButton.quality = quality
                    itemButton.bindType = bindType
                    UpdateLevelText(merchantButton)
                    UpdateHaveTex(merchantButton)
                    UpdateClassTex(merchantButton)
                    UpdateBOEText(merchantButton)

                    if (extendedCost and (price <= 0)) then
                        itemButton.price = nil;
                        itemButton.extendedCost = true;

                        MerchantFrame_UpdateAltCurrency(index, btID, canAfford);
                        merchantAltCurrency:ClearAllPoints();
                        merchantAltCurrency:SetPoint("BOTTOMLEFT", _G[btName .. "NameFrame"], "BOTTOMLEFT", 2, 31);
                        merchantMoney:Hide();
                        merchantAltCurrency:Show();
                    elseif (extendedCost and (price > 0)) then
                        itemButton.price = price;
                        itemButton.extendedCost = true;
                        local altCurrencyWidth = MerchantFrame_UpdateAltCurrency(index, btID, canAfford);
                        MoneyFrame_SetMaxDisplayWidth(merchantMoney, MAX_MONEY_DISPLAY_WIDTH - altCurrencyWidth);
                        MoneyFrame_Update(merchantMoney:GetName(), price);
                        local color;
                        if (canAfford == false) then
                            color = "gray";
                        end
                        SetMoneyFrameColor(merchantMoney:GetName(), color);
                        merchantAltCurrency:ClearAllPoints();
                        merchantAltCurrency:SetPoint("LEFT", merchantMoney:GetName(), "RIGHT", -12, 0);
                        merchantAltCurrency:Show();
                        merchantMoney:Show();
                    else
                        itemButton.price = price;
                        itemButton.extendedCost = nil;
                        MoneyFrame_SetMaxDisplayWidth(merchantMoney, MAX_MONEY_DISPLAY_WIDTH);
                        MoneyFrame_Update(merchantMoney:GetName(), price);
                        local color;
                        if (canAfford == false) then
                            color = "gray";
                        end
                        SetMoneyFrameColor(merchantMoney:GetName(), color);
                        merchantAltCurrency:Hide();
                        merchantMoney:Show();
                    end

                    local merchantItemID = GetMerchantItemID(index);

                    local isHeirloom, isKnownHeirloom;
                    if (ClassicExpansionAtLeast(LE_EXPANSION_WRATH_OF_THE_LICH_KING)) then
                        isHeirloom = merchantItemID and C_Heirloom.IsItemHeirloom(merchantItemID);
                        isKnownHeirloom = isHeirloom and C_Heirloom.PlayerHasHeirloom(merchantItemID);
                    else
                        isHeirloom = false;
                        isKnownHeirloom = false;
                    end

                    itemButton.showNonrefundablePrompt = isHeirloom;

                    itemButton.hasItem = true;
                    itemButton:SetID(index);
                    itemButton:Show();

                    local tintRed = not isPurchasable or (not isUsable and not isHeirloom);

                    SetItemButtonDesaturated(itemButton, isKnownHeirloom);

                    if (numAvailable == 0 or isKnownHeirloom) then
                        -- If not available and not usable
                        if (tintRed) then
                            SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0, 0);
                            SetItemButtonSlotVertexColor(merchantButton, 0.5, 0, 0);
                            SetItemButtonTextureVertexColor(itemButton, 0.5, 0, 0);
                            SetItemButtonNormalTextureVertexColor(itemButton, 0.5, 0, 0);
                        else
                            SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5);
                            SetItemButtonSlotVertexColor(merchantButton, 0.5, 0.5, 0.5);
                            SetItemButtonTextureVertexColor(itemButton, 0.5, 0.5, 0.5);
                            SetItemButtonNormalTextureVertexColor(itemButton, 0.5, 0.5, 0.5);
                        end
                    elseif (tintRed) then
                        SetItemButtonNameFrameVertexColor(merchantButton, 1.0, 0, 0);
                        SetItemButtonSlotVertexColor(merchantButton, 1.0, 0, 0);
                        SetItemButtonTextureVertexColor(itemButton, 0.9, 0, 0);
                        SetItemButtonNormalTextureVertexColor(itemButton, 0.9, 0, 0);
                    else
                        SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5);
                        SetItemButtonSlotVertexColor(merchantButton, 1.0, 1.0, 1.0);
                        SetItemButtonTextureVertexColor(itemButton, 1.0, 1.0, 1.0);
                        SetItemButtonNormalTextureVertexColor(itemButton, 1.0, 1.0, 1.0);
                    end
                end
            else
            end
        end

        if mainFrame.equipLocCount < itemCountShow then return end
        mainFrame:Show()
        local showCount = 0
        for _, slotFrame in ipairs(mainFrame.slots) do
            if slotFrame:IsVisible() then
                slotFrame:ClearAllPoints()
                slotFrame:SetPoint("TOPLEFT", 5, -buttonHeight * showCount - 5)

                local t = mainFrame:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                t:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, -buttonHeight * showCount - 37 - filterHeight)
                t:SetTextColor(1, 1, 1)
                t:SetText(slotFrame.name)
                t:SetWidth(slotTextWidth)
                tinsert(mainFrame.slotTexts, t)
                showCount = showCount + 1
            end
        end

        mainFrame:SetHeight(45 + filterHeight + showCount * buttonHeight)
        if setValue then
            mainFrame.scroll.ScrollBar:SetValue(0)
        end
    end

    function BG.UpdateMerchantFrame(delay, setValue)
        ResetFrame()
        if delay then
            for index = 1, GetMerchantNumItems() do
                GetMerchantItemLink(index)
            end
            After(0, function()
                UpdateMerchantInfo(true)
            end)
        else
            UpdateMerchantInfo(setValue)
        end
    end

    BG.RegisterEvent("MERCHANT_SHOW", function()
        if BiaoGe.showShopping == 1 then
            BG.UpdateMerchantFrame(true)
        end
    end)

    local f = CreateFrame("Frame")
    f:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    f:RegisterEvent("PLAYER_MONEY")
    f:RegisterEvent("BAG_UPDATE_DELAYED")
    f:SetScript("OnEvent", function(self, event, ...)
        if mainFrame:IsVisible() then
            After(1, function()
                if mainFrame:IsVisible() then
                    UpdateAllHaveTex()
                end
            end)
        end
    end)

    hooksecurefunc("MerchantFrame_Update", function()
        if mainFrame:IsVisible() then
            mainFrame.t = 0
            mainFrame:SetScript("OnUpdate", function(self, t)
                mainFrame.t = mainFrame.t + t
                if mainFrame.t >= 0.1 then
                    BG.UpdateMerchantFrame()
                    self:SetScript("OnUpdate", nil)
                    return
                end
            end)
        end
    end)
end)
