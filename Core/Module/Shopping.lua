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
local GetClassName = ns.GetClassName
local CreateLine = ns.CreateLine
local SendSystemMessage = ns.SendSystemMessage
local ver = ns.ver
local After = C_Timer.After
local player = UnitName("player")
local realmID = GetRealmID()

local pt = print
local RealmID = GetRealmID()

local tbl = {}
if BG.IsMOP then
    tbl = {
        {
            icon = "Interface\\Icons\\Spell_Deathknight_BloodPresence", -- DKT
            itemID = {
                86656, 86654, 86658, 86657, 86655, 85316, 85314, 85318, 85317, 85315, 86920, 86922, 86918, 86919, 86921,
                95830, 95832, 95834, 95831, 95833, 95230, 95232, 95234, 95231, 95233, 96574, 96576, 96578, 96575, 96577,
                99049, 99040, 99060, 99048, 99039, 99605, 99652, 99640, 99604, 99564, 99190, 99179, 99188, 99189, 99191, 99323, 99325, 99330, 99331, 99324,
            }
        },
        {
            icon = "Interface\\Icons\\inv_sword_122", -- 输出DK
            itemID = {
                86676, 86674, 86678, 86677, 86675, 85336, 85334, 85338, 85337, 85335, 86915, 86917, 86913, 86914, 86916,
                96569, 96571, 96573, 96570, 96572, 95225, 95227, 95229, 95226, 95228, 95825, 95827, 95829, 95826, 95828,
                99057, 99059, 99066, 99067, 99058, 99571, 99639, 99608, 99609, 99572, 99194, 99187, 99192, 99193, 99186, 99337, 99339, 99335, 99336, 99338,
            }
        },
        {
            icon = "Interface\\Icons\\ability_warrior_defensivestance", -- FZ
            itemID = {
                86666, 86664, 86668, 86667, 86665, 85326, 85324, 85328, 85327, 85325, 87199, 87201, 87197, 87198, 87200,
                95993, 95995, 95991, 95992, 95994, 95337, 95339, 95335, 95336, 95338, 96737, 96739, 96735, 96736, 96738,
                99032, 99030, 99037, 99038, 99033, 99557, 99597, 99562, 99563, 99558, 99203, 99196, 99201, 99202, 99195, 99409, 99407, 99415, 99408, 99410,
            }
        },
        {
            icon = "Interface\\Icons\\INV_Sword_48", -- 输出ZS
            itemID = {
                86673, 86669, 86672, 86671, 86670, 85333, 85329, 85332, 85331, 85330, 87192, 87196, 87193, 87194, 87195,
                96730, 96734, 96731, 96732, 96733, 95330, 95334, 95331, 95332, 95333, 95986, 95990, 95987, 95988, 95989,
                99046, 99036, 99047, 99034, 99035, 99602, 99561, 99603, 99559, 99560, 99206, 99200, 99197, 99198, 99199, 99418, 99414, 99411, 99412, 99413,
            }
        },
        {
            icon = "Interface\\Icons\\spell_holy_holybolt", -- NQ
            itemID = {
                87106, 87108, 87104, 87105, 87107, 85346, 85344, 85348, 85347, 85345, 86686, 86684, 86688, 86687, 86685,
                95917, 95919, 95915, 95916, 95918, 95287, 95289, 95285, 95286, 95288, 96661, 96663, 96659, 96660, 96662,
                99003, 98979, 99076, 98982, 98980, 99626, 99665, 99656, 99648, 99666, 99133, 99135, 99125, 99134, 99124, 99374, 99376, 99378, 99375, 99377,
            }
        },

        {
            icon = "Interface\\Icons\\spell_holy_devotionaura", -- FQ
            itemID = {
                86661, 86659, 86663, 86662, 86660, 85321, 85319, 85323, 85322, 85320, 87101, 87103, 87099, 87100, 87102,
                96666, 96668, 96664, 96665, 96667, 95292, 95294, 95290, 95291, 95293, 95922, 95924, 95920, 95921, 95923,
                99031, 99029, 99027, 99028, 99026, 99598, 99596, 99594, 99595, 99593, 99126, 99128, 99130, 99127, 99129, 99368, 99370, 99364, 99369, 99371,
            }
        },
        {
            icon = "Interface\\Icons\\spell_holy_auraoflight", -- CJQ
            itemID = {
                87101, 87103, 87099, 87100, 87102, 85341, 85339, 85343, 85342, 85340, 86681, 86679, 86683, 86682, 86680,
                95912, 95914, 95910, 95911, 95913, 95282, 95284, 95280, 95281, 95283, 96656, 96658, 96654, 96655, 96657,
                99052, 98985, 98987, 99002, 98986, 99566, 99651, 99662, 99625, 99661, 99136, 99138, 99132, 99137, 99139, 99387, 99379, 99373, 99380, 99372,
            }
        },
        {
            icon = "Interface\\Icons\\spell_nature_lightning", -- 元素
            itemID = {
                86631, 86633, 86629, 86630, 86632, 85291, 85293, 85289, 85290, 85292, 87141, 87143, 87139, 87140, 87142,
                95950, 95952, 95954, 95951, 95953, 95320, 95322, 95324, 95321, 95323, 96694, 96696, 96698, 96695, 96697,
                99087, 99089, 99091, 99088, 99090, 99579, 99645, 99647, 99580, 99646, 99106, 99093, 99095, 99092, 99094, 99344, 99332, 99334, 99345, 99333,
            }
        },
        {
            icon = "Interface\\Icons\\spell_nature_lightningshield", -- ZQ
            itemID = {
                86626, 86624, 86628, 86627, 86625, 85286, 85284, 85288, 85287, 85285, 87136, 87138, 87134, 87135, 87137,
                95947, 95949, 95945, 95946, 95948, 95317, 95319, 95315, 95316, 95318, 96691, 96693, 96689, 96690, 96692,
                98992, 98983, 98977, 98993, 98984, 99615, 99649, 99663, 99616, 99650, 99101, 99103, 99105, 99102, 99104, 99347, 99341, 99343, 99340, 99342,
            }
        },
        {
            icon = "Interface\\Icons\\spell_nature_magicimmunity", -- NS
            itemID = {
                87131, 87133, 87129, 87130, 87132, 85351, 85349, 85353, 85352, 85350, 86691, 86689, 86693, 86692, 86690,
                95940, 95942, 95944, 95941, 95943, 95310, 95312, 95314, 95311, 95313, 96684, 96686, 96688, 96685, 96687,
                99011, 98989, 98991, 98988, 98990, 99636, 99612, 99614, 99611, 99613, 99107, 99109, 99100, 99108, 99099, 99351, 99353, 99346, 99352, 99354,
            }
        },
        {
            icon = "Interface\\Icons\\spell_nature_starfall", -- 鸟
            itemID = {
                86647, 86644, 86645, 86648, 86646, 85307, 85304, 85305, 85308, 85306, 86934, 86937, 86936, 86933, 86935,
                95848, 95846, 95849, 95845, 95847, 95248, 95246, 95249, 95245, 95247, 96592, 96590, 96593, 96589, 96591,
                98995, 98998, 98997, 98994, 98996, 99618, 99621, 99620, 99617, 99619, 99175, 99169, 99177, 99174, 99176, 99433, 99428, 99427, 99432, 99434,
            }
        },
        {
            icon = "Interface\\Icons\\ability_racial_bearform", -- 熊
            itemID = {
                86721, 86723, 86719, 86720, 86722, 85381, 85383, 85379, 85380, 85382, 86940, 86942, 86938, 86939, 86941,
                95850, 95852, 95854, 95851, 95853, 95250, 95252, 95254, 95251, 95253, 96594, 96596, 96598, 96595, 96597,
                99001, 98978, 98999, 99000, 98981, 99624, 99664, 99622, 99623, 99610, 99164, 99166, 99170, 99163, 99165, 99421, 99423, 99419, 99420, 99422,
            }
        },
        {
            icon = "Interface\\Icons\\ability_druid_catform", -- 猫
            itemID = {
                86925, 86927, 86923, 86924, 86926, 85311, 85309, 85313, 85312, 85310, 86651, 86649, 86653, 86652, 86650,
                95835, 95837, 95839, 95836, 95838, 95235, 95237, 95239, 95236, 95238, 96579, 96581, 96583, 96580, 96582,
                99043, 99022, 99041, 99042, 99044, 99599, 99589, 99632, 99633, 99600, 99182, 99184, 99180, 99181, 99183, 99328, 99322, 99326, 99327, 99329,
            }
        },
        {
            icon = "Interface\\Icons\\spell_nature_healingtouch", -- ND
            itemID = {
                86929, 86932, 86931, 86928, 86930, 85357, 85354, 85355, 85358, 85356, 86697, 86694, 86695, 86698, 86696,
                95843, 95841, 95844, 95840, 95842, 95243, 95241, 95244, 95240, 95242, 96587, 96585, 96588, 96584, 96586,
                99013, 99016, 99015, 99012, 99014, 99638, 99583, 99582, 99637, 99581, 99178, 99173, 99172, 99185, 99171, 99436, 99431, 99430, 99435, 99429,
            }
        },
        {
            icon = "Interface\\Icons\\spell_holy_wordfortitude", -- 奶牧
            itemID = {
                87115, 87118, 87117, 87114, 87116, 85362, 85359, 85360, 85363, 85361, 86702, 86699, 86700, 86703, 86701,
                95928, 95926, 95929, 95925, 95927, 95298, 95296, 95299, 95295, 95297, 96672, 96670, 96673, 96669, 96671,
                99017, 99024, 99018, 99023, 99025, 99584, 99591, 99585, 99590, 99592, 99119, 99117, 99120, 99131, 99118, 99357, 99366, 99358, 99365, 99367,
            }
        },
        {
            icon = "Interface\\Icons\\spell_shadow_shadowwordpain", -- AM
            itemID = {
                86705, 86708, 86707, 86704, 86706, 85365, 85368, 85367, 85364, 85366, 87120, 87123, 87122, 87119, 87121,
                95933, 95931, 95934, 95930, 95932, 95303, 95301, 95304, 95300, 95302, 96677, 96675, 96678, 96674, 96676,
                99004, 99020, 99005, 99019, 99021, 99627, 99587, 99628, 99586, 99588, 99110, 99122, 99111, 99121, 99123, 99362, 99360, 99363, 99359, 99361,
            }
        },
        {
            icon = "Interface\\Icons\\spell_monk_brewmaster_spec", -- 酒仙
            itemID = {
                86726, 86724, 86728, 86727, 86725, 85386, 85384, 85388, 85387, 85385, 87096, 87098, 87094, 87095, 87097,
                95907, 95909, 95905, 95906, 95908, 95277, 95279, 95275, 95276, 95278, 96651, 96653, 96649, 96650, 96652,
                99063, 99065, 99051, 99064, 99050, 99643, 99607, 99565, 99644, 99606, 99140, 99142, 99144, 99141, 99143, 99382, 99384, 99386, 99383, 99385,
            }
        },
        {
            icon = "Interface\\Icons\\spell_monk_mistweaver_spec", -- 织雾
            itemID = {
                87090, 87093, 87092, 87089, 87091, 85390, 85393, 85392, 85389, 85391, 86730, 86733, 86732, 86729, 86731,
                95901, 95904, 95903, 95900, 95902, 95271, 95274, 95273, 95270, 95272, 96645, 96648, 96647, 96644, 96646,
                99061, 99069, 99062, 99068, 99070, 99641, 99553, 99642, 99552, 99554, 99150, 99148, 99151, 99147, 99149, 99391, 99389, 99381, 99388, 99390,
            }
        },
        {
            icon = "Interface\\Icons\\spell_monk_windwalker_spec", -- 踏风
            itemID = {
                87086, 87088, 87084, 87085, 87087, 85396, 85398, 85394, 85395, 85397, 86736, 86738, 86734, 86735, 86737,
                95897, 95899, 95895, 95896, 95898, 95267, 95269, 95265, 95266, 95268, 96641, 96643, 96639, 96640, 96642,
                99071, 99073, 99075, 99072, 99074, 99555, 99653, 99655, 99556, 99654, 99154, 99156, 99146, 99155, 99145, 99396, 99393, 99395, 99392, 99394,
            }
        },
    }
