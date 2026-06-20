local AddonName, ns = ...

local L = ns.L

local pt = print

local RealmID = GetRealmID()
local player = BG.playerName
local _, class = UnitClass("player")

BG.Init(function()
    BG.Once("FilterClassItemDB", 260425, function()
        BiaoGe.FilterClassItemDB = nil
    end)

    if BG.IsMOP then
        BG.Once("FilterClassItemDB", 260504, function()
            BiaoGe.FilterClassItemDB = nil
        end)
    end

    BiaoGe.FilterClassItemDB = BiaoGe.FilterClassItemDB or {}
    BiaoGe.FilterClassItemDB[RealmID] = BiaoGe.FilterClassItemDB[RealmID] or {}
    BiaoGe.FilterClassItemDB[RealmID][player] = BiaoGe.FilterClassItemDB[RealmID][player] or {}

    if BG.verLess3 and select(2, UnitClass('player')) == 'HUNTER' then
        BG.Once("FilterClassItemDB" .. UnitGUID('player'), 260618, function()
            BiaoGe.FilterClassItemDB[RealmID][player] = {}
        end)
    end
    local db = BiaoGe.FilterClassItemDB[RealmID][player]

    BG.FilterClassItemDB = {}
    BG.FilterClassItem_Default = {}

    local WeaponIDs = {
        ["单手斧"] = "0",
        ["双手斧"] = "1",
        ["弓"] = "2",
        ["枪"] = "3",
        ["单手锤"] = "4",
        ["双手锤"] = "5",
        ["长柄武器"] = "6",
        ["单手剑"] = "7",
        ["双手剑"] = "8",
        ["战刃"] = "9",
        ["法杖"] = "10",
        ["拳套"] = "13",
        ["匕首"] = "15",
        ["投掷武器"] = "16",
        ["弩"] = "18",
        ["魔杖"] = "19",
        ["钓鱼竿"] = "20",
    }
    local ArmorIDs = {
        ["布甲"] = "1",
        ["皮甲"] = "2",
        ["锁甲"] = "3",
        ["板甲"] = "4",
        ["盾牌"] = "6",
        ["副手物品"] = "0",
        ["圣契"] = "7",
        ["神像"] = "8",
        ["图腾"] = "9",
        ["魔印"] = "10",
    }

    local canUse = {
        Weapon = {
            DEATHKNIGHT = { "单手斧", "单手锤", "单手剑", "双手斧", "双手锤", "双手剑", "长柄武器" },
            WARRIOR = { "匕首", "拳套", "单手斧", "单手锤", "单手剑", "双手斧", "双手锤", "双手剑", "长柄武器", "法杖", "弓", "弩", "枪", "投掷武器" },
            PALADIN = { "单手斧", "单手锤", "单手剑", "双手斧", "双手锤", "双手剑", "长柄武器" },

            HUNTER = { "匕首", "拳套", "单手斧", "单手剑", "双手斧", "双手剑", "长柄武器", "法杖", "弓", "弩", "枪" },
            SHAMAN = { "匕首", "拳套", "单手斧", "单手锤", "双手斧", "双手锤", "法杖" },
            EVOKER = { "匕首", "拳套", "单手斧", "单手锤", "单手剑", "法杖", }, -- 唤魔师

            DRUID = { "匕首", "拳套", "单手锤", "双手锤", "长柄武器", "法杖" },
            ROGUE = { "匕首", "拳套", "单手斧", "单手锤", "单手剑", "弓", "弩", "枪", "投掷武器" },
            MONK = { "拳套", "单手斧", "单手锤", "单手剑", "长柄武器", "法杖" },
            DEMONHUNTER = { "战刃", "拳套", "单手斧", "单手剑", }, -- 恶魔猎手

            PRIEST = { "匕首", "单手锤", "法杖", "魔杖" },
            MAGE = { "匕首", "单手剑", "法杖", "魔杖" },
            WARLOCK = { "匕首", "单手剑", "法杖", "魔杖" },
        },
        Armor = {
            DEATHKNIGHT = { "皮甲", "锁甲", "板甲", "魔印" },
            WARRIOR = { "皮甲", "锁甲", "板甲", "盾牌", },
            PALADIN = { "布甲", "皮甲", "锁甲", "板甲", "盾牌", "副手物品", "圣契", },

            HUNTER = { "皮甲", "锁甲", },
            SHAMAN = { "布甲", "皮甲", "锁甲", "盾牌", "副手物品", "图腾", },
            EVOKER = { "锁甲", }, -- 唤魔师

            DRUID = { "布甲", "皮甲", "副手物品", "神像", },
            ROGUE = { "皮甲", },
            MONK = { "皮甲", "副手物品", },
            DEMONHUNTER = { "皮甲", }, -- 恶魔猎手

            PRIEST = { "布甲", "副手物品", },
            MAGE = { "布甲", "副手物品", },
            WARLOCK = { "布甲", "副手物品", },
        }
    }

    -- 装备词缀
    do
        if BG.verLess2 then
            BG.FilterClassItemDB.ShuXing = {
                { name = "力量", value = "%+%C-" .. ITEM_MOD_STRENGTH_SHORT, name2 = ITEM_MOD_STRENGTH_SHORT },
                { name = "敏捷", value = "%+%C-" .. ITEM_MOD_AGILITY_SHORT, name2 = ITEM_MOD_AGILITY_SHORT },
                { name = "智力", value = "%+%C-" .. ITEM_MOD_INTELLECT_SHORT, name2 = ITEM_MOD_INTELLECT_SHORT },
                { name = "精神", value = "%+%C-" .. ITEM_MOD_SPIRIT_SHORT, name2 = ITEM_MOD_SPIRIT_SHORT },
                { name = "5回法力值", value = ITEM_MOD_MANA_REGENERATION },
                { name = "防御", value = STAT_CATEGORY_DEFENSE },
                { name = "招架", value = STAT_PARRY },
                { name = "躲闪", value = STAT_DODGE },
                { name = "格挡", name2 = ITEM_MOD_BLOCK_RATING_SHORT, value = ITEM_MOD_BLOCK_VALUE_SHORT },
                { name = "攻击强度", value = ITEM_MOD_ATTACK_POWER_SHORT },
                { name = "武器技能", value = COMBAT_RATING_NAME1 },
                { name = "击中时可能", value = ITEM_SPELL_TRIGGER_ONPROC },
                { name = "命中", value = HIT_LCD, nothave = { ITEM_SPELL_TRIGGER_ONPROC }, onenter = L["这个词缀是赛季服新增的，指物理和法系的命中，治疗需要过滤此词缀"] },
                { name = "物理命中", name2 = L["物理命中"], value = { L["你击中目标"], ITEM_MOD_HIT_RATING } },
                { name = "物理爆击", name2 = L["物理爆击"], value = { L["你造成爆击"], ITEM_MOD_CRIT_RATING } },
                { name = "法术命中", name2 = L["法系命中"], value = { L["你的法术击中"], ITEM_MOD_HIT_SPELL_RATING }, nothave = { ITEM_SPELL_TRIGGER_ONPROC } },
                { name = "法术爆击", name2 = L["法系爆击"], value = { L["你的法术造成爆击"], ITEM_MOD_CRIT_SPELL_RATING }, nothave = { ITEM_SPELL_TRIGGER_ONPROC } },
                { name = "特定法术强度", name2 = L["特定法术强度"], value = { L["法术和效果所造成的伤害"] }, nothave = { ITEM_SPELL_TRIGGER_ONPROC }, onenter = L["仅加法强，不加奶强，治疗需要过滤此词缀"] },
                { name = "法术强度", name2 = L["法术强度"], value = L["所有法术和魔法效果所造成的伤害和治疗效果"], nothave = { ITEM_SPELL_TRIGGER_ONPROC }, onenter = L["法强+奶强"] },
                { name = "治疗强度", name2 = L["治疗强度"], value = { L["法术所造成的治疗效果"], L["法术治疗提高"], L["法术和效果造成的治疗提高"] }, nothave = { ITEM_SPELL_TRIGGER_ONPROC } },
            }
        elseif BG.IsWLK then
            local f1 = ITEM_MOD_SPELL_DAMAGE_DONE:gsub("%%s", ".+")
            local f2 = ITEM_MOD_SPELL_HEALING_DONE:gsub("%%s", ".+")
            BG.FilterClassItemDB.ShuXing = {
                { name = "力量", value = "%+%C-" .. ITEM_MOD_STRENGTH_SHORT, name2 = ITEM_MOD_STRENGTH_SHORT },
                { name = "敏捷", value = "%+%C-" .. ITEM_MOD_AGILITY_SHORT, name2 = ITEM_MOD_AGILITY_SHORT },
                { name = "智力", value = "%+%C-" .. ITEM_MOD_INTELLECT_SHORT, name2 = ITEM_MOD_INTELLECT_SHORT },
                { name = "精神", value = "%+%C-" .. ITEM_MOD_SPIRIT_SHORT, name2 = ITEM_MOD_SPIRIT_SHORT },
                { name = "5回法力值", value = ITEM_MOD_MANA_REGENERATION },
                { name = "命中", value = HIT_LCD },
                { name = "急速", value = STAT_HASTE },
                { name = "爆击", value = STAT_CRITICAL_STRIKE },
                { name = "防御", value = STAT_CATEGORY_DEFENSE },
                { name = "招架", value = STAT_PARRY },
                { name = "躲闪", value = STAT_DODGE },
                { name = "格挡", value = { ITEM_MOD_BLOCK_RATING_SHORT, ITEM_MOD_BLOCK_VALUE_SHORT }, name2 = ITEM_MOD_BLOCK_RATING_SHORT },
                { name = "攻击强度", value = ITEM_MOD_ATTACK_POWER_SHORT },
                { name = "精准", value = STAT_EXPERTISE },
                { name = "护甲穿透", value = ITEM_MOD_ARMOR_PENETRATION_RATING },
                { name = "击中时可能", value = ITEM_SPELL_TRIGGER_ONPROC },
                -- { name = "近战攻击", value = MELEE_ATTACK },
                -- { name = "远程攻击", value = RANGED_ATTACK },
                { name = "法术强度", name2 = ITEM_MOD_SPELL_POWER_SHORT, value = { ITEM_MOD_SPELL_POWER_SHORT, f1, f2 } },
            }
        elseif BG.IsCTM then
            BG.FilterClassItemDB.ShuXing = {
                { name = "力量", value = "%+%C-" .. ITEM_MOD_STRENGTH_SHORT, name2 = ITEM_MOD_STRENGTH_SHORT },
                { name = "敏捷", value = "%+%C-" .. ITEM_MOD_AGILITY_SHORT, name2 = ITEM_MOD_AGILITY_SHORT },
                { name = "智力", value = "%+%C-" .. ITEM_MOD_INTELLECT_SHORT, name2 = ITEM_MOD_INTELLECT_SHORT },
                { name = "精神", value = "%+%C-" .. ITEM_MOD_SPIRIT_SHORT, name2 = ITEM_MOD_SPIRIT_SHORT },
                { name = "5回法力值", value = ITEM_MOD_MANA_REGENERATION },
                { name = "精通", value = "%+%C-" .. ITEM_MOD_MASTERY_RATING_SHORT, name2 = ITEM_MOD_MASTERY_RATING_SHORT },
                { name = "命中", value = HIT_LCD },
                { name = "急速", value = STAT_HASTE },
                { name = "爆击", value = STAT_CRITICAL_STRIKE },
                { name = "韧性", value = RESILIENCE },
                { name = "防御", value = STAT_CATEGORY_DEFENSE },
                { name = "招架", value = STAT_PARRY },
                { name = "躲闪", value = STAT_DODGE },
                { name = "格挡", value = { ITEM_MOD_BLOCK_RATING_SHORT, ITEM_MOD_BLOCK_VALUE_SHORT }, name2 = ITEM_MOD_BLOCK_RATING_SHORT },
                { name = "攻击强度", value = ITEM_MOD_ATTACK_POWER_SHORT },
                { name = "精准", value = STAT_EXPERTISE },
                { name = "法术强度", value = ITEM_MOD_SPELL_POWER_SHORT },
            }
        elseif BG.IsMOP then
            BG.FilterClassItemDB.ShuXing = {
                { name = "力量", value = "%+%C-" .. ITEM_MOD_STRENGTH_SHORT, name2 = ITEM_MOD_STRENGTH_SHORT },
                { name = "敏捷", value = "%+%C-" .. ITEM_MOD_AGILITY_SHORT, name2 = ITEM_MOD_AGILITY_SHORT },
                { name = "智力", value = "%+%C-" .. ITEM_MOD_INTELLECT_SHORT, name2 = ITEM_MOD_INTELLECT_SHORT },
                { name = "精神", value = "%+%C-" .. ITEM_MOD_SPIRIT_SHORT, name2 = ITEM_MOD_SPIRIT_SHORT },
                { name = "精通", value = "%+%C-" .. ITEM_MOD_MASTERY_RATING_SHORT, name2 = ITEM_MOD_MASTERY_RATING_SHORT },
                { name = "命中", value = HIT_LCD },
                { name = "急速", value = STAT_HASTE },
                { name = "爆击", value = STAT_CRITICAL_STRIKE },
                { name = "韧性", value = RESILIENCE },
                { name = "防御", value = STAT_CATEGORY_DEFENSE },
                { name = "招架", value = STAT_PARRY },
                { name = "躲闪", value = STAT_DODGE },
                { name = "攻击强度", value = ITEM_MOD_ATTACK_POWER_SHORT },
                { name = "精准", value = STAT_EXPERTISE },
                { name = "法术强度", value = ITEM_MOD_SPELL_POWER_SHORT },
            }
        elseif BG.IsRetail then
            BG.FilterClassItemDB.ShuXing = {
                { name = "精通", value = "%+%C-" .. ITEM_MOD_MASTERY_RATING_SHORT, name2 = ITEM_MOD_MASTERY_RATING_SHORT },
                { name = "爆击", value = "%+%C-" .. ITEM_MOD_CRIT_RATING_SHORT, name2 = ITEM_MOD_CRIT_RATING_SHORT },
                { name = "急速", value = "%+%C-" .. ITEM_MOD_HASTE_RATING_SHORT, name2 = ITEM_MOD_HASTE_RATING_SHORT },
                { name = "全能", value = "%+%C-" .. ITEM_MOD_VERSATILITY, name2 = ITEM_MOD_VERSATILITY },
            }
        end

        for _, v in pairs(BG.FilterClassItemDB.ShuXing) do
            if type(v.value) ~= "table" then
                v.name2 = v.name2 or v.value:gsub("%%s", "xx")
                v.value = { v.value }
            end
            for i in pairs(v.value) do
                v.value[i] = v.value[i]:gsub("%%s", "(.+)")
            end
        end

        local tbl = {}
        for _, v in pairs(BG.FilterClassItemDB.ShuXing) do
            tbl[v.name] = v
        end
        BG.FilterClassItemDB.ShuXing_filter = tbl
    end

    local function Insert(tbl1, tbl2)
        for i, v in ipairs(tbl2) do
            tinsert(tbl1, v)
        end
        return tbl1
    end
    local all = { "精通", "爆击", "急速", "全能", }
    local t0 = Insert(CopyTable(all), { "命中", "防御", "躲闪", "攻击强度", "精准", "护甲穿透", "近战攻击", "物理命中", "物理爆击", "击中时可能", })
    local t1 = Insert(CopyTable(t0), BG.verLess3 and { "力量", "敏捷", "招架" } or { "力量", "招架" }) -- DKT
    local t2 = Insert(CopyTable(t0), BG.verLess3 and { "力量", "敏捷", "招架", "格挡", "武器技能", } or { "力量", "招架", "格挡", }) -- 防战 防骑
    local t3 = Insert(CopyTable(t0), BG.verLess3 and { "力量", "敏捷", } or { "敏捷", }) -- 熊
    local t4 = Insert(CopyTable(t0), { "敏捷", "招架" }) -- 酒仙 DHT

    local dps0 = Insert(CopyTable(all), { "命中", "攻击强度", "精准", "护甲穿透", "近战攻击", "物理命中", "物理爆击", "武器技能", "击中时可能", })
    local dps1 = Insert(CopyTable(dps0), BG.verLess3 and { "力量", "敏捷", "智力", } or { "力量", }) -- KBZ/CJQ/DK
    local dps2 = Insert(CopyTable(dps0), BG.verLess3 and { "力量", "敏捷", } or { "敏捷", }) -- DZ/猫
    local dps3 = Insert(CopyTable(dps0), BG.verLess3 and { "力量", "敏捷", "智力", "法术强度", "法术命中", "法术爆击", } or { "敏捷", }) -- ZQS

    local lr0 = Insert(CopyTable(all), { "敏捷", "命中", "攻击强度", "护甲穿透", "远程攻击", "物理命中", "物理爆击", "武器技能", "击中时可能", })
    local lr1 = Insert(CopyTable(lr0), BG.verLess3 and { "智力", } or { "精准", }) -- LR

    local fx0 = Insert(CopyTable(all), { "智力", "命中", "法术强度", "法术伤害强度", "法术命中", "法术爆击", "特定法术强度", })
    local fx1 = Insert(CopyTable(fx0), BG.IsMOP and { "精准", "精神", } or { "精神", }) -- 法师 术士 暗牧 鸟德
    local fx2 = Insert(CopyTable(fx0), BG.IsMOP and { "精准", "5回法力值", } or { "5回法力值", }) -- 元素萨

    local n0 = Insert(CopyTable(all), { "智力", "5回法力值", "法术强度", "治疗强度", "法术爆击", })
    local n1 = Insert(CopyTable(n0), { "精神", }) -- 奶牧 奶德
    local n2 = Insert(CopyTable(n0), BG.IsMOP and { "精神", } or {}) -- 奶骑 奶萨

    BG.FilterClassItemInfo = {
        DEATHKNIGHT = {
            {
                icon = "Interface/Icons/spell_deathknight_classicon",
                name = L["死亡骑士"],
                notUseWeapon = {},
                notUseArmor = BG.verLess3 and {} or { "布甲", "皮甲", "锁甲", },
                Tank = {},
                useShuXing = Insert(CopyTable(t1), dps1),
                MainAttribute = { "力量", },
            },
            {
                icon = "Interface/Icons/spell_deathknight_bloodpresence",
                name = L["死亡骑士-鲜血"],
                notUseWeapon = { "单手斧", "单手锤", "单手剑", },
                notUseArmor = { "皮甲", "锁甲", },
                Tank = { "过滤坦克" },
                useShuXing = t1,
                MainAttribute = { "力量", },
            },
            {
                icon = "Interface/Icons/spell_deathknight_frostpresence",
                name = L["死亡骑士-冰霜"],
                notUseWeapon = {},
                notUseArmor = BG.verLess3 and {} or { "皮甲", "锁甲", },
                useShuXing = dps1,
                MainAttribute = { "力量", },
            },
            {
                icon = "Interface/Icons/spell_deathknight_unholypresence",
                name = L["死亡骑士-邪恶"],
                notUseWeapon = BG.verLess3 and {} or { "单手斧", "单手锤", "单手剑", },
                notUseArmor = BG.verLess3 and {} or { "皮甲", "锁甲", },
                useShuXing = dps1,
                MainAttribute = { "力量", },
            },
        },
        WARRIOR = {
            {
                icon = "Interface/Icons/classicon_WARRIOR",
                name = L["战士"],
                notUseWeapon = BG.verLess3 and {} or { "弓", "弩", "枪", },
                notUseArmor = BG.verLess3 and {} or { "布甲", "皮甲", "锁甲", },
                Tank = {},
                useShuXing = Insert(CopyTable(t2), dps1),
                MainAttribute = { "力量", },
            },
            {
                icon = "Interface/Icons/ability_warrior_defensivestance",
                name = L["战士-防御"],
                notUseWeapon = BG.verLess3 and { "双手斧", "双手锤", "双手剑", "长柄武器", "法杖", } or { "双手斧", "双手锤", "双手剑", "长柄武器", "法杖", "弓", "弩", "枪", },
                notUseArmor = { "皮甲", "锁甲", },
                Tank = { "过滤坦克" },
                useShuXing = t2,
                MainAttribute = { "力量", },
            },
            {
                icon = "Interface/Icons/ability_warrior_savageblow",
                name = L["战士-武器"],
                notUseWeapon = BG.verLess3 and { "匕首", "拳套", "单手斧", "单手锤", "单手剑", } or { "匕首", "拳套", "单手斧", "单手锤", "单手剑", "弓", "弩", "枪", },
                notUseArmor = BG.verLess3 and { "盾牌", } or { "皮甲", "锁甲", "盾牌", },
                useShuXing = dps1,
                MainAttribute = { "力量", },
            },
            {
                icon = "Interface/Icons/ability_warrior_innerrage",
                name = L["战士-狂怒"],
                notUseWeapon = BG.verLess2 and { "双手斧", "双手锤", "双手剑", "长柄武器", "法杖", } or { "匕首", "拳套", "单手斧", "单手锤", "单手剑", },
                notUseArmor = BG.verLess3 and { "盾牌", } or { "皮甲", "锁甲", "盾牌", },
                useShuXing = dps1,
                MainAttribute = { "力量", },
            },
        },
        PALADIN = {
            {
                icon = "Interface/Icons/classicon_paladin",
                name = L["圣骑士"],
                notUseWeapon = {},
                notUseArmor = BG.verLess3 and {} or { "布甲", "皮甲", "锁甲", },
                Tank = {},
                useShuXing = Insert(CopyTable(t2), Insert(CopyTable(dps1), n1)),
                MainAttribute = { "力量", "智力" },
            },
            {
                icon = "Interface/Icons/spell_holy_devotionaura",
                name = L["圣骑士-防御"],
                notUseWeapon = { "双手斧", "双手锤", "双手剑", "长柄武器", },
                notUseArmor = { "布甲", "皮甲", "锁甲", "副手物品", },
                Tank = { "过滤坦克" },
                useShuXing = t2,
                MainAttribute = { "力量", },
            },
            {
                icon = "Interface/Icons/spell_holy_auraoflight",
                name = L["圣骑士-惩戒"],
                notUseWeapon = { "单手斧", "单手锤", "单手剑", },
                notUseArmor = BG.verLess3 and { "布甲", "盾牌", "副手物品", } or { "布甲", "皮甲", "锁甲", "盾牌", "副手物品", },
                useShuXing = dps1,
                MainAttribute = { "力量", },
            },
            {
                icon = "Interface/Icons/spell_holy_holybolt",
                name = L["圣骑士-神圣"],
                notUseWeapon = { "双手斧", "双手锤", "双手剑", "长柄武器", },
                notUseArmor = BG.verLess3 and {} or { "布甲", "皮甲", "锁甲", },
                useShuXing = n2,
                MainAttribute = { "智力" },
            },
        },
        HUNTER = {
            {
                icon = "Interface/Icons/classicon_HUNTER",
                name = L["猎人"],
                notUseWeapon = BG.verLess3 and {} or { "匕首", "拳套", "单手斧", "单手剑", "双手斧", "双手剑", "长柄武器", "法杖", },
                notUseArmor = BG.verLess3 and {} or { "布甲", "皮甲", },
                Tank = {},
                useShuXing = lr1,
                MainAttribute = { "敏捷", },
            },
        },
        SHAMAN = {
            {
                icon = "Interface/Icons/classicon_SHAMAN",
                name = L["萨满"],
                notUseWeapon = {},
                notUseArmor = BG.verLess3 and {} or { "布甲", "皮甲", },
                Tank = {},
                useShuXing = Insert(CopyTable(dps3), Insert(CopyTable(fx2), n2)),
                MainAttribute = { "敏捷", "智力" },
            },
            {
                icon = "Interface/Icons/spell_nature_lightningshield",
                name = L["萨满-增强"],
                notUseWeapon = {},
                notUseArmor = BG.verLess3 and { "盾牌", "副手物品", } or { "布甲", "皮甲", "盾牌", "副手物品", },
                useShuXing = dps3,
                MainAttribute = { "敏捷", },
            },
            {
                icon = "Interface/Icons/spell_nature_lightning",
                name = L["萨满-元素"],
                notUseWeapon = { "双手斧", "双手锤", },
                notUseArmor = BG.verLess3 and {} or { "布甲", "皮甲", },
                useShuXing = fx2,
                MainAttribute = { "智力" },
            },
            {
                icon = "Interface/Icons/spell_nature_magicimmunity",
                name = L["萨满-恢复"],
                notUseWeapon = { "双手斧", "双手锤", },
                notUseArmor = BG.verLess3 and {} or { "布甲", "皮甲", },
                useShuXing = n2,
                MainAttribute = { "智力" },
            },
        },
        EVOKER = {
            {
                icon = "Interface/Icons/ClassIcon_Evoker",
                name = L["唤魔师"],
                notUseWeapon = {},
                notUseArmor = {},
                useShuXing = all,
                MainAttribute = { "智力" },
            },
        },
        DRUID = {
            {
                icon = "Interface/Icons/classicon_DRUID",
                name = L["德鲁伊"],
                notUseWeapon = {},
                notUseArmor = BG.verLess3 and {} or { "布甲", },
                Tank = {},
                useShuXing = Insert(CopyTable(t3), Insert(CopyTable(dps2), Insert(CopyTable(fx1), n1))),
                MainAttribute = { "敏捷", "智力" },
            },
            {
                icon = "Interface/Icons/ability_racial_bearform",
                name = L["德鲁伊-巨熊"],
                notUseWeapon = { "匕首", "拳套", "单手锤", },
                notUseArmor = BG.verLess3 and { "布甲", "副手物品", } or { "布甲", "副手物品", },
                useShuXing = t3,
                MainAttribute = { "敏捷" },
            },
            {
                icon = "Interface/Icons/ability_druid_catform",
                name = L["德鲁伊-猎豹"],
                notUseWeapon = { "匕首", "拳套", "单手锤", },
                notUseArmor = BG.verLess3 and { "布甲", "副手物品", } or { "布甲", "副手物品", },
                useShuXing = dps2,
                MainAttribute = { "敏捷" },
            },
            {
                icon = "Interface/Icons/spell_nature_starfall",
                name = L["德鲁伊-平衡"],
                notUseWeapon = { "双手锤", "长柄武器" },
                notUseArmor = BG.verLess3 and {} or { "布甲", },
                useShuXing = fx1,
                MainAttribute = { "智力" },
            },
            {
                icon = "Interface/Icons/spell_nature_healingtouch",
                name = L["德鲁伊-恢复"],
                notUseWeapon = { "双手锤", "长柄武器" },
                notUseArmor = BG.verLess3 and {} or { "布甲", },
                useShuXing = n1,
                MainAttribute = { "智力" },
            },
        },
        ROGUE = {
            {
                icon = "Interface/Icons/classicon_rogue",
                name = L["盗贼"],
                notUseWeapon = BG.verLess3 and {} or { "弓", "弩", "枪", },
                notUseArmor = {},
                useShuXing = dps2,
                MainAttribute = { "敏捷" },
            },
        },
        MONK = {
            {
                icon = "Interface/Icons/classicon_MONK",
                name = L["武僧"],
                notUseWeapon = {},
                notUseArmor = BG.verLess3 and {} or { "布甲", },
                Tank = {},
                useShuXing = Insert(CopyTable(t4), Insert(CopyTable(dps2), n1)),
                MainAttribute = { "敏捷", "智力" },
            },
            {
                icon = "Interface/Icons/spell_monk_brewmaster_spec",
                name = L["武僧-酒仙"],
                notUseWeapon = {},
                notUseArmor = { "副手物品", },
                useShuXing = t4,
                MainAttribute = { "敏捷" },
            },
            {
                icon = "Interface/Icons/spell_monk_windwalker_spec",
                name = L["武僧-踏风"],
                notUseWeapon = {},
                notUseArmor = { "副手物品", },
                useShuXing = dps2,
                MainAttribute = { "敏捷" },
            },
            {
                icon = "Interface/Icons/spell_monk_mistweaver_spec",
                name = L["武僧-织雾"],
                notUseWeapon = { "长柄武器", },
                notUseArmor = {},
                useShuXing = n1,
                MainAttribute = { "智力" },
            },
        },
        DEMONHUNTER = {
            {
                icon = "Interface/Icons/classicon_DEMONHUNTER",
                name = L["恶魔猎手"],
                notUseWeapon = {},
                notUseArmor = {},
                useShuXing = all,
                MainAttribute = { "敏捷", "智力" },
            },
            {
                icon = "Interface/Icons/Ability_DemonHunter_SpecTank",
                name = L["恶魔猎手-复仇"],
                notUseWeapon = {},
                notUseArmor = {},
                useShuXing = all,
                MainAttribute = { "敏捷" },
            },
            {
                icon = "Interface/Icons/ability_demonhunter_specdps",
                name = L["恶魔猎手-浩劫"],
                notUseWeapon = {},
                notUseArmor = {},
                useShuXing = all,
                MainAttribute = { "敏捷" },
            },
            {
                icon = "Interface/Icons/classicon_demonhunter_void",
                name = L["恶魔猎手-噬灭"],
                notUseWeapon = {},
                notUseArmor = {},
                useShuXing = all,
                MainAttribute = { "智力" },
            },
        },
        PRIEST = {
            {
                icon = "Interface/Icons/classicon_PRIEST",
                name = L["牧师"],
                notUseWeapon = {},
                notUseArmor = {},
                Tank = {},
                useShuXing = Insert(CopyTable(fx1), n1),
                MainAttribute = { "智力" },
            },
            {
                icon = "Interface/Icons/spell_shadow_shadowwordpain",
                name = L["牧师-暗影"],
                notUseWeapon = {},
                notUseArmor = {},
                useShuXing = fx1,
                MainAttribute = { "智力" },
            },
            {
                icon = "Interface/Icons/spell_holy_wordfortitude",
                name = L["牧师-戒律"],
                notUseWeapon = {},
                notUseArmor = {},
                useShuXing = n1,
                MainAttribute = { "智力" },
            },
            {
                icon = "Interface/Icons/spell_holy_guardianspirit",
                name = L["牧师-神圣"],
                notUseWeapon = {},
                notUseArmor = {},
                useShuXing = n1,
                MainAttribute = { "智力" },
            },
        },
        MAGE = {
            {
                icon = "Interface/Icons/classicon_mage",
                name = L["法师"],
                notUseWeapon = {},
                notUseArmor = {},
                useShuXing = fx1,
                MainAttribute = { "智力" },
            },
        },
        WARLOCK = {
            {
                icon = "Interface/Icons/classicon_warlock",
                name = L["术士"],
                notUseWeapon = {},
                notUseArmor = {},
                useShuXing = fx1,
                MainAttribute = { "智力" },
            },
        },
    }
    if BG.IsRetail then
        tinsert(BG.FilterClassItemInfo.HUNTER,
            {
                icon = "Interface/Icons/ability_hunter_beasttaming",
                name = L["猎人-兽王"],
                notUseWeapon = BG.verLess3 and {} or { "匕首", "拳套", "单手斧", "单手剑", "长柄武器", "法杖", },
                notUseArmor = BG.verLess3 and {} or { "皮甲", },
                useShuXing = lr1,
                MainAttribute = { "敏捷", },
            }
        )
        tinsert(BG.FilterClassItemInfo.HUNTER,
            {
                icon = "Interface/Icons/ability_marksmanship",
                name = L["猎人-射击"],
                notUseWeapon = BG.verLess3 and {} or { "匕首", "拳套", "单手斧", "单手剑", "长柄武器", "法杖", },
                notUseArmor = BG.verLess3 and {} or { "皮甲", },
                useShuXing = lr1,
                MainAttribute = { "敏捷", },
            }
        )
        tinsert(BG.FilterClassItemInfo.HUNTER,
            {
                icon = "Interface/Icons/ability_hunter_camouflage",
                name = L["猎人-生存"],
                notUseWeapon = BG.verLess3 and {} or { "弓", "弩", "枪" },
                notUseArmor = BG.verLess3 and {} or { "皮甲", },
                useShuXing = lr1,
                MainAttribute = { "敏捷", },
            }
        )
    end

    BG.MaxFilter = #BG.FilterClassItemInfo[class]
    for index, v in ipairs(BG.FilterClassItemInfo[class]) do
        BG.FilterClassItemInfo[class][index].Class = { "过滤职业限定" }
        BG.FilterClassItemInfo[class][index].BnetAccount = { "忽略战网绑定" }
        if not BG.FilterClassItemInfo[class][index].Tank then
            BG.FilterClassItemInfo[class][index].Tank = {}
        end
        db[index] = db[index] or {}
        db[index].Icon = v.icon
        db[index].Name = v.name
        -- 武器、护甲
        for _, type in ipairs({ "Weapon", "Armor", }) do
            local tbl = type == "Weapon" and WeaponIDs or ArmorIDs
            local canUseTbl = CopyTable(canUse[type][class])
            -- 剔除排除项
            for i = #canUseTbl, 1, -1 do
                for _, key in pairs(v["notUse" .. type]) do
                    if canUseTbl[i] == key then
                        tremove(canUseTbl, i)
                        break
                    end
                end
            end
            -- 把不能用的类型添加到初始化数据库
            local new = {}
            for key, id in pairs(tbl) do
                local yes = true
                for _, _key in pairs(canUseTbl) do
                    if key == _key then
                        yes = false
                        break
                    end
                end
                if yes then
                    tinsert(new, id)
                end
            end
            BG.FilterClassItemInfo[class][index][type] = new
            -- 创建初始化数据库
            if not db[index][type] then
                db[index][type] = {}
                for _, id in ipairs(new) do
                    db[index][type][id] = 1
                end
            end
        end
        -- 词缀
        do
            local type = "ShuXing"
            -- 剔除排除项
            local new = {}
            for _, v2 in pairs(BG.FilterClassItemDB[type]) do
                local yes = true
                for _, key in pairs(v["use" .. type]) do
                    if v2.name == key then
                        yes = false
                        break
                    end
                end
                if yes then
                    tinsert(new, v2.name)
                end
            end
            BG.FilterClassItemInfo[class][index][type] = new
            -- 创建初始化数据库
            if not db[index][type] then
                db[index][type] = {}
                for _, id in ipairs(new) do
                    db[index][type][id] = 1
                end
            end
        end
        -- 职业、战网绑定、坦克
        for _, type in ipairs({ "Class", "BnetAccount", "Tank" }) do
            if not db[index][type] then
                db[index][type] = {}
                for _, key in pairs(v[type]) do
                    db[index][type][key] = 1
                end
            end
        end
        -- 主属性
        if BG.IsRetail then
            local type = "MainAttribute"
            if not db[index][type] then
                db[index][type] = {}
                for _, key in pairs(v[type]) do
                    db[index][type][key] = 1
                end
            end
        end
    end

    -- 按钮图标
    do
        local tex = UIParent:CreateTexture()
        tex:SetSize(20, 20)
        tex:SetPoint("CENTER")
        tex:Hide()
        BG.FilterClassItemDB.NewIcon = {}
        local classIcon = {
            "Interface/Icons/spell_deathknight_classicon",
            "Interface/Icons/classicon_WARRIOR",
            "Interface/Icons/classicon_paladin",
            "Interface/Icons/classicon_HUNTER",
            "Interface/Icons/classicon_SHAMAN",
            "Interface/Icons/ClassIcon_Evoker",
            "Interface/Icons/classicon_DRUID",
            "Interface/Icons/classicon_rogue",
            "Interface/Icons/classicon_MONK",
            "Interface/Icons/classicon_DEMONHUNTER",
            "Interface/Icons/classicon_PRIEST",
            "Interface/Icons/classicon_mage",
            "Interface/Icons/classicon_warlock",
        }
        for _, icon in ipairs(classIcon) do
            tex:SetTexture(icon)
            if tex:GetTexture() then
                tinsert(BG.FilterClassItemDB.NewIcon, icon)
            end
        end
        for class, v1 in pairs(BG.talentIcon) do
            for k, icon in pairs(v1) do
                tex:SetTexture(icon)
                if tex:GetTexture() then
                    tinsert(BG.FilterClassItemDB.NewIcon, icon)
                end
            end
        end
        if not BG.IsRetail and not BG.IsTBC then
            local tbl = {
                -- 额外
                135957, 237480, 135372,
                132369, 132337, 132362,
                135993, 135891, 135959,
                132180, 132293, 135826,
                135790, 136023, 237579,
                136078, 236162, 236168,
                132304, 132298, 136177,
                136183, 237558, 136228,
                135841, 236217, 135735,
                136200, 135936, 135940,
            }
            for _, icon in ipairs(tbl) do
                tex:SetTexture(icon)
                if tex:GetTexture() then
                    tinsert(BG.FilterClassItemDB.NewIcon, icon)
                end
            end
        end
    end
    -- 武器类型
    do
        BG.FilterClassItemDB.Weapon = {
            { name = "9", value = L["战刃"] },
            { name = "7", value = L["单手剑"] },
            { name = "0", value = L["单手斧"] },
            { name = "4", value = L["单手锤"] },
            { name = "15", value = L["匕首"] },
            { name = "13", value = L["拳套"] },
            { name = "8", value = L["双手剑"] },
            { name = "1", value = L["双手斧"] },
            { name = "5", value = L["双手锤"] },
            { name = "6", value = L["长柄武器"] },
            { name = "10", value = L["法杖"] },
            { name = "19", value = L["魔杖"] },
            { name = "2", value = L["弓"] },
            { name = "3", value = L["枪"] },
            { name = "18", value = L["弩"] },
            { name = "16", value = L["投掷武器"] },
        }

        if BG.IsRetail then
            -- 删除魔杖、投掷武器
            for i = #BG.FilterClassItemDB.Weapon, 1, -1 do
                local v = BG.FilterClassItemDB.Weapon[i]
                if v.name == "16" or v.name == "19" then
                    tremove(BG.FilterClassItemDB.Weapon, i)
                end
            end
        else
            -- 删除战刃
            for i = #BG.FilterClassItemDB.Weapon, 1, -1 do
                local v = BG.FilterClassItemDB.Weapon[i]
                if v.name == "9" then
                    tremove(BG.FilterClassItemDB.Weapon, i)
                end
            end
            -- 删除投掷武器
            if BG.verOver4 then
                for i = #BG.FilterClassItemDB.Weapon, 1, -1 do
                    local v = BG.FilterClassItemDB.Weapon[i]
                    if v.name == "16" then
                        tremove(BG.FilterClassItemDB.Weapon, i)
                    end
                end
            end
        end
    end
    -- 护甲类型
    do
        BG.FilterClassItemDB.Armor = {
            { name = "1", value = L["布甲"], onenter = L["全部布甲会被过滤（披风除外，否则本来合适你的披风也可能会被过滤）"] },
            { name = "2", value = L["皮甲"] },
            { name = "3", value = L["锁甲"] },
            { name = "4", value = L["板甲"] },
            { name = "6", value = SHIELDSLOT },
            { name = "0", value = INVTYPE_HOLDABLE },
        }
        if BG.verLess2 then
            for i, v in ipairs({
                { name = "7", value = L["圣契"] },
                { name = "8", value = L["神像"] },
                { name = "9", value = L["图腾"] },
            }) do
                tinsert(BG.FilterClassItemDB.Armor, v)
            end
        elseif BG.IsWLK or BG.IsCTM then
            for i, v in ipairs({
                { name = "7", value = L["圣契"] },
                { name = "8", value = L["神像"] },
                { name = "9", value = L["图腾"] },
                { name = "10", value = L["魔印"] },
            }) do
                tinsert(BG.FilterClassItemDB.Armor, v)
            end
        end
    end
    -- 职业限定
    do
        BG.FilterClassItemDB.Class = {
            { name = "过滤职业限定", value = L["过滤职业限定的装备"], },
        }
    end
    -- 忽略战网绑定
    do
        BG.FilterClassItemDB.BnetAccount = {
            { name = "忽略战网绑定", value = L["忽略战网绑定的装备"], },
        }
        for index in ipairs(db) do
            db[index]["BnetAccount"] = db[index]["BnetAccount"] or {}
        end
    end
    -- 坦克特殊过滤
    do
        local type = "Tank"
        if BG.verOver3 and not BG.IsRetail then
            BG.FilterClassItemDB[type] = {
                { name = "过滤坦克", value = L["过滤没有坦克属性的装备"], },
            }

            BG.FilterClassItem_Default.TankKey = {
                STAT_CATEGORY_DEFENSE,
                STAT_PARRY,
                STAT_DODGE,
                STAT_BLOCK,
            }
            if BG.verOver4 then
                tinsert(BG.FilterClassItem_Default.TankKey, STAT_MASTERY)
            end
        else
            for i = 1, BG.MaxFilter do
                BiaoGe.FilterClassItemDB[RealmID][player][i][type] = nil
            end
        end
    end
    -- 主属性
    if BG.IsRetail then
        BG.FilterClassItemDB.MainAttribute = {
            { name = "力量", value = ITEM_MOD_STRENGTH_SHORT, key = "ITEM_MOD_STRENGTH_SHORT" },
            { name = "敏捷", value = ITEM_MOD_AGILITY_SHORT, key = "ITEM_MOD_AGILITY_SHORT" },
            { name = "智力", value = ITEM_MOD_INTELLECT_SHORT, key = "ITEM_MOD_INTELLECT_SHORT" },
        }
        BG.FilterClassItemDB.MainAttribute_filter = {}
        for k, v in pairs(BG.FilterClassItemDB.MainAttribute) do
            BG.FilterClassItemDB.MainAttribute_filter[v.name] = v.key
        end
        for index in ipairs(db) do
            db[index]["MainAttribute"] = db[index]["MainAttribute"] or {}
        end
    end
end)
