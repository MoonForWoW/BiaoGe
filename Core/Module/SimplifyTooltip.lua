if BG.IsBlackListPlayer then return end
local l = GetLocale()
if not (BG.IsForever and (l == "zhCN" or l == "zhTW" or l == 'enUS')) then return end

local AddonName, ns = ...
local L = ns.L

ns.canUseSimplifyTooltip = true

BG.Init(function()
    BiaoGe.options.simplifyTooltip = BiaoGe.options.simplifyTooltip or 0

    local replacements = {
        TOOLTIP_ITEM_STAT_SPELL_POWER_INCREASE = L["装备：+%1$d 法术强度。"],
        TOOLTIP_ITEM_STAT_SPELL_HEALING_INCREASE_DAMAGE_INCREASE = L["装备：+%1$d 法术治疗，+%2$d 法术伤害。"],
        TOOLTIP_ITEM_STAT_SPELL_DAMAGE_INCREASE = L["装备：+%1$d 法术伤害。 "],
    }

    local schools = {
        ARCANE = L["奥术"],
        FIRE = L["火焰"],
        FROST = L["冰霜"],
        NATURE = L["自然"],
        SHADOW = L["暗影"],
        HOLY = L["神圣"],
    }
    for english, name in pairs(schools) do
        local key = "TOOLTIP_ITEM_STAT_" .. english .. "_DAMAGE_INCREASE"
        replacements[key] = L["装备：+%1$d %s伤害。 "]:gsub("%%s", name)
    end

    local originals = {}
    for key in pairs(replacements) do
        if type(_G[key]) == "string" then
            originals[key] = _G[key]
        end
    end

    function BG.UpdateSimplifyTooltip()
        local enabled = BiaoGe.options.simplifyTooltip == 1
        for key, original in pairs(originals) do
            if enabled then
                if _G[key] ~= replacements[key] then
                    _G[key] = replacements[key]
                end
            else
                if _G[key] == replacements[key] then
                    _G[key] = original
                end
            end
        end
    end

    BG.UpdateSimplifyTooltip()
end)
