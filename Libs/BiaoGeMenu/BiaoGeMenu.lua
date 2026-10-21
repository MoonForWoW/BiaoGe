-- Original BiaoGeMenu implementation.
-- Copyright (c) 2026 苍穹之霜. See the project License.txt.
-- Independent implementation; includes adapters for BiaoGeX's existing calls.
local AddonName, ns = ...
local Menu = {}
ns.Menu = Menu

local panels = {}
local owner, closeDelay, elapsedOutside
local ROW_HEIGHT, MAX_ROWS = 20, 40
local SCROLLBAR_SPACE = 18
local MIN_MENU_WIDTH = 100 -- 弹出菜单的最小宽度
local STATE_UPDATE_INTERVAL = .1 -- 动态选项状态刷新间隔（秒）
local stateUpdateElapsed = 0
local tooltip
local rowInitializers = {}
local collection
local openOptions
local countingPaused = false

local function PlayMenuSound(sound)
    PlaySound(sound)
end

local function ClassColor()
    local _, class = UnitClass("player")
    local color = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class])
        or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
    if color then return color.r, color.g, color.b end
    return 1, 1, 1
end

local function Font(parent, size, fontObject)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(fontObject or GameFontHighlightSmallLeft)
    if size then
        local font, _, flags = text:GetFont()
        text:SetFont(font, size, flags)
    end
    return text
end

local function HideTip()
    if tooltip then tooltip:Hide() end
end

local function ShowTip(frame, title, text)
    if not title and not text then return end
    if not tooltip then
        tooltip = CreateFrame("GameTooltip", "BiaoGeMenuTooltip", UIParent, "GameTooltipTemplate")
    end
    tooltip:SetOwner(frame, "ANCHOR_RIGHT")
    tooltip:ClearLines()
    if title then tooltip:AddLine(title, 1, .82, 0, true) end
    if text then tooltip:AddLine(text, 1, 1, 1, true) end
    tooltip:Show()
end

local function HideAfter(level)
    for i = #panels, level + 1, -1 do panels[i]:Hide() end
end

function Menu:Close()
    HideAfter(0)
    HideTip()
    owner, closeDelay, elapsedOutside = nil, nil, 0
    countingPaused = false
end

function Menu:IsOpen(control)
    return panels[1] and panels[1]:IsShown() and (not control or owner == control)
end

local function Value(value)
    if type(value) == "function" then return value() end
    return value
end

-- disabledFuc(item) is evaluated on opening, while visible, and on clicking.
-- Returning true disables the option. Without a predicate, use disabled as before.
local function IsItemDisabled(item)
    if item.disabledFuc then return not not item.disabledFuc(item) end
    return not not Value(item.disabled)
end

local function ItemButtonSize(action)
    return math.max(8, math.min(action.size or 20, ROW_HEIGHT))
end

local function TextPadding(item)
    local left = (item.notCheckable or item.isTitle or item.separator) and 8 or 26
    local right = item.action and (ItemButtonSize(item.action) + 18) or 34
    return left, right
end

local function UpdateCheck(row)
    local item = row.item
    local checkable = not item.separator and not item.isTitle and not item.notCheckable
    local selected = not not Value(item.checked)
    -- Native menu texture: square marks on the upper half, radio marks below.
    local top = item.isNotRadio and 0 or .5
    row.check:SetTexCoord(0, .5, top, top + .5)
    row.checkBackground:SetTexCoord(.5, 1, top, top + .5)
    row.checkBackground:SetShown(checkable and not selected)
    row.check:SetShown(checkable and selected)
end

local Build
local function UpdateHighlight(row)
    local item = row.item
    local hovered = row.menuHovered or (row.action and row.action.menuHovered)
    if item ~= nil and row:IsEnabled() and hovered
        and not IsItemDisabled(item) and not item.isTitle and not item.separator then
        row:LockHighlight()
        row.Highlight:Show()
    else
        row:UnlockHighlight()
        row.Highlight:Hide()
    end
end

