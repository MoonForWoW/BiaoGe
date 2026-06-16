if BG.IsBlackListPlayer then return end

local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
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
local realmName = BG.realmName

local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded

--最后更新时间：25/6/23 10:25
local AFDtbl_360 = {
    -- 1200
    "wlk怀旧-范沃森-Selendis",
    -- 1080
    "水晶之牙-Ace-Nanami",
    -- 780
    "露露缇娅",
    -- 600
    "陈",
    -- 360
    -- "",
    "龙牙-风轻",
    "橙子",
    "虎大超",
    "卧龙草船借箭-龙牙",
    "依然不低调",
    "匕首岭-麻生成实",
    "Funny",
    "全能小霸王",
    "龙之召唤<破冰>粥糟-粥枣",
}
local AFDtbl_180 = {

    -- "",
    -- "",
    -- "",
    "克罗米-AFN公会-Saira",
    "祈福-好运来-大黏痰宝宝",
    "霜语-大坏神",
    "龙牙-半子",
    "奥罗-Hoary-懒虫蟋蟀",
    "怒炉-神圣皮皮",
    "碧玉矿洞-Fated",
    "维克洛尔-SilverMoon-桃太浪",
    "匕首岭-丹妮卡丽熙",
    "祈福-夜色丨骑",
    "巴罗夫-亲近自然",
    "铁血I-抱抱熊丷",
    "灰烬使者-XenophobicOrigin-魂曲",
    "过期",
    "汪涛",
    "ImTheW",
    "炸炸",
    "云澈澈",
    "布鲁-末日重生公会",
    "骑着鸭狂飙",
    "泡面",
    "橘子棒冰",
    "霜语-猫空半日-萬神殿",
    "水晶之牙-RichOnly",
    "抹茶慕斯-奥罗-白雪公主",
    "飞猪",
    "寒冰之王-我是侬伢叔",
    "依然无奈",
    "Allen摩卡",
    "恼火",
    "塬",
    "阡陌小熊",
    "阿豆豆",
    "啧啧啧",
    "奥金斧-大板栗",
    "三藏骑猪",
    "光",
    "铁血II-书香",
    "铁血II-书香秘密",
    "寒脊山小径-起点-花舞",
    "霜语-丑死我了",
    "伊梅尔达",
    "超级小奶爸",
}
local AFDtbl_90 = {
    -- "",
    -- "",
    -- "",
    "匕首岭-我就是硬",
    "白烏鴉",
    "大王别介",
    "forest1818",
    "超能力领域-展开",
    "小戆戆",
}

