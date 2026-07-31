local _, ns = ...

local L = ns.L
local RGB_16 = ns.RGB_16
local GetClassRGB = ns.GetClassRGB
local GetItemID = ns.GetItemID
local SendSystemMessage = BG.SendSystemMessage
local player = BG.playerName
local realmID = GetRealmID()

BG.Init(function()
    BiaoGe.bestPrice = BiaoGe.bestPrice or {}
    BiaoGe.bestPrice[realmID] = BiaoGe.bestPrice[realmID] or {}
    BiaoGe.bestPrice[realmID][player] = BiaoGe.bestPrice[realmID][player] or {}

    local mainFrame
    local rows = {}
    local entryButton
    local setPriceFrame
    local SetBestPrice
    local CreateSetPriceFrame
    local bestPriceDB = BiaoGe.bestPrice[realmID][player]
    bestPriceDB.money = bestPriceDB.money or ""

    local function BestPriceIsFull(itemID)
        local hasEmptyRow
        for ri = 1, 10 do
            local data = bestPriceDB[ri]
            local equipment = data and data.equipment or ""
            if itemID and GetItemID(equipment) == itemID then
                return false
            end
            if equipment == "" then
                hasEmptyRow = true
            end
        end
        return not hasEmptyRow
    end

    local function SaveBestPrice(link, money)
        money = tonumber(money) or 0
        if money <= 0 then return end
        local itemID = GetItemID(link)
        if BestPriceIsFull(itemID) then
            UIErrorsFrame:AddMessage(L["心理价格已满，请先删除一条心理价格。"], 1, 0, 0)
            return
        end
        SetBestPrice(link, money)
        SendSystemMessage(format(L["%s的心理价格已设为：%s"], link, BG.FormatNumber(money, 2)))
        return true
    end

    function BG.SetBestPrice(link, anchor)
        local itemID = GetItemID(link)
        local name, link, quality, level, _, itemType, itemSubType, _, itemEquipLoc, Texture,
        _, classID, subclassID, bindType = GetItemInfo(link)
        if not itemID or not link then return end
        if BestPriceIsFull(itemID) then
            UIErrorsFrame:AddMessage(L["心理价格已满，请先删除一条心理价格。"], 1, 0, 0)
            GameTooltip:Hide()
            return
        end
        local f = CreateSetPriceFrame()
        f.link = link
        f.iconFrame.link = link
        f.iconFrame.itemID = itemID
        local r, g, b = GetItemQualityColor(quality or 1)
        f.iconFrame:SetBackdropBorderColor(r, g, b, 1)
        f.iconFrame.tex:SetTexture(Texture)
        f.iconFrame.level:SetText(level or "")
        f.iconFrame.level:SetTextColor(r, g, b)
        f.iconFrame.bind:SetShown(bindType == 2)
        f.itemText:SetText((link or name or ""):gsub("%[", ""):gsub("%]", ""))
        local classText = BG.GetTooltipClassText(itemID) or ""
        if _G[itemEquipLoc] then
            if classID == 2 then
                f.itemTypeText:SetText((itemSubType or "") .. "  " .. classText)
            else
                f.itemTypeText:SetText(_G[itemEquipLoc] .. " " .. (itemSubType or "") .. "  " .. classText)
            end
        else
            f.itemTypeText:SetText(classText)
        end
        f:ClearAllPoints()
        if anchor then
            f:SetPoint("BOTTOM", anchor, "TOP", 0, 0)
        elseif entryButton then
            f:SetPoint("BOTTOM", entryButton, "TOP", 0, 0)
        else
            f:SetPoint("CENTER", UIParent, "CENTER")
        end
        f:Show()
        f.edit:SetText(bestPriceDB.money or '')
        f.edit:SetFocus()
        f.edit:SetCursorPosition(#f.edit:GetText())
        GameTooltip:Hide()
    end

    local function NormalizeRow(ri)
        bestPriceDB[ri] = bestPriceDB[ri] or {}
        local data = bestPriceDB[ri]
        data.enabled = data.enabled ~= false
        data.equipment = data.equipment or ""
        data.price = tonumber(data.price) or 0
        return data
    end

    local function RefreshRow(row, data)
        row.cb:SetChecked(data.enabled)
        row.editEquip:SetText(data.equipment or "")
        row.editPrice:SetText(data.price ~= 0 and data.price or "")
        row.UpdateEquipInfo()
        row.UpdateRowAlpha()
    end

    local function GetBestPriceCount()
        local count = 0
        for ri = 1, 10 do
            local data = NormalizeRow(ri)
            if data.enabled and data.price > 0 and GetItemID(data.equipment) then
                count = count + 1
            end
        end
        return count
    end

    local function UpdateEntryButtonText()
        if entryButton then
            local count = GetBestPriceCount()
            local r, g, b = 0.5, 0.5, 0.5
            if count == 10 then
                r, g, b = 1, 0, 0
            elseif count > 0 then
                r, g, b = 0, 1, 0
            end
            entryButton:SetText(L["心理价格"] .. "(" .. RGB_16(count, r, g, b) .. ")")
        end
    end

    SetBestPrice = function(link, price)
        local itemID = GetItemID(link)
        local rowIndex

        for ri = 1, 10 do
            local data = NormalizeRow(ri)
            if itemID and GetItemID(data.equipment) == itemID then
                rowIndex = ri
                break
            end
            if not rowIndex and data.equipment == "" then
                rowIndex = ri
            end
        end

        rowIndex = rowIndex or 10

        local data = NormalizeRow(rowIndex)
        data.enabled = true
        data.equipment = link or ""
        data.price = tonumber(price) or 0

        if rows[rowIndex] then
            RefreshRow(rows[rowIndex], data)
        end
        UpdateEntryButtonText()
    end

    function BG.GetBestPrice(itemID)
        itemID = tonumber(itemID)
        if itemID then
            for ri = 1, 10 do
                local data = NormalizeRow(ri)
                if data.enabled and data.price > 0 and GetItemID(data.equipment) == itemID then
                    return data.price
                end
            end
        end
        return nil
    end

    function BG.DisableBestPrice(itemID)
        itemID = tonumber(itemID)
        if not itemID then return end

        for ri = 1, 10 do
            local data = NormalizeRow(ri)
            if GetItemID(data.equipment) == itemID then
                data.enabled = false
                if rows[ri] then
                    RefreshRow(rows[ri], data)
                end
                UpdateEntryButtonText()
                return true
            end
        end
    end

    local function RefreshAllRows()
        for ri = 1, 10 do
            if rows[ri] then
                RefreshRow(rows[ri], NormalizeRow(ri))
            end
        end
        UpdateEntryButtonText()
    end

    local function SetAllRowsEnabled(enabled)
        for ri = 1, 10 do
            NormalizeRow(ri).enabled = enabled and true or false
        end
        RefreshAllRows()
    end

    local function ClearAllRows()
        for ri = 1, 10 do
            local data = NormalizeRow(ri)
            data.enabled = true
            data.equipment = ""
            data.price = 0
        end
        RefreshAllRows()
    end

    -- UI
    CreateSetPriceFrame = function()
        if BG.StartAucitonFrame then BG.StartAucitonFrame:Hide() end
        if setPriceFrame then return setPriceFrame end

        -- 基础窗口
        local f = CreateFrame("Frame", nil, BG.MainFrame, "BackdropTemplate")
        do
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 2,
            })
            f:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
            f:SetBackdropBorderColor(0, 0, 0, 1)
            f:SetFrameLevel(210)
            f:EnableMouse(true)
            f:SetMovable(true)
            f:SetClampedToScreen(true)
            f:SetSize(250, 120)
            f:SetScript("OnMouseDown", function(self)
                self:StartMoving()
                if self.edit then
                    self.edit:ClearFocus()
                end
            end)
            f:SetScript("OnMouseUp", function(self)
                self:StopMovingOrSizing()
            end)
            f:Hide()

            BG.CreateCloseButton(f, 0, 0)
            f.CloseButton:SetSize(35, 35)
            f.CloseButton:SetFrameLevel(f.CloseButton:GetParent():GetFrameLevel() + 50)
        end

        -- 装备展示区域
        do
            f.itemFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
            f.itemFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
            f.itemFrame:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -2, -35)
            f.itemFrame:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
            })
            f.itemFrame:SetBackdropColor(0, 0, 0, 0.8)
            f.itemFrame:EnableMouse(true)
            f.itemFrame:SetScript("OnMouseDown", function(self)
                self:GetParent():GetScript("OnMouseDown")(self:GetParent())
            end)
            f.itemFrame:SetScript("OnMouseUp", function(self)
                self:GetParent():GetScript("OnMouseUp")(self:GetParent())
            end)
        end

        -- 装备图标和鼠标提示
        do
            f.iconFrame = CreateFrame("Frame", nil, f.itemFrame, "BackdropTemplate")
            f.iconFrame:SetBackdrop({
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1.5,
            })
            f.iconFrame:SetPoint("TOPLEFT", 0, 0)
            f.iconFrame:SetSize(31, 31)
            f.iconFrame:EnableMouse(true)
            f.iconFrame:SetScript("OnEnter", function(self)
                if self.link then
                    if BG.ButtonIsInRight(self) then
                        GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
                    else
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                    end
                    GameTooltip:ClearLines()
                    GameTooltip:SetHyperlink(BG.SetSpecIDToLink(self.link))
                end
            end)
            f.iconFrame:SetScript("OnLeave", GameTooltip_Hide)
            f.iconFrame:SetScript("OnMouseDown", function(self)
                self:GetParent():GetScript("OnMouseDown")(self:GetParent())
            end)
            f.iconFrame:SetScript("OnMouseUp", function(self)
                self:GetParent():GetScript("OnMouseUp")(self:GetParent())
            end)
            f.iconFrame.tex = f.iconFrame:CreateTexture(nil, "BACKGROUND")
            f.iconFrame.tex:SetAllPoints()
            f.iconFrame.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)

            f.iconFrame.level = f.iconFrame:CreateFontString()
            f.iconFrame.level:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
            f.iconFrame.level:SetPoint("BOTTOM", f.iconFrame, "BOTTOM", 0, 1)

            f.iconFrame.bind = f.iconFrame:CreateFontString()
            f.iconFrame.bind:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
            f.iconFrame.bind:SetPoint("TOP", f.iconFrame, 0, -2)
            f.iconFrame.bind:SetText(L["装绑"])
            f.iconFrame.bind:SetTextColor(0, 1, 0)
        end

        -- 装备名称和类型文字
        do
            f.itemText = f.itemFrame:CreateFontString()
            f.itemText:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            f.itemText:SetPoint("TOPLEFT", f.iconFrame, "TOPRIGHT", 2, -2)
            f.itemText:SetPoint("RIGHT", f.itemFrame, "RIGHT", -22, 0)
            f.itemText:SetJustifyH("LEFT")
            f.itemText:SetWordWrap(false)

            f.itemTypeText = f.itemFrame:CreateFontString()
            f.itemTypeText:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
            f.itemTypeText:SetPoint("BOTTOMLEFT", f.iconFrame, "BOTTOMRIGHT", 2, 1)
            f.itemTypeText:SetPoint("RIGHT", f.itemText, "RIGHT", 0, 0)
            f.itemTypeText:SetHeight(12)
            f.itemTypeText:SetJustifyH("LEFT")
            f.itemTypeText:SetWordWrap(false)
        end

        -- 心理价格输入框
        do
            local label = f:CreateFontString()
            label:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            label:SetPoint("TOPLEFT", f.itemFrame, "BOTTOMLEFT", 5, -10)
            label:SetSize(110, 20)
            label:SetTextColor(1, 0.82, 0)
            label:SetJustifyH("RIGHT")
            label:SetText(L["心理价格："])

            f.edit = CreateFrame("EditBox", nil, f, BG.editTemplate)
            f.edit:SetSize(90, 20)
            f.edit:SetPoint("LEFT", label, "RIGHT", 5, 0)
            f.edit:SetAutoFocus(false)
            f.edit:SetNumeric(true)
            f.edit:SetMaxLetters(8)
            f.edit:SetScript("OnEscapePressed", function(self)
                self:GetParent():Hide()
            end)
            f.edit:SetScript("OnEnterPressed", function(self)
                self:GetParent().ok:Click()
            end)
            f.edit:SetScript("OnTextChanged", function(self)
                BG.UpdateTwo0(self)
                bestPriceDB.money = self:GetText()
            end)
        end

        -- 确定和取消按钮
        do
            f.ok = BG.CreateButton(f)
            f.ok:SetSize(100, 25)
            f.ok:SetPoint("BOTTOM", -55, 12)
            f.ok:SetText(OKAY)
            f.ok:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                local parent = self:GetParent()
                if SaveBestPrice(parent.link, parent.edit:GetText()) then
                    parent:Hide()
                end
            end)

            f.cancel = BG.CreateButton(f)
            f.cancel:SetSize(100, 25)
            f.cancel:SetPoint("BOTTOM", 55, 12)
            f.cancel:SetText(CANCEL)
            f.cancel:SetScript("OnClick", function(self)
                self:GetParent():Hide()
            end)
        end

        setPriceFrame = f
        return f
    end

    -- 行类：创建单行 UI 部件
    local headerW = { 40, 190, 100, 40 }
    local function CreateRow(parent, ri, y)
        local data = NormalizeRow(ri)
        local x = 20

        -- 行内所有子部件的透明度控制
        local widgets = {}
        local editEquip
        local function UpdateRowAlpha()
            local a = data.enabled and 1 or 0.5
            for _, w in ipairs(widgets) do
                w:SetAlpha(a)
            end
        end

        local function ClearEquipInfo()
            if editEquip.icon then
                editEquip.icon:SetTexture(nil)
            end
            if BG.BindOnEquip then
                BG.BindOnEquip(editEquip)
            end
            if BG.LevelText then
                BG.LevelText(editEquip)
            end
        end

        local function UpdateEquipInfo()
            local itemText = editEquip:GetText()
            local itemID = GetItemID(itemText)
            if not itemID then
                ClearEquipInfo()
                return
            end

            local function SetInfo()
                if editEquip:GetText() ~= itemText then return end
                local name, link, quality, level, _, _, _, _, _, Texture,
                _, typeID, _, bindType = GetItemInfo(itemText)
                editEquip.icon:SetTexture(Texture)
                if BG.BindOnEquip then
                    BG.BindOnEquip(editEquip, bindType)
                end
                if BG.LevelText then
                    BG.LevelText(editEquip, level, typeID)
                end
            end

            if BG.OnItemLoad then
                BG.OnItemLoad(itemText):ContinueOnItemLoad(SetInfo)
            else
                SetInfo()
            end
        end

        -- 第1列：启用的复选框
        local cb = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", x + 5, y)
        cb:SetChecked(data.enabled)
        cb:SetHitRectInsets(0, 0, 0, 0)
        cb:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            data.enabled = self:GetChecked() and true or false
            UpdateRowAlpha()
            UpdateEntryButtonText()
        end)
        tinsert(widgets, cb)

        x = x + headerW[1] + 5

        -- 第2列：装备输入框
        editEquip = CreateFrame("EditBox", nil, parent, BG.editTemplate)
        editEquip:SetSize(headerW[2], 20)
        editEquip:SetPoint("TOPLEFT", x, y)
        editEquip:SetTextInsets(18, 28, 0, 0)
        editEquip.icon = editEquip:CreateTexture(nil, "ARTWORK")
        editEquip.icon:SetPoint("LEFT", 0, 0)
        editEquip.icon:SetSize(16, 16)
        editEquip.icon:SetTexCoord(unpack(BG.iconTexCoord or { 0.08, 0.92, 0.08, 0.92 }))
        editEquip:SetText(data.equipment or "")
        editEquip:SetAutoFocus(false)
        editEquip:SetScript("OnTextChanged", function(self)
            data.equipment = self:GetText()
            UpdateEquipInfo()
            UpdateEntryButtonText()
        end)
        BG.SetEditBaseClass(editEquip)
        BG.OnEnterDelay(editEquip, function(self)
            local link = self:GetText()
            BG.Show_AllHighlight(link)
            local itemID = GetItemID(link)
            if itemID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:SetHyperlink(BG.SetSpecIDToLink(link))
                GameTooltip:Show()
            end
        end, BG.itemOnEnterDelay)
        BG.OnLeaveDelay(editEquip, function(self)
            self.isEnter = false
            GameTooltip:Hide()
            BG.Hide_AllHighlight()
        end)
        tinsert(widgets, editEquip)

        x = x + headerW[2] + 5

        -- 第3列：心理价格输入框
        local editPrice = CreateFrame("EditBox", nil, parent, BG.editTemplate)
        editPrice:SetSize(headerW[3], 20)
        editPrice:SetPoint("TOPLEFT", x, y)
        editPrice:SetText(data.price ~= 0 and data.price or "")
        editPrice:SetAutoFocus(false)
        editPrice:SetNumeric(true)
        editPrice:SetScript("OnTextChanged", function(self)
            local num = tonumber(self:GetText())
            data.price = num or 0
            UpdateEntryButtonText()
        end)
        BG.SetEditBaseClass(editPrice)
        tinsert(widgets, editPrice)

        x = x + headerW[3] + 5

        -- 第4列：红色X清空按钮
        local clearBt = CreateFrame("Button", nil, parent)
        clearBt:SetSize(16, 16)
        clearBt:SetPoint("TOPLEFT", x + 0, y - 2)
        clearBt:SetNormalTexture("interface/raidframe/readycheck-notready")
        clearBt:SetHighlightTexture("interface/raidframe/readycheck-notready")
        clearBt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            editEquip:SetText("")
            editPrice:SetText("")
            cb:SetChecked(true)
            data.enabled = true
            data.equipment = ""
            data.price = 0
            UpdateRowAlpha()
            UpdateEquipInfo()
            UpdateEntryButtonText()
        end)
        tinsert(widgets, clearBt)

        UpdateEquipInfo()
        UpdateRowAlpha()

        return { cb = cb, editEquip = editEquip, editPrice = editPrice, clearBt = clearBt, UpdateRowAlpha = UpdateRowAlpha, UpdateEquipInfo = UpdateEquipInfo }
    end

    local function UpdateTip(tip)
        tip:SetTextColor(0.8, 0.8, 0.8)
        if BG.IsML then
            tip:SetText(L["提示：CTRL+ALT+点击表格装备，可预设心理价格。"])
        else
            tip:SetText(L["提示：ALT+右键点击表格装备，可添加心理价格。"])
        end
    end

    -- 实体：创建整个心理价格界面
    local function CreateXinLiJiaGeFrame(parent)
        if mainFrame then
            mainFrame:SetShown(not mainFrame:IsShown())
            mainFrame:ClearAllPoints()
            if parent then
                mainFrame:SetPoint("BOTTOM", parent, "TOP")
            else
                mainFrame:SetPoint("CENTER", BG.MainFrame, "CENTER")
            end
            UpdateTip(mainFrame.tip)
            return
        end

        local f = CreateFrame("Frame", nil, parent or BG.MainFrame, "BackdropTemplate")
        do
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 16,
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            f:SetBackdropColor(0, 0, 0, 0.9)
            f:SetBackdropBorderColor(GetClassRGB(nil, "player"))
            f:SetFrameLevel(205)
            f:EnableMouse(true)
            f:SetMovable(true)
            f:SetToplevel(true)
            f:SetSize(410, 338)
            if parent then
                f:SetPoint("BOTTOM", parent, "TOP")
            else
                f:SetPoint("CENTER", BG.MainFrame, "CENTER")
            end
            f:SetClampedToScreen(true)
            f:SetScript("OnMouseDown", function(self)
                BG.ClearFocus()
                self:StartMoving()
            end)
            f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

            f.CloseButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
            f.CloseButton:SetPoint("TOPRIGHT", 2, 2)

            local title = f:CreateFontString()
            title:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            title:SetPoint("TOP", 0, -7)
            title:SetText(L["预设心理价格"])
        end

        -- 表头
        local headerX = 20
        local headerY = -30
        local headers = { L["启用"], L["装备"], L["心理价格"], "" }
        for i = 1, 4 do
            local ht = f:CreateFontString()
            ht:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            ht:SetPoint("TOPLEFT", headerX, headerY)
            ht:SetText(headers[i])
            ht:SetTextColor(1, 0.82, 0)
            ht:SetWidth(headerW[i])
            ht:SetJustifyH(i == 4 and "CENTER" or "LEFT")
            headerX = headerX + headerW[i] + 5
        end

        -- 实例化 10 行
        local rowStartY = headerY - 18
        local rowHeight = 22
        for ri = 1, 10 do
            rows[ri] = CreateRow(f, ri, rowStartY - (ri - 1) * rowHeight)
        end

        local tip = f:CreateFontString()
        tip:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
        tip:SetPoint("BOTTOM", f, "BOTTOM", 0, 48)
        f.tip = tip
        UpdateTip(tip)

        local buttonInfo = {
            { text = L["全部启用"], onClick = function() SetAllRowsEnabled(true) end },
            { text = L["全部禁用"], onClick = function() SetAllRowsEnabled(false) end },
            { text = L["全部清空"], onClick = ClearAllRows },
            { text = L["关闭"], onClick = function() f:Hide() end },
        }
        local buttonW = 88
        local buttonGap = 8
        local totalW = #buttonInfo * buttonW + (#buttonInfo - 1) * buttonGap
        local startX = -totalW / 2 + buttonW / 2
        for i, info in ipairs(buttonInfo) do
            local bt = BG.CreateButton(f)
            bt:SetSize(buttonW, 25)
            bt:SetPoint("BOTTOM", f, "BOTTOM", startX + (i - 1) * (buttonW + buttonGap), 14)
            bt:SetText(info.text)
            bt:SetScript("OnClick", function(self)
                if i ~= #buttonInfo then
                    BG.PlaySound(1)
                end
                info.onClick()
            end)
        end

        mainFrame = f
    end

    local bt = BG.CreateButton(BG.FilterClassItemMainFrame.Buttons2)
    bt:SetSize(130, 25)
    bt:SetPoint("LEFT", BG.FilterClassItemMainFrame.Buttons2, "RIGHT", BG.onlyOneHard and 100 or 70, 0)
    entryButton = bt
    UpdateEntryButtonText()
    bt:SetScript("OnClick", function(self)
        BG.PlaySound(1)
        CreateXinLiJiaGeFrame(self)
    end)
end)
