local AddonName, ns = ...

local L             = ns.L
local pt            = print
local realmID       = GetRealmID()
local player        = BG.playerName
local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded
local GetLootMethod = GetLootMethod or C_PartyInfo.GetLootMethod
local GetAddOnMetadata = GetAddOnMetadata or C_AddOns.GetAddOnMetadata

C_ChatInfo.RegisterAddonMessagePrefix("BiaoGe")
C_ChatInfo.RegisterAddonMessagePrefix("BiaoGe2")
C_ChatInfo.RegisterAddonMessagePrefix("BiaoGeWorldBoss")

BiaoGeTooltip = CreateFrame("GameTooltip", "BiaoGeTooltip", UIParent, "GameTooltipTemplate")   -- 用于装备过滤功能
BiaoGeTooltip2 = CreateFrame("GameTooltip", "BiaoGeTooltip2", UIParent, "GameTooltipTemplate") -- 用于装备库
BiaoGeTooltip2:SetClampedToScreen(false)
BiaoGeTooltip3 = CreateFrame("GameTooltip", "BiaoGeTooltip3", UIParent, "GameTooltipTemplate") -- 用于装备过期提醒
BiaoGeTooltip4 = CreateFrame("GameTooltip", "BiaoGeTooltip4", UIParent, "GameTooltipTemplate") -- 用于装等获取
BiaoGeTooltip5 = CreateFrame("GameTooltip", "BiaoGeTooltip5", UIParent, "GameTooltipTemplate") -- 用于显示已装备的同部位装备
BiaoGeTooltip5:SetClampedToScreen(false)

-- 用于提示套装属性
for i = 11, 15 do
    local frameName = "BiaoGeTooltip" .. i
    CreateFrame("GameTooltip", frameName, UIParent, "GameTooltipTemplate")
    _G[frameName]:SetClampedToScreen(false)
end

-- 游戏按键设置
BINDING_HEADER_BIAOGE     = "BiaoGe"
BINDING_NAME_BIAOGE       = L["打开/关闭表格"]
BINDING_NAME_RoleOverview = L["打开/关闭角色总览"]

BG.blackListPlayer = {
}
if BG.blackListPlayer[realmID] and BG.blackListPlayer[realmID][BG.playerName] then
end

BG.Init2(function()
    if BG.hasHolidayLoot then
        BG.After(1, function()
            ToggleCalendar()
            Calendar_Hide()
        end)
    end

    if BG.IsWLK_80 then
        if BG.IsTBCFB(BG.FB1) and not ns.canShowTBC then
            BG.ClickFBbutton("ICC")
        end
        if not ns.canShowTBC then
            BG.TabButtonsFB_TBC:Hide()
            BG.TabButtonsFB_TBC:SetParent(nil)
            BG.TabButtonsFB_TBC = nil
        end
    end
end)