-- 30
local AFDtbl_30 = {}
local tbl = {
    -- "",
    -- "",
    -- "",
    -- "",
    -- "",
    -- "",
    -- "",
    -- "",
    -- "",
    -- "",
    -- "",
    -- "",
    -- "",
    -- "",
    -- "",
    -- "",
    -- "",
    "红玉圣殿 -归来仍少年-熊猫",
    "萨弗拉斯-炎魔之灵",
    "莫格莱尼-琉月",
    "緬苝张学友",
    "龙牙-金铲铲-璀璨旭日阿喀琉斯",
    "龙之召唤-天府团",
    "席瓦莱恩-Astar-小兔晶",
    "震地者-香蕉团",
    "碧空之歌-风景模糊",
    "奥罗-一隊小德",
    "水晶之牙-莎莎歌舞厅",
    "鸡冠头-龙之召唤",
    "银色北伐军-Forgetfulness-忘机丷",

    "毁灭之刃-wifeisboss-上兵伐谋",
    "硬汉-阿萨斯王子",
    "狙安猎爹人-龙牙",
    "奥罗-助人为乐-英魂",
    "范克瑞斯-欧皇社团-武梓琪丶",
    "龙牙-茶余饭后俱乐部-含丶蓄",
    "莫格莱尼-暨阳山庄-丨江离丨",
    "奥金斧-Sylvanas-猎鹰",
    "铁血II-野狼之怒",
    "银色北伐军-晨星-腐化之心",
    "范克瑞斯-坦途-老逗",
    "灰烬使者-小芝",
    "奥金斧-夜店-醉丶红颜",
    "哈霍兰-飞机儿大",
    "夕阳半落-祈福",
    "逆行者-范克瑞斯",
    "布鲁-大繁荣商店-梦游的栗子",
    "维希度斯-往事随风-歪大",
    "龙牙-我有鱼鱼症-蛋卷真好吃",
    "霜语-幽幽子",
    "比斯巨兽-雁渡寒潭-霜夜之殇",
    "龙牙-Astartes-叁肆",
    "比斯巨兽-荣誉兄弟会-火山哥",
    "埃提耶什-行者-双刀探花",
    "霜语-赛萨阳光-阴偙尛淼晶",
    "无畏-言狗狗保护协会-言而有信",
    "红玉圣殿-大力彬哥",
    "银色北伐军-天雨星沉-乔丶",
    "龙之召唤-听香水榭公会",
    "比格沃斯-小熊晚安",
    "死亡猎手-第二世界-小锅米线",
    "祈福-摸鱼-血风沅",
    "死亡猎手-ONEPIECE-卡尔汀娜",
    "特螂普",
    "比斯巨兽-闪耀光芒吧",
    "灰烬使者-Ns",
    "无尽风暴-年轻艺术家-王子",
    "龙之召唤-大老虎-二狗子",
    "龙之召唤，神話工会，山岸又逢花",
    "灰烬使者-七夜雪-北榭倾城丶",
    "铁血-巴牧师",
    "莫格莱尼-无忧-河南彭于晏",
    "比格沃斯-FromShadow-合体熊猫",
    "碧玉矿洞-小乖不哭",
    "霜语-八零-一刀满血秒",
    "辛洛斯-风游鲸",
    "法尔班克斯-風雨飘飘落凡尘-丶風尘",
    "霜语-马村勇进",
    "奥罗-特兰克斯团",
    "无畏-恶魔术之神-多拂朗明哥",
    "祝福加油",
    "灰烬使者-小熊布袋",
    "QQ小经典",
    "萨弗拉斯-破晓-小蜜柚",
    "匕首岭-星空下的守夜人-風情一刀",
    "匕首岭-TypeMoon-小米布丁",
    "红玉圣殿-泰山之巅-丢丢",
    "范克瑞斯-彩云之南-个人设置",
    "比格沃斯-波比波比",
    "维希度斯-议会-赛雷",
    "怒炉-小天",
    "匕首岭-天泫-踏雪凌風",
    "银色北伐军-高深-Pichu",
    "火锤-协和医院工会",
    "莫格莱尼-利刃-死亡灬印记",
    "哈喽哈喽小农民需要表格唯爱屁",
    "范克瑞斯-钻石武力公会",
    "红玉圣殿-彩虹小小糖",
    "火锤-荭手-刘诗诗丶",
    "碧玉矿洞-虚无妹妹的风俗小铺-虚无丶月",
    "安娜kt",
    "莫格莱尼-承筱诺",
    "龙之召唤-诺诺吖",
    "铁血-诺诺吖",
    "龙牙-犍为斌哥哥",
    "灰烬使者-壹玖叁公会-海天一线",
    "维希度斯-盛世鼎红-爱有来生",
    "比格沃斯-大崬",
    "吉安娜-边总",
    "奥罗-众生之巅-王之守护",
    "melody",
    "萨弗拉斯-深田姥师",
    "abbiy921",
    "弄啥呢",
    "十六夜夜",
    "DemonClin",
    "祈福-橙光-璀璨橙光",
    "水晶之牙-莎莎歌舞厅-斗篷丶",
    "小亏",
    "smapwje",
    "铁血II-亚洲金团",
    "豆包",
    "硬汉服-七七超甜",
    "名牌太贵",
    "麻辣蛋黄派",
    "GUNι",
    "Caroline-觅心者",
    "xbrave",
    "邵拉达",
    "泡沫",
    "范克瑞斯-扶光",
    "霜语-天人境",
    "Karaok",
    "多宝色猪",
    "维希度斯-藏星",
    "秋秋丶夜-震地者",
    "小语风",
    "标标",
    "龙牙-金铲铲-璀璨旭日",
    "正浩",
    "落灬花",
    "大都市",
    "婴儿爽身粉",
    "Anthony",
    "会飞的鱼",
    "执念",
    "BananaCream",
    "怒炉-南山必胜阁",
    "wuqing0304",
    "埃提耶什-花飘零感谢。",
    "夏天冷",
    "举神",
    "那個尐仙",
    "风雨小楼",
    "戴洋",
    "yuyiiiiii",
    "danny",
    "兔子",
    "兜兜里好多糖",
    "霜语-团队毒瘤-非天",
    "飞猪归来",
    "没奶是爷",
    "Gagle",
    "Lin",
    "吉安娜小蜡烛",
    "mini1118",
    "北执南念",
    "龙牙-云梦泽-锦绣丶夜未央",
    "风暴越大鱼越贵",
    "Seraph",
    "空白",
    "可乐团长",
    "林栎熙",
    "少年",
    "猜猜",
    "毛哥",
    "龙牙-茶余饭后俱乐部-浩劫的呼唤",
    "匕首岭-动之以情丶",
    "还有莪在",
    "Rody",
    "魚",
    "伦鲁迪洛尔-白马会所-啊嘻吧",
    "佐岸天使",
    "西子湖畔划划水",
    "张不二",
    "爆浆",
    "長門有希",
    "银色北伐军-晨星-君莫美",
    "DarkKnight",
    "萌城少年",
    "yy",
    "碧玉矿洞-风暴之巅-帅贼贼帅",
    "凤丶年",
    "请温柔一点",
    "豆包糯叽叽",
    "kk",
    "lasaqe",
    "芋圆爱发dian",
    "裤子有个洞-狮心",
    "祈福-Eternal-bonds",
    "木亿TR",
    "段先生",
    "秘制",
    "矮骑壹",
    "小蚂蚱",
    "jiang",
    "一只小鲸鱼",
    "sinx",
    "Damon",
    "老逗呀",
    "龙牙-教头",
    "4775",
    "享享",
    "KrisLau",
    "祈福老金",
    "乔爸俊杰",
    "mws",
    "萨弗拉斯-魔剑美神",
    "萨弗拉斯-炎魔周润发",
    "灰烬使者天災坦克",
    "不再留恋",
    "寒冰之王-绘世长歌-新裤子",
    "达芬奇",
    "消失的远方",
    "走路",
    "凌菡如枫",
    "麦田",
    "ahwhycshx",
    "松能",
    "堂姐套圈圈",
    "加丁-一口袋橘子",
    "归零重启",
    "血腥之牙",
    "浪浪",
    "刚刚好",
    "安德",
    "阿多尼斯冰雪",
    "加盾-祈福-绝地公会",
    "嗜血",
    "震地者-弑神死骑",
    "Venko",
    "呆丶呆",
    "风神之怒",
    "火舞龙腾",
}
for _, name in ipairs(tbl) do
    tinsert(AFDtbl_30, tostring(name:gsub(" ", "")))
