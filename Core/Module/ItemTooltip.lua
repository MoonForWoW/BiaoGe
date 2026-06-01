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

BG.Init(function()
    local classNames = {}
    for i = 1, GetNumClasses() do
        local className, classFilename = GetClassInfo(i)
        if className then
            classNames[className] = classFilename
        end
    end

    local db = {}
    if BG.IsTitan then
        db = {
            [19721] = {
                HUNTER = 19831,
                PRIEST = 19841,
                DEATHKNIGHT = 268778,
            },
            [19720] = {
                HUNTER = 19832,
                PRIEST = 19842,
                DEATHKNIGHT = 268779,
            },
            [19717] = {
                HUNTER = 19833,
                PRIEST = 19843,
                DEATHKNIGHT = 268780,
            },
            [19722] = {
                ROGUE = 19835,
                MAGE = 19845,
                WARLOCK = 19849,
            },
            [19723] = {
                ROGUE = 19834,
                MAGE = 20034,
                WARLOCK = 20033,
            },
            [19716] = {
                ROGUE = 19836,
                MAGE = 19846,
                WARLOCK = 19848,
            },
            [19724] = {
                WARRIOR = 19822,
                PALADIN = 19825,
                SHAMAN = 19828,
                DRUID = 19838,
            },
            [19719] = {
                WARRIOR = 19823,
                PALADIN = 19826,
                SHAMAN = 19829,
                DRUID = 19839,
            },
            [19718] = {
                WARRIOR = 19824,
                PALADIN = 19827,
                SHAMAN = 19830,
                DRUID = 19840,
            },
        }

        -- TOC套装
        local tbl = {}
        if BG.IsAlliance then
            -- 手
            tbl[276778] = { 48482, 48539, 47753, 48133, 48163, 48212, }
            tbl[276777] = { 48576, 48608, 48640, 48224, 48286, 48317, 48347, }
            tbl[276776] = { 48377, 48452, 48256, 47983, 48077, 47782, }
            -- 腿
            tbl[276775] = { 48484, 48541, 47755, 48135, 48165, 48210, }
            tbl[276774] = { 48379, 48446, 48258, 47985, 48079, 47780, }
            tbl[276773] = { 48578, 48610, 48638, 48226, 48288, 48319, 48349, }
            -- 肩膀
            tbl[276772] = { 48579, 48611, 48637, 48227, 48289, 48320, 48350, }
            tbl[276771] = { 48380, 48454, 48259, 47987, 48081, 47781, }
            tbl[276770] = { 48485, 48542, 47757, 48137, 48167, 48208, }
            -- 头
            tbl[276769] = { 48483, 48540, 47754, 48134, 48164, 48211, }
            tbl[276768] = { 48378, 48430, 48257, 47984, 48078, 47778, }
            tbl[276767] = { 48577, 48609, 48639, 48225, 48287, 48318, 48348, }
            -- 胸
            tbl[47559] = { 48481, 48538, 47756, 48136, 48166, 48209, }
            tbl[47558] = { 48376, 48450, 48255, 47986, 48080, 47779, }
            tbl[47557] = { 48575, 48607, 48641, 48223, 48285, 48316, 48346, }
        else
            -- 手
            tbl[276778] = { 48499, 48556, 47772, 48152, 48182, 48193, }
            tbl[276777] = { 48593, 48625, 48658, 48241, 48301, 48334, 48364, }
            tbl[276776] = { 48392, 48462, 48273, 48066, 48096, 47803, }
            -- 腿
            tbl[276775] = { 48497, 48554, 47770, 48150, 48180, 48195, }
            tbl[276774] = { 48394, 48464, 48271, 48064, 48094, 47805, }
            tbl[276773] = { 48591, 48623, 48660, 48239, 48303, 48332, 48362, }
            -- 肩膀
            tbl[276772] = { 48590, 48622, 48661, 48238, 48304, 48331, 48361, }
            tbl[276771] = { 48395, 48465, 48270, 48062, 48092, 47807, }
            tbl[276770] = { 48496, 48553, 47768, 48148, 48178, 48197, }
            -- 头
            tbl[276769] = { 48498, 48555, 47771, 48151, 48181, 48194, }
            tbl[276768] = { 48393, 48463, 48272, 48065, 48095, 47804, }
            tbl[276767] = { 48592, 48624, 48659, 48240, 48302, 48333, 48363, }
            -- 胸
            tbl[47559] = { 48500, 48557, 47769, 48149, 48179, 48196, }
            tbl[47558] = { 48391, 48461, 48274, 48063, 48093, 47806, }
            tbl[47557] = { 48594, 48626, 48657, 48242, 48300, 48335, 48365, }
        end
        local matchStr = ITEM_CLASSES_ALLOWED:gsub("%%s", "")
        for exItemID, itemIDs in pairs(tbl) do
            db[exItemID] = db[exItemID] or {}
            for _, itemID in ipairs(itemIDs) do
                Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
                    BG.Tooltip_SetItemByID(itemID)
                    for i = 1, BiaoGeTooltip:NumLines() do
                        local str = _G["BiaoGeTooltipTextLeft" .. i]:GetText()
                        if str then
                            local classStr = str:match(matchStr .. "(.+)")
                            if classStr and classNames[classStr] then
                                local classFilename = classNames[classStr]
                                db[exItemID][classFilename] = db[exItemID][classFilename] or {}
                                tinsert(db[exItemID][classFilename], itemID)
                                break
                            end
                        end
                    end
                end)
            end
        end
    end

    local class = select(2, UnitClass('player'))
    function BG.SetZUGSetTooltip(itemID, point)
        local id = db[itemID] and db[itemID][class]
        local ids
        if type(id) == 'number' then
            ids = { id }
        elseif type(id) == 'table' then
            ids = id
        end
        if ids then
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
                tooltip:SetItemByID(id, 1, 1, 1, true)
                tooltip:SetParent(GameTooltip)
                tooltip:AddLine(' ')
                tooltip:AddLine(L['|cff00BFFFBiaoGe：|r你的职业对应兑换的装备'], 1, 1, 1, true)
                tooltip:Show()
                lastTooltip = tooltip
            end
        end
    end
end)