elseif BG.IsTitan or BG.IsTBC then
    tbl = {
        {
            icon = "Interface\\Icons\\Spell_Deathknight_BloodPresence", -- DKT
            itemID = {
                256079, 256072, 256077, 256076, 256073, 256078, 256074, 256075,
                264437, 264438, 264439, 264440, 264441,
                40565, 40568, 40559, 40563, 40567,
                48555, 48553, 48557, 48556, 48554,
            }
        },
        {
            icon = "Interface\\Icons\\inv_sword_122", -- 输出DK
            itemID = {
                257631, 257629, 257634, 257627, 257632, 257628, 257630, 257633,
                264442, 264443, 264444, 264445, 264446,
                40554, 40557, 40550, 40552, 40556,
                48498, 48496, 48500, 48499, 48497,
            }
        },
        {
            icon = "Interface\\Icons\\ability_warrior_defensivestance", -- FZ
            itemID = {
                -- MC 毒蛇风暴 NAXX 卡拉赞 十字军
                255080, 255082, 255079, 257602, 255077, 255078, 255081, 255076,
                30115, 30117, 30113, 30114, 30116,
                40546, 40548, 40544, 40545, 40547,
                29011, 29016, 29012, 29017, 29015,
                48463, 48465, 48461, 48462, 48464,
            }
        },
        {
            icon = "Interface\\Icons\\INV_Sword_48", -- 输出ZS
            itemID = {
                257615, 257613, 257618, 257611, 257616, 257612, 257614, 257617,
                30120, 30122, 30118, 30119, 30121,
                40528, 40530, 40525, 40527, 40529,
                29021, 29023, 29019, 29020, 29022,
                48393, 48395, 48391, 48392, 48394,
            }
        },
        {
            icon = "Interface\\Icons\\spell_holy_holybolt", -- NQ
            itemID = {
                255068, 255070, 255067, 255071, 255074, 255072, 255069, 255073,
                30136, 30138, 30134, 30135, 30137,
                40571, 40573, 40569, 40570, 40572,
                29061, 29064, 29062, 29065, 29063,
                48592, 48590, 48594, 48593, 48591,
            }
        },
        {
            icon = "Interface\\Icons\\spell_holy_devotionaura", -- FQ
            itemID = {
                257647, 257645, 257650, 257643, 257648, 257644, 257646, 257649,
                30125, 30127, 30123, 30124, 30126,
                40581, 40584, 40579, 40580, 40583,
                29068, 29070, 29066, 29067, 29069,
                48659, 48661, 48657, 48658, 48660,
            }
        },
        {
            icon = "Interface\\Icons\\spell_holy_auraoflight", -- CJQ
            itemID = {
                257637, 257635, 257639, 257640, 257638, 257642, 257636, 257641,
                30131, 30133, 30129, 30130, 30132,
                40576, 40578, 40574, 40575, 40577,
                29073, 29075, 29071, 29072, 29074,
                48624, 48622, 48626, 48625, 48623,
            }
        },
        {
            icon = "Interface\\Icons\\spell_nature_magicimmunity", -- 奶萨
            itemID = {
                255056, 255058, 255055, 255054, 255053, 255052, 255057, 255051,
                30166, 30168, 30164, 30165, 30167,
                40510, 40513, 40508, 40509, 40512,
                29028, 29031, 29029, 29032, 29030,
                48302, 48304, 48300, 48301, 48303,
            }
        },
        {
            icon = "Interface\\Icons\\spell_nature_lightning", -- 元素
            itemID = {
                257671, 257669, 257674, 257667, 257672, 257668, 257670, 257673,
                30171, 30173, 30169, 30170, 30172,
                40516, 40518, 40514, 40515, 40517,
                29035, 29037, 29033, 29034, 29036,
                48333, 48331, 48335, 48334, 48332,
            }
        },
        {
            icon = "Interface\\Icons\\spell_nature_lightningshield", -- 增强
            itemID = {
                257679, 257677, 257682, 257675, 257680, 257676, 257678, 257681,
                30190, 30194, 30185, 30189, 30192,
                40521, 40524, 40523, 40520, 40522,
                29040, 29043, 29038, 29039, 29042,
                48363, 48361, 48365, 48364, 48362,
            }
        },
        {
            icon = "Interface\\Icons\\spell_nature_healingtouch", -- 奶德
            itemID = {
                255048, 255050, 255047, 255045, 255046, 255043, 255049, 255044,
                30219, 30221, 30216, 30217, 30220,
                40461, 40465, 40463, 40460, 40462,
                29086, 29089, 29087, 29090, 29088,
                48151, 48148, 48149, 48152, 48150,
            }
        },
        {
            icon = "Interface\\Icons\\spell_nature_starfall", -- 鸟
            itemID = {
                257664, 257662, 257659, 257660, 257665, 257661, 257663, 257666,
                30233, 30235, 30231, 30232, 30234,
                40467, 40470, 40469, 40466, 40468,
                29093, 29095, 29091, 29092, 29094,
                48181, 48178, 48179, 48182, 48180,
            }
        },
        {
            icon = "Interface\\Icons\\ability_racial_bearform", -- 熊
            itemID = {
                257655, 257653, 257658, 257651, 257656, 257652, 257654, 257657,
                30228, 30230, 30222, 30223, 30229,
                40473, 40494, 40471, 40472, 40493,
                29098, 29100, 29096, 29097, 29099,
                48194, 48197, 48196, 48193, 48195,
            }
        },

        {
            icon = "Interface\\Icons\\spell_holy_wordfortitude", -- 奶牧
            itemID = {
                255029, 255032, 255031, 255034, 255028, 255033, 255030, 255027,
                30152, 30154, 30150, 30151, 30153,
                40447, 40450, 40449, 40445, 40448,
                29049, 29054, 29050, 29055, 29053,
                48065, 48062, 48063, 48066, 48064,
            }
        },
        {
            icon = "Interface\\Icons\\spell_shadow_shadowwordpain", -- AM
            itemID = {
                257621, 257624, 257623, 257626, 257620, 257625, 257622, 257619,
                30161, 30163, 30159, 30160, 30162,
                40456, 40459, 40458, 40454, 40457,
                29058, 29060, 29056, 29057, 29059,
                48095, 48092, 48093, 48096, 48094,
            }
        },
    }
