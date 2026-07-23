if BG.IsBlackListPlayer then return end
local _, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local RR = ns.RR
local Size = ns.Size
local RGB = ns.RGB
local SetClassCFF = ns.SetClassCFF
local AddTexture = ns.AddTexture

local Y = {}

BG.Init(function()
    -- 初始化数据库
    do
        if not BiaoGe.YYdb then
            BiaoGe.YYdb = {}
        end
        if not BiaoGe.YYdb.all then
            BiaoGe.YYdb.all = {}
        end
        if not BiaoGe.YYdb.allFilter then
            BiaoGe.YYdb.allFilter = 0
        end
        if not BiaoGe.YYdb.share then
            BiaoGe.YYdb.share = 1
        end
    end

    function Y.CreateLine(parent, y, width, height, color, alpha)
        local l = parent:CreateLine()
        l:SetColorTexture(RGB(color or "808080", alpha or 1))
        l:SetStartPoint("TOPLEFT", 5, y)
        l:SetEndPoint("TOPLEFT", width, y)
        l:SetThickness(height or 1.5)
        return l
    end

    -- 新增评价Frame
    do
        local f = CreateFrame("Frame", nil, BG.YYMainFrame, "BackdropTemplate")
        f:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(0, 0, 0, 0.4)
        f:SetSize(600, 180)
        f:SetPoint("TOPLEFT", BG.MainFrame, "TOPLEFT", 25, -55)
        BG.YYMainFrame.new = f

        -- 大标题：新增评价
        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetTextColor(RGB(BG.y2))
        t:SetPoint("BOTTOM", f, "TOP", 0, 2)
        t:SetText(L["< 新增评价 >"])
        t:SetTextColor(1, 1, 1)
        BG.YYMainFrame.new.title = t

        Y.textcolor_table = {} -- 用于根据所选评价给输入框设置相应颜色
        local height = 22      -- 每行高度
        local n = 0

        -- 小标题
        do
            local text_table = {
                { name = L["YY："] },
                { name = L["备注："] },
                { name = L["评价："] },
                { name = L["理由："] }
            }
            for i, v in ipairs(text_table) do
                local f = CreateFrame("Frame", nil, BG.YYMainFrame.new)
                f:SetPoint("TOPLEFT", 10, -15 - height * (i - 1))
                f:SetSize(90, 20)
                f.Text = f:CreateFontString()
                f.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                f.Text:SetTextColor(RGB(BG.y2))
                f.Text:SetAllPoints()
                f.Text:SetWordWrap(false)
                f.Text:SetText(v.name)
                f.Text:SetTextColor(1, 1, 0)
                f.Text:SetJustifyH("RIGHT")
                tinsert(Y.textcolor_table, f.Text)
            end
        end
        -- YY号
        do
            local edit = CreateFrame("EditBox", nil, BG.YYMainFrame.new, BG.editTemplate)
            edit:SetSize(150, 20)
            edit:SetPoint("TOPLEFT", 110, -15 - height * n)
            edit:SetAutoFocus(false)
            edit:SetNumeric(true)
            edit:SetTextColor(1, 1, 0)
            tinsert(Y.textcolor_table, edit)
            BG.YYMainFrame.new.yy = edit
            n = n + 1
            local t = edit:CreateFontString(nil, "ARTWORK")
            t:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
            t:SetTextColor(.5, .5, .5)
            t:SetPoint("LEFT", 3, 0)
            t:SetText(L["必填"])
            edit:HookScript("OnEditFocusGained", function(self)
                BG.lastfocus = self
                BG.ListYY(self)
            end)
            edit:SetScript("OnEditFocusLost", function(self)
                _G.L_DropDownList1:Hide()
            end)
            edit:SetScript("OnTextChanged", function(self)
                if self:GetText() ~= "" then
                    t:Hide()
                else
                    t:Show()
                end
                if not BG.YYMainFrame.new.buttonesc:IsVisible() then
                    for key, value in pairs(BiaoGe.YYdb.all) do
                        if self:GetText() == value.yy then
                            BG.YYMainFrame.new.yy.num = key
                            BG.YYMainFrame.new.buttonrepeat:Show()
                            return
                        end
                    end
                    BG.YYMainFrame.new.yy.num = nil
                    BG.YYMainFrame.new.buttonrepeat:Hide()
                end
            end)
            edit:SetScript("OnKeyDown", function(self, enter)
                if enter == "ENTER" or enter == "TAB" then
                    BG.YYMainFrame.new.name:SetFocus()
                end
            end)
            edit:SetScript("OnMouseDown", function(self, enter)
                -- if BG.YYMainFrame.new.buttonesc:IsVisible() then return end
                if enter == "RightButton" then
                    self:SetEnabled(false)
                    self:SetText("")
                end
            end)
            edit:SetScript("OnMouseUp", function(self, enter)
                -- if BG.YYMainFrame.new.buttonesc:IsVisible() then return end
                if enter == "RightButton" then
                    self:SetEnabled(true)
                end
            end)
        end
        -- 备注
        do
            local edit = CreateFrame("EditBox", nil, BG.YYMainFrame.new, BG.editTemplate)
            edit:SetSize(150, 20)
            edit:SetPoint("TOPLEFT", 110, -15 - height * n)
            edit:SetAutoFocus(false)
            edit:SetTextColor(1, 1, 0)
            tinsert(Y.textcolor_table, edit)
            BG.YYMainFrame.new.name = edit
            n = n + 1
            local t = edit:CreateFontString(nil, "ARTWORK")
            t:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
            t:SetTextColor(.5, .5, .5)
            t:SetPoint("LEFT", 3, 0)
            t:SetText(L["选填"])
            t:SetJustifyH("LEFT")
            t:SetWidth(edit:GetWidth() - 5)
            t:SetWordWrap(false)
            edit:HookScript("OnEditFocusGained", function(self)
                BG.lastfocus = self
            end)
            edit:SetScript("OnTextChanged", function(self)
                if self:GetText() ~= "" then
                    t:Hide()
                else
                    t:Show()
                end
            end)
            edit:SetScript("OnKeyDown", function(self, enter)
                if enter == "ENTER" or enter == "TAB" then
                    BG.YYMainFrame.new.edit:SetFocus()
                end
            end)
            edit:SetScript("OnMouseDown", function(self, enter)
                if enter == "RightButton" then
                    self:SetEnabled(false)
                    self:SetText("")
                end
            end)
            edit:SetScript("OnMouseUp", function(self, enter)
                if enter == "RightButton" then
                    self:SetEnabled(true)
                end
            end)
        end
        -- 评价
        do
            local PingJiaGroup = CreateFrame("Frame", nil, BG.YYMainFrame.new)
            PingJiaGroup:SetPoint("TOPLEFT", 110, -15 - height * n)
            PingJiaGroup:SetSize(1, 1)
            local numOptions = {
                { name = L["好评"], color = "00FF00" },
                { name = L["中评"], color = "FFFF00" },
                { name = L["差评"], color = "DC143C" },
            }
            BG.YYMainFrame.new.pingjiaButtons = {}
            for i = 1, #numOptions do
                local bt = CreateFrame("CheckButton", nil, PingJiaGroup, "UIRadioButtonTemplate")
                bt:SetPoint("TOPLEFT", ((i - 1) * 60), -3)
                bt:SetSize(15, 15)
                if i == 2 then
                    bt:SetChecked(true)
                    BG.YYMainFrame.new.pingjia = i
                end
                BG.YYMainFrame.new.pingjiaButtons[i] = bt

                bt.Text = bt:CreateFontString()
                bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                bt.Text:SetTextColor(RGB(BG.y2))
                bt.Text:SetPoint("LEFT", bt, "RIGHT", 0, 0)
                bt.Text:SetText(numOptions[i].name)
                bt.Text:SetTextColor(RGB(numOptions[i].color))
                bt:SetHitRectInsets(0, -bt.Text:GetWidth(), -5, -5)

                bt:SetScript("OnClick", function(self)
                    for _, radioButton in ipairs(BG.YYMainFrame.new.pingjiaButtons) do
                        if radioButton ~= self then
                            radioButton:SetChecked(false)
                        end
                    end
                    for _, edit in pairs(Y.textcolor_table) do
                        edit:SetTextColor(RGB(numOptions[i].color))
                    end
                    self:SetChecked(true)
                    BG.YYMainFrame.new.pingjia = i

                    BG.PlaySound(1)
                end)
            end
            n = n + 1
        end
        -- 理由
        do
            local maxbytes = 200
            local f = CreateFrame("Frame", nil, BG.YYMainFrame.new, "BackdropTemplate")
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 16,
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            f:SetBackdropColor(0, 0, 0, 0.2)
            f:SetBackdropBorderColor(1, 1, 1, 0.6)
            f:SetSize(420, 80)
            f:SetPoint("TOPLEFT", 105, -17 - height * n)
            local edit = CreateFrame("EditBox", nil, f)
            edit:SetWidth(f:GetWidth())
            edit:SetAutoFocus(false)
            edit:SetMaxBytes(maxbytes)
            edit:EnableMouse(true)
            edit:SetTextInsets(0, 10, 0, 5)
            edit:SetMultiLine(true)
            edit:SetTextColor(1, 1, 0)
            edit:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
            tinsert(Y.textcolor_table, edit)
            BG.YYMainFrame.new.edit = edit
            local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
            scroll:SetWidth(f:GetWidth() - 10)
            scroll:SetHeight(f:GetHeight() - 10)
            scroll:SetPoint("CENTER")
            scroll.ScrollBar.scrollStep = BG.scrollStep
            BG.CreateSrollBarBackdrop(scroll.ScrollBar)
            BG.HookScrollBarShowOrHide(scroll)
            scroll:SetScrollChild(edit)
            BG.YYMainFrame.new.scroll = scroll

            local rightt = f:CreateFontString(nil, "ARTWORK")
            rightt:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
            rightt:SetTextColor(.5, .5, .5)
            rightt:SetPoint("BOTTOMRIGHT", -5, 5)
            local leftt = f:CreateFontString(nil, "ARTWORK")
            leftt:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
            leftt:SetTextColor(.5, .5, .5)
            leftt:SetPoint("TOPLEFT", 7, -5)
            leftt:SetText(L["选填"])

            edit:SetScript("OnEditFocusGained", function(self)
                BG.lastfocus = self
            end)
            edit:SetScript("OnTextChanged", function(self)
                local len = strlen(self:GetText())
                rightt:SetText(maxbytes - len)

                if self:GetText() ~= "" then
                    leftt:Hide()
                else
                    leftt:Show()
                end
            end)
            edit:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
            end)
            edit:SetScript("OnEnterPressed", function(self)
                Y.SaveOnClick(self)
            end)
            edit:SetScript("OnMouseDown", function(self, enter)
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
            f:SetScript("OnMouseDown", function(self, enter)
                if enter == "RightButton" then
                    edit:SetEnabled(false)
                    edit:SetText("")
                else
                    edit:SetFocus()
                end
            end)
            f:SetScript("OnMouseUp", function(self, enter)
                if enter == "RightButton" then
                    edit:SetEnabled(true)
                end
            end)
        end
        -- 保存
        do
            function Y.SaveOnClick(self)
                local new = BG.YYMainFrame.new
                if not new.pingjia then return end
                if new.yy:GetText() == "" or new.yy:GetText() == 0 then return end
                if BG.YYMainFrame.new.yy.num then return end

                if BG.YYMainFrame.my.all.lastNum then
                    tremove(BiaoGe.YYdb.all, BG.YYMainFrame.my.all.lastNum)
                end
                local a = {
                    date = tonumber(date("%y%m%d", GetServerTime())),
                    yy = new.yy:GetText(),
                    name = new.name:GetText(),
                    pingjia = new.pingjia,
                    edit = new.edit:GetText(),
                }
                tinsert(BiaoGe.YYdb.all, 1, a)

                Y.SetAll()
                Y.EscXiuGai()

                BG.PlaySound(1)
            end

            local bt = BG.CreateButton(BG.YYMainFrame.new)
            bt:SetSize(80, 20)
            bt:SetPoint("BOTTOMRIGHT", BG.YYMainFrame.new.scroll, "TOPRIGHT", 0, 7)
            bt:SetText(L["保存评价"])
            BG.YYMainFrame.new.buttonsave = bt
            bt:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:SetText(L["|cffffffff< 保存评价 >|r\n\n1、必填项填完才能保存\n2、同一个YY只能写一次评价，但你可以修改之前的评价"])
            end)
            BG.GameTooltip_Hide(bt)
            bt:SetScript("OnClick", Y.SaveOnClick)
        end
        -- 退出修改
        do
            local bt = BG.CreateButton(BG.YYMainFrame.new)
            bt:SetSize(80, 20)
            bt:SetPoint("RIGHT", BG.YYMainFrame.new.buttonsave, "LEFT", -5, 0)
            bt:SetText(L["退出修改"])
            bt:Hide()
            BG.YYMainFrame.new.buttonesc = bt
            bt:SetScript("OnClick", function(self)
                Y.EscXiuGai()
                BG.PlaySound(1)
            end)
            bt:SetScript("OnShow", function(self)
                BG.YYMainFrame.new.buttonrepeat:Hide()
            end)
        end
        -- 修改评价
        do
            local bt = CreateFrame("Button", nil, BG.YYMainFrame.new)
            bt:SetSize(190, 20)
            bt:SetPoint("LEFT", BG.YYMainFrame.new.yy, "RIGHT", 10, 0)
            bt:SetNormalFontObject(BG.FontGreen15)
            bt:SetDisabledFontObject(BG.FontDis15)
            bt:SetHighlightFontObject(BG.FontWhite15)
            bt:SetText(L["该YY已有评价，需要修改吗？"])
            bt:Hide()
            BG.YYMainFrame.new.buttonrepeat = bt
            bt:SetScript("OnClick", function(self)
                Y.XiuGai(self, "new")
                bt:Hide()
                BG.PlaySound(1)
            end)
        end
    end

    -- 我的全部评价Frame
    do
        local height = 20 -- 每行高度
        local n = 0

        local f = CreateFrame("Frame", nil, BG.YYMainFrame, "BackdropTemplate")
        f:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(0, 0, 0, 0.4)
        f:SetSize(BG.YYMainFrame.new:GetWidth(), 470)
        f:SetPoint("TOPLEFT", BG.YYMainFrame.new, "BOTTOMLEFT", 0, -20)
        BG.YYMainFrame.my = f

        -- 大标题：我的评价
        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetTextColor(RGB(BG.y2))
        t:SetPoint("BOTTOM", f, "TOP", 0, 2)
        t:SetText(L["< 我的评价 >"])
        t:SetTextColor(1, 1, 1)

        local title_table = {
            { name = L["序号"], width = 35, color = "FFFFFF" },
            { name = L["日期"], width = 80, color = "FFFFFF" },
            { name = L["YY"], width = 110, color = "FFFFFF" },
            { name = L["备注"], width = 90, color = "FFFFFF" },
            { name = L["评价"], width = 40, color = "FFFFFF" },
            { name = L["理由"], width = 205, color = "FFFFFF" },
        }

        -- 标题
        local right
        for i, v in ipairs(title_table) do
            local f = CreateFrame("Frame", nil, BG.YYMainFrame.my)
            f:SetSize(title_table[i].width, 20)
            if i == 1 then
                f:SetPoint("TOPLEFT", 10, -10)
            else
                f:SetPoint("TOPLEFT", right, "TOPRIGHT", 0, 0)
            end
            right = f
            f.Text = f:CreateFontString()
            f.Text:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
            f.Text:SetWidth(f:GetWidth() - 3)
            f.Text:SetPoint("CENTER")
            f.Text:SetText(title_table[i].name)
            f.Text:SetTextColor(RGB(title_table[i].color))
            f.Text:SetWordWrap(false)
            if title_table[i].name == L["理由"] then
                f.Text:SetJustifyH("LEFT")
            end
        end
        n = n + 1
        Y.CreateLine(BG.YYMainFrame.my, -n * height - 10, BG.YYMainFrame.my:GetWidth() - 25)

        -- 内容
        local f = CreateFrame("Frame", nil, BG.YYMainFrame.my)
        f:SetSize(1, 1)
        BG.YYMainFrame.my.all = f
        local scroll = CreateFrame("ScrollFrame", nil, BG.YYMainFrame.my, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", BG.YYMainFrame.my, 0, -height - 10 - 3)
        scroll:SetPoint("BOTTOMRIGHT", BG.YYMainFrame.my, -27, 5)
        scroll.ScrollBar.scrollStep = BG.scrollStep
        BG.CreateSrollBarBackdrop(scroll.ScrollBar)
        BG.HookScrollBarShowOrHide(scroll)
        scroll:SetScrollChild(f)

        function Y.Pingjia(text)
            local pingjia = text
            if pingjia == 1 then
                pingjia = "|cff00FF00" .. L["好评"] .. RR
            elseif pingjia == 2 then
                pingjia = "|cffFFFF00" .. L["中评"] .. RR
            elseif pingjia == 3 then
                pingjia = "|cffDC143C" .. L["差评"] .. RR
            end
            return pingjia
        end

        function Y.PingjiaColor(text)
            local pingjia = text
            if pingjia == 1 then
                pingjia = "00FF00"
            elseif pingjia == 2 then
                pingjia = "FFFF00"
            elseif pingjia == 3 then
                pingjia = "DC143C"
            end
            return pingjia
        end

        function Y.EscXiuGai()
            if BG.YYMainFrame.my.all.lastHigh then
                BG.YYMainFrame.my.all.lastHigh:Hide()
            end
            BG.YYMainFrame.my.all.lastHigh = nil
            BG.YYMainFrame.my.all.lastNum = nil
            BG.YYMainFrame.new.buttonesc:Hide()
            BG.YYMainFrame.new:SetBackdropBorderColor(1, 1, 1, 1)
            BG.YYMainFrame.new.title:SetText(L["< 新增评价 >"])
            BG.YYMainFrame.new.title:SetTextColor(1, 1, 1, 1)
            BG.YYMainFrame.new.buttonsave:SetText(L["保存评价"])

            BG.YYMainFrame.new.yy:SetText("")
            BG.YYMainFrame.new.name:SetText("")
            BG.YYMainFrame.new.edit:SetText("")
            BG.YYMainFrame.new.pingjia = 2
            BG.YYMainFrame.new.pingjiaButtons[1]:SetChecked(false)
            BG.YYMainFrame.new.pingjiaButtons[2]:SetChecked(true)
            BG.YYMainFrame.new.pingjiaButtons[3]:SetChecked(false)

            -- BG.YYMainFrame.new.yy:SetEnabled(true)

            for _, edit in pairs(Y.textcolor_table) do
                edit:SetTextColor(1, 1, 0)
            end
            BG.ClearFocus()
        end

        function Y.XiuGai(self, new)
            local num
            if new == "new" then
                num = BG.YYMainFrame.new.yy.num
            else
                num = self.num
            end
            if not num then return end
            if BG.YYMainFrame.my.all.lastHigh then
                BG.YYMainFrame.my.all.lastHigh:Hide()
            end
            BG.YYMainFrame.my.all.lastHigh = BG.YYMainFrame.my.all.button[num].dsHigh
            BG.YYMainFrame.my.all.lastHigh:Show()
            BG.YYMainFrame.my.all.lastNum = num
            BG.YYMainFrame.new.buttonesc:Show()
            BG.YYMainFrame.new:SetBackdropBorderColor(RGB("00BFFF", 1))
            BG.YYMainFrame.new.title:SetText(L["< 修改评价 >"])
            BG.YYMainFrame.new.title:SetTextColor(RGB("00BFFF"))
            BG.YYMainFrame.new.buttonsave:SetText(L["保存修改"])

            BG.YYMainFrame.new.yy:SetText(BiaoGe.YYdb.all[num].yy)
            BG.YYMainFrame.new.name:SetText(BiaoGe.YYdb.all[num].name)
            BG.YYMainFrame.new.edit:SetText(BiaoGe.YYdb.all[num].edit)
            BG.YYMainFrame.new.pingjia = BiaoGe.YYdb.all[num].pingjia
            BG.YYMainFrame.new.pingjiaButtons[1]:SetChecked(false)
            BG.YYMainFrame.new.pingjiaButtons[2]:SetChecked(false)
            BG.YYMainFrame.new.pingjiaButtons[3]:SetChecked(false)
            BG.YYMainFrame.new.pingjiaButtons[BiaoGe.YYdb.all[num].pingjia]:SetChecked(true)

            -- BG.YYMainFrame.new.yy:SetEnabled(false)
            BG.YYMainFrame.new.edit:SetFocus()
            BG.YYMainFrame.new.yy.num = nil

            for _, edit in pairs(Y.textcolor_table) do
                edit:SetTextColor(RGB(Y.PingjiaColor(BiaoGe.YYdb.all[num].pingjia)))
            end
        end

        local function OnEnter(self)
            BG.YYMainFrame.my.all.button[self.num].ds:Show()
            if not self.onenter then return end
            local r, g, b = self.Text:GetTextColor()
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self.onenter, r, g, b, true)
            GameTooltip:Show()
        end
        local function OnLeave(self)
            BG.YYMainFrame.my.all.button[self.num].ds:Hide()
            GameTooltip:Hide()
        end
        local function OnMouseDown(self, enter)
            if IsAltKeyDown() and enter == "RightButton" then -- 删除评价
                tremove(BiaoGe.YYdb.all, self.num)
                Y.SetAll()
                Y.EscXiuGai()
            elseif not IsAltKeyDown() and enter == "LeftButton" then -- 修改评价
                if BG.YYMainFrame.my.all.lastHigh == BG.YYMainFrame.my.all.button[self.num].dsHigh then
                    Y.EscXiuGai()
                else
                    Y.XiuGai(self)
                end
            end
            BG.PlaySound(1)
        end
        function Y.SetAll()
            -- 先隐藏之前的列表内容
            for i, v in pairs(BG.YYMainFrame.my.all.button) do
                v:Hide()
                v:SetParent(nil)
            end
            BG.YYMainFrame.my.all.button = {}
            local n = 1
            -- 再开始创建新的内容
            for ii, _ in ipairs(BiaoGe.YYdb.all) do
                local right
                for i, _ in ipairs(title_table) do
                    local f = CreateFrame("Frame", nil, right or BG.YYMainFrame.my.all)
                    f:SetSize(title_table[i].width, 20)
                    if i == 1 then
                        f:SetPoint("TOPLEFT", BG.YYMainFrame.my.all, "TOPLEFT", 10, -(n - 1) * height)
                        BG.YYMainFrame.my.all.button[ii] = f
                    else
                        f:SetPoint("TOPLEFT", right, "TOPRIGHT", 0, 0)
                    end
                    right = f
                    f.num = ii
                    f.Text = f:CreateFontString()
                    f.Text:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                    f.Text:SetWidth(f:GetWidth() - 3)
                    f.Text:SetPoint("CENTER")
                    local date    = BiaoGe.YYdb.all[ii].date
                    date          = strsub(date, 1, 2) .. "/" .. strsub(date, 3, 4) .. "/" .. strsub(date, 5, 6)
                    local i_table = { ii, date, BiaoGe.YYdb.all[ii].yy, BiaoGe.YYdb.all[ii].name, Y.Pingjia(BiaoGe.YYdb.all[ii].pingjia),
                        BiaoGe.YYdb.all[ii].edit }
                    f.Text:SetText(i_table[i])
                    f.Text:SetWordWrap(false)
                    if f.Text:GetStringWidth() + 3 > f:GetWidth() then
                        f.onenter = i_table[i]
                    end
                    if i == #title_table then
                        f.Text:SetJustifyH("LEFT")
                    end

                    f:SetScript("OnMouseDown", OnMouseDown)
                    f:SetScript("OnEnter", OnEnter)
                    f:SetScript("OnLeave", OnLeave)
                end
                -- 底色材质
                f.ds = f:CreateTexture()
                f.ds:SetPoint("TOPLEFT", BG.YYMainFrame.my.all, "TOPLEFT", 2, -(n - 1) * height)
                f.ds:SetPoint("BOTTOMRIGHT", BG.YYMainFrame.my.all, "BOTTOMRIGHT", BG.YYMainFrame.my:GetWidth(), -n * height)
                f.ds:SetColorTexture(1, 1, 1, 0.1)
                f.ds:Hide()
                BG.YYMainFrame.my.all.button[ii].ds = f.ds
                -- 修改评价的材质
                f.dsHigh = f:CreateTexture()
                f.dsHigh:SetPoint("TOPLEFT", BG.YYMainFrame.my.all, "TOPLEFT", 2, -(n - 1) * height)
                f.dsHigh:SetPoint("BOTTOMRIGHT", BG.YYMainFrame.my.all, "BOTTOMRIGHT", BG.YYMainFrame.my:GetWidth(), -n * height)
                f.dsHigh:SetColorTexture(RGB("00BFFF", 0.2))
                f.dsHigh:Hide()
                BG.YYMainFrame.my.all.button[ii].dsHigh = f.dsHigh

                local l = right:CreateLine()
                l:SetColorTexture(RGB("808080", 0.2))
                l:SetStartPoint("TOPLEFT", BG.YYMainFrame.my.all, 5, -n * height)
                l:SetEndPoint("TOPLEFT", BG.YYMainFrame.my.all, BG.YYMainFrame.my:GetWidth() - 8, -n * height)
                l:SetThickness(1)
                n = n + 1
            end
        end

        BG.YYMainFrame.my.all.button = {}
        Y.SetAll()
    end

    -- 把聊天里的YY转换为链接
    local starttime
    local UpdateFrame = CreateFrame("Frame")
    do
        Y.yykey = "[yY]*[yY][：:_/%-%s]*([%d%s][%d%s][%d%s][%d%s]*%d+)"
        Y.yykey2 = "(%d+[%d%s][%d%s][%d%s][%d%s]*)[：:_/%-%s]*[yY][yY]*"
        Y.yykey3 = "[歪]*歪[：:_/%-%s]*([%d%s][%d%s][%d%s][%d%s]*%d+)"
        ns.yykey = Y.yykey

        local function GetMyPingJia(cleanedYY)
            for _, v in ipairs(BiaoGe.YYdb.all) do
                if tonumber(cleanedYY) == tonumber(v.yy) then
                    return v
                end
            end
        end

        local function CreateLink(cleanedYY)
            local color = "00BFFF"
            local myPingJia = GetMyPingJia(cleanedYY)
            if myPingJia then
                local colors = { L["00FF00"], L["FFFF00"], L["DC143C"] }
                color = colors[myPingJia.pingjia] or color
            end
            return "|cff" .. color .. "|Hgarrmission:BiaoGeYY:YY:" .. cleanedYY ..
                "|h[YY:" .. cleanedYY .. "]|h|r"
        end

        local function CreateLinkForGsub(yy)
            return CreateLink(yy:gsub("%s", ""))
        end

        local function ChangSendLink(self, event, msg, player, l, cs, t, flag, channelId, ...)
            if BiaoGe.YYdb.share ~= 1 then return end
            -- 进团5分钟内把团长发送的纯数字转换为超链接
            if starttime and Y.IsLeader(BG.GSN(player)) then
                local cleanedYY = msg:gsub("%s", ""):match("^%d+$")
                if cleanedYY and strlen(cleanedYY) >= 4 then
                    return false, CreateLink(cleanedYY), player, l, cs, t, flag, channelId, ...
                end
            end
            msg = msg:gsub(Y.yykey, CreateLinkForGsub):gsub(Y.yykey2, CreateLinkForGsub):gsub(Y.yykey3, CreateLinkForGsub)
            return false, msg, player, l, cs, t, flag, channelId, ...
        end

        ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", ChangSendLink)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", ChangSendLink)

        hooksecurefunc("SetItemRef", function(link)
            local _, linkType, action, yy = strsplit(":", link)
            if linkType == "BiaoGeYY" and action == "YY" and yy then
                local editBox = ChatEdit_ChooseBoxForSend()
                ChatEdit_ActivateChat(editBox)
                editBox:SetText(yy)
                editBox:HighlightText()
            end
        end)

        local function OnHyperlinkEnter(self, link)
            if not link then return end
            local _, linkType, action, yy = strsplit(":", link)
            if linkType ~= "BiaoGeYY" or action ~= "YY" or not yy then return end

            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine("|cff00BFFFYY:" .. yy .. RR)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(AddTexture("LEFT") .. L["复制该号码"])

            local myPingJia = GetMyPingJia(yy)
            if myPingJia then
                local savedDate = tostring(myPingJia.date or "")
                if strlen(savedDate) == 6 then
                    savedDate = strsub(savedDate, 1, 2) .. "/" .. strsub(savedDate, 3, 4) .. "/" .. strsub(savedDate, 5, 6)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["我的评价："])
                GameTooltip:AddLine(BG.STC_w1(L["日期："]) .. savedDate, 1, 0.82, 0, true)
                GameTooltip:AddLine(BG.STC_w1(L["备注："]) .. (myPingJia.name or ""), 1, 0.82, 0, true)
                GameTooltip:AddLine(BG.STC_w1(L["评价："]) .. Y.Pingjia(myPingJia.pingjia), 1, 0.82, 0, true)
                GameTooltip:AddLine(BG.STC_w1(L["理由："]) .. (myPingJia.edit or ""), 1, 0.82, 0, true)
            end
            GameTooltip:Show()
        end

        local i = 1
        while _G["ChatFrame" .. i] do
            _G["ChatFrame" .. i]:HookScript("OnHyperlinkEnter", OnHyperlinkEnter)
            _G["ChatFrame" .. i]:HookScript("OnHyperlinkLeave", GameTooltip_Hide)
            i = i + 1
        end
    end

    -- 记录团长发过的YY号
    do
        BiaoGe.YYdb.LeaderYY = BiaoGe.YYdb.LeaderYY or {}
        BG.Once("yy", 250509, function()
            wipe(BiaoGe.YYdb.LeaderYY)
        end)

        -- 是否团长/助理
        function Y.IsLeader(playerName)
            if BG.raidRosterInfo and type(BG.raidRosterInfo) == "table" then
                for _, v in ipairs(BG.raidRosterInfo) do
                    if v.rank == 2 and v.name == playerName then -- 团长
                        return true
                    end
                    if v.isML and v.name == playerName then -- 物品分配者
                        return true
                    end
                    if v.rank == 1 and v.name == playerName then -- 助理
                        return true
                    end
                end
            end
        end

        function Y.SaveLeaderYY(yy, playerName)
            local raidMember = {}
            if IsInRaid(1) then
                for _, v in ipairs(BG.raidRosterInfo) do
                    tinsert(raidMember, v.name)
                end
            end
            BiaoGe.YYdb.LeaderYY[yy] = {
                yy = yy,
                time = GetServerTime(),
                name = playerName,
                colorname = SetClassCFF(playerName),
                raidMember = raidMember,
            }
        end

        -- 收集团长YY
        BG.RegisterEvent({ "CHAT_MSG_RAID_WARNING", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_WHISPER" }, function(self, event, msg, playerName, ...)
            if BG.IsSecret(msg) then return end
            if BiaoGe.YYdb.share ~= 1 then return end
            playerName = BG.GSN(playerName)
            if not Y.IsLeader(playerName) then return end
            if starttime then
                msg = gsub(msg, "%s", "")
                local cleanedYY = strmatch(msg, "^%d+$")
                if cleanedYY and strlen(cleanedYY) >= 4 then
                    for k, v in pairs(BiaoGe.YYdb.LeaderYY) do
                        if tonumber(v.yy) == tonumber(cleanedYY) and v.name == playerName then
                            return
                        end
                    end
                    cleanedYY = tonumber(cleanedYY)
                    Y.SaveLeaderYY(cleanedYY, playerName)
                    return
                end
            end
            local cleanedYY = msg:match(Y.yykey)
            if not cleanedYY then
                cleanedYY = msg:match(Y.yykey2)
            end
            if not cleanedYY then return end
            cleanedYY = cleanedYY:gsub("%s", "")
            cleanedYY = tonumber(cleanedYY)
            Y.SaveLeaderYY(cleanedYY, playerName)
        end)

        -- 进团后的x分钟内生效
        BG.RegisterEvent("GROUP_JOINED", function()
            C_Timer.After(0.5, function()
                if IsInRaid(1) then
                    starttime = GetServerTime()
                    UpdateFrame.timeElapsed = 0
                    UpdateFrame:SetScript("OnUpdate", function(self, elapsed)
                        self.timeElapsed = self.timeElapsed + elapsed
                        if self.timeElapsed >= 60 * 10 then
                            starttime = nil
                            self:SetScript("OnUpdate", nil)
                        end
                    end)
                end
            end)
        end)
        -- 退团后失效
        BG.RegisterEvent("GROUP_ROSTER_UPDATE", function()
            C_Timer.After(1, function()
                if not IsInRaid(1) then
                    starttime = nil
                    UpdateFrame:SetScript("OnUpdate", nil)
                end
            end)
        end)
        -- 进了副本则失效
        BG.RegisterEvent("RAID_INSTANCE_WELCOME", function()
            if not starttime then return end
            local FBID = select(8, GetInstanceInfo()) -- 获取副本ID
            for id in pairs(BG.FBIDtable) do
                if tonumber(FBID) == tonumber(id) then
                    starttime = nil
                    UpdateFrame:SetScript("OnUpdate", nil)
                end
            end
        end)

        -- 如果超过x小时就删掉该YY号记录
        local deleteTime = 60 * 60 * 6
        BG.RegisterEvent("PLAYER_ENTERING_WORLD", function()
            for yy, v in pairs(BiaoGe.YYdb.LeaderYY) do
                if GetServerTime() - v.time >= deleteTime then
                    BiaoGe.YYdb.LeaderYY[yy] = nil
                end
            end
        end)

        local dropDown = LibBG:Create_UIDropDownMenu(nil, UIParent)
        BG.ListYYdropDown = dropDown
        function BG.ListYY(edit)
            if not edit:HasFocus() then return end
            if Size(BiaoGe.YYdb.LeaderYY) == 0 then return end

            local channelTypeMenu = {
                {
                    isTitle = true,
                    text = L["团长YY(根据聊天记录生成)"],
                    notCheckable = true,
                },
                {
                    isTitle = true,
                    text = "   ",
                    notCheckable = true,
                },
            }

            for _, v in pairs(BiaoGe.YYdb.LeaderYY) do
                local pingjiaText = ""
                for k, vv in pairs(BiaoGe.YYdb.all) do
                    if v.yy == tonumber(vv.yy) then
                        pingjiaText = format(BG.STC_dis(L["（曾评价为：|cff%s%s|r）"]), Y.PingjiaColor(vv.pingjia), Y.Pingjia(vv.pingjia))
                        break
                    end
                end
                local a = {
                    text = v.yy .. " " .. v.colorname .. pingjiaText,
                    notCheckable = true,
                    func = function()
                        edit:SetText(v.yy)
                        edit:ClearFocus()
                    end
                }
                tinsert(channelTypeMenu, a)
            end
            local a = {
                text = CANCEL,
                notCheckable = true,
                func = function(self)
                    LibBG:CloseDropDownMenus()
                    edit:ClearFocus()
                end,
            }
            tinsert(channelTypeMenu, a)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "BOTTOM", edit, "TOP")
            LibBG:EasyMenu(channelTypeMenu, dropDown, edit, 0, 0, "MENU", 15)
        end
    end

    -- 快速评价
    do
        BG.EndPJ = {}

        function BG.GetLeaderYY()
            -- 是否有团长发的YY
            for yy, v in pairs(BiaoGe.YYdb.LeaderYY) do
                for _, vv in ipairs(BG.raidRosterInfo) do
                    if v.name == vv.name and vv.rank == 2 then
                        return yy
                    end
                end
            end
            -- 是否有物品分配者发的YY
            for yy, v in pairs(BiaoGe.YYdb.LeaderYY) do
                for _, vv in ipairs(BG.raidRosterInfo) do
                    if v.name == vv.name and vv.isML then
                        return yy
                    end
                end
            end
            -- 是否有其他人发的YY
            for yy, v in pairs(BiaoGe.YYdb.LeaderYY) do
                for _, vv in ipairs(BG.raidRosterInfo) do
                    if v.name == vv.name then
                        return yy
                    end
                end
            end
            for yy in pairs(BiaoGe.YYdb.LeaderYY) do
                if BiaoGe.YYdb.LeaderYY[yy].raidMember then
                    local same = 0
                    for _, raidName in ipairs(BiaoGe.YYdb.LeaderYY[yy].raidMember) do
                        if BG.raidRosterName[raidName] then
                            same = same + 1
                        end
                    end
                    if same >= 15 then
                        return yy
                    end
                end
            end
        end

        local showed
        function BG.ShowYYPJ(sender)
            if not showed and BiaoGe.YYdb.share == 1 and not BG.IsML and BG.IsMLByName(sender) then
                local yy = BG.GetLeaderYY()
                if yy then
                    for k, vv in pairs(BiaoGe.YYdb.all) do
                        if tonumber(yy) == tonumber(vv.yy) then
                            return
                        end
                    end
                    showed = true
                    BG.After(1, function()
                        BG.EndPJ.new:Show()
                    end)
                end
            end
        end

        -- UI
        do
            local f = CreateFrame("Frame", "BG.EndPJ.new", UIParent, "BackdropTemplate")
            do
                f:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
                    edgeSize = 32,
                    insets = { left = 3, right = 3, top = 3, bottom = 3 }
                })
                f:SetBackdropColor(0, 0, 0, 0.8)
                f:SetSize(340, 275)
                f:SetPoint("TOP", 0, -300)
                f:SetClampedToScreen(true)
                f:SetFrameStrata("FULLSCREEN_DIALOG")
                f:SetFrameLevel(190)
                f:EnableMouse(true)
                f:SetMovable(true)
                f:Hide()
                BG.EndPJ.new = f
                f:SetScript("OnMouseUp", function(self)
                    self:StopMovingOrSizing()
                end)
                f:SetScript("OnMouseDown", function(self)
                    BG.EndPJ.new.yy:ClearFocus()
                    self:StartMoving()
                end)
                f:SetScript("OnShow", function()
                    BG.EndPJ.new.yy:SetText("")
                    BG.EndPJ.new.name:SetText("")
                    BG.EndPJ.new.edit:SetText("")
                    BG.EndPJ.new.pingjia = 1
                    BG.EndPJ.new.pingjiaButtons[1]:SetChecked(true)
                    BG.EndPJ.new.pingjiaButtons[2]:SetChecked(false)
                    BG.EndPJ.new.pingjiaButtons[3]:SetChecked(false)
                    BG.EndPJ.new.buttonsave:SetEnabled(true)

                    for _, edit in pairs(BG.EndPJ.textcolor_table) do
                        edit:SetTextColor(0, 1, 0)
                    end

                    -- 历遍团长YY记录
                    BG.EndPJ.new.yy:SetText(BG.GetLeaderYY())

                    BG.ClearFocus()
                    BG.PlaySound(2)
                    BG.After(2.5, function()
                        BG.PlaySound("pingjia")
                    end)
                end)
            end
            tinsert(UISpecialFrames, "BG.EndPJ.new")

            -- 大标题
            do
                local t = f:CreateTexture(nil, "ARTWORK")
                t:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")
                t:SetWidth(256)
                t:SetHeight(64)
                t:SetPoint("TOP", f, 0, 12)
                f.texture = t

                local t = f:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetText(L["< 快速评价 >"])
                t:SetPoint("TOP", f.texture, 0, -12)
                t:SetTextColor(1, 1, 1)

                local t = f:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetText(L["请给团长个评价吧！"])
                t:SetPoint("TOP", BG.EndPJ.new, "TOP", 0, -30)
                t:SetTextColor(1, 1, 1)
                t:SetWidth(300)

                local l = f:CreateLine()
                l:SetColorTexture(RGB("808080", 1))
                l:SetStartPoint("BOTTOMLEFT", t, 0, -2)
                l:SetEndPoint("BOTTOMRIGHT", t, 0, -2)
                l:SetThickness(1)
            end

            BG.EndPJ.textcolor_table = {} -- 用于根据所选评价给输入框设置相应颜色
            local height = 22             -- 每行高度
            local height_start = -65
            local n = 0

            -- 小标题
            do
                local text_table = {
                    { name = L["YY："] },
                    { name = L["备注："] },
                    { name = L["评价："] },
                    { name = L["理由："] },
                }
                for i, _ in ipairs(text_table) do
                    local f = CreateFrame("Frame", nil, BG.EndPJ.new)
                    f:SetPoint("TOPLEFT", 5, height_start - height * (i - 1))
                    f:SetSize(85, 20)
                    f.Text = f:CreateFontString()
                    f.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                    f.Text:SetAllPoints()
                    f.Text:SetWordWrap(false)
                    f.Text:SetText(text_table[i].name)
                    f.Text:SetTextColor(1, 1, 0)
                    f.Text:SetJustifyH("RIGHT")
                    tinsert(BG.EndPJ.textcolor_table, f.Text)
                end
            end
            -- YY号
            do
                local edit = CreateFrame("EditBox", nil, BG.EndPJ.new, BG.editTemplate)
                edit:SetSize(190, 20)
                edit:SetPoint("TOPLEFT", 100, height_start - height * n)
                edit:SetAutoFocus(false)
                edit:SetNumeric(true)
                edit:SetTextColor(1, 1, 0)
                tinsert(BG.EndPJ.textcolor_table, edit)
                BG.EndPJ.new.yy = edit
                n = n + 1
                local t = edit:CreateFontString(nil, "ARTWORK")
                t:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                t:SetTextColor(.5, .5, .5)
                t:SetPoint("LEFT", 3, 0)
                t:SetText(L["必填"])
                edit:SetScript("OnEditFocusGained", function(self)
                    BG.ListYY(self)
                end)
                edit:SetScript("OnEditFocusLost", function(self)
                    _G.L_DropDownList1:Hide()
                end)
                edit:SetScript("OnTextChanged", function(self)
                    BG.EndPJ.new.buttonsave:SetEnabled(true)
                    BG.EndPJ.new.buttonsave.dis:Hide()
                    if self:GetText() ~= "" then
                        t:Hide()
                    else
                        t:Show()
                        BG.EndPJ.new.buttonsave:SetEnabled(false)
                        BG.EndPJ.new.buttonsave.dis:Show()
                    end
                    BG.EndPJ.new.havedYY:Hide()
                    for key, value in pairs(BiaoGe.YYdb.all) do
                        if self:GetText() == value.yy then
                            BG.EndPJ.new.havedYY:Show()
                            return
                        end
                    end
                end)
                edit:SetScript("OnEnterPressed", function(self, enter)
                    self:ClearFocus()
                end)
                edit:SetScript("OnMouseDown", function(self, enter)
                    if enter == "RightButton" then
                        self:SetEnabled(false)
                        self:SetText("")
                    end
                end)
                edit:SetScript("OnMouseUp", function(self, enter)
                    if enter == "RightButton" then
                        self:SetEnabled(true)
                    end
                end)
            end
            -- 备注
            do
                local edit = CreateFrame("EditBox", nil, BG.EndPJ.new, BG.editTemplate)
                edit:SetSize(190, 20)
                edit:SetPoint("TOPLEFT", 100, height_start - height * n)
                edit:SetAutoFocus(false)
                edit:SetTextColor(1, 1, 0)
                tinsert(BG.EndPJ.textcolor_table, edit)
                BG.EndPJ.new.name = edit
                n = n + 1
                local t = edit:CreateFontString(nil, "ARTWORK")
                t:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                t:SetTextColor(.5, .5, .5)
                t:SetPoint("LEFT", 3, 0)
                t:SetText(L["选填"])
                t:SetJustifyH("LEFT")
                t:SetWidth(edit:GetWidth() - 5)
                t:SetWordWrap(false)
                edit:SetScript("OnEditFocusGained", function(self)
                    BG.lastfocus = self
                end)
                edit:SetScript("OnTextChanged", function(self)
                    if self:GetText() ~= "" then
                        t:Hide()
                    else
                        t:Show()
                    end
                end)
                edit:SetScript("OnKeyDown", function(self, enter)
                    if enter == "ENTER" or enter == "TAB" then
                        BG.EndPJ.new.edit:SetFocus()
                    end
                end)
                edit:SetScript("OnMouseDown", function(self, enter)
                    if enter == "RightButton" then
                        self:SetEnabled(false)
                        self:SetText("")
                    end
                end)
                edit:SetScript("OnMouseUp", function(self, enter)
                    if enter == "RightButton" then
                        self:SetEnabled(true)
                    end
                end)
            end
            -- 评价
            do
                local PingJiaGroup = CreateFrame("Frame", nil, BG.EndPJ.new)
                PingJiaGroup:SetPoint("TOPLEFT", 100, height_start - height * n)
                PingJiaGroup:SetSize(1, 1)
                local numOptions = {
                    { name = L["好评"], color = "00FF00" },
                    { name = L["中评"], color = "FFFF00" },
                    { name = L["差评"], color = "DC143C" },
                }
                BG.EndPJ.new.pingjiaButtons = {}
                for i = 1, #numOptions do
                    local bt = CreateFrame("CheckButton", nil, PingJiaGroup, "UIRadioButtonTemplate")
                    bt:SetPoint("TOPLEFT", -5 + ((i - 1) * 60), -3)
                    bt:SetSize(15, 15)
                    if i == 2 then
                        bt:SetChecked(true)
                        BG.EndPJ.new.pingjia = i
                    end
                    BG.EndPJ.new.pingjiaButtons[i] = bt

                    bt.Text = bt:CreateFontString()
                    bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                    bt.Text:SetPoint("LEFT", bt, "RIGHT", 0, 0)
                    bt.Text:SetText(numOptions[i].name)
                    bt.Text:SetTextColor(RGB(numOptions[i].color))
                    bt:SetHitRectInsets(0, -bt.Text:GetWidth(), -5, -5)

                    bt:SetScript("OnClick", function(self)
                        for _, radioButton in ipairs(BG.EndPJ.new.pingjiaButtons) do
                            if radioButton ~= self then
                                radioButton:SetChecked(false)
                            end
                        end
                        for _, edit in pairs(BG.EndPJ.textcolor_table) do
                            edit:SetTextColor(RGB(numOptions[i].color))
                        end
                        self:SetChecked(true)
                        BG.EndPJ.new.pingjia = i

                        BG.PlaySound(1)
                    end)
                end
                n = n + 1
            end
            -- 理由
            do
                local maxbytes = 200
                local f = CreateFrame("Frame", nil, BG.EndPJ.new, "BackdropTemplate")
                f:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                    edgeSize = 16,
                    insets = { left = 3, right = 3, top = 3, bottom = 3 }
                })
                f:SetBackdropColor(0, 0, 0, 0.2)
                f:SetBackdropBorderColor(1, 1, 1, 0.6)
                f:SetSize(200, height * 2)
                f:SetPoint("TOPLEFT", 95, height_start - height * n - 2)
                local edit = CreateFrame("EditBox", nil, f)
                edit:SetWidth(f:GetWidth())
                edit:SetAutoFocus(false)
                edit:SetMaxBytes(maxbytes)
                edit:EnableMouse(true)
                edit:SetTextInsets(0, 10, 0, 5)
                edit:SetMultiLine(true)
                edit:SetTextColor(1, 1, 0)
                edit:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                tinsert(BG.EndPJ.textcolor_table, edit)
                BG.EndPJ.new.edit = edit
                local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
                scroll:SetWidth(f:GetWidth() - 10)
                scroll:SetHeight(f:GetHeight() - 10)
                scroll:SetPoint("CENTER")
                scroll.ScrollBar.scrollStep = BG.scrollStep
                BG.CreateSrollBarBackdrop(scroll.ScrollBar)
                BG.HookScrollBarShowOrHide(scroll)
                scroll:SetScrollChild(edit)
                n = n + 2

                local leftt = f:CreateFontString(nil, "ARTWORK")
                leftt:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                leftt:SetTextColor(.5, .5, .5)
                leftt:SetPoint("TOPLEFT", 7, -5)
                leftt:SetText(L["选填"])

                edit:SetScript("OnTextChanged", function(self)
                    if self:GetText() ~= "" then
                        leftt:Hide()
                    else
                        leftt:Show()
                    end
                end)
                edit:SetScript("OnEscapePressed", function(self)
                    self:ClearFocus()
                end)
                edit:SetScript("OnEnterPressed", function(self)
                    self:ClearFocus()
                end)
                edit:SetScript("OnMouseDown", function(self, enter)
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
                f:SetScript("OnMouseDown", function(self, enter)
                    if enter == "RightButton" then
                        edit:SetEnabled(false)
                        edit:SetText("")
                    else
                        edit:SetFocus()
                    end
                end)
                f:SetScript("OnMouseUp", function(self, enter)
                    if enter == "RightButton" then
                        edit:SetEnabled(true)
                    end
                end)
            end
            -- 短词
            do
                local goodTbl = {
                    L["指挥很好"],
                    L["非常效率"],
                    L["没有团双"],
                    L["稳如老狗"],
                    L["又快又黑=。="],
                }
                local badTbl = {
                    L["指挥很烂"],
                    L["拼多多团"],
                    L["强X装备"],
                    L["黑金"],
                    L["毛装备"],
                    L["只罚野人不罚亲友"],
                }
                local f1 = CreateFrame("Frame", nil, BG.EndPJ.new)
                f1:SetPoint("BOTTOM", BG.EndPJ.new, -5, 73)
                f1:SetHeight(18)
                f1.buttons = {}
                f1.width = 0
                f1.r, f1.g, f1.b = 0, 1, 0

                local f2 = CreateFrame("Frame", nil, BG.EndPJ.new)
                f2:SetPoint("BOTTOM", BG.EndPJ.new, -5, 50)
                f2:SetHeight(18)
                f2.buttons = {}
                f2.width = 0
                f2.r, f2.g, f2.b = 1, 0, 0

                local function CreateButton(f, text)
                    local r, g, b = f.r, f.g, f.b
                    local r, g, b = 1, 1, 1
                    local bt = CreateFrame("Button", nil, f, "BackdropTemplate")
                    bt:SetBackdrop({
                        bgFile = "Interface/ChatFrame/ChatFrameBackground",
                    })
                    bt:SetBackdropColor(r, g, b, .2)
                    bt:SetSize(0, 18)
                    if #f.buttons == 0 then
                        bt:SetPoint("LEFT")
                    else
                        bt:SetPoint("LEFT", f.buttons[#f.buttons], "RIGHT", 3, 0)
                    end
                    tinsert(f.buttons, bt)
                    local t = bt:CreateFontString()
                    t:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                    t:SetPoint("CENTER")
                    t:SetTextColor(r, g, b)
                    t:SetText(text)
                    bt:SetFontString(t)
                    bt:SetWidth(t:GetWrappedWidth() + 2)
                    f.width = f.width + bt:GetWidth()
                    f:SetWidth(f.width)

                    bt:SetScript("OnClick", function()
                        BG.PlaySound(1)
                        BG.EndPJ.new.edit:Insert(text .. " ")
                    end)
                    bt:SetScript("OnEnter", function(self)
                        bt:SetBackdropColor(1, 1, 1, .2)
                        t:SetTextColor(1, 1, 1)
                    end)
                    bt:SetScript("OnLeave", function(self)
                        bt:SetBackdropColor(r, g, b, .2)
                        t:SetTextColor(r, g, b)
                    end)
                end
                for i, text in ipairs(goodTbl) do
                    CreateButton(f1, text)
                end
                for i, text in ipairs(badTbl) do
                    CreateButton(f2, text)
                end
            end
            -- 保存
            do
                function OnClick(self)
                    if not BG.EndPJ.new.buttonsave:IsEnabled() then return end

                    local new = BG.EndPJ.new
                    if not new.pingjia then return end
                    if new.yy:GetText() == "" or new.yy:GetText() == 0 then return end

                    for i = #BiaoGe.YYdb.all, 1, -1 do
                        if new.yy:GetText() == BiaoGe.YYdb.all[i].yy then
                            tremove(BiaoGe.YYdb.all, i)
                        end
                    end

                    local a = {
                        date = tonumber(date("%y%m%d", GetServerTime())),
                        yy = new.yy:GetText(),
                        name = new.name:GetText(),
                        pingjia = new.pingjia,
                        edit = new.edit:GetText(),
                    }
                    tinsert(BiaoGe.YYdb.all, 1, a)

                    Y.SetAll()
                    Y.EscXiuGai()
                    BG.EndPJ.new:Hide()

                    local liyou = ""
                    if BG.EndPJ.new.edit:GetText() ~= "" then
                        liyou = L["（"] .. BG.EndPJ.new.edit:GetText() .. L["）"]
                    end
                    SendSystemMessage(BG.BG .. format(L["|cff%s感谢你的评价：YY%s，>>%s<<%s。|r"],
                        Y.PingjiaColor(a.pingjia), a.yy, Y.Pingjia(a.pingjia), liyou))

                    BG.PlaySound(1)
                end

                local bt = CreateFrame("Button", nil, BG.EndPJ.new, "UIPanelButtonTemplate")
                bt:SetSize(115, 25)
                bt:SetPoint("BOTTOMRIGHT", BG.EndPJ.new, "BOTTOM", -5, 20)
                bt:SetText(L["保存"])
                BG.EndPJ.new.buttonsave = bt
                bt:SetScript("OnClick", OnClick)

                local f = CreateFrame("Frame", nil, bt)
                f:SetAllPoints()
                f.dis = true
                f.bt = bt
                f:Hide()
                bt.dis = f
                f:SetScript("OnEnter", function(self)
                    if BG.EndPJ.new.yy:GetText() == "" then
                        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(bt:GetText(), 1, 1, 1, true)
                        GameTooltip:AddLine(L["未填写YY，不能保存。"], 1, 0, 0, true)
                        GameTooltip:Show()
                    end
                end)
                f:SetScript("OnLeave", GameTooltip_Hide)
            end
            -- 取消
            do
                local bt = CreateFrame("Button", nil, BG.EndPJ.new, "UIPanelButtonTemplate")
                bt:SetSize(115, 25)
                bt:SetPoint("BOTTOMLEFT", BG.EndPJ.new, "BOTTOM", 5, 20)
                bt:SetText(L["退出"])
                BG.EndPJ.new.escsave = bt
                bt:SetScript("OnClick", function()
                    BG.EndPJ.new:Hide()
                    BG.PlaySound(1)
                end)
            end
            -- 底下文字
            do
                local t = f:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetPoint("TOP", f, "BOTTOM", 0, 0)
                t:SetTextColor(1, 0, 0)
                t:SetText(L["你已给该YY写过评价！"])
                t:Hide()
                BG.EndPJ.new.havedYY = t
            end
        end
    end

    -- YY评价功能是否关闭
    do
        local t = BG.YYMainFrame:CreateFontString()
        t:SetPoint("TOP", BG.MainFrame, "TOP", 0, -50)
        t:SetFont(BIAOGE_TEXT_FONT, 20, "OUTLINE")
        t:SetTextColor(1, 0, 0)
        t:SetText(L["该模块已被禁用"])

        function BG.YYShowHide()
            if BiaoGe.YYdb.share == 1 then
                BG.YYMainFrame.new:Show()
                BG.YYMainFrame.my:Show()
                t:Hide()
            else
                BG.YYMainFrame.new:Hide()
                BG.YYMainFrame.my:Hide()
                t:Show()
            end
            Y:UpdateCloseYYButton()
        end

        function Y:UpdateCloseYYButton()
            local mainFrame = BG.YYMainFrame
            if not Y.closeYYButton then
                Y.closeYYButton = BG.CreateButton(mainFrame)
                Y.closeYYButton:SetSize(150, 25)
                Y.closeYYButton:SetPoint("RIGHT", mainFrame.backBiaoGeButton, "LEFT", -20, 0)
            end
            local show = BiaoGe.YYdb.share
            if show == 1 then
                Y.closeYYButton:SetText(L["禁用该模块"])
                Y.closeYYButton:SetScript("OnClick", function(self)
                    BiaoGe.YYdb.share = 0
                    BG.YYShowHide()
                    BG.PlaySound(1)
                end)
            else
                Y.closeYYButton:SetText(L["开启该模块"])
                Y.closeYYButton:SetScript("OnClick", function(self)
                    StaticPopupDialogs["BiaoGe_OpenYY"] = {
                        text = L["开启该模块需要重载游戏。\n现在立刻重载吗？"],
                        button1 = L["是"],
                        button2 = L["否"],
                        OnAccept = function()
                            BiaoGe.YYdb.share = 1
                            ReloadUI()
                        end,
                        OnCancel = function()
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        showAlert = true,
                    }
                    StaticPopup_Show("BiaoGe_OpenYY")
                end)
            end
        end
        BG.YYShowHide()
    end
end)