local function UpdateItemButton(row)
    local item = row.item
    local action = item and item.action
    row.action:SetShown(action ~= nil and not IsItemDisabled(item) and not item.isTitle and not item.separator
        and (not action.hoverOnly or row.menuHovered or row.action.menuHovered))
end

local function DeferItemButtonHide(row)
    local item = row.item
    -- Give OnEnter on the child button (or its parent row) time to run first.
    C_Timer.After(0, function()
        if row.item ~= item then return end
        if not row:IsVisible() then
            row.action:Hide(); return
        end
        UpdateItemButton(row)
    end)
end

local function SetItemButtonIconColor(row, hovered)
    local action = row.item and row.item.action
    if not action then return end
    local color = (hovered and action.hoverIconColor) or action.iconColor
    if color then
        row.action.icon:SetVertexColor(unpack(color))
    else
        row.action.icon:SetVertexColor(1, 1, 1)
    end
end

local function UpdateRowState(row)
    local item = row.item
    local disabled = IsItemDisabled(item)
    local action = item.action
    local actionDisabled = action and not not Value(action.disabled) or false
    row.disabledState, row.actionDisabledState = disabled, actionDisabled
    row.Highlight:SetAlpha((disabled or item.isTitle or item.separator) and 0 or .25)
    if item.isTitle then row.text:SetTextColor(1, .82, 0)
    elseif disabled then row.text:SetTextColor(.45, .45, .45)
    else row.text:SetTextColor(.92, .95, 1) end
    row.checkBackground:SetAlpha(disabled and .45 or 1)
    row.check:SetAlpha(disabled and .45 or 1)
    if action then
        row.action:SetEnabled(not actionDisabled)
        row.action:SetAlpha(actionDisabled and .45 or 1)
    end
    -- Keep disabled rows mouse-enabled so their explanatory tooltips still work.
    -- Click handlers recheck the predicate before executing any operation.
    UpdateHighlight(row)
    UpdateItemButton(row)
end