end

do
    local tbl = {
        "奥罗-大都市",
        "云游天下丷-无畏",
        "月影连天",
        "Sakple",
        "匕首岭-丹妮卡丽熙",
        "天天好快乐",
        "Schmnn",
        "小龙",
        "阳琳",
        "梦中得婚礼",
        "火锤-直到世界的尽头-花雪",
        "灰烬使者-小熊布袋",
        "柚子",
        "啊啊啊付大夫是",
        "aarongu826",
        "叶弦",
        "Tohigh",
        "奈斯丶",
        "风涧",
        "凉爽皮夹黄",
        "维克洛尔-月下斋-迪凯哥",
        "大以巴狼",
        "萝卜",
        "龙之召唤-圈圈的味道",
        "布朗熊",
        "Jan",
        "小啊狸",
        "酒酿芋小圆",
        "龍",
        "Lanlanluu—范克瑞斯",
        "龙牙-铁血部落-怒风战",
        "玛卡阿巴",
        "小亏",
        "七禾野",
        "猫尾巴",
        "napoleanic",
        "加丁-逍遥公会-三甲",
        "面包鸡",
        "鑫贝贝",
        "王赜",
        "沙滩",
        "大王别介",
        "amyge977",
        "铁血I-赏金部落-巴佐",
        "憋大招",
        "Justcallme17",
        "布丁叔叔",
        "欧黄",
        "十六夜夜",
        "DemonClin",
        "Caroline-觅心者",
        "abbiy921",
        "听弦断",
        "玄天",
        "铁血I-无忧筱筑-妖児薇薇妙",
        "清华大学校草-无畏",
        "花光的荣耀",
        "Micross熊猫",
        "顾半城",
        "阿鲁高",
        "ctrlcc",
        "漫漫",
        "深海壹号",
        "龙牙-犍为翘脚儿",
        "死亡猎手-萨神一姑苏",
        "异灵-红玉圣殿",
        "平静丶心",
        "灰灰丶",
        "水晶",
        "死亡猎手-Dark-Wings-長安一一",
        "风涧",
        "KTHOPE",
        "龙牙-愿此行",
        "神神叨叨",
        "好好学习",
        "震地者丨四合一",
        "xy8888",
        "比斯巨兽-Story-风暴行者",
        "富贵",
        "帕奇维克-友谊长存-鸽子一骑",
        "何处不相逢",
        "xbrave",
        "雪见月十九",
        "小兔晶",
        "罐头",
        "赤水断苍山",
        "不再留恋",
        "Damon",
        "凌菡如枫",
        "维希度斯-自己",
        "璀璨橙光-祈福-橙光公会",
        "消失的远方",
        "Bill",
        "死亡猎手部落小羽吃西瓜",
        "风神之怒",
        "ybwywen",
        "HH",
        "哥哥有一手",
        "ImTheW",
        "刚刚好",
        "godcat",
        "DEE",
        "弑神死骑",
        "维克尼拉斯-年事梦中休",
        "lyl",
        "天天好快乐",
        "北执南念",
        "萌城少年",
        "林栎熙",
        "Sakple",
        "satraxx",
        "猜猜",
        "zzzz。llll",
        "奈斯丶",
        "红石头",
        "毛哥",
        "奶油先生",
        "范克瑞斯-钻石武力-夜月琉璃",
        "Venko",
        "猫猫",
        "乘风随风",
        "jiang",
        "星河-堕落兵团-维希度斯",
        "智妍大姐姐",
        "阿多尼斯冰雪",
        "智妍大姐姐",
        "晚风",
        "yuuu",
        "tetelook",
        "加丁-KISS-Glivec",
        "Kayekiah",
        "BananaCream",
        "不吃牛蛙",
        "飞",
        "灰烬使者-天災公会",
        "银鞍照白马",
        "范克瑞斯-狮王之傲-丿路西法",
        "邵拉达",
        "大白",
        "yyf",
        "辛迪加-辛艾萨莉-小家猫卡琳娜",
        "xxx794665",
        "沙滩",
        "范克瑞斯-逝去的青春-丶黑炭",
        "那個尐仙",
        "不懂英语小明",
        "叶凡-龙牙",
        "Sr",
        "碧玉矿洞-八汤",
        "憋大招",
        "龙之召唤-天府一街",
        "灰烬使者-Revenger",
        "清华大学校草-无畏",
        "风涧",
        "大大大怪兽",
        "霜语-旺仔尛馒头",
        "严羽幻",
        "吉安娜-吕小骑",
        "橙贰胖-巴罗夫",
        "長門有希",
        "大鸟甩甩",
        "爱萝莉的格雷福斯",
        "狮心-圣火喵喵教-阿壶金团",
        "我是读书人",
        "比格沃斯-面包",
        "咖啡",
        "欧黄",
        "DemonClin",
        "龙之召唤-不是芋圆",
        "Endearment",
        "糖果与火焰山-死亡猎手",
        "收藏家",
        "阡陌小熊",
        "肝坚强",
        "老年呆贼",
        "有才",
        "不再留恋",
        "拉萨",
        "青椒回锅肉",
        "匕首岭-冷疯-逐风工会",
        "硬汉-晨时微凉丶",
        "咩咩米",
        "奥金斧-Shameles",
        "千夕",
        "鸟窝",
        "Veda",
        "无畏-多拂朗明哥-PatrickStar",
        "安德",
        "夏天冷",
        "假寐的死神",
        "Choo",
        "遇见",
        "五郎八卦棍",
        "龙之召唤-轻舟",
        "弑神死骑",
        "DarkAlexPPP",
        "狮心董卓",
        "W",
        "漫漫",
        "lyl",
        "比格沃斯",
        "koy_czq",
        "HappyM0802",
        "龙之召唤-面包金团",
        "死亡猎手-memory",
        "makabakas",
        "斯内克",
        "灰烬使者-小手勾勾",
        "布朗熊",
        "老周不想取名",
        "埃提耶什-<夜宴>-正夏",
        "单脚跳",
        "法尔班克斯-<骚年远征军>-雪见月十九",
        "水晶之牙-Equipo Octavo",
        "维系度斯-你看我牛牛吗",
        "关青龙",
        "好好学习",
        "吉安娜小蜡烛",
        "大栓",
        "伽蓝",
        "龙之召唤-承筱诺",
        "龙之召唤-鼓励团结有爱",
        "龙之召唤-阿多尼斯冰雪",
        -- 没有名字
        L["以及多个没有留名的爱发电用户"],
    }
    for _, name in ipairs(tbl) do
        tinsert(AFDtbl_30, tostring(name:gsub(" ", "")))
    end
