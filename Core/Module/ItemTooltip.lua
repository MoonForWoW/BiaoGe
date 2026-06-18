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

local Maxb = ns.Maxb

local pt = print
local realmID = GetRealmID()
local player = BG.playerName

local myClassFileName = select(2, UnitClass('player'))
local r, g, b = GetClassRGB(nil, "player")

BG.Init2(function()
    local db = {}
    local db2 = {}
    local blackList = {}
    local all = {}

    local matchStr = ITEM_CLASSES_ALLOWED:gsub("%%s", "(.+)")
    local classNames = {}
    for i = 1, GetNumClasses() do
        local className, classFilename = GetClassInfo(i)
        if className then
            classNames[className] = classFilename
        end
    end

    local function AddItem(exItemID, itemIDs)
        db[exItemID] = db[exItemID] or {}
        db2[exItemID] = db2[exItemID] or {}

        for _, itemID in ipairs(itemIDs) do
            BG.OnItemLoad(itemID):ContinueOnItemLoad(function()
                BG.Tooltip_SetItemByID(itemID)
                for i = 1, BiaoGeTooltip:NumLines() do
                    local str = _G["BiaoGeTooltipTextLeft" .. i]:GetText()
                    if str then
                        local classStr = str:match(matchStr)
                        if classStr then
                            local classFileName = classNames[classStr]
                            if classFileName then
                                db[exItemID][classFileName] = db[exItemID][classFileName] or {}
                                db2[exItemID][classFileName] = db2[exItemID][classFileName] or {}
                                if not db2[exItemID][classFileName][itemID] then
                                    tinsert(db[exItemID][classFileName], itemID)
                                    db2[exItemID][classFileName][itemID] = true
                                    local isSet = select(16, GetItemInfo(itemID))
                                    if isSet and classFileName ~= myClassFileName then
                                        all[exItemID] = nil
                                    end
                                end
                            end
                            return
                        end
                    end
                end
            end)
        end
    end

    for _, FB in ipairs(BG.FBtable) do
        for exItemID, itemIDs in pairs(BG.Loot[FB].ExchangeItems) do
            all[exItemID] = itemIDs
        end
    end
    for _, FB in ipairs(BG.FBtable) do
        for exItemID, itemIDs in pairs(BG.Loot[FB].ExchangeItems) do
            AddItem(exItemID, itemIDs)
        end
    end

    --[[
INVTYPE_FINGER = 11, 12,
INVTYPE_TRINKET = 13, 14,
INVTYPE_WEAPON = 16, 17,
]]
    local invSlotMap
    if BG.verOver4 then
        invSlotMap = {
            INVTYPE_HEAD = 1,
            INVTYPE_NECK = 2,
            INVTYPE_SHOULDER = 3,
            INVTYPE_BODY = 4,
            INVTYPE_CHEST = 5,
            INVTYPE_WAIST = 6,
            INVTYPE_LEGS = 7,
            INVTYPE_FEET = 8,
            INVTYPE_WRIST = 9,
            INVTYPE_HAND = 10,
            INVTYPE_SHIELD = 17,
            INVTYPE_RANGED = 16,
            INVTYPE_CLOAK = 15,
            INVTYPE_2HWEAPON = 16,
            INVTYPE_TABARD = 19,
            INVTYPE_ROBE = 5,
            INVTYPE_WEAPONMAINHAND = 16,
            INVTYPE_WEAPONOFFHAND = 16,
            INVTYPE_HOLDABLE = 17,
            INVTYPE_THROWN = 16,
            INVTYPE_RANGEDRIGHT = 16,
            INVTYPE_WEAPON = 16,
        }
    else
        invSlotMap = {
            INVTYPE_HEAD = 1,
            INVTYPE_NECK = 2,
            INVTYPE_SHOULDER = 3,
            INVTYPE_BODY = 4,
            INVTYPE_CHEST = 5,
            INVTYPE_WAIST = 6,
            INVTYPE_LEGS = 7,
            INVTYPE_FEET = 8,
            INVTYPE_WRIST = 9,
            INVTYPE_HAND = 10,
            INVTYPE_SHIELD = 17,
            INVTYPE_RANGED = 18,
            INVTYPE_CLOAK = 15,
            INVTYPE_2HWEAPON = 16,
            INVTYPE_TABARD = 19,
            INVTYPE_ROBE = 5,
            INVTYPE_WEAPONMAINHAND = 16,
            INVTYPE_WEAPONOFFHAND = 17,
            INVTYPE_HOLDABLE = 17,
            INVTYPE_THROWN = 18,
            INVTYPE_RANGEDRIGHT = 18,
            INVTYPE_WEAPON = 16,
        }
    end

    local function AddTooltipText(tooltip, index, text)
        local _text = _G[tooltip:GetName() .. "TextLeft" .. index]
        if _text then
            local str = _text:GetText()
            _text:SetText(text .. str)
        end
    end

    local function ShowEquiped(slotID, tooltip, point1, point2)
        local currentItemLink = GetInventoryItemLink("player", slotID)
        if currentItemLink then
            local compareTip = BiaoGeTooltip5
            compareTip:SetOwner(tooltip, "ANCHOR_NONE")
            compareTip:ClearLines()
            compareTip:SetPoint(point1, tooltip, point2, 0, -10)
            compareTip:SetHyperlink(currentItemLink)
            AddTooltipText(compareTip, 1, format('|cff808080%s|r\n',CURRENTLY_EQUIPPED))
            local quality, level = select(3, GetItemInfo(currentItemLink))
            if BG.verLess3 then
                if level then
                    AddTooltipText(compareTip, 2, L['|cffFFD100物品等级%s|r\n']:format(level))
                end
            end
            compareTip:SetParent(tooltip)
            compareTip:Show()
        end
    end

    function BG.SetZUGSetTooltip(exItemID, point)
        local ids = db[exItemID] and db[exItemID][myClassFileName]
        if not ids then
            ids = all[exItemID]
        end
        if ids and #ids <= 5 then
            local lastTooltip = GameTooltip
            local point1, point2, lastItemEquipLoc
            for i, id in ipairs(ids) do
                local tooltip = _G['BiaoGeTooltip' .. (i + 10)]
                tooltip:SetOwner(GameTooltip, "ANCHOR_NONE", 0, 0)
                tooltip:ClearLines()
                if point == 'LEFT' then
                    tooltip:SetPoint('TOPRIGHT', lastTooltip, "TOPLEFT", 0, 0)
                    point1 = 'TOPRIGHT'
                    point2 = 'TOPLEFT'
                else
                    tooltip:SetPoint('TOPLEFT', lastTooltip, "TOPRIGHT", 0, 0)
                    point1 = 'TOPLEFT'
                    point2 = 'TOPRIGHT'
                end
                if type(id) == 'number' then
                    tooltip:SetItemByID(id)
                else
                    tooltip:SetHyperlink(id)
                end
                AddTooltipText(tooltip, 1, L['|cff808080兑换后的装备|r\n'])
                local quality, level, _, _, _, _, itemEquipLoc = select(3, GetItemInfo(id))
                lastItemEquipLoc = itemEquipLoc
                if BG.verLess3 then
                    if level then
                        AddTooltipText(tooltip, 2, L['|cffFFD100物品等级%s|r\n'] :format( level ))
                    end
                end
                tooltip:SetParent(GameTooltip)
                tooltip:Show()
                lastTooltip = tooltip
            end
            if invSlotMap[lastItemEquipLoc] then
                ShowEquiped(invSlotMap[lastItemEquipLoc], lastTooltip, point1, point2)
            end
        end
    end
end)
