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
    end

    local class = select(2, UnitClass('player'))
    function BG.SetZUGSetTooltip(itemID, point)
        local id = db[itemID] and db[itemID][class]
        if id then
            BiaoGeTooltip2:SetOwner(GameTooltip, "ANCHOR_NONE", 0, 0)
            BiaoGeTooltip2:ClearLines()
            if point == 'LEFT' then
                BiaoGeTooltip2:SetPoint('TOPRIGHT', GameTooltip, "TOPLEFT", 0, 0)
            else
                BiaoGeTooltip2:SetPoint('TOPLEFT', GameTooltip, "TOPRIGHT", 0, 0)
            end
            BiaoGeTooltip2:SetItemByID(id, 1, 1, 1, true)
            BiaoGeTooltip2:SetParent(GameTooltip)
            BiaoGeTooltip2:AddLine(' ')
            BiaoGeTooltip2:AddLine(L['|cff00BFFFBiaoGe：|r你的职业对应兑换的装备'], 1, 1, 1, true)
            BiaoGeTooltip2:Show()
        end
    end
end)