end


BG.Init(function()
    local lastBt
    local hight = 25
    local delayTime=.2
    -- 角色总览
    do
        local bt = CreateFrame("Button", nil, BG.MainFrame)
        bt:SetSize(20, hight)
        if lastBt then
            bt:SetPoint("RIGHT", lastBt, "LEFT", -10, 0)
        else
            bt:SetPoint("BOTTOMRIGHT", -20, 1)
        end
        bt:SetNormalFontObject(BG.FontYellow13)
        bt:SetHighlightFontObject(BG.FontWhite13)
        bt:SetText("|A:GarrMission_ClassIcon-" .. string.lower(select(2, UnitClass("player"))) .. ":0:0|a" .. L["角色总览"])
        -- bt:SetText("|A:classicon-" .. string.lower(select(2, UnitClass("player"))) .. ":0:0|a" .. L["角色总览"])
        bt:SetWidth(bt:GetFontString():GetStringWidth())
        BG.ButtonRoleOverview = bt
        lastBt = bt
        BG.OnEnterDelay(bt, function(self)
            BG.SetFBCD(self)
        end, delayTime)
        BG.OnLeaveDelay(bt, function(self)
            if BG.FBCDFrame and not BG.FBCDFrame.click then
                BG.FBCDFrame:Hide()
            end
        end)
        bt:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then
                if IsControlKeyDown() then
                    BG.SetFBCD(nil, nil, true)
                end
            elseif button == "RightButton" then
                BG.OpenOption()
                BG.MainFrame:Hide()
            end
            BG.PlaySound(1)
        end)
    end

    -- 爱发电
    do
        -- local bt = CreateFrame("Button", nil, BG.MainFrame)
        -- bt:SetSize(20, hight)
        -- if lastBt then
        --     bt:SetPoint("RIGHT", lastBt, "LEFT", -10, 0)
        -- else
        --     bt:SetPoint("BOTTOMRIGHT", -10, 1)
        -- end
        -- bt:SetNormalFontObject(BG.FontYellow13)
        -- bt:SetHighlightFontObject(BG.FontWhite13)
        -- bt:SetText(AddTexture("Interface\\AddOns\\BiaoGe\\Media\\icon\\AFD") .. L["爱发电"])
        -- bt:SetWidth(bt:GetFontString():GetStringWidth())
        -- bt.texts = {}
        -- bt.w = 50
        -- BG.ButtonAFD = bt
        -- lastBt = bt

        -- local function AddText(self, tbl, r, g, b)
        --     local f = self.frame
        --     local w = self.w
        --     local text
        --     if type(tbl) == "table" then
        --         local same = {}
        --         local remove = {}
        --         for i = 1, #tbl do
        --             if tbl[i]:find(realmName, 1, true) then
        --                 tbl[i] = BG.STC_g1(tbl[i])
        --             end
        --             if not same[tbl[i]] then
        --                 same[tbl[i]] = true
        --             else
        --                 remove[i] = true
        --             end
        --         end
        --         for k, v in pairs(remove) do
        --             tremove(tbl, k)
        --         end
        --         text = table.concat(tbl, BG.STC_dis("，"))
        --     else
        --         text = tbl
        --     end

        --     local t = self.child:CreateFontString()
        --     t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        --     t:SetText(text)
        --     t:SetWidth(f:GetWidth() - w * 3)
        --     if not next(self.texts) then
        --         t:SetPoint("TOPLEFT", 20, -20)
        --     else
        --         t:SetPoint("TOPLEFT", self.texts[#self.texts], "BOTTOMLEFT", 0, -15)
        --     end
        --     t:SetJustifyH("LEFT")
        --     t:SetTextColor(r, g, b)
        --     t:SetText(text)
        --     tinsert(self.texts, t)
        -- end
        -- BG.OnEnterDelay(bt, function(self)
        --     wipe(self.texts)
        --     local w, h = BG.MainFrame:GetWidth(), BG.MainFrame:GetHeight() - 50
        --     local f, child = BG.CreateScrollFrame(self, w, h)
        --     f:SetBackdrop({
        --         bgFile = "Interface/ChatFrame/ChatFrameBackground",
        --         insets = { left = 3, right = 3, top = 3, bottom = 3 }
        --     })
        --     f:SetBackdropColor(0, 0, 0, .9)
        --     f:SetPoint("TOPLEFT", BG.MainFrame, "TOPLEFT", 0, -20)
        --     f:SetFrameLevel(320)
        --     f:EnableMouse(false)
        --     self.frame = f
        --     self.child = child
        --     AddText(self, L["感谢以下玩家的发电："], 1, 1, 1)
        --     AddText(self, AFDtbl_360, 1, .82, 0)
        --     AddText(self, AFDtbl_180, 1, .82, 0)
        --     AddText(self, AFDtbl_90, 1, .82, 0)
        --     AddText(self, AFDtbl_30, 1, .82, 0)
        -- end)
        -- BG.OnLeaveDelay(bt, function(self)
        --     if self.frame then
        --         self.frame:Hide()
        --     end
        --     GameTooltip:Hide()
        --     BiaoGeTooltip2:Hide()
        -- end)
    end

    -- 网易DD
    --[[     do
        local bt = CreateFrame("Button", nil, BG.MainFrame)
        bt:SetSize(20, hight)
        if lastBt then
            bt:SetPoint("RIGHT", lastBt, "LEFT", -10, 0)
        else
            bt:SetPoint("BOTTOMRIGHT", -10, 1)
        end
        bt:SetNormalFontObject(BG.FontYellow13)
        bt:SetHighlightFontObject(BG.FontWhite13)
        bt:SetText(AddTexture("DD") .. L["网易DD"])
        bt:SetWidth(bt:GetFontString():GetStringWidth())
        BG.ButtonDD = bt
        lastBt = bt

        BG.OnEnterDelay(bt, function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
            GameTooltip:AddLine(L["官方插件平台"], 1, 1, 1, true)
            GameTooltip:AddLine(L["集插件管理、配置分享、云端备份、团队语音于一体。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(L["你可以在这里更新BiaoGe插件。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(L["（点击复制网址）"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        BG.OnLeaveDelay(bt, GameTooltip_Hide)
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
            ChatEdit_ChooseBoxForSend():SetText("https://dd.163.com/?utm_source=112231")
            ChatEdit_ChooseBoxForSend():HighlightText()
        end)
    end ]]

    -- 新手盒子
    --[[     do
        local bt = CreateFrame("Button", nil, BG.MainFrame)
        bt:SetSize(20, hight)
        if lastBt then
            bt:SetPoint("RIGHT", lastBt, "LEFT", -10, 0)
        else
            bt:SetPoint("BOTTOMRIGHT", -10, 1)
        end
        bt:SetNormalFontObject(BG.FontYellow13)
        bt:SetHighlightFontObject(BG.FontWhite13)
        bt:SetText(AddTexture("BOX") .. L["新手盒子"])
        bt:SetWidth(bt:GetFontString():GetStringWidth())
        BG.ButtonBOX = bt
        lastBt = bt

        BG.OnEnterDelay(bt, function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
            GameTooltip:AddLine(L["集插件管理、配置分享、云端备份、游戏攻略、游戏工具于一体。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(L["你可以在这里更新BiaoGe插件。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(L["（点击复制网址）"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        BG.OnLeaveDelay(bt, GameTooltip_Hide)
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
            ChatEdit_ChooseBoxForSend():SetText("https://www.wclbox.com/")
            ChatEdit_ChooseBoxForSend():HighlightText()
        end)
    end ]]

    -- 提交BUG
    do
        local bt = CreateFrame("Button", nil, BG.MainFrame)
        bt:SetSize(20, hight)
        if lastBt then
            bt:SetPoint("RIGHT", lastBt, "LEFT", -10, 0)
        else
            bt:SetPoint("BOTTOMRIGHT", -10, 1)
        end
        bt:SetNormalFontObject(BG.FontYellow13)
        bt:SetHighlightFontObject(BG.FontWhite13)
        bt.title = AddTexture("Interface\\AddOns\\BiaoGe\\Media\\icon\\icon") .. L["QQ群"]
        bt.title2 = AddTexture("Interface\\AddOns\\BiaoGe\\Media\\icon\\icon") .. L["有报错！"]
        bt:SetText(bt.title)
        bt:SetWidth(bt:GetFontString():GetStringWidth())
        BG.ButtonBug = bt
        lastBt = bt

        BG.OnEnterDelay(bt, function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["BiaoGe沟通交流群"], 1, 1, 1, true)
            GameTooltip:AddLine(L["Q群："] .. "322785325", 1, 0.82, 0, true)
            GameTooltip:AddLine(L["密码："] .. "金团表格", 1, 0.82, 0, true)
            GameTooltip:AddLine(L["（点击复制Q群）"], 1, 0.82, 0, true)
            GameTooltip:Show()

            if self.hasError then
                local e = self.errors
                local gameVer = GetBuildInfo()
                if BG.IsVanilla_Sod then
                    gameVer = gameVer .. " sod"
                end
                BiaoGeTooltip2:SetOwner(GameTooltip, "ANCHOR_TOPLEFT", 0, 0)
                BiaoGeTooltip2:ClearLines()
                BiaoGeTooltip2:AddLine(L["报错"], 1, 0, 0, true)
                BiaoGeTooltip2:AddLine(L["请你把该报错截图发给作者"], 1, 0.82, 0, true)
                BiaoGeTooltip2:AddLine(L["版本："] .. BG.ver, 1, 0.82, 0, true)
                BiaoGeTooltip2:AddLine(L["游戏："] .. gameVer, 1, 0.82, 0, true)
                BiaoGeTooltip2:AddLine(L["时间："] .. (type(e.time) == "number" and date("%m-%d %H:%M:%S", e.time) or e.time), 1, 0.82, 0, true)
                BiaoGeTooltip2:AddLine(L["错误："] .. e.counter .. "x " .. e.message, .5, .5, .5, true)
                if e.stack then
                    BiaoGeTooltip2:AddLine(L["栈："] .. e.stack, .5, .5, .5, true)
                end
                BiaoGeTooltip2:Show()
            end
        end, delayTime)
        BG.OnLeaveDelay(bt, function(self)
            GameTooltip:Hide()
            BiaoGeTooltip2:Hide()
        end)
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
            ChatEdit_ChooseBoxForSend():SetText("322785325")
            ChatEdit_ChooseBoxForSend():HighlightText()
        end)
        bt:SetScript("OnShow", function(self)
            BG.After(1, function()
                if BugGrabberDB and BugGrabberDB.errors then
                    for i, e in next, BugGrabberDB.errors do
                        if BugGrabberDB.session == e.session and type(e.message) == "string"
                            and e.message:find("BiaoGe") and not e.message:find("BiaoGeAI")
                            and not e.message:find("ADDON_ACTION_FORBIDDEN") and not e.message:find("ADDON_ACTION_BLOCKED") then
                            self.hasError = true
                            self.errors = {
                                time = e.time,
                                message = e.message,
                                stack = e.stack,
                                locals = e.locals,
                                counter = e.counter,
                            }
                            self:SetNormalFontObject(BG.FontRed13)
                            self:SetText(self.title2)
                            self:SetScript("OnShow", nil)
                            BG.MainFrame.ErrorText:SetText(L["插件加载错误，请查看右下角的红字报错，把报错内容截图发给作者，谢谢。（Q群：322785325，密码：金团表格）"])
                            break
                        end
                    end
                end
            end)
        end)
    end

    -- 时光徽章价格
    do
        BiaoGe.marketPrice = BiaoGe.marketPrice or {}
        local saveCD = 60 * 60 * 3
        local saveMaxCount = 20
        local outTime = 90 * 86400
        for i = #BiaoGe.marketPrice, 1, -1 do
            if GetServerTime() - BiaoGe.marketPrice[i].time > outTime then
                tremove(BiaoGe.marketPrice, i)
            end
        end

        local function CreateHistoryFrame(self)
            if not self.currentPrice then return end
            local titleWidth = 130
            local barWidth = 200
            local priceWidth = 100
            local frameWidth = titleWidth + barWidth + priceWidth + 20
            local barHeight = 18
            local _max, _min = 0, 0
            for i, v in ipairs(BiaoGe.marketPrice) do
                _max = max(v.price, _max)
                _min = min(v.price, _min)
            end
            local f = CreateFrame("Frame", nil, BG.MainFrame, "BackdropTemplate")
            f:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            f:SetBackdropColor(0, 0, 0, 0.8)
            f:SetBackdropBorderColor(1, 1, 1, .5)
            f:SetSize(500, 300)
            f:SetPoint("BOTTOM", self, "TOP", 0, 0)
            f:SetFrameStrata("HIGH")
            f:SetClampedToScreen(true)
            f.buttons = {}
            self.frame = f
            local toptitle = f:CreateFontString()
            toptitle:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            toptitle:SetPoint("TOP", f, "TOP", 0, -5)
            toptitle:SetTextColor(0, .75, 1)
            toptitle:SetText(AddTexture(1120721) .. L["时光徽章历史价格"])

            local function CreateBar(i, v, isNow)
                local title = f:CreateFontString()
                title:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                title:SetSize(titleWidth, barHeight)
                if next(f.buttons) then
                    title:SetPoint("TOPLEFT", f.buttons[i - 1], "BOTTOMLEFT", 0, 0)
                else
                    title:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -30)
                end
                title:SetTextColor(1, 1, 1)
                title:SetText(isNow and L["现在"] or date("%m-%d %H:%M", v.time))
                title:SetJustifyH("RIGHT")
                title:SetWordWrap(false)
                tinsert(f.buttons, title)

                local bar = CreateFrame("Frame", nil, f, "BackdropTemplate")
                bar:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                })
                bar:SetBackdropColor(1, 1, 0, .8)
                bar:SetPoint("LEFT", title, "RIGHT", 5, 0)
                local widthPercent = v.price / _max
                if widthPercent ~= 1 then
                    widthPercent = widthPercent * widthPercent
                end
                local width
                if widthPercent == 0 then
                    width = 5
                else
                    width = barWidth * widthPercent
                end
                bar:SetSize(width, 14)

                local price = f:CreateFontString()
                price:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                price:SetSize(priceWidth, 20)
                price:SetPoint("LEFT", bar, "RIGHT", 5, 0)
                price:SetTextColor(1, 0.82, 0)
                price:SetText(GetMoneyString(v.price, true))
                price:SetJustifyH("LEFT")
                price:SetWordWrap(false)
            end
            for i, v in ipairs(BiaoGe.marketPrice) do
                CreateBar(i, v)
            end
            CreateBar(#BiaoGe.marketPrice + 1, { price = self.currentPrice or 0 }, true)

            local text
            local moneyTitle, money
            if not BG.IsTW then
                moneyTitle = "¥"
                money = 90
            else
                moneyTitle = "HK$"
                money = 150
            end
            local m1 = self.currentPrice / money / 10000
            m1 = floor(m1) * 10000
            text = moneyTitle .. "1 = " .. GetMoneyString(m1, true)
            local m2 = money / (self.currentPrice / 10000)
            if BG.IsRetail then
                m2 = format("%.6f", m2)
            else
                m2 = format("%.4f", m2)
            end
            text = text .. "   " .. GetMoneyString(10000, true) .. " = " .. m2 .. moneyTitle
            local bottomText = f:CreateFontString()
            bottomText:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
            bottomText:SetPoint("BOTTOM", f, "BOTTOM", 0, 8)
            bottomText:SetTextColor(1, .85, 0)
            bottomText:SetText(text)

            f:SetSize(frameWidth, (#f.buttons + 1) * barHeight + 40)
        end

        local bt = CreateFrame("Button", nil, BG.MainFrame)
        bt:SetSize(1, 20)
        if lastBt then
            bt:SetPoint("RIGHT", lastBt, "LEFT", -10, 0)
        else
            bt:SetPoint("BOTTOMRIGHT", -10, 1)
        end
        bt:SetNormalFontObject(BG.FontYellow13)
        bt:SetHighlightFontObject(BG.FontWhite13)
        BG.OnEnterDelay(bt, CreateHistoryFrame, delayTime)
        BG.OnLeaveDelay(bt, function(self)
            if self.frame then
                self.frame:Hide()
            end
        end)
        BG.ButtonToken = bt

        local function SavePrice(currentPrice)
            if not next(BiaoGe.marketPrice) or
                GetServerTime() - BiaoGe.marketPrice[#BiaoGe.marketPrice].time > saveCD then
                tinsert(BiaoGe.marketPrice, {
                    time = GetServerTime(),
                    price = currentPrice,
                })
                if #BiaoGe.marketPrice > saveMaxCount then
                    for i = #BiaoGe.marketPrice - saveMaxCount, 1, -1 do
                        tremove(BiaoGe.marketPrice, i)
                    end
                end
            end
        end
        local function OnTokenMarketPriceUpdated(event, result)
            local currentPrice = C_WowTokenPublic.GetCurrentMarketPrice()
            if currentPrice then
                SavePrice(currentPrice)
                bt.currentPrice = currentPrice
                bt:SetText(AddTexture(1120721) .. BG.FormatNumber(currentPrice / 1e4, 0))
                bt:SetWidth(bt:GetFontString():GetWidth())
            else
                bt:SetText("")
                bt:SetWidth(1)
            end
        end
        BG.RegisterEvent("TOKEN_MARKET_PRICE_UPDATED", OnTokenMarketPriceUpdated)

        BG.Init2(function()
            C_Timer.After(2, function()
                C_WowTokenPublic.UpdateMarketPrice()
                OnTokenMarketPriceUpdated()
            end)
        end)
        C_Timer.NewTicker(60, function()
            C_WowTokenPublic.UpdateMarketPrice()
        end)
    end

    -- 在线玩家数
    if BG.IsTW then
        BG.Init2(function()
            if not IsAddOnLoaded("Blizzard_Communities") then
                UIParentLoadAddOn("Blizzard_Communities")
            end
        end)

        local World = LOOK_FOR_GROUP

        local function GetFactionName()
            if UnitFactionGroup("player") == "Alliance" then
                return FACTION_ALLIANCE
            else
                return FACTION_HORDE
            end
        end
        local function OnEnter(self)
            self.isOnEnter = true
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(format(L["%s在线人数"], GetFactionName()), 1, 1, 1, true)
            if self.count then
                GameTooltip:AddLine(self.count .. L["人"] .. format(L["（获取时间：%s）"], self.time), 1, 0.82, 0, true)
            else
                local yes
                local channels = { GetChannelList() }
                for i = 1, #channels, 3 do
                    if channels[i + 1] == World then
                        yes = true
                        break
                    end
                end
                if yes then
                    GameTooltip:AddLine(L["未刷新"], 0.5, 0.5, 0.5, true)
                else
                    GameTooltip:AddLine(format(L["你未加入%s，无法获取在线人数。"], World), 0.5, 0.5, 0.5, true)
                end
            end
            GameTooltip:AddLine(L["<点击刷新>"], 0, 1, 0, true)

            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(format(L["数据来源："]), 1, 1, 1, true)
            GameTooltip:AddLine(format(L["%s在线人数"], World), 1, 0.82, 0, true)
            GameTooltip:Show()
        end
        local function OnLeave(self)
            self.isOnEnter = false
            GameTooltip:Hide()
        end

        local bt = CreateFrame("Button", nil, BG.MainFrame)
        bt:SetSize(1, 20)
        bt:SetPoint("LEFT", BG.ButtonToken, "RIGHT", 0, 0)
        bt:SetNormalFontObject(BG.FontWhite13)
        bt:SetText(AddTexture(135994) .. L["待刷新"])
        bt:GetFontString():SetPoint("LEFT")
        bt:SetWidth(bt:GetFontString():GetWidth() + 10)
        bt.channel = World
        BG.OnEnterDelay(bt, OnEnter, 0)
        BG.OnLeaveDelay(bt, OnLeave)
        bt:SetScript("OnClick", function(self)
            BG.GetChannelMemberCount(self.channel)
            BG.PlaySound(1)
        end)
        BG.ButtonOnLineCount = bt

        function BG.GetChannelMemberCount(channelName)
            local channels = { GetChannelList() }
            for i = 1, #channels, 3 do
                if channels[i + 1] == channelName then
                    if ChannelFrame:IsShown() then
                        HideUIPanel(ChannelFrame)
                    end
                    ChannelFrame.targetChannel = channelName
                    ShowUIPanel(ChannelFrame)
                    return
                end
            end
        end

        hooksecurefunc(ChannelFrame.ChannelList, 'AddChannelButtonInternal', function(_, channelbt, _, name, _, channelID)
            if name == ChannelFrame.targetChannel then
                BG.After(0.3, function()
                    ChannelFrame.ChannelList:SetSelectedChannel(channelbt)
                    BG.After(1, function()
                        local _, _, _, _, count = GetChannelDisplayInfo(channelbt.channelID)
                        if count then
                            bt.count = count
                            local m, s = GetGameTime()
                            s = format("%02d", s)
                            bt.time = m .. ":" .. s
                            bt:SetText(AddTexture(135994) .. count .. L["人"])
                            bt:GetFontString():SetPoint("LEFT")
                            bt:SetWidth(bt:GetFontString():GetWidth() + 10)
                            if bt.isOnEnter then
                                OnEnter(bt)
                            end
                        end
                        for k, bt in ipairs(ChannelFrame.ChannelList.buttons) do
                            if bt.name == CHANNEL_CATEGORY_WORLD then
                                ChannelFrame.ChannelList:SetSelectedChannel(bt)
                                return
                            end
                        end
                    end)
                end)
                ChannelFrame.targetChannel = nil
                HideUIPanel(ChannelFrame)
            end
        end)
    end
end)