local function NewRow(panel)
    local r, g, b = ClassColor()
    local row = CreateFrame("Button", nil, panel.content)
    row:SetHeight(ROW_HEIGHT)
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function(_, delta)
        panel:GetScript("OnMouseWheel")(panel, delta)
    end)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetHighlightTexture("Interface/Buttons/WHITE8X8")
    row:GetHighlightTexture():SetVertexColor(r, g, b, .25)
    row.Highlight = row:GetHighlightTexture()
    row.Highlight:Hide()
    row:SetScript("OnDisable", function(self)
        self:UnlockHighlight()
        self.Highlight:Hide()
    end)
    row:SetScript("OnEnable", UpdateHighlight)
    row:SetScript("OnHide", function(self)
        self.menuHovered = false
        self:UnlockHighlight()
        self.Highlight:Hide()
    end)
    row.text = Font(row)
    row.text:SetPoint("LEFT", 26, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row.checkBackground = row:CreateTexture(nil, "ARTWORK")
    row.checkBackground:SetSize(18, 18)
    row.checkBackground:SetPoint("LEFT", 8, 0)
    row.checkBackground:SetTexture("Interface/Common/UI-DropDownRadioChecks")
    row.check = row:CreateTexture(nil, "OVERLAY")
    row.check:SetSize(18, 18)
    row.check:SetPoint("LEFT", 8, 0)
    row.check:SetTexture("Interface/Common/UI-DropDownRadioChecks")
    row.arrow = Font(row, 16)
    row.arrow:SetPoint("RIGHT", -9, 0)
    row.arrow:SetText(">")
    row.arrow:SetTextColor(1, 1, 1)
    row.line = row:CreateTexture(nil, "ARTWORK")
    row.line:SetColorTexture(.5, .5, .5, .7)
    row.line:SetHeight(1)
    row.line:SetPoint("LEFT", 8, 0)
    row.line:SetPoint("RIGHT", -8, 0)
    row.action = CreateFrame("Button", nil, row)
    row.action:SetSize(20, 20)
    row.action:SetPoint("RIGHT", -6, 0)
    row.action:RegisterForClicks("AnyUp")
    row.action.icon = row.action:CreateTexture(nil, "ARTWORK")
    row.action.icon:SetAllPoints()
    row.action.text = Font(row.action)
    row.action.text:SetPoint("CENTER")
    row.action.text:SetTextColor(r, g, b)
    row.action:SetHighlightTexture("Interface/Buttons/WHITE8X8")
    row.action:GetHighlightTexture():SetVertexColor(r, g, b, .25)
    row.action:SetScript("OnEnter", function(self)
        local action = row.item and row.item.action
        if not action then return end
        HideTip()
        elapsedOutside = 0
        countingPaused = true
        self.menuHovered = true
        UpdateItemButton(row)
        UpdateHighlight(row)
        SetItemButtonIconColor(row, true)
        ShowTip(self, action.tooltipTitle or action.tooltip, action.tooltipText)
        if action.onEnter then action.onEnter(self, row.item, row) end
    end)
    row.action:SetScript("OnLeave", function(self)
        self.menuHovered = false
        countingPaused, elapsedOutside = false, 0
        UpdateHighlight(row)
        HideTip()
        local action = row.item and row.item.action
        SetItemButtonIconColor(row, false)
        if action and action.onLeave then action.onLeave(self, row.item, row) end
        DeferItemButtonHide(row)
    end)
    row.action:SetScript("OnHide", function(self)
        if self.menuHovered then
            self.menuHovered = false
            countingPaused, elapsedOutside = false, 0
            HideTip()
        end
    end)
    row.action:SetScript("OnClick", function(self, mouseButton)
        local item = row.item
        local currentOwner = owner
        local action = item.action
        if not self:IsEnabled() or IsItemDisabled(item) or not action or Value(action.disabled) then return end
        local refresh, clickSound = action.refresh, not action.noClickSound
        if action.func then
            action.func(currentOwner, item, self, row, mouseButton)
            if clickSound then PlayMenuSound(SOUNDKIT.U_CHAT_SCROLL_BUTTON) end
        end
        -- Refresh only this menu; a callback may have closed it or opened another.
        if refresh and Menu:IsOpen(currentOwner) then Menu:Refresh(currentOwner) end
    end)
    row:SetScript("OnEnter", function(self)
        self.menuHovered = true
        UpdateItemButton(self)
        UpdateHighlight(self)
        HideTip()
        elapsedOutside = 0
        HideAfter(panel.level)
        local item = self.item
        if item.menuList and not IsItemDisabled(item) then
            Build(panel.level + 1, Value(item.menuList), self)
        end
        ShowTip(self, item.tooltipTitle, item.tooltipText)
        if item.onEnter then item.onEnter(self, item) end
    end)
    row:SetScript("OnLeave", function(self)
        self.menuHovered = false
        UpdateHighlight(self)
        if not self.action.menuHovered then HideTip() end
        if self.item.onLeave then self.item.onLeave(self, self.item) end
        DeferItemButtonHide(self)
    end)
    row:SetScript("OnClick", function(self, mouseButton)
        local item = self.item
        if not self:IsEnabled() or IsItemDisabled(item) or item.isTitle or item.separator or item.menuList then return end
        local currentOwner = owner
        local clickSound = item.func and not item.noClickSound
        -- Close before the callback so a callback can safely open another menu.
        if not item.keepShownOnClick then Menu:Close() end
        if item.func then item.func(self, item.arg1, item.arg2, mouseButton) end
        if item.keepShownOnClick and Menu:IsOpen(currentOwner) then
            UpdateCheck(self)
        end
        if clickSound then PlayMenuSound(SOUNDKIT.U_CHAT_SCROLL_BUTTON) end
    end)
    return row
end

local BOARDCOLOR = .1
local function GetPanel(level)
    if panels[level] then return panels[level] end
    local panel = CreateFrame("Frame", "BiaoGeMenuList" .. level, UIParent, "BackdropTemplate")
    panel:Hide()
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetFrameLevel(100 + level * 10)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel.level, panel.rows, panel.numButtons = level, {}, 0
    panel:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8X8",
        edgeFile = "Interface/Buttons/WHITE8X8",
        edgeSize = 1
    })
    panel:SetBackdropColor(0, 0, 0, .8)
    panel:SetBackdropBorderColor(BOARDCOLOR, BOARDCOLOR, BOARDCOLOR, 1)
    panel.scroll = CreateFrame("ScrollFrame", nil, panel, BG.scrollTemplate)
    panel.scroll:SetPoint("TOPLEFT", 4, -5)
    panel.scroll:SetPoint("BOTTOMRIGHT", -4, 5)
    panel.content = CreateFrame("Frame", nil, panel.scroll)
    panel.scroll:SetScrollChild(panel.content)
    panel.ScrollBar = panel.scroll.ScrollBar
    panel.ScrollBar:ClearAllPoints()
    panel.ScrollBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -5)
    panel.ScrollBar:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 5)
    panel.ScrollBar.scrollStep = ROW_HEIGHT * 3
    panel.scroll:HookScript("OnVerticalScroll", function()
        HideTip()
        HideAfter(level)
        elapsedOutside = 0
    end)
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(self, delta)
        HideTip()
        HideAfter(level)
        local low, high = self.ScrollBar:GetMinMaxValues()
        self.ScrollBar:SetValue(math.max(low, math.min(high,
            self.ScrollBar:GetValue() - delta * ROW_HEIGHT * 3)))
    end)
    panel.scroll:EnableMouseWheel(true)
    panel.scroll:SetScript("OnMouseWheel", function(_, delta)
        panel:GetScript("OnMouseWheel")(panel, delta)
    end)
    panel:SetScript("OnHide", function()
        local thumb = panel.ScrollBar.ThumbButton
        if thumb then
            thumb.modernDragging = nil
            thumb:SetScript("OnUpdate", nil)
        end
        HideAfter(level)
        HideTip()
        if level == 1 then owner = nil end
    end)
    panels[level] = panel
    -- Let the game handle Escape without intercepting movement keys.
    UISpecialFrames[#UISpecialFrames + 1] = panel:GetName()
    return panel
end

Build = function(level, items, anchor, cursor)
    local panel = GetPanel(level)
    HideAfter(level)
    local width = MIN_MENU_WIDTH
    for _, item in ipairs(items) do
        panel.measure = panel.measure or Font(panel)
        panel.measure:SetText(tostring(item.text or ""))
        local left, right = TextPadding(item)
        width = math.max(width, panel.measure:GetStringWidth() + left + right + 5)
        panel.measure:Hide()
    end
    local visibleRows = math.min(MAX_ROWS, math.max(1, math.floor((UIParent:GetHeight() - 30) / ROW_HEIGHT)))
    panel.scrollbarSpace = #items > visibleRows and SCROLLBAR_SPACE or 0
    width = math.min(width + panel.scrollbarSpace, math.max(MIN_MENU_WIDTH, UIParent:GetWidth() - 30))
    local visibleHeight = math.min(math.max(1, #items), visibleRows) * ROW_HEIGHT
    local contentHeight = math.max(1, #items) * ROW_HEIGHT
    local contentWidth = width - 8 - panel.scrollbarSpace
    panel:SetSize(width, visibleHeight + 10)
    panel.scroll:SetPoint("BOTTOMRIGHT", -4 - panel.scrollbarSpace, 5)
    panel.content:SetSize(contentWidth, contentHeight)
    panel.ScrollBar:SetMinMaxValues(0, math.max(0, contentHeight - visibleHeight))
    panel.ScrollBar:SetValue(0)
    panel.scroll:SetVerticalScroll(0)
    panel.ScrollBar:SetShown(panel.scrollbarSpace > 0)
    panel:ClearAllPoints()
    if level > 1 then
        local gap = (panels[level - 1].scrollbarSpace or 0) + 6
        if anchor:GetRight() and anchor:GetRight() + gap + width > UIParent:GetWidth() then
            panel:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -2, 0)
        else
            panel:SetPoint("TOPLEFT", anchor, "TOPRIGHT", gap, 0)
        end
    elseif cursor then
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + (openOptions.x or 4), y / scale + (openOptions.y or -4))
    elseif openOptions and openOptions.anchor then
        local point = openOptions.anchor
        panel:SetPoint(point.point, point.relativeTo or anchor, point.relativePoint, point.x, point.y)
    else
        panel:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", (openOptions and openOptions.x) or 0, (openOptions and openOptions.y) or -4)
    end
    panel.dropdown, panel.numButtons = owner, #items
    panel.dynamicRows = {}
    for i, item in ipairs(items) do
        local row = panel.rows[i]
        if not row then
            row = NewRow(panel); panel.rows[i] = row
            if level == 1 then
                for _, initialize in ipairs(rowInitializers) do initialize(row, i) end
            end
        end
        row.item = item
        -- Rows are pooled across menus; reset children before configuring this item.
        for _, child in ipairs({ row:GetChildren() }) do child:Hide() end
        row.arg1, row.arg2, row.value = item.arg1, item.arg2, item.value or item.text
        row.isOnEnter = false
        row.menuHovered = false
        row:Enable()
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:SetWidth(contentWidth)
        row.text:SetText(tostring(item.text or ""))
        local textLeft, textRight = TextPadding(item)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", textLeft, 0)
        row.text:SetWidth(math.max(1, contentWidth - textLeft - textRight + 8))
        row:UnlockHighlight()
        row.Highlight:Hide()
        UpdateCheck(row)
        row.arrow:SetShown(item.menuList ~= nil)
        row.line:SetShown(not not item.separator)
        row.text:SetShown(not item.separator)
        local action = item.action
        if action then
            local size = ItemButtonSize(action)
            row.action:SetSize(size, size)
            local hasIcon = action.icon ~= nil or action.atlas ~= nil
            row.action.icon:SetShown(hasIcon)
            row.action.text:SetShown(not hasIcon)
            if action.atlas then
                row.action.icon:SetAtlas(action.atlas)
            else
                row.action.icon:SetTexture(action.icon)
            end
            SetItemButtonIconColor(row, false)
            row.action.text:SetText(action.text or "×")
        end
        UpdateRowState(row)
        if item.disabledFuc or type(item.disabled) == "function" or (action and type(action.disabled) == "function") then
            panel.dynamicRows[#panel.dynamicRows + 1] = row
        end
        -- Disabled rows still receive hover events for explanatory tooltips.
        row:Show()
    end
    for i = #items + 1, #panel.rows do panel.rows[i]:Hide() end
    panel:Show()
end

local driver = CreateFrame("Frame")
driver:Hide()
local wasLeft, wasRight
driver:SetScript("OnUpdate", function(self, dt)
    if not Menu:IsOpen() then
        self:Hide(); return
    end
    if owner and not owner:IsVisible() then
        Menu:Close(); self:Hide(); return
    end
    stateUpdateElapsed = stateUpdateElapsed + dt
    if stateUpdateElapsed >= STATE_UPDATE_INTERVAL then
        stateUpdateElapsed = 0
        for _, panel in ipairs(panels) do
            if panel:IsShown() then
                for _, row in ipairs(panel.dynamicRows or {}) do
                    local item = row.item
                    local disabled = IsItemDisabled(item)
                    local actionDisabled = item.action and not not Value(item.action.disabled) or false
                    if disabled ~= row.disabledState or actionDisabled ~= row.actionDisabledState then
                        UpdateRowState(row)
                    end
                end
            end
        end
    end
    local inside = owner and owner:IsMouseOver()
    for _, panel in ipairs(panels) do
        if panel:IsShown() and (panel:IsMouseOver()
            or (panel.ScrollBar.ThumbButton and panel.ScrollBar.ThumbButton.modernDragging)) then inside = true end
    end
    local left, right = IsMouseButtonDown("LeftButton"), IsMouseButtonDown("RightButton")
    if not inside and ((left and not wasLeft) or (right and not wasRight)) then
        Menu:Close()
    elseif inside then
        elapsedOutside = 0
    elseif closeDelay and not countingPaused then
        elapsedOutside = (elapsedOutside or 0) + dt
        if elapsedOutside >= closeDelay then Menu:Close() end
    end
    wasLeft, wasRight = left, right
end)

function Menu:Open(control, items, options)
    options = options or {}
    self:Close()
    -- Existing initialize callbacks may close other menus through BG.FrameHide.
    -- Resolve their items before establishing the new owner and anchor state.
    local resolvedItems = Value(items)
    openOptions = options
    owner, closeDelay, elapsedOutside = control, options.closeDelay, 0
    stateUpdateElapsed = 0
    Build(1, resolvedItems, control, options.cursor)
    wasLeft, wasRight = IsMouseButtonDown("LeftButton"), IsMouseButtonDown("RightButton")
    driver:Show()
end

function Menu:GetPanel(level)
    return GetPanel(level or 1)
end

-- Attach one independent button to an option's right side. Works with both
-- UIDropDownMenu_AddButton info tables and Open/EasyMenu item tables.
-- Callback: func(control, item, button, row, mouseButton).
-- icon/atlas or text; size; tooltipTitle/tooltipText; disabled; noClickSound;
-- iconColor/hoverIconColor; onEnter/onLeave(button, item, row).
-- hoverOnly=true shows the button only while the row or button is hovered.
-- refresh=true reruns the control's item factory after the callback.
function Menu:SetItemButton(item, action)
    assert(type(item) == "table", "SetItemButton requires a menu item")
    assert(action == nil or type(action) == "table", "Item button configuration must be a table")
    item.action = action
    return item
end

function Menu:Refresh(control)
    if not self:IsOpen(control) then return end
    control = control or owner
    local items = control and control.items
    if items then self:Open(control, items, openOptions) end
end

function Menu:GetRow(level, index)
    return GetPanel(level).rows[index]
end

function Menu:GetRowCapacity()
    return #GetPanel(1).rows
end

-- Register row customizations once; also apply them to newly allocated rows.
function Menu:ForEachRow(initialize)
    rowInitializers[#rowInitializers + 1] = initialize
    for i, row in ipairs(GetPanel(1).rows) do initialize(row, i) end
end

function Menu:Create_UIDropDownMenu(name, parent)
    local control = self:CreateDropdown(parent)
    -- Production controls toggle on mouse down; avoid a second toggle on release.
    control:SetScript("OnClick", nil)
    control:SetScript("OnMouseDown", function(self)
        if not self.isDisabled then
            Menu:ToggleDropDownMenu(nil, nil, self)
            PlayMenuSound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    control.menuName = name
    return control
end

function Menu:UIDropDownMenu_SetWidth(control, width)
    control:SetWidth(width + 30)
end

function Menu:UIDropDownMenu_SetText(control, text) control:SetText(text or "") end

function Menu:UIDropDownMenu_GetText(control) return control:GetText() end

function Menu:UIDropDownMenu_EnableDropDown(control) control:SetMenuEnabled(true) end

function Menu:UIDropDownMenu_DisableDropDown(control) control:SetMenuEnabled(false) end

function Menu:UIDropDownMenu_SetAnchor(control, x, y, point, relativeTo, relativePoint)
    control.menuAnchor = {
        x = x or 0,
        y = y or 0,
        point = point or "TOPLEFT",
        relativeTo = relativeTo,
        relativePoint = relativePoint or "BOTTOMLEFT"
    }
end

function Menu:UIDropDownMenu_CreateInfo() return {} end

function Menu:UIDropDownMenu_AddButton(info)
    assert(collection, "Menu items must be added inside an initialize callback")
    local item = {}
    for key, value in pairs(info) do item[key] = value end
    if item.text == "   " and item.isTitle then item.separator = true end
    collection[#collection + 1] = item
end

function Menu:UIDropDownMenu_Initialize(control, initialize)
    control.initialize = initialize
    control:SetItems(function()
        local previous = collection
        collection = {}
        local ok, err = pcall(initialize, control, 1)
        local items = collection
        collection = previous
        if not ok then error(err) end
        return items
    end)
end

function Menu:ToggleDropDownMenu(_, _, control)
    if not control or control.isDisabled then return end
    if Menu:IsOpen(control) then
        Menu:Close(); return
    end
    Menu:Open(control, control.items or {}, { anchor = control.menuAnchor, closeDelay = 2 })
end

local function CopyItems(items)
    local result = {}
    for i, info in ipairs(items) do
        local item = {}
        for key, value in pairs(info) do item[key] = value end
        if item.text == "   " and item.isTitle then item.separator = true end
        if type(item.menuList) == "table" then item.menuList = CopyItems(item.menuList) end
        result[i] = item
    end
    return result
end

function Menu:EasyMenu(items, control, anchor, x, y, _, delay)
    Menu:Open(control, CopyItems(items), {
        cursor = anchor == "cursor",
        x = x,
        y = y,
        anchor = anchor ~= "cursor" and (control.menuAnchor or { point = "TOPLEFT",
            relativeTo = anchor, relativePoint = "BOTTOMLEFT", x = x or 0, y = y or 0 }) or nil,
        closeDelay = delay or 2
    })
end

-- Can also be passed directly as an item's callback (without a library self).
function Menu.CloseDropDownMenus() Menu:Close() end

function Menu.UIDropDownMenu_StopCounting()
    countingPaused = true; elapsedOutside = 0
end

function Menu.UIDropDownMenu_StartCounting()
    countingPaused = false; elapsedOutside = 0
end

local BOARDCOLOR = .4
function Menu:CreateDropdown(parent, width)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 210, 26)
    button:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8X8",
        edgeFile = "Interface/Buttons/WHITE8X8",
        edgeSize = 1
    })
    button:SetBackdropColor(0, 0, 0, .5)
    button:SetBackdropBorderColor(BOARDCOLOR, BOARDCOLOR, BOARDCOLOR, 1)
    button.Text = Font(button, nil, GameFontHighlightSmall)
    button.Text:SetPoint("LEFT", 10, 0)
    button.Text:SetPoint("RIGHT", -28, 0)
    button.Text:SetJustifyH("LEFT")
    button.Text:SetWordWrap(false)
    button.arrow = button:CreateTexture(nil, "ARTWORK")
    button.arrow:SetSize(16, 16)
    button.arrow:SetPoint("RIGHT", -10, 0)
    button.arrow:SetTexture("Interface\\AddOns\\" .. AddonName .. "\\Libs\\BiaoGeMenu\\arrow.tga")
    button.arrow:SetRotation(math.pi)
    button.arrow:SetVertexColor(1, 1, 1)
    function button:SetText(text) self.Text:SetText(text) end

    function button:GetText() return self.Text:GetText() end

    function button:SetItems(items) self.items = items end

    function button:SetMenuEnabled(enabled)
        self.isDisabled = not enabled
        self:SetAlpha(enabled and 1 or .45)
        if not enabled and Menu:IsOpen(self) then Menu:Close() end
    end

    button:SetScript("OnEnter", function(self)
        if not self.isDisabled then
            local r, g, b = ClassColor()
            self:SetBackdropColor(r, g, b, .2)
            self:SetBackdropBorderColor(r, g, b, 1)
        end
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0, 0, 0, .5)
        self:SetBackdropBorderColor(BOARDCOLOR, BOARDCOLOR, BOARDCOLOR, 1)
    end)
    button:SetScript("OnClick", function(self)
        if self.isDisabled or not self.items then return end
        if Menu:IsOpen(self) then Menu:Close() else Menu:Open(self, self.items) end
        PlayMenuSound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end)
    button:SetScript("OnHide", function(self) if Menu:IsOpen(self) then Menu:Close() end end)
    return button
end
