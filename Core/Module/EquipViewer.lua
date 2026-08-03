local _, ns = ...

local L = ns.L
local GetClassColor = ns.GetClassColor
local GetClassName = ns.GetClassName

BG.Init(function()
    -- 多角色装备
    local mainFrame, leftFrame, rightFrame, slotTbl
    local iLevelColor
    local enchantCount
    local gemInfo = {}
    if BG.IsVanilla then
        enchantCount = {
            INVTYPE_HEAD = 1,           -- 头
            INVTYPE_SHOULDER = 1,       -- 肩膀
            INVTYPE_CHEST = 1,          -- 胸
            INVTYPE_ROBE = 1,           -- 胸
            INVTYPE_LEGS = 1,           -- 腿
            INVTYPE_FEET = 1,           -- 脚
            INVTYPE_WRIST = 1,          -- 手腕
            INVTYPE_HAND = 1,           -- 手
            INVTYPE_2HWEAPON = 1,       -- 双手武器
            INVTYPE_WEAPON = 1,         -- 单手武器
            INVTYPE_WEAPONMAINHAND = 1, -- 主手武器
            INVTYPE_WEAPONOFFHAND = 1,  -- 副手武器
            INVTYPE_SHIELD = 1,         -- 盾牌
            INVTYPE_RANGED = 1,         -- 远程武器
            INVTYPE_CLOAK = 1,          -- 披风
        }
    elseif BG.IsTBC then
        enchantCount = {
            INVTYPE_HEAD = 1,           -- 头
            INVTYPE_SHOULDER = 1,       -- 肩膀
            INVTYPE_CHEST = 1,          -- 胸
            INVTYPE_ROBE = 1,           -- 胸
            INVTYPE_LEGS = 1,           -- 腿
            INVTYPE_FEET = 1,           -- 脚
            INVTYPE_WRIST = 1,          -- 手腕
            INVTYPE_HAND = 1,           -- 手
            INVTYPE_2HWEAPON = 1,       -- 双手武器
            INVTYPE_WEAPON = 1,         -- 单手武器
            INVTYPE_WEAPONMAINHAND = 1, -- 主手武器
            INVTYPE_WEAPONOFFHAND = 1,  -- 副手武器
            INVTYPE_SHIELD = 1,         -- 盾牌
            INVTYPE_RANGED = 1,         -- 远程武器
            INVTYPE_CLOAK = 1,          -- 披风
            INVTYPE_FINGER = { id = 333, level = 360 }
        }
    elseif BG.IsWLK then
        enchantCount = {
            INVTYPE_HEAD = 1,           -- 头
            INVTYPE_SHOULDER = 1,       -- 肩膀
            INVTYPE_CHEST = 1,          -- 胸
            INVTYPE_ROBE = 1,           -- 胸
            INVTYPE_LEGS = 1,           -- 腿
            INVTYPE_FEET = 1,           -- 脚
            INVTYPE_WRIST = 1,          -- 手腕
            INVTYPE_HAND = 1,           -- 手
            INVTYPE_2HWEAPON = 1,       -- 双手武器
            INVTYPE_WEAPON = 1,         -- 单手武器
            INVTYPE_WEAPONMAINHAND = 1, -- 主手武器
            INVTYPE_WEAPONOFFHAND = 1,  -- 副手武器
            INVTYPE_SHIELD = 1,         -- 盾牌
            INVTYPE_RANGED = 1,         -- 远程武器
            INVTYPE_CLOAK = 1,          -- 披风
            INVTYPE_FINGER = { id = 333, level = 400 }
            -- INVTYPE_NECK = 1,           -- 项链
            -- INVTYPE_WAIST = 1,          -- 腰
            -- INVTYPE_HOLDABLE = 1,       -- 副手
            -- INVTYPE_RANGEDRIGHT = 1,    -- 魔杖
        }
        gemInfo = {
            INVTYPE_WRIST = { id = 164, level = 400 }, -- 手腕
            INVTYPE_HAND = { id = 164, level = 400 },  -- 手
        }
    else
        enchantCount = {
            -- INVTYPE_HEAD = 1,           -- 头
            INVTYPE_SHOULDER = 1,       -- 肩膀
            INVTYPE_CHEST = 1,          -- 胸
            INVTYPE_ROBE = 1,           -- 胸
            INVTYPE_LEGS = 1,           -- 腿
            INVTYPE_FEET = 1,           -- 脚
            INVTYPE_WRIST = 1,          -- 手腕
            INVTYPE_HAND = 1,           -- 手
            INVTYPE_2HWEAPON = 1,       -- 双手武器
            INVTYPE_WEAPON = 1,         -- 单手武器
            INVTYPE_WEAPONMAINHAND = 1, -- 主手武器
            INVTYPE_WEAPONOFFHAND = 1,  -- 副手武器
            INVTYPE_SHIELD = 1,         -- 盾牌
            INVTYPE_RANGED = 1,         -- 远程武器
            INVTYPE_CLOAK = 1,          -- 披风
            INVTYPE_FINGER = { id = 333, level = 550 }
            -- INVTYPE_NECK = 1,           -- 项链
            -- INVTYPE_WAIST = 1,          -- 腰
            -- INVTYPE_HOLDABLE = 1,       -- 副手
            -- INVTYPE_RANGEDRIGHT = 1,    -- 魔杖
        }
        gemInfo = {
            INVTYPE_WRIST = { id = 164, level = 550 }, -- 手腕
            INVTYPE_HAND = { id = 164, level = 550 },  -- 手
        }
    end

    local function SetiLevelColor(level)
        if iLevelColor then
            for i = #iLevelColor, 1, -1 do
                if level >= iLevelColor[i] then
                    local r, g, b = GetItemQualityColor(i)
                    return r, g, b
                end
            end
        end
        return 1, 1, 1
    end
    local function GetGemCount(link)
        local count = 0
        local stats = GetItemStats(link)
        if stats then
            for stat, _count in pairs(stats) do
                if stat:find("EMPTY_SOCKET_") then
                    count = count + _count
                end
            end
        end
        return count
    end
    local function ItemNeedEnchant(equipLoc, skill)
        local info = enchantCount[equipLoc]
        local _type = type(info)
        if _type == 'number' then
            return info
        elseif _type == "table" and skill and skill[info.id] and skill[info.id].level >= info.level then
            return 1
        end
        return false
    end
    local function ItemNeedGem(equipLoc, link, skill)
        local gemCount = GetGemCount(link)
        if BG.verOver3 and equipLoc == "INVTYPE_WAIST" then
            gemCount = gemCount + 1
        elseif skill then
            local info = gemInfo[equipLoc]
            if info and skill[info.id] and skill[info.id].level >= info.level then
                gemCount = gemCount + 1
            end
        end
        return gemCount
    end
    function BG.GetEnchantInfo(link, skill)
        if not link then return end
        local itemID, chant, gem1, gem2, gem3, gem4 = link:match("item:(%d+):(%d-):(%d-):(%d-):(%d-):")
        if itemID then itemID = tonumber(itemID) end
        if chant then chant = tonumber(chant) end
        if gem1 then gem1 = tonumber(gem1) end
        if gem2 then gem2 = tonumber(gem2) end
        if gem3 then gem3 = tonumber(gem3) end
        if gem4 then gem4 = tonumber(gem4) end
        local equipLoc = select(4, GetItemInfoInstant(itemID))
        return chant, ItemNeedEnchant(equipLoc, skill), { gem1, gem2, gem3, gem4 }, ItemNeedGem(equipLoc, link, skill), equipLoc, itemID
    end

    local function CreateMainFrame()
        local r, g, b = GetClassColor(select(2, UnitClass("player")))
        local f = CreateFrame("Frame", nil, nil)
        f:SetSize(1, 350)
        f:SetToplevel(true)
        f:SetFrameStrata("HIGH")
        mainFrame = f
        BG.equipFrame = f
        f:SetScript("OnHide", function(self)
            self.realmID = nil
            self.player = nil
            self.click = nil
            self:Hide()
        end)

        -- leftFrame
        do
            -- 框架
            do
                local f = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
                f:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = 16,
                    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                    insets = { left = 3, right = 3, top = 3, bottom = 3 }
                })
                f:SetBackdropColor(0, 0, 0, 0.8)
                f:SetBackdropBorderColor(r, g, b, 1)
                f:SetPoint("TOPLEFT")
                f:SetSize(280, mainFrame:GetHeight())
                leftFrame = f

                mainFrame.CloseButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
                mainFrame.CloseButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)

                local tex = f:CreateTexture()
                tex:SetPoint("TOPLEFT", 8, -6)
                tex:SetSize(16, 16)
                tex:SetTexture("Interface\\AddOns\\BiaoGe\\Media\\icon\\icon.tga")
                tex:SetTexCoord(.1, .9, .1, .9)

                local l = leftFrame:CreateLine()
                l:SetColorTexture(r, g, b, 1)
                l:SetStartPoint("TOPLEFT", 5, -25)
                l:SetEndPoint("TOPRIGHT", -5, -25)
                l:SetThickness(1)
                leftFrame.line = l

                local t = leftFrame:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetPoint("CENTER", leftFrame, "TOP", 0, -14)
                t:SetTextColor(1, 1, 1)
                leftFrame.NameText = t

                local t = leftFrame:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                t:SetPoint("TOP", leftFrame, "TOP", 0, -30)
                t:SetTextColor(1, .82, 0)
                leftFrame.LevelText = t

                local t = leftFrame:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                t:SetPoint("TOP", leftFrame, "TOP", 0, -50)
                t:SetTextColor(1, .82, 0)
                leftFrame.iLevelText = t

                leftFrame.setFrame = CreateFrame("Frame", nil, leftFrame)
                leftFrame.setFrame:SetPoint("BOTTOM", leftFrame, "BOTTOM", 0, 50)
                leftFrame.setFrame:SetSize(1, 1)
                leftFrame.sets = {}

                local t = leftFrame:CreateFontString(nil, "OVERLAY")
                t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                t:SetPoint("BOTTOMLEFT", leftFrame, "TOPLEFT", 5, 0)
                t:SetTextColor(1, .82, 0)
                t:SetWidth(leftFrame:GetWidth() - 10)
                t:SetJustifyH("LEFT")
                leftFrame.accountText = t
            end

            -- WLK传家宝附魔
            if BG.IsWLK then
                local tbl
                if BG.IsTitan then
                    tbl = {
                        50369, 44136, -- T
                        50367, 44133, -- 物理
                        50368, 44135, -- 法系
                        44152, 44134, -- N
                    }
                elseif BG.IsWLK_80 then
                    tbl = {
                        44150, 44136, -- T
                        44149, 44133, -- 物理
                        44159, 44135, -- 法系
                        44152, 44134, -- N
                    }
                end
                leftFrame.enchantButtons = {}
                local function CreateButton(itemID)
                    local bt = CreateFrame("Button", nil, leftFrame, "BackdropTemplate")
                    bt:SetBackdrop({
                        edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                        edgeSize = 1.5,
                    })
                    bt.borderColorBG = { r, g, b, 1 }
                    bt:SetSize(28, 28)
                    if next(leftFrame.enchantButtons) then
                        local i = #leftFrame.enchantButtons
                        bt:SetPoint("TOPLEFT", leftFrame.enchantButtons[i], "TOPRIGHT", i % 2 == 0 and 10 or 2, 0)
                    else
                        bt:SetPoint("TOPLEFT", leftFrame, "BOTTOMLEFT", 10, -0)
                    end
                    bt.itemID = itemID
                    bt:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
                    tinsert(leftFrame.enchantButtons, bt)

                    bt.icon = bt:CreateTexture(nil, "BACKGROUND", nil, 1)
                    bt.icon:SetAllPoints()
                    bt.icon:SetTexture(select(5, GetItemInfoInstant(itemID)))
                    bt.icon:SetTexCoord(unpack(BG.iconTexCoord))

                    bt.countText = bt:CreateFontString()
                    bt.countText:SetFont(BIAOGE_TEXT_FONT, 18, "OUTLINE")
                    bt.countText:SetPoint("BOTTOM", 0, 1)
                    bt.countText:SetTextColor(0, 1, 0)
                    bt.count = 0

                    bt:SetScript("OnEnter", function(self)
                        if BG.ButtonIsInRight(self) then
                            GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
                        else
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                        end
                        GameTooltip:ClearLines()
                        GameTooltip:SetHyperlink(self.link)
                    end)
                    bt:SetScript("OnLeave", GameTooltip_Hide)

                    function bt:Update()
                        bt:Show()
                        if self.count > 0 then
                            self:SetAlpha(1)
                            if self.borderColorBG then
                                self:SetBackdropBorderColor(unpack(self.borderColorBG))
                            end
                            self.icon:SetDesaturated(false)
                            self.countText:SetText(self.count)
                        else
                            self:SetAlpha(.5)
                            self:SetBackdropBorderColor(.5, .5, .5)
                            self.icon:SetDesaturated(true)
                            self.countText:SetText("")
                        end
                    end

                    local item = Item:CreateFromItemID(itemID)
                    item:ContinueOnItemLoad(function()
                        local _, link, quality = GetItemInfo(itemID)
                        local r, g, b = GetItemQualityColor(quality)
                        bt.borderColorBG = { r, g, b, 1 }
                        bt.link = link
                        bt:Update()
                    end)
                end
                for i, itemID in ipairs(tbl) do
                    CreateButton(itemID)
                end
            end

            -- 装备槽位
            slotTbl = {
                { slot = "Headslot", point = { "TOPLEFT", leftFrame, "TOPLEFT", 8, -30 } },
                { slot = "NeckSlot", point = "down" },
                { slot = "ShoulderSlot", point = "down" },
                { slot = "BackSlot", point = "down" },
                { slot = "ChestSlot", point = "down" },
                { slot = "ShirtSlot", point = "down" },
                { slot = "TabardSlot", point = "down" }, -- slotID=19
                { slot = "WristSlot", point = "down" },
                { slot = "HandsSlot", point = { "TOPRIGHT", leftFrame, "TOPRIGHT", -8, -30 } },
                { slot = "WaistSlot", point = "down" },
                { slot = "LegsSlot", point = "down" },
                { slot = "FeetSlot", point = "down" },
                { slot = "Finger0Slot", point = "down" },
                { slot = "Finger1Slot", point = "down" },
                { slot = "Trinket0Slot", point = "down" },
                { slot = "Trinket1Slot", point = "down" },
            }
            if BG.IsMOP then
                tinsert(slotTbl, { slot = "MainHandSlot", point = { "BOTTOmRIGHT", leftFrame, "BOTTOM", 0, 8 } })
                tinsert(slotTbl, { slot = "SecondaryHandSlot", point = "right" })
            else
                tinsert(slotTbl, { slot = "MainHandSlot", point = { "BOTTOMLEFT", leftFrame, "BOTTOMLEFT", leftFrame:GetWidth() / 2 - 53, 8 } })
                tinsert(slotTbl, { slot = "SecondaryHandSlot", point = "right" })
                tinsert(slotTbl, { slot = "RangedSlot", point = "right" })
            end
            local function GetSlotPoint(slot)
                for k, v in pairs(slotTbl) do
                    if v.slot == slot then
                        return v.point
                    end
                end
            end
            local lastButton
            local function CreateSlot(slot)
                local slotID, textureName = GetInventorySlotInfo(slot)
                local bt = CreateFrame("Button", nil, leftFrame, "BackdropTemplate")
                bt:SetBackdrop({
                    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = 1.5,
                })
                bt.borderColorBG = { .3, .3, .3, 1 }
                bt:SetBackdropBorderColor(unpack(bt.borderColorBG))
                bt:SetSize(35, 35)
                local point = GetSlotPoint(slot)
                if type(point) == "table" then
                    bt:SetPoint(unpack(point))
                elseif point == "down" then
                    bt:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -3)
                elseif point == "right" then
                    bt:SetPoint("TOPLEFT", lastButton, "TOPRIGHT", 3, 0)
                end
                bt.ID = slotID
                bt.textureBG = textureName
                leftFrame["slot" .. slotID] = bt
                lastButton = bt
                bt.icon = bt:CreateTexture(nil, "BACKGROUND", nil, 1)
                bt.icon:SetAllPoints()
                bt.icon:SetTexture(textureName)
                bt.icon:SetTexCoord(unpack(BG.iconTexCoord))
                bt:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])

                bt.level = bt:CreateFontString()
                bt.level:SetFont(BIAOGE_TEXT_FONT, 12.5, "OUTLINE")
                bt.level:SetPoint("BOTTOM", 0, 1)

                bt:SetScript("OnEnter", function(self)
                    if not bt.link then return end
                    if BG.ButtonIsInRight(self) then
                        GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
                    else
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                    end
                    GameTooltip:ClearLines()
                    GameTooltip:SetHyperlink(bt.link)
                end)
                bt:SetScript("OnLeave", GameTooltip_Hide)
            end
            for _, v in ipairs(slotTbl) do
                CreateSlot(v.slot)
            end
        end

        -- rightFrame
        do
            -- 框架
            local f = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 16,
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            f:SetBackdropColor(0, 0, 0, 0.8)
            f:SetBackdropBorderColor(r, g, b, 1)
            f:SetPoint("TOPLEFT", leftFrame, "TOPRIGHT", -2, 0)
            f:SetSize(1, mainFrame:GetHeight())
            f.slotButtons = {}
            rightFrame = f

            local t = f:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("BOTTOM", f, "TOP", 0, 0)
            t:SetTextColor(1, 0.82, 0)
            t:SetText(L["点击角色名字：使面板固定显示"])
            mainFrame.tipText = t

            -- 装备列表
            local lastButton
            local function CreateButton(slot)
                local slotID = GetInventorySlotInfo(slot)
                local frame = CreateFrame("Frame", nil, rightFrame, "BackdropTemplate")
                frame:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                })
                frame:SetBackdropColor(1, 1, 1, 0)
                frame:SetSize(1, 19.5)
                if lastButton then
                    frame:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, 0)
                else
                    frame:SetPoint("TOPLEFT", rightFrame, "TOPLEFT", 10, -10)
                end
                frame:EnableMouse(true)
                frame.otherButtons = {}
                lastButton = frame
                rightFrame["slot" .. slotID] = frame
                tinsert(rightFrame.slotButtons, frame)
                frame:SetScript("OnEnter", function(self)
                    if not frame.link then return end
                    if BG.ButtonIsInRight(self.item) then
                        GameTooltip:SetOwner(self.item, "ANCHOR_LEFT", 0, 0)
                    else
                        GameTooltip:SetOwner(self.item, "ANCHOR_RIGHT", 0, 0)
                    end
                    GameTooltip:ClearLines()
                    GameTooltip:SetHyperlink(frame.link)
                    self:SetBackdropColor(1, 1, 1, .1)
                end)
                frame:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                    self:SetBackdropColor(1, 1, 1, 0)
                end)

                local f = CreateFrame("Frame", nil, frame, "BackdropTemplate")
                f:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = 1,
                })
                f.baseDropColor = { .5, .5, .5, .05 }
                f.baseBorderColor = { .5, .5, .5, .2 }
                f:SetPoint("LEFT")
                f:SetSize(30, 17)
                frame.bg = f

                frame.slot = f:CreateFontString()
                frame.slot:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
                frame.slot:SetPoint("CENTER", f, "CENTER", 0, 0)
                frame.slot:SetText(_G[slot:upper()])
                frame.slot.baseColor = { .5, .5, .5 }

                frame.level = frame:CreateFontString()
                frame.level:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                frame.level:SetPoint("LEFT", frame.bg, "RIGHT", 5, 0)

                frame.item = frame:CreateFontString()
                frame.item:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                frame.item:SetPoint("LEFT", frame.level, "RIGHT", 2, 0)
                frame.item:SetJustifyH("CENTER")
            end
            for _, v in ipairs(slotTbl) do
                if v.slot ~= "ShirtSlot" and v.slot ~= "TabardSlot" then
                    CreateButton(v.slot)
                end
            end
        end

        -- 附魔和宝石
        rightFrame.enchantButtons = {}

        local function AddEnchant(bt, itemID, spellID, type)
            local iconTex, _, subTypeID
            if itemID then
                iconTex, _, subTypeID = select(5, GetItemInfoInstant(itemID))
            elseif spellID then
                iconTex = select(3, GetSpellInfo(spellID))
            end
            local height = bt:GetHeight()
            local f = CreateFrame("Frame", nil, bt)
            f:SetSize(height, height)
            if next(bt.otherButtons) then
                f:SetPoint("LEFT", bt.otherButtons[#bt.otherButtons], "RIGHT", 0, 0)
            else
                f:SetPoint("LEFT", bt.item, "RIGHT", 2, 0)
            end
            tinsert(bt.otherButtons, f)
            f:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                if itemID then
                    GameTooltip:SetItemByID(itemID)
                elseif spellID then
                    GameTooltip:SetSpellByID(spellID)
                else
                    if type == "chant" then
                        GameTooltip:AddLine(L["缺少附魔！"], 1, 0, 0, true)
                    else
                        GameTooltip:AddLine(L["缺少宝石！"], 1, 0, 0, true)
                    end
                    GameTooltip:Show()
                end
            end)
            f:SetScript("OnLeave", GameTooltip_Hide)

            local mask = f:CreateMaskTexture()
            mask:SetPoint("CENTER")
            mask:SetSize(13, 13)
            mask:SetTexture([[Interface\CharacterFrame\TempPortraitAlphaMask]], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            local icon = f:CreateTexture()
            icon:SetPoint("CENTER")
            if iconTex then
                icon:SetSize(15, 15)
                icon:SetTexture(iconTex)
            else
                icon:SetSize(20, 20)
            end
            icon:AddMaskTexture(mask)
            local broder = f:CreateTexture(nil, "OVERLAY")
            broder:SetAllPoints()
            broder:SetTexture([[Interface\AddOns\BiaoGe\Media\icon\SocketBroder.blp]])
            local alpha = .8
            if type == "chant" then
                if iconTex then
                    broder:SetVertexColor(0, 1, 0, alpha)
                else
                    broder:SetVertexColor(1, 0, 0, alpha)
                    icon:SetTexture("Interface/Icons/trade_engraving")
                    icon:SetAlpha(.6)
                end
            else
                if subTypeID then
                    broder:SetVertexColor(0, 1, 0, alpha)
                else
                    broder:SetVertexColor(1, 0, 0, alpha)
                    icon:SetTexture("Interface/Icons/inv_misc_gem_01")
                    icon:SetAlpha(.6)
                end
            end
        end

        function rightFrame.UpdateEnchant(bt, link, skill)
            for _, otherButton in ipairs(bt.otherButtons) do
                otherButton:Hide()
            end
            wipe(bt.otherButtons)
            if not link then return end
            local chant, noChant, gemTbl, gemCount, equipLoc = BG.GetEnchantInfo(link, skill)
            if chant then
                if BG.enchant[chant] then
                    local itemID = BG.enchant[chant].itemID
                    if itemID then
                        AddEnchant(bt, itemID, nil, "chant")
                    else
                        local spellID = BG.enchant[chant].spellID
                        if spellID then
                            AddEnchant(bt, nil, spellID, "chant")
                        end
                    end
                else
                    if BGDEBUG then
                        print("未知附魔：", chant, link)
                    end
                end
            elseif noChant then
                AddEnchant(bt, nil, nil, "chant")
            end
            for _, gem in ipairs(gemTbl) do
                if gem then
                    AddEnchant(bt, gem, nil, "gem")
                end
            end
            for i = 1, gemCount - #gemTbl do
                AddEnchant(bt, nil, nil, "gem")
            end
        end
    end

    local function GetTooltipSetInfo(link, quality, setName)
        local tip = BiaoGeTooltip2
        tip:SetOwner(UIParent, "ANCHOR_NONE")
        tip:ClearLines()
        tip:SetHyperlink(link)
        for i = 2, tip:NumLines() do
            local text = _G[tip:GetName() .. "TextLeft" .. i]:GetText()
            if text and text ~= "" then
                local maxCount = text:match("^" .. setName .. ".-%d+/(%d+)")
                if maxCount then
                    for _, t in pairs(leftFrame.sets) do
                        if t.name == setName then
                            t.count = t.count + 1
                            t:SetText(setName .. L["："] .. t.count .. "/" .. maxCount)
                            return
                        end
                    end
                    local r, g, b = GetItemQualityColor(quality)
                    local t = leftFrame.setFrame:CreateFontString()
                    t:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                    if next(leftFrame.sets) then
                        t:SetPoint("BOTTOM", leftFrame.sets[#leftFrame.sets], "TOP", 0, 2)
                    else
                        t:SetPoint("BOTTOM", 0, 0)
                    end
                    t:SetTextColor(r, g, b)
                    t.name = setName
                    t.count = 1
                    t:SetText(setName .. L["："] .. t.count .. "/" .. maxCount)
                    tinsert(leftFrame.sets, t)
                    return
                end
            end
        end
    end

    function BG.ShowEquipFrame(click, bt, isAccounts, realmID, player,
                                colorplayer, level, class, iLevel, BiaoGeAIdb,
                                BiaoGeAItalent, points)
        local db
        if not BiaoGeAIdb then
            if isAccounts then
                db = BiaoGeAccounts
            else
                db = BiaoGe
            end
            if not (db.equip and db.equip[realmID] and db.equip[realmID][player]) then
                GameTooltip:SetOwner(bt, "ANCHOR_NONE", 0, 0)
                if bt.isFBCD or BiaoGe.options.roleOverviewLayout == "left_right" then
                    GameTooltip:SetPoint("TOPRIGHT", bt, "TOPLEFT", -12, 0)
                else
                    GameTooltip:SetPoint("BOTTOMRIGHT", bt, "BOTTOMLEFT", -12, 0)
                end
                GameTooltip:ClearLines()
                GameTooltip:AddLine(colorplayer, 1, 1, 1, true)
                GameTooltip:AddLine(L["没有该角色的装备数据。"], 1, .82, 0, true)
                if isAccounts then
                    GameTooltip:AddLine(L["请打开同步软件并登录一次该角色。"], 1, .82, 0, true)
                else
                    GameTooltip:AddLine(L["请登录一次该角色。"], 1, .82, 0, true)
                end
                GameTooltip:Show()
                return
            end
        end
        if not mainFrame then
            CreateMainFrame()
        end
        if click then
            if mainFrame.click and mainFrame.realmID == realmID and mainFrame.player == player then
                mainFrame:Hide()
                return
            end
            mainFrame.tipText:Hide()
            mainFrame:EnableMouse(true)
            mainFrame:SetMovable(true)
            mainFrame:SetScript("OnMouseUp", function(self)
                self:StopMovingOrSizing()
            end)
            mainFrame:SetScript("OnMouseDown", function(self)
                self:StartMoving()
            end)
        else
            mainFrame.tipText:Show()
            mainFrame:EnableMouse(false)
            mainFrame:SetMovable(false)
            mainFrame:SetScript("OnMouseUp", nil)
            mainFrame:SetScript("OnMouseDown", nil)
        end
        for i, v in ipairs(slotTbl) do
            i = tostring(i)
            local bt = leftFrame["slot" .. i]
            if bt then
                bt:SetEnabled(click)
            end
        end
        mainFrame.time = GetTime()
        mainFrame.realmID = realmID
        mainFrame.player = player
        mainFrame.click = click
        mainFrame.CloseButton:SetShown(click)
        mainFrame:Show()
        mainFrame:SetParent(bt)
        mainFrame:SetFrameLevel(bt:GetFrameLevel() + 10)
        mainFrame:ClearAllPoints()
        if points then
            mainFrame:SetPoint(unpack(points))
        elseif BiaoGeAIdb then
            mainFrame:SetPoint("TOPLEFT", bt, "TOPRIGHT", 1, 0)
        elseif bt.isFBCD or BiaoGe.options.roleOverviewLayout == "left_right" then
            mainFrame:SetPoint("TOPRIGHT", bt, "TOPLEFT", -10, 0)
        else
            mainFrame:SetPoint("BOTTOMRIGHT", bt, "BOTTOMLEFT", -10, 0)
        end
        local r, g, b = GetClassColor(class)
        leftFrame:SetBackdropBorderColor(r, g, b, 1)
        leftFrame.line:SetColorTexture(r, g, b, 1)
        rightFrame:SetBackdropBorderColor(r, g, b, 1)
        for _, t in pairs(leftFrame.sets) do
            t:Hide()
        end
        wipe(leftFrame.sets)

        local talentText = ""
        if BG.GetTalentIcon then
            local talent
            if BiaoGeAIdb then
                talent = BiaoGeAItalent
            else
                talent = BiaoGeAItalent or db.playerInfo[realmID][player].talent
            end
            talentText = BG.GetTalentIcon(class, talent)
        end
        leftFrame.NameText:SetText(talentText .. colorplayer)
        local raceText = ""
        if not BiaoGeAIdb and (db.playerInfo and db.playerInfo[realmID] and db.playerInfo[realmID][player] and db.playerInfo[realmID][player].raceID) then
            raceText = C_CreatureInfo.GetRaceInfo(db.playerInfo[realmID][player].raceID).raceName
        end
        leftFrame.LevelText:SetText(LEVEL .. (level or UNKNOWN) .. " " .. raceText .. GetClassName(class))
        leftFrame.iLevelText:SetText(L["装等："] .. (iLevel and ns.Round(iLevel, 1) or UNKNOWN))

        -- 子账号
        if not BiaoGeAIdb and BiaoGeAccounts and BiaoGeAccounts.accountName then
            local tbl = {}
            for accountName in pairs(BiaoGeAccounts.accountName) do
                for _realmID in pairs(BiaoGeAccounts.accountName[accountName]) do
                    if realmID == _realmID then
                        for _player in pairs(BiaoGeAccounts.accountName[accountName][realmID]) do
                            if player == _player then
                                tinsert(tbl, accountName)
                            end
                        end
                    end
                end
            end
            local sameText = ""
            if #tbl > 1 then
                sameText = L["|cffff0000（角色存在重复情况，会导致同步失效和数据错误。请登录上述账号，表格设置-角色配置-删除角色。）|r"]
            end
            leftFrame.accountText:SetText(L["子账号："] .. table.concat(tbl, L["，"]) .. sameText)
        else
            leftFrame.accountText:SetText("")
        end

        local equipTbl = BiaoGeAIdb or db.equip[realmID][player]
        for i in ipairs(slotTbl) do
            if not BiaoGeAIdb then
                i = tostring(i)
            end
            local v = equipTbl[i]
            local bt1 = leftFrame["slot" .. i]
            local bt2 = rightFrame["slot" .. i]
            if bt1 and bt2 then
                if v and v.link and v.link:match("item:(%d+)") then
                    Item:CreateFromItemLink(v.link):ContinueOnItemLoad(function()
                        local info = { GetItemInfo(v.link) }
                        local link = info[2]
                        local quality = info[3]
                        local level = info[4]
                        local icon = info[10]
                        local setID = info[16]
                        local r, g, b = GetItemQualityColor(quality)
                        bt1.icon:SetTexture(icon)
                        bt1.level:SetText(level)
                        bt1.link = link
                        bt1:SetBackdropBorderColor(r, g, b)
                        bt1.level:SetTextColor(r, g, b)

                        bt2.level:SetText(level)
                        bt2.level:SetWidth(bt2.level:GetStringWidth())
                        bt2.level:SetTextColor(SetiLevelColor(level))
                        bt2.item:SetText(link)
                        bt2.link = link
                        bt2.bg:SetBackdropColor(r, g, b, .05)
                        bt2.bg:SetBackdropBorderColor(r, g, b, .2)
                        bt2.slot:SetTextColor(r, g, b)

                        if setID then
                            local setName = GetItemSetInfo(setID)
                            if setName then
                                GetTooltipSetInfo(link, quality, setName)
                            end
                        end
                    end)
                else
                    bt1.icon:SetTexture(bt1.textureBG)
                    bt1.level:SetText("")
                    bt1.link = nil
                    bt1:SetBackdropBorderColor(unpack(bt1.borderColorBG))

                    bt2.level:SetText("")
                    bt2.level:SetWidth(0)
                    bt2.item:SetText("")
                    bt2.link = nil
                    bt2.bg:SetBackdropColor(unpack(bt2.bg.baseDropColor))
                    bt2.bg:SetBackdropBorderColor(unpack(bt2.bg.baseBorderColor))
                    bt2.slot:SetTextColor(unpack(bt2.slot.baseColor))
                end
                local skill = db and db["MONEY"] and db["MONEY"][realmID] and db["MONEY"][realmID][player]
                    and db["MONEY"][realmID][player].skill
                rightFrame.UpdateEnchant(bt2, v and v.link, skill)
            end
        end

        -- 传家宝附魔
        if leftFrame.enchantButtons then
            for i, bt in ipairs(leftFrame.enchantButtons) do
                if BiaoGeAIdb then
                    bt:Hide()
                else
                    local count = 0
                    local itemID = bt.itemID
                    if db.bag and db.bag[realmID] and db.bag[realmID][player] and BG.GetItemBagCount then
                        count = BG.GetItemBagCount(db.bag[realmID][player], itemID) or 0
                    end
                    bt.count = count
                    bt:Update()
                end
            end
        end

        -- 设置装等文本统一宽度
        local maxLevelWidth, maxWidth
        for _, bt in ipairs(rightFrame.slotButtons) do
            local w = bt.level:GetWidth() or 0
            if not maxLevelWidth then
                maxLevelWidth = w
            end
            maxLevelWidth = max(maxLevelWidth, w)
        end
        -- 设置装备列表宽度
        for _, bt in ipairs(rightFrame.slotButtons) do
            bt.level:SetWidth(maxLevelWidth)
            local w1, w2
            w1 = bt.bg:GetLeft()
            if bt.otherButtons[#bt.otherButtons] then
                w2 = bt.otherButtons[#bt.otherButtons]:GetRight()
            elseif bt.item then
                w2 = bt.item:GetRight()
            else
                w2 = bt.bg:GetRight()
            end
            local w = w2 - w1
            bt:SetWidth(w)
            if not maxWidth then
                maxWidth = w
            end
            maxWidth = max(maxWidth, w)
        end
        rightFrame:SetWidth(maxWidth + 20)
        mainFrame:SetWidth(leftFrame:GetWidth() + rightFrame:GetWidth())
    end
end)
