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

    function BG.SetZUGSetTooltip(exItemID, point)
        local ids = db[exItemID] and db[exItemID][myClassFileName]
        local colorNum = 1
        if not ids then
            ids = all[exItemID]
            colorNum = 2
        end
        if ids and #ids <= 5 then
            local lastTooltip = GameTooltip
            for i, id in ipairs(ids) do
                local tooltip = _G['BiaoGeTooltip' .. (i + 10)]
                tooltip:SetOwner(GameTooltip, "ANCHOR_NONE", 0, 0)
                tooltip:ClearLines()
                if point == 'LEFT' then
                    tooltip:SetPoint('TOPRIGHT', lastTooltip, "TOPLEFT", 0, 0)
                else
                    tooltip:SetPoint('TOPLEFT', lastTooltip, "TOPRIGHT", 0, 0)
                end
                if type(id) == 'number' then
                    tooltip:SetItemByID(id)
                else
                    tooltip:SetHyperlink(id)
                end
                -- local r, g, b = 0, 0, 0
                local quality, level = select(3, GetItemInfo(id))
                if BG.verLess3 then
                    -- if quality then
                    --     r, g, b = GetItemQualityColor(quality)
                    -- end
                    if level then
                        local text2 = _G[tooltip:GetName() .. "TextLeft" .. 2]
                        if text2 then
                            local str = text2:GetText()
                            text2:SetText(L['|cffFFD100物品等级'] .. level .. '|r\n' .. str)
                        end
                    end
                end
                tooltip:SetParent(GameTooltip)
                tooltip:AddLine(' ')
                if colorNum == 1 then
                    tooltip:AddLine(BG.GetTalentIcon(myClassFileName) .. L['BiaoGe：你的职业兑换后的装备'], 0, .75, 1, true)
                elseif colorNum == 2 then
                    tooltip:AddLine(L['BiaoGe：兑换后的装备'], 0, .75, 1, true)
                end
                tooltip:Show()
                -- if tooltip.bg then
                --     tooltip.bg:SetBackdropBorderColor(r, g, b, 1)
                -- end
                lastTooltip = tooltip
            end
        end
    end
end)