end
local classItems = {}
for _, v in ipairs(tbl) do
    for _, itemID in ipairs(v.itemID) do
        classItems[itemID] = v.icon
    end
end

BG.Init(function()
    BiaoGe.showShopping = BiaoGe.showShopping or 0
end)

BG.Init2(function()
    local mainFrameWidth = 640
    local filterHeight = 30
    local buttonHeight = 45
    local buttonWidth = 153
    local slotTextWidth = 70
    local btScale = 0.9
    local MAX_MONEY_DISPLAY_WIDTH = 120
    local itemCountShow = 5
    local step = 570

    local slots = {
        { name = INVTYPE_HEAD, name2 = "INVTYPE_HEAD", key = { "INVTYPE_HEAD" } },                                                                 -- 头
        { name = INVTYPE_NECK, name2 = "INVTYPE_NECK", key = { "INVTYPE_NECK" } },                                                                 -- 项链
        { name = INVTYPE_SHOULDER, name2 = "INVTYPE_SHOULDER", key = { "INVTYPE_SHOULDER" } },                                                     -- 肩膀
        { name = INVTYPE_CLOAK, name2 = "INVTYPE_CLOAK", key = { "INVTYPE_CLOAK" } },                                                              -- 背
        { name = INVTYPE_CHEST, name2 = "INVTYPE_CHEST", key = { "INVTYPE_CHEST", "INVTYPE_ROBE" } },                                              -- 胸
        { name = INVTYPE_WRIST, name2 = "INVTYPE_WRIST", key = { "INVTYPE_WRIST" } },                                                              -- 手腕
        { name = INVTYPE_HAND, name2 = "INVTYPE_HAND", key = { "INVTYPE_HAND" } },                                                                 -- 手
        { name = INVTYPE_WAIST, name2 = "INVTYPE_WAIST", key = { "INVTYPE_WAIST" } },                                                              -- 腰带
        { name = INVTYPE_LEGS, name2 = "INVTYPE_LEGS", key = { "INVTYPE_LEGS" } },                                                                 -- 腿
        { name = INVTYPE_FEET, name2 = "INVTYPE_FEET", key = { "INVTYPE_FEET" } },                                                                 -- 脚
        { name = INVTYPE_FINGER, name2 = "INVTYPE_FINGER", key = { "INVTYPE_FINGER" } },                                                           -- 戒指
        { name = INVTYPE_TRINKET, name2 = "INVTYPE_TRINKET", key = { "INVTYPE_TRINKET" } },                                                        -- 饰品
        { name = TWO_HANDED, name2 = "TWO_HANDED", key = { "INVTYPE_2HWEAPON" } },                                                                 -- 双手
        { name = INVTYPE_WEAPON, name2 = "INVTYPE_WEAPON", key = { "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND" } },                                 -- 单手
        { name = INVTYPE_SHIELD, name2 = "INVTYPE_SHIELD", key = { "INVTYPE_SHIELD", "INVTYPE_HOLDABLE", "INVTYPE_WEAPONOFFHAND" } },              -- 副手
        { name = INVTYPE_RANGED, name2 = "INVTYPE_RANGED", key = { "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT", "INVTYPE_THROWN", "INVTYPE_RELIC" } }, -- 远程
        { name = L["职业相关"], name2 = L["职业相关"], key = {} },
        { name = L["其他"], name2 = L["其他"], key = {} },
    }

    local mainFrame = CreateFrame("Frame", nil, MerchantFrame, "BackdropTemplate")
    do
        do
            mainFrame:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            mainFrame:SetBackdropColor(0, 0, 0, 0.8)
            mainFrame:SetBackdropBorderColor(1, 1, 1, BG.borderAlpha)
            mainFrame:SetSize(mainFrameWidth, 500)
            mainFrame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 2, 0)
            mainFrame:EnableMouse(true)
            mainFrame:Hide()
            mainFrame.slots = {}
            mainFrame.slotTexts = {}
            mainFrame.buttons = {}
            mainFrame.CloseButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
            mainFrame.CloseButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 5, 5)
            mainFrame.CloseButton:HookScript("OnClick", function()
                BiaoGe.showShopping = 0
            end)
            local l = mainFrame:CreateLine()
            l:SetColorTexture(1, 1, 1, BG.borderAlpha)
            l:SetStartPoint("TOPLEFT", 1, -21)
            l:SetEndPoint("TOPRIGHT", -1, -21)
            l:SetThickness(1)
            mainFrame.titleText = mainFrame:CreateFontString()
            mainFrame.titleText:SetPoint("TOP", 0, -2)
            mainFrame.titleText:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            mainFrame.titleText:SetText(L["商品总览"])
            mainFrame:SetScript("OnShow", function(self)
            end)
            mainFrame:SetScript("OnHide", function(self)
            end)
            mainFrame:SetScript("OnEvent", function(self, event, ...)
            end)
        end

        local function CreateHorizontalScrollFrameWithTemplate()
            -- 1. 创建基础滚动框（使用内置模板）
            local scrollFrame = CreateFrame("ScrollFrame", "BGMerchantItemScrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
            scrollFrame:SetPoint("TOPLEFT", slotTextWidth, -20 - filterHeight)
            scrollFrame:SetPoint("BOTTOMRIGHT", -5, 0)

            -- 5. 创建内容框
            local scrollChild = CreateFrame("Frame", nil, scrollFrame)
            scrollFrame:SetScrollChild(scrollChild)
            scrollChild:SetPoint("CENTER")
            scrollChild:SetSize(1, 1)
            scrollFrame.child = scrollChild

            -- 2. 获取模板自带的滚动条并改造为横向
            local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
            scrollBar:Hide()
            scrollBar:ClearAllPoints()
            scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMLEFT", 15, 3)
            scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -15, 3)
            scrollBar:SetHeight(16)
            scrollBar:SetOrientation("HORIZONTAL")
            scrollBar.scrollStep = step
            BG.CreateSrollBarBackdrop(scrollBar)

            -- 3. 修复滚动条箭头（旋转+启用+位置）
            local upButton = _G[scrollBar:GetName() .. "ScrollUpButton"]     -- 左箭头（原上箭头）
            local downButton = _G[scrollBar:GetName() .. "ScrollDownButton"] -- 右箭头（原下箭头）
            upButton:GetNormalTexture():SetRotation(math.rad(90))            -- 上箭头→左箭头（逆时针90度）
            upButton:GetPushedTexture():SetRotation(math.rad(90))
            upButton:GetDisabledTexture():SetRotation(math.rad(90))
            upButton:GetHighlightTexture():SetRotation(math.rad(90))
            downButton:GetNormalTexture():SetRotation(math.rad(90)) -- 下箭头→右箭头（顺时针90度）
            downButton:GetPushedTexture():SetRotation(math.rad(90))
            downButton:GetDisabledTexture():SetRotation(math.rad(90))
            downButton:GetHighlightTexture():SetRotation(math.rad(90))
            upButton:ClearAllPoints()
            upButton:SetPoint("LEFT", scrollBar, "LEFT", -16, 1)
            upButton:SetSize(16, 16)
            downButton:ClearAllPoints()
            downButton:SetPoint("RIGHT", scrollBar, "RIGHT", 16, 1)
            downButton:SetSize(16, 16)

            -- 关键：启用箭头按钮（模板默认可能禁用）
            upButton:Enable()
            downButton:Enable()

            -- 4. 修复箭头点击逻辑+状态同步
            local function UpdateArrowStates()
                local currentX = scrollFrame:GetHorizontalScroll()
                local maxX = scrollFrame:GetHorizontalScrollRange()
                -- 左箭头：滚动到最左侧时禁用
                if currentX <= 0 then
                    upButton:Disable()
                else
                    upButton:Enable()
                end
                -- 右箭头：滚动到最右侧时禁用
                if currentX >= maxX then
                    downButton:Disable()
                else
                    downButton:Enable()
                end
            end

            -- 左箭头点击（左移）
            upButton:SetScript("OnClick", function()
                local current = scrollFrame:GetHorizontalScroll()
                local new = math.max(0, current - 50)
                scrollFrame:SetHorizontalScroll(new)
                UpdateArrowStates() -- 点击后更新状态
            end)

            -- 右箭头点击（右移）
            downButton:SetScript("OnClick", function()
                local current = scrollFrame:GetHorizontalScroll()
                local maxX = scrollFrame:GetHorizontalScrollRange()
                local new = math.min(maxX, current + 50)
                scrollFrame:SetHorizontalScroll(new)
                UpdateArrowStates() -- 点击后更新状态
            end)

            -- 7. 同步滚动条与滚动位置+箭头状态
            scrollFrame:SetScript("OnScrollRangeChanged", function(self, xRange, yRange)
                scrollBar:SetMinMaxValues(0, xRange)
                scrollBar:SetValue(self:GetHorizontalScroll())
                UpdateArrowStates() -- 范围变化时更新状态

                if xRange <= 8 then
                    self.ScrollBar:Hide()
                else
                    self.ScrollBar:Show()
                end
            end)

            scrollBar:SetScript("OnValueChanged", function(self, value)
                scrollFrame:SetHorizontalScroll(value)
                UpdateArrowStates() -- 滚动条拖动时更新状态
            end)

            scrollFrame:SetScript("OnHorizontalScroll", function(self, value)
                scrollBar:SetValue(value)
                UpdateArrowStates() -- 滚动时更新状态
            end)

            -- 8. 鼠标滚轮支持+状态同步
            scrollFrame:SetScript("OnMouseWheel", function(self, delta)
                local currentX = self:GetHorizontalScroll()
                local maxX = self:GetHorizontalScrollRange()
                local newX = currentX - delta * step
                newX = math.max(0, math.min(newX, maxX))
                self:SetHorizontalScroll(newX)
                UpdateArrowStates() -- 滚轮后更新状态
            end)

            -- 初始化箭头状态
            UpdateArrowStates()

            return scrollFrame, scrollChild
        end

        local scroll, child = CreateHorizontalScrollFrameWithTemplate()
        mainFrame.scroll = scroll
        mainFrame.child = child

        local Buttons = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
        do
            Buttons:SetPoint("TOP", 10, -25)
            Buttons:SetSize(0, 30)
            Buttons.type = 3
            mainFrame.filterButtons = Buttons
            tinsert(BG.filterClassButtons, Buttons)

            local t = Buttons:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetText(L["装备过滤："])
            t:SetTextColor(1, 0.82, 0)
            t:SetPoint("RIGHT", Buttons, "LEFT", -10, 0)
            BG.CreateFilterClassButtons(Buttons)
        end
    end

    local bt = BG.CreateButton(MerchantFrame)
    do
        bt:SetPoint("TOPRIGHT", -10, -30)
        bt:SetText(L["商品总览"])
        bt:SetSize(100, 25)
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            if mainFrame:IsVisible() then
                BiaoGe.showShopping = 0
                mainFrame:Hide()
            else
                BiaoGe.showShopping = 1
                BG.UpdateMerchantFrame(true)
            end
        end)
        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
            GameTooltip:AddLine(L["把商品按装备部位进行排列，并且可以自定义过滤。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(L["该功能仅对销售装备的商人生效。"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        bt:SetScript("OnLeave", GameTooltip_Hide)
    end

    local function CreateButton(slotFrame, ii, i)
        local id = ii .. "/" .. i
        local bt = CreateFrame("Frame", "BGMerchantItem" .. id, slotFrame, "MerchantItemTemplate")
        bt:SetPoint("LEFT", (buttonWidth + 5) * (i - 1), -4)
        bt:SetScale(btScale)
        bt:Hide()
        bt.id = id
        local tex = bt.ItemButton:CreateTexture(nil, "OVERLAY")
        tex:SetPoint("BOTTOM", 0, -5)
        tex:SetSize(45, 45)
        tex:SetTexture("interface/raidframe/readycheck-ready")
        tex:Hide()
        bt.havedTex = tex
        local t = bt.ItemButton:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
        t:SetPoint("BOTTOM", 0, 0)
        bt.levelText = t
        local f = CreateFrame("Frame", nil, bt.ItemButton, "BackdropTemplate")
        f:SetBackdrop({
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 1,
        })
        f:SetBackdropBorderColor(1, 1, 1, .6)
        f:SetPoint("TOPLEFT", 0, 0)
        f:SetSize(20, 20)
        f:Hide()
        bt.classFrame = f
        local tex = f:CreateTexture(nil, "BACKGROUND")
        tex:SetAllPoints()
        bt.classTex = tex
        local t = bt.ItemButton:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
        t:SetPoint("TOP", 0, -2)
        t:SetTextColor(0, 1, 0)
        t:SetText(L["装绑"])
        bt.boeText = t
        local SlotTexture = _G[bt:GetName() .. "SlotTexture"]
        SlotTexture:Hide()
        local nameFrame = _G[bt:GetName() .. "NameFrame"]
        nameFrame:SetHeight(72)
        nameFrame:ClearAllPoints()
        nameFrame:SetPoint("LEFT", SlotTexture, "RIGHT", -9, -12)
        local Name = _G[bt:GetName() .. "Name"]
        Name:ClearAllPoints()
        Name:SetPoint("LEFT", SlotTexture, "RIGHT", -5, 11)
        Name:SetWordWrap(false)
        tinsert(slotFrame.buttons, bt)
        return bt
    end

    for ii, v in ipairs(slots) do
        local slotFrame = CreateFrame("Frame", nil, mainFrame.child, "BackdropTemplate")
        slotFrame:SetSize(mainFrameWidth - 100, buttonHeight)
        slotFrame.buttons = {}
        slotFrame.num = 1
        slotFrame.name = v.name
        tinsert(mainFrame.slots, slotFrame)

        for i = 1, 10 do
            CreateButton(slotFrame, ii, i)
        end
    end

    local function Filter(itemLink)
        local itemID, _, _, EquipLoc, _, typeID, subclassID = GetItemInfoInstant(itemLink)
        local num = BiaoGe.FilterClassItemDB[RealmID][player].chooseID
        if itemID and num then
            if BG.FilterAll(itemID, typeID, EquipLoc, subclassID) then
                return true
            end
        end
    end
    local function GetButtonIndex(slotIndex)
        local slotFrame = mainFrame.slots[slotIndex]
        local btIndex = 1
        while true do
            local bt = slotFrame.buttons[btIndex]
            if not bt then
                bt = CreateButton(slotFrame, slotIndex, btIndex)
            end
            if not bt:IsShown() then
                bt:Show()
                slotFrame:Show()
                return bt
            end
            btIndex = btIndex + 1
        end
    end
    local function GetButtonByEquipLoc(equipLoc, itemLink, itemID, quality)
        if equipLoc and not equipLoc:find("_NON_") then
            if quality >= 2 then -- 紫装数量
                mainFrame.equipLocCount = mainFrame.equipLocCount + 1
            end
            if Filter(itemLink) then return end
            for i, v in ipairs(slots) do
                for _, _equipLoc in ipairs(v.key) do
                    if equipLoc == _equipLoc then
                        return GetButtonIndex(i)
                    end
                end
            end
        end
        if itemID and BG.GetTooltipTextLeftAll(itemID):find(CLASS) then
            return GetButtonIndex(#slots - 1)
        else
            return GetButtonIndex(#slots)
        end
    end
    local function UpdateLevelText(bt)
        local typeID = bt.ItemButton.typeID
        local quality = bt.ItemButton.quality
        local level = bt.ItemButton.level
        if (typeID == 2 or typeID == 4) and quality > 1 and level > 1 then
            local r, g, b = GetItemQualityColor(quality)
            bt.levelText:SetText(level)
            bt.levelText:SetTextColor(r, g, b)
        else
            bt.levelText:SetText("")
        end
    end
    local function UpdateHaveTex(bt)
        local typeID = bt.ItemButton.typeID
        local quality = bt.ItemButton.quality
        local level = bt.ItemButton.level
        local itemID = bt.ItemButton.itemID
        if (typeID == 2 or typeID == 4) and quality > 1 and level > 1
            and GetItemCount(itemID, true) > 0 then
            bt.havedTex:Show()
        else
            bt.havedTex:Hide()
        end
    end
    local function UpdateBOEText(bt)
        bt.boeText:SetShown(bt.ItemButton.bindType == 2)
    end
    local function UpdateClassTex(bt)
        local itemID = bt.ItemButton.itemID
        if classItems[itemID] then
            bt.classFrame:Show()
            bt.classTex:SetTexture(classItems[itemID])
        else
            bt.classFrame:Hide()
            bt.classTex:SetTexture(nil)
        end
    end
    local function UpdateAllHaveTex()
        for k, slotFrame in pairs(mainFrame.slots) do
            for k, bt in pairs(slotFrame.buttons) do
                if bt:IsVisible() then
                    UpdateHaveTex(bt)
                end
            end
        end
    end
    local function ResetFrame()
        mainFrame.equipLocCount = 0
        mainFrame:Hide()
        for k, slotFrame in pairs(mainFrame.slots) do
            slotFrame:Hide()
            for k, bt in pairs(slotFrame.buttons) do
                bt:Hide()
            end
        end
        for i = #mainFrame.slotTexts, 1, -1 do
            mainFrame.slotTexts[i]:Hide()
            tremove(mainFrame.slotTexts, i)
        end
    end
    local function MerchantFrame_UpdateAltCurrency(index, indexOnPage, canAfford)
        local itemCount = GetMerchantItemCostInfo(index);
        local frameName = "BGMerchantItem" .. indexOnPage .. "AltCurrencyFrame";
        local usedCurrencies = 0;
        local width = 0;

        -- update Alt Currency Frame with itemValues
        if (itemCount > 0) then
            for i = 1, MAX_ITEM_COST do
                local itemTexture, itemValue, itemLink = GetMerchantItemCostItem(index, i);
                if (itemTexture) then
                    usedCurrencies = usedCurrencies + 1;
                    local button = _G[frameName .. "Item" .. usedCurrencies];
                    button.index = index;
                    button.item = i;
                    button.itemLink = itemLink;
                    AltCurrencyFrame_Update(frameName .. "Item" .. usedCurrencies, itemTexture, itemValue, canAfford);
                    width = width + button:GetWidth();
                    if (usedCurrencies > 1) then
                        -- button spacing;
                        width = width + 4;
                    end
                    button:Show();
                end
            end
            for i = usedCurrencies + 1, MAX_ITEM_COST do
                _G[frameName .. "Item" .. i]:Hide();
            end
        else
            for i = 1, MAX_ITEM_COST do
                _G[frameName .. "Item" .. i]:Hide();
            end
        end
        return width;
    end

    -- 主函数
    local function UpdateMerchantInfo(setValue)
        local name, texture, price, stackCount, numAvailable, isPurchasable, isUsable, extendedCost, currencyID;
        for index = 1, GetMerchantNumItems() do
            local itemLink = GetMerchantItemLink(index)
            if itemLink then
                local equipLoc, _, typeID, bindType
                local quality, level
                local r, g, b = 1, .82, 0
                local itemID = GetMerchantItemID(index)
                if itemID then
                    equipLoc, _, typeID = select(4, GetItemInfoInstant(itemID))
                    local _info = { GetItemInfo(itemLink) }
                    quality = _info[3]
                    level = _info[4]
                    bindType = _info[14]
                    r, g, b = GetItemQualityColor(quality)
                end
                local merchantButton = GetButtonByEquipLoc(equipLoc, itemLink, itemID, quality)
                if merchantButton then
                    local btName = merchantButton:GetName()
                    local itemButton = _G[btName .. "ItemButton"]
                    local merchantMoney = _G[btName .. "MoneyFrame"]
                    local merchantAltCurrency = _G[btName .. "AltCurrencyFrame"]
                    local nameText = _G[btName .. "Name"]
                    local btID = merchantButton.id

                    name, texture, price, stackCount, numAvailable,
                    isPurchasable, isUsable, extendedCost, currencyID = GetMerchantItemInfo(index);
                    if (currencyID) then
                        name, texture, numAvailable = CurrencyContainerUtil.GetCurrencyContainerInfo(currencyID, numAvailable, name, texture, nil);
                    end

                    local canAfford = CanAffordMerchantItem(index);
                    nameText:SetText(name);
                    nameText:SetTextColor(r, g, b);
                    SetItemButtonCount(itemButton, stackCount);
                    SetItemButtonStock(itemButton, numAvailable);
                    SetItemButtonTexture(itemButton, texture);

                    itemButton.name = name;
                    itemButton.link = GetMerchantItemLink(index);
                    itemButton.texture = texture;
                    itemButton.itemID = itemID
                    itemButton.typeID = typeID
                    itemButton.level = level
                    itemButton.quality = quality
                    itemButton.bindType = bindType
                    UpdateLevelText(merchantButton)
                    UpdateHaveTex(merchantButton)
                    UpdateClassTex(merchantButton)
                    UpdateBOEText(merchantButton)

                    if (extendedCost and (price <= 0)) then
                        itemButton.price = nil;
                        itemButton.extendedCost = true;

                        MerchantFrame_UpdateAltCurrency(index, btID, canAfford);
                        merchantAltCurrency:ClearAllPoints();
                        merchantAltCurrency:SetPoint("BOTTOMLEFT", _G[btName .. "NameFrame"], "BOTTOMLEFT", 2, 31);
                        merchantMoney:Hide();
                        merchantAltCurrency:Show();
                    elseif (extendedCost and (price > 0)) then
                        itemButton.price = price;
                        itemButton.extendedCost = true;
                        local altCurrencyWidth = MerchantFrame_UpdateAltCurrency(index, btID, canAfford);
                        MoneyFrame_SetMaxDisplayWidth(merchantMoney, MAX_MONEY_DISPLAY_WIDTH - altCurrencyWidth);
                        MoneyFrame_Update(merchantMoney:GetName(), price);
                        local color;
                        if (canAfford == false) then
                            color = "gray";
                        end
                        SetMoneyFrameColor(merchantMoney:GetName(), color);
                        merchantAltCurrency:ClearAllPoints();
                        merchantAltCurrency:SetPoint("LEFT", merchantMoney:GetName(), "RIGHT", -12, 0);
                        merchantAltCurrency:Show();
                        merchantMoney:Show();
                    else
                        itemButton.price = price;
                        itemButton.extendedCost = nil;
                        MoneyFrame_SetMaxDisplayWidth(merchantMoney, MAX_MONEY_DISPLAY_WIDTH);
                        MoneyFrame_Update(merchantMoney:GetName(), price);
                        local color;
                        if (canAfford == false) then
                            color = "gray";
                        end
                        SetMoneyFrameColor(merchantMoney:GetName(), color);
                        merchantAltCurrency:Hide();
                        merchantMoney:Show();
                    end

                    local merchantItemID = GetMerchantItemID(index);

                    local isHeirloom, isKnownHeirloom;
                    if (ClassicExpansionAtLeast(LE_EXPANSION_WRATH_OF_THE_LICH_KING)) then
                        isHeirloom = merchantItemID and C_Heirloom.IsItemHeirloom(merchantItemID);
                        isKnownHeirloom = isHeirloom and C_Heirloom.PlayerHasHeirloom(merchantItemID);
                    else
                        isHeirloom = false;
                        isKnownHeirloom = false;
                    end

                    itemButton.showNonrefundablePrompt = isHeirloom;

                    itemButton.hasItem = true;
                    itemButton:SetID(index);
                    itemButton:Show();

                    local tintRed = not isPurchasable or (not isUsable and not isHeirloom);

                    SetItemButtonDesaturated(itemButton, isKnownHeirloom);

                    if (numAvailable == 0 or isKnownHeirloom) then
                        -- If not available and not usable
                        if (tintRed) then
                            SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0, 0);
                            SetItemButtonSlotVertexColor(merchantButton, 0.5, 0, 0);
                            SetItemButtonTextureVertexColor(itemButton, 0.5, 0, 0);
                            SetItemButtonNormalTextureVertexColor(itemButton, 0.5, 0, 0);
                        else
                            SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5);
                            SetItemButtonSlotVertexColor(merchantButton, 0.5, 0.5, 0.5);
                            SetItemButtonTextureVertexColor(itemButton, 0.5, 0.5, 0.5);
                            SetItemButtonNormalTextureVertexColor(itemButton, 0.5, 0.5, 0.5);
                        end
                    elseif (tintRed) then
                        SetItemButtonNameFrameVertexColor(merchantButton, 1.0, 0, 0);
                        SetItemButtonSlotVertexColor(merchantButton, 1.0, 0, 0);
                        SetItemButtonTextureVertexColor(itemButton, 0.9, 0, 0);
                        SetItemButtonNormalTextureVertexColor(itemButton, 0.9, 0, 0);
                    else
                        SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5);
                        SetItemButtonSlotVertexColor(merchantButton, 1.0, 1.0, 1.0);
                        SetItemButtonTextureVertexColor(itemButton, 1.0, 1.0, 1.0);
                        SetItemButtonNormalTextureVertexColor(itemButton, 1.0, 1.0, 1.0);
                    end
                end
            else
            end
        end

        if mainFrame.equipLocCount < itemCountShow then return end
        mainFrame:Show()
        local showCount = 0
        for _, slotFrame in ipairs(mainFrame.slots) do
            if slotFrame:IsVisible() then
                slotFrame:ClearAllPoints()
                slotFrame:SetPoint("TOPLEFT", 5, -buttonHeight * showCount - 5)

                local t = mainFrame:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                t:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, -buttonHeight * showCount - 37 - filterHeight)
                t:SetTextColor(1, 1, 1)
                t:SetText(slotFrame.name)
                t:SetWidth(slotTextWidth)
                tinsert(mainFrame.slotTexts, t)
                showCount = showCount + 1
            end
        end

        mainFrame:SetHeight(45 + filterHeight + showCount * buttonHeight)
        if setValue then
            mainFrame.scroll.ScrollBar:SetValue(0)
        end
    end

    function BG.UpdateMerchantFrame(delay, setValue)
        ResetFrame()
        if delay then
            for index = 1, GetMerchantNumItems() do
                GetMerchantItemLink(index)
            end
            After(0, function()
                UpdateMerchantInfo(true)
            end)
        else
            UpdateMerchantInfo(setValue)
        end
    end

    BG.RegisterEvent("MERCHANT_SHOW", function()
        if BiaoGe.showShopping == 1 then
            BG.UpdateMerchantFrame(true)
        end
    end)

    local f = CreateFrame("Frame")
    f:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    f:RegisterEvent("PLAYER_MONEY")
    f:RegisterEvent("BAG_UPDATE_DELAYED")
    f:SetScript("OnEvent", function(self, event, ...)
        if mainFrame:IsVisible() then
            After(1, function()
                if mainFrame:IsVisible() then
                    UpdateAllHaveTex()
                end
            end)
        end
    end)

    hooksecurefunc("MerchantFrame_Update", function()
        if mainFrame:IsVisible() then
            mainFrame.t = 0
            mainFrame:SetScript("OnUpdate", function(self, t)
                mainFrame.t = mainFrame.t + t
                if mainFrame.t >= 0.1 then
                    BG.UpdateMerchantFrame()
                    self:SetScript("OnUpdate", nil)
                    return
                end
            end)
        end
    end)
end)
