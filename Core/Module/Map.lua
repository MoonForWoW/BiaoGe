if BG.IsBlackListPlayer then return end
if not (BG.IsTBC or BG.IsWLK or BG.IsMOP) then return end
local _, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
local Size = ns.Size
local RGB = ns.RGB
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local Maxb = ns.Maxb
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID

local pt = print

local _, class = UnitClass("player")
local r, g, b, cff = GetClassColor(class)

local channel = "BiaoGeAIMap"
C_ChatInfo.RegisterAddonMessagePrefix(channel)
for i = 1, BG.addonChannelCount do
    local channelName = channel .. i
    C_ChatInfo.RegisterAddonMessagePrefix(channelName)
end

BG.Init(function()
    BiaoGe.options.mapScale = BiaoGe.options.mapScale or .75
    BiaoGe.options.mapIconScale = BiaoGe.options.mapIconScale or 1
    BiaoGe.options.mapFrameLevel = BiaoGe.options.mapFrameLevel or "MEDIUM"

    BiaoGe.maps = BiaoGe.maps or {}
    if BiaoGe.lastMapCode then
        tinsert(BiaoGe.maps, 1, { code = BiaoGe.lastMapCode })
        BiaoGe.lastMapCode = nil
    end

    local maxDB = 10
    local mapIndex = 1

    local GetDropDownText, UpdateDropDownText

    local function UpdateMapDB()
        while #BiaoGe.maps > maxDB do
            tremove(BiaoGe.maps, #BiaoGe.maps)
        end
    end
    UpdateMapDB()

    function BG.ShowMap()
        local code = BiaoGe.maps[mapIndex] and BiaoGe.maps[mapIndex].code
        if code then
            BG.BuildMapByCode(code, true)
            UpdateDropDownText()
        else
            BG.SendSystemMessage(L["缺少站位图数据，无法显示。"])
        end
    end

    local bt = CreateFrame("Button", nil, BG.MainFrame)
    do
        bt:SetPoint("LEFT", BG.ButtonGuoQi, "RIGHT", BG.TopLeftButtonJianGe, 0)
        bt:SetNormalFontObject(BG.FontGreen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        bt:SetText(L["站位图"])
        bt:SetSize(bt:GetFontString():GetWidth(), 20)
        BG.SetTextHighlightTexture(bt)
        BG.ButtonMap = bt
        bt:SetScript("OnClick", function(self)
            if BG.MapFrame:IsVisible() then
                BG.MapFrame:Hide()
            else
                BG.ShowMap()
            end
            BG.PlaySound(1)
        end)
        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_NONE")
            GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
            GameTooltip:AddLine(L["显示团长上次发送的站位图。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(L["快捷命令：/bgmap 或 /aimap"], 1, 0.82, 0, true)
            GameTooltip:AddLine(" ", 1, 0.82, 0, true)
            if BGAI then
                GameTooltip:AddLine(L["团长使用教程：输入命令/ai打开BiaoGeAI插件，点击一键安排，再点击发送。"], 1, 0.82, 0, true)
            else
                GameTooltip:AddLine(L["团长需使用BiaoGeAI插件才能发送站位图。"], 1, 0.82, 0, true)
            end
            GameTooltip:Show()
        end)
        bt:SetScript("OnLeave", GameTooltip_Hide)
    end

    local frameName = "BG.MapFrame"
    local f = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    do
        f:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 1,
        })
        f:SetBackdropColor(0, 0, 0, 0)
        f:SetBackdropBorderColor(0, 0, 0, 1)
        f:SetSize(450, 450)
        f.minW = 150
        f.minH = 35
        f:SetClampedToScreen(true)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:SetFrameStrata(BiaoGe.options.mapFrameLevel)
        f:SetToplevel(true)
        f:Hide()
        f.defaultPoint = { "TOPLEFT", 0, 0 }
        f:SetScale(BiaoGe.options.mapScale)
        if BiaoGe.point[frameName] then
            BiaoGe.point[frameName][2] = nil
            f:SetPoint(unpack(BiaoGe.point[frameName]))
        else
            f:SetPoint(unpack(f.defaultPoint))
        end
        f.icons = {}
        BG.MapFrame = f

        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 20, "OUTLINE")
        t:SetPoint("LEFT", 10, 0)
        t:SetTextColor(1, .82, 0)
        t:SetText(L["站位图"])
        t:Hide()
        f.minTitle = t

        local tex = f:CreateTexture()
        tex:SetPoint("TOPLEFT", 1, -1)
        tex:SetPoint("BOTTOMRIGHT", -1, 1)
        f.mapTex = tex

        f:SetScript("OnMouseDown", function(self)
            self:StartMoving()
        end)
        f:SetScript("OnMouseUp", function(self, enter)
            self:StopMovingOrSizing()
            if enter == "RightButton" then
                f:ClearAllPoints()
                f:SetPoint(unpack(f.defaultPoint))
            end
            BiaoGe.point[frameName] = { f:GetPoint(1) }
        end)
        f:SetScript("OnEnter", function(self)
            f.isOnEnter = true
        end)
        f:SetScript("OnLeave", function(self)
            f.isOnEnter = nil
        end)
        f.t = 0
        f:SetScript("OnUpdate", function(self, t)
            if self.isMinimized then return end
            if self.isOnEnter then
                self.minimizeButton:Show()
                self.t = 0
            else
                self.t = self.t + t
                if self.t >= 0.05 then
                    self.t = 0
                    if not self.isOnEnter then
                        self.minimizeButton:Hide()
                    end
                end
            end
        end)

        function BG.MapFrame:SetMax()
            local cx, cy = f:GetCenter()
            local toprightX = cx + f.minW / 2
            local toprightY = cy + f.minH / 2
            f:SetBackdropColor(0, 0, 0, 0)
            f:SetSize(f.originalWidth, f.originalHeight)
            f:ClearAllPoints()
            f:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
                toprightX - f.originalWidth / 2, toprightY - f.originalHeight / 2)
            f.savedPoint = { f:GetPoint(1) }
            f.minTitle:Hide()
            f.mapTex:Show()
            f.dropDown:Show()
            f.resizeButton:Show()
            f.optionButton:Show()
            for _, icon in ipairs(f.icons) do
                icon:Show()
            end
            f.isMinimized = false
            BG.MapFrame.minimizeButton:SetMaxTex()
        end

        function BG.MapFrame:SetMin()
            if not f.originalWidth then
                f.originalWidth = f:GetWidth()
                f.originalHeight = f:GetHeight()
            end
            f.savedPoint = { f:GetPoint(1) }
            local centerX, centerY = f:GetCenter()
            local toprightX = centerX + f.originalWidth / 2
            local toprightY = centerY + f.originalHeight / 2
            f:SetSize(f.minW, f.minH)
            f:ClearAllPoints()
            f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", toprightX - f.minW / 2, toprightY - f.minH / 2)
            f:SetBackdropColor(0, 0, 0, .6)
            f.minTitle:Show()
            f.mapTex:Hide()
            f.dropDown:Hide()
            f.resizeButton:Hide()
            f.optionButton:Hide()
            for _, icon in ipairs(f.icons) do
                icon:Hide()
            end
            f.isMinimized = true
            BG.MapFrame.minimizeButton:SetMinTex()
        end

        f.resizeButton = BG.CreateFrameResizeHandle(f, "mapScale", .5, 1.5)
        f.resizeButton:HookScript("OnEnter", f:GetScript("OnEnter"))
        f.resizeButton:HookScript("OnLeave", f:GetScript("OnLeave"))

        BG.CreateCloseButton(f, BG.IsRetail and 0 or 2, BG.IsRetail and 0 or 2)
        f.CloseButton:SetSize(40, 40)
        f.CloseButton:HookScript("OnEnter", BG.MapFrame:GetScript("OnEnter"))
        f.CloseButton:HookScript("OnLeave", BG.MapFrame:GetScript("OnLeave"))

        -- 最小化按钮（在关闭按钮左边）
        local minimizeBtn = CreateFrame("Button", nil, f)
        minimizeBtn:SetSize(25, 25)
        minimizeBtn:SetPoint("RIGHT", f.CloseButton, "LEFT", 0, 0)
        f.minimizeButton = minimizeBtn
        f.isMinimized = false
        function BG.MapFrame.minimizeButton:SetMaxTex()
            self:SetNormalTexture([[Interface\Buttons\UI-Panel-SmallerButton-Up]])
            self:GetNormalTexture():SetTexCoord(0.18, 0.82, 0.18, 0.82)
            self:SetPushedTexture([[Interface\Buttons\UI-Panel-SmallerButton-Down]])
            self:GetPushedTexture():SetTexCoord(0.18, 0.82, 0.18, 0.82)
            self:SetHighlightTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Highlight]])
            self:GetHighlightTexture():SetTexCoord(0.18, 0.82, 0.18, 0.82)
        end

        function BG.MapFrame.minimizeButton:SetMinTex()
            self:SetNormalTexture([[Interface\Buttons\UI-Panel-BiggerButton-Up]])
            self:GetNormalTexture():SetTexCoord(0.18, 0.82, 0.18, 0.82)
            self:SetPushedTexture([[Interface\Buttons\UI-Panel-BiggerButton-Down]])
            self:GetPushedTexture():SetTexCoord(0.18, 0.82, 0.18, 0.82)
            self:SetHighlightTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Highlight]])
            self:GetHighlightTexture():SetTexCoord(0.18, 0.82, 0.18, 0.82)
        end

        BG.MapFrame.minimizeButton:SetMaxTex()

        -- 设置按钮（在最小化按钮左边）
        local bt = CreateFrame("Button", nil, f.minimizeButton)
        bt:SetSize(25, 25)
        bt:SetNormalTexture([[Interface\Buttons\UI-OptionsButton]])
        bt:SetHighlightTexture([[Interface\Buttons\UI-OptionsButton]])
        bt:SetPoint("RIGHT", f.minimizeButton, "LEFT", -5, 0)
        bt:RegisterForClicks("AnyUp")
        bt:SetScript("OnClick", function(self)
            BG.OpenOption()
            BG.ButtonOptions_map:Click()
        end)
        bt:HookScript("OnEnter", BG.MapFrame:GetScript("OnEnter"))
        bt:HookScript("OnLeave", BG.MapFrame:GetScript("OnLeave"))
        f.optionButton = bt

        minimizeBtn:SetScript("OnClick", function(self)
            if f.isMinimized then
                BG.MapFrame:SetMax()
            else
                BG.MapFrame:SetMin()
            end
            BG.PlaySound(1)
        end)
        minimizeBtn:HookScript("OnEnter", BG.MapFrame:GetScript("OnEnter"))
        minimizeBtn:HookScript("OnLeave", BG.MapFrame:GetScript("OnLeave"))
    end

    local dropDown = LibBG:Create_UIDropDownMenu(nil, f.minimizeButton)
    do
        dropDown:SetPoint("TOPLEFT", f, "TOPLEFT", -14, -1)
        dropDown:SetScale(1.1)
        LibBG:UIDropDownMenu_SetWidth(dropDown, 250)
        LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOPLEFT", dropDown, "BOTTOMLEFT")
        BG.dropDownToggle(dropDown)
        f.dropDown = dropDown
        dropDown:HookScript("OnEnter", BG.MapFrame:GetScript("OnEnter"))
        dropDown:HookScript("OnLeave", BG.MapFrame:GetScript("OnLeave"))

        function UpdateDropDownText()
            LibBG:UIDropDownMenu_SetText(dropDown, GetDropDownText())
        end

        function GetDropDownText(index)
            index = index or mapIndex
            local v = BiaoGe.maps[index]
            if v and v.time and v.sender and v.FB and v.bossIndex then
                local time = date("%H:%M:%S", v.time) or ""
                local sender = v.sender
                local FB = v.FB
                local bossName = v.bossName
                    or (BG.Boss[FB] and BG.Boss[FB]["boss" .. v.bossIndex]
                        and BG.Boss[FB]["boss" .. v.bossIndex].name2)
                    or ""
                return L["%s %s %s"]:format(time, sender, bossName)
            else
                return L["站位图"]
            end
        end

        LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
            for i, v in ipairs(BiaoGe.maps) do
                local info = LibBG:UIDropDownMenu_CreateInfo()
                info.text = GetDropDownText(i)
                info.checked = LibBG:UIDropDownMenu_GetText(dropDown) == info.text
                info.arg1 = i
                info.func = function()
                    mapIndex = i
                    UpdateDropDownText()
                    local code = BiaoGe.maps[mapIndex] and BiaoGe.maps[mapIndex].code
                    if code then
                        BG.BuildMapByCode(code, true)
                    end
                end
                LibBG:UIDropDownMenu_AddButton(info)
            end
        end)

        L_DropDownList1:HookScript("OnEnter", function(self)
            if L_DropDownList1.dropdown ~= dropDown then return end
            BG.MapFrame:GetScript("OnEnter")()
        end)
        L_DropDownList1:HookScript("OnLeave", function(self)
            if L_DropDownList1.dropdown ~= dropDown then return end
            BG.MapFrame:GetScript("OnLeave")()
        end)

        local buttonName = "deleteMap"
        for i = 1, L_UIDROPDOWNMENU_MAXBUTTONS do
            local button = _G["L_DropDownList1Button" .. i]
            button:HookScript("OnEnter", function()
                if L_DropDownList1.dropdown ~= dropDown then return end
                BG.MapFrame:GetScript("OnEnter")()
                if not button[buttonName] then
                    local bt = CreateFrame("Button", nil, button)
                    bt:SetSize(15, 15)
                    bt:SetPoint("RIGHT", -2, 0)
                    bt:SetNormalTexture("interface/raidframe/readycheck-notready")
                    bt:SetHighlightTexture("interface/raidframe/readycheck-notready")
                    bt:RegisterForClicks("AnyUp")
                    bt.num = i
                    bt:Hide()
                    button[buttonName] = bt
                    bt:SetScript("OnClick", function(self)
                        BG.PlaySound(1)
                        tremove(BiaoGe.maps, button.arg1)
                        LibBG:CloseDropDownMenus()
                        LibBG:ToggleDropDownMenu(nil, nil, dropDown)
                    end)
                    bt:SetScript("OnEnter", function(self)
                        BG.MapFrame:GetScript("OnEnter")()
                        button.isOnEnter = true
                        LibBG:UIDropDownMenu_StopCounting(self:GetParent():GetParent())
                        button.Highlight:Show()
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(L["删除该站位图"], 1, 1, 1, true)
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
                    if bt[buttonName] then
                        bt[buttonName]:Hide()
                    end
                end
                if button.arg1 then
                    button[buttonName]:Show()
                end
            end)
            button:HookScript("OnLeave", function()
                if L_DropDownList1.dropdown ~= dropDown then return end
                BG.MapFrame:GetScript("OnLeave")()
                button.isOnEnter = false
                BG.After(0, function()
                    if not button.isOnEnter then
                        button[buttonName]:Hide()
                    end
                end)
            end)
        end
    end

    function BG.UpdateMapIconScale()
        local value = BiaoGe.options.mapIconScale
        for i, icon in ipairs(BG.MapFrame.icons) do
            icon:SetScale(value)
            icon:SetPoint("CENTER", icon:GetParent(), "TOPLEFT",
                icon.x / value, icon.y / value)
        end
    end

    local receiveStart = {}
    local receiveCodes = {}
    local receiveStart2 = {}
    local receiveCodes2 = {}

    local function CreateMapIcon(FB, level, x, y, width, height, iconType, iconTex, coord, broderShow, broderColor, numText, numColor, playerText, playerColor)
        local f = CreateFrame("Frame", nil, BG.MapFrame)
        local value = BiaoGe.options.mapIconScale
        f:SetSize(width, height)
        f:SetScale(value)
        f:SetFrameLevel(BG.MapFrame:GetFrameLevel() + level)
        f:SetPoint("CENTER", f:GetParent(), "TOPLEFT", x / value, y / value)
        f.x = x
        f.y = y

        local mask = f:CreateMaskTexture()
        mask:SetPoint("CENTER")
        mask:SetSize(width - 4, width - 4)
        mask:SetTexture([[Interface\CharacterFrame\TempPortraitAlphaMask]], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")

        local icon = f:CreateTexture()
        icon:SetPoint("CENTER")
        icon:SetSize(width + 6, width + 6)
        if iconType == "boss" then
            icon:SetTexture(format("Interface\\AddOns\\BiaoGe\\Media\\icon\\%s\\%s.png", FB, iconTex))
        elseif iconType == "tex" then
            icon:SetTexture((iconTex))
        elseif iconType == "atlas" then
            icon:SetAtlas((iconTex))
        end
        if coord then
            icon:SetTexCoord(unpack(coord))
        end

        local broder = f:CreateTexture()
        broder:SetAllPoints()
        broder:SetTexture([[Interface\AddOns\BiaoGe\Media\icon\broder.png]])
        broder:SetVertexColor(unpack(broderColor))
        if broderShow == 0 then
            broder:Hide()
        else
            icon:AddMaskTexture(mask)
        end

        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetPoint("CENTER", 1, 0)
        t:SetText(numText)
        t:SetTextColor(unpack(numColor))
        f.numText = t

        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetPoint("TOP", f, "BOTTOM", 0, 0)
        t:SetText(playerText)
        t:SetTextColor(unpack(playerColor))
        if playerText ~= "" then
            f.numText:SetText("")
        end

        tinsert(BG.MapFrame.icons, f)
    end

    function BG.BuildMapByCode(code, notSave, sender)
        local str
        if not ns.IsBase64(code) then
            return
        end
        str = C_EncodingUtil.DecompressString(ns.Decode(code))
        local info, icons = BG.Split("^^", str)
        local FB, bossIndex, mapWidth, mapHeight, childIndex, bossName = BG.Split("&&", info)
        bossIndex = tonumber(bossIndex)
        mapWidth = tonumber(mapWidth)
        mapHeight = tonumber(mapHeight)
        if FB and bossIndex and mapWidth and mapHeight then
            local mapTex = format("Interface\\AddOns\\BiaoGe\\Media\\icon\\%s\\m%s.png", FB, bossIndex .. (childIndex or ""))
            local tex = UIParent:CreateTexture()
            tex:SetPoint("CENTER")
            tex:SetSize(10, 10)
            tex:SetTexture(mapTex)
            tex:Hide()
            if not tex:GetTexture() then
                return
            end
            if not notSave then
                local codeInfo = {}
                codeInfo.time = time()
                codeInfo.sender = SetClassCFF(sender)
                codeInfo.code = code
                codeInfo.FB = FB
                codeInfo.bossIndex = bossIndex
                codeInfo.bossName = bossName
                tinsert(BiaoGe.maps, 1, codeInfo)
                UpdateMapDB()
            end
            BG.MapFrame.originalWidth = mapWidth
            BG.MapFrame.originalHeight = mapHeight
            if BG.MapFrame.isMinimized then
                BG.MapFrame:SetMax()
            end
            BG.MapFrame.minimizeButton:Hide()
            BG.MapFrame.mapTex:SetTexture(mapTex)
            BG.MapFrame:SetSize(mapWidth, mapHeight)
            BG.MapFrame:Show()
            for i, icon in ipairs(BG.MapFrame.icons) do
                icon:Hide()
            end
            wipe(BG.MapFrame.icons)
            for _, iconStr in ipairs({ BG.Split("&&", icons) }) do
                if iconStr and iconStr ~= "" then
                    local
                    level,
                    x,
                    y,
                    width,
                    height,
                    iconType,
                    iconTex,
                    left,
                    right,
                    top,
                    bottom,
                    broderShow,
                    broder_r,
                    broder_g,
                    broder_b,
                    numText,
                    num_r,
                    num_g,
                    num_b,
                    playerText,
                    player_r,
                    player_g,
                    player_b
                               = BG.Split("¦", iconStr)
                    level      = tonumber(level)
                    x          = tonumber(x)
                    y          = tonumber(y)
                    width      = tonumber(width)
                    height     = tonumber(height)
                    left       = tonumber(left)
                    right      = tonumber(right)
                    top        = tonumber(top)
                    bottom     = tonumber(bottom)
                    broderShow = tonumber(broderShow)
                    broder_r   = tonumber(broder_r)
                    broder_g   = tonumber(broder_g)
                    broder_b   = tonumber(broder_b)
                    num_r      = tonumber(num_r)
                    num_g      = tonumber(num_g)
                    num_b      = tonumber(num_b)
                    player_r   = tonumber(player_r)
                    player_g   = tonumber(player_g)
                    player_b   = tonumber(player_b)
                    CreateMapIcon(
                        FB,
                        level,
                        x,
                        y,
                        width,
                        height,
                        iconType,
                        iconTex,
                        left and { left, right, top, bottom, },
                        broderShow,
                        { broder_r, broder_g, broder_b, },
                        numText,
                        { num_r, num_g, num_b, },
                        playerText,
                        { player_r, player_g, player_b }
                    )
                end
            end
            return true
        end
    end

    local function ReceiveFinish(sender, codes)
        local code = table.concat(codes)
        code = code:match("^!AIMAP!(.+)!END!$")
        if not code then return end
        local success = BG.BuildMapByCode(code, nil, sender)
        if success then
            mapIndex = 1
            UpdateDropDownText()
        end
    end

    -- 接收数据
    BG.RegisterEvent("CHAT_MSG_ADDON", function(self, event, ...)
        local prefix, msg, distType, _, sender = ...
        if distType == "RAID" and (UnitIsGroupLeader(sender) or UnitIsGroupAssistant(sender)) then
            if prefix == channel then
                if not receiveStart2[sender] then
                    if msg:match("^!AIMAP!") then
                        receiveStart[sender] = true
                        wipe(receiveCodes)
                    end
                    if receiveStart[sender] then
                        tinsert(receiveCodes, msg)
                        if msg:match("!END!$") then
                            receiveStart[sender] = nil
                            ReceiveFinish(sender, receiveCodes)
                        end
                    end
                end
            elseif prefix:match(channel .. '(%d+)') then
                if msg:match("^!AIMAP!") then
                    receiveStart2[sender] = true
                    wipe(receiveCodes2)
                end
                if receiveStart2[sender] then
                    tinsert(receiveCodes2, msg)
                    if msg:match("!END!$") then
                        ReceiveFinish(sender, receiveCodes2)
                        BG.After(2, function()
                            receiveStart2[sender] = nil
                            receiveStart[sender] = nil
                        end)
                    end
                end
                receiveStart[sender] = nil
            end
        end
    end)
end)
