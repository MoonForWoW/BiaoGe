if BG.IsBlackListPlayer then return end
if not (BG.IsTBC or BG.IsWLK or BG.IsCTM or BG.IsMOP) then return end
BG.canShowAtlasLoot = true

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

local pt = print
local RealmId = GetRealmID()
local player = BG.playerName
local className, classFilename, classID = UnitClass("player")
local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded

BG.Init2(function()
    local addonName
    if IsAddOnLoaded("AtlasLootClassic") then
        addonName = "AtlasLootClassic"
    elseif IsAddOnLoaded("AtlasLootMY") then
        addonName = "AtlasLootMY"
    end
    if not addonName then return end

    local mainFrame = _G["AtlasLoot_GUI-Frame"]
    if not mainFrame then return end
    BG.AtlasLootMainFrame = mainFrame

    local AtlasLoot = AtlasLoot or AtlasLootMY
    local ClickSelectButton

    local verNum
    if BG.IsTBC then
        verNum = 2
    elseif BG.IsWLK_80 then
        verNum = 3
    elseif BG.IsTitan then
        verNum = 3
    elseif BG.IsCTM then
        verNum = 4
    elseif BG.IsMOP then
        verNum = 5
    end

    local verText = {
        [2] = "BC",
        [3] = "Wrath",
        [4] = "Cata",
        [5] = "MoP",
    }
    local function GetVerText()
        return verText[AtlasLoot.db.GUI.selectedGameVersion] or ""
    end

    local infoTbl = {
        [2] = {
            ["Enchanting"] = 1,      -- 附魔
            ["Blacksmithing"] = 19,  -- 锻造
            ["Engineering"] = 7,     -- 工程
            ["Tailoring"] = 11,      -- 裁缝
            ["Leatherworking"] = 10, -- 制皮
            ["Jewelcrafting"] = 6,   -- 珠宝
            ["Alchemy"] = 1,         -- 炼金
            ["Cooking"] = 1,         -- 烹饪
            -- 专业制造
            [addonName .. "_Crafting"] = function()
                mainFrame.subCatSelect:SetSelected("Enchanting" .. GetVerText())
            end,
            -- 地下城和团队副本
            [addonName .. "_DungeonsAndRaids"] = function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
                mainFrame.subCatSelect:SetSelected("Karazhan")
            end,
        },
        [4] = {
            ["Enchanting"] = 1,      -- 附魔
            ["Blacksmithing"] = 15,  -- 锻造
            ["Engineering"] = 6,     -- 工程
            ["Tailoring"] = 10,      -- 裁缝
            ["Leatherworking"] = 10, -- 制皮
            ["Jewelcrafting"] = 5,   -- 珠宝
            ["Inscription"] = function()
                local id = {
                    WARRIOR = 11,
                    PALADIN = 6,
                    HUNTER = 4,
                    ROGUE = 8,
                    PRIEST = 7,
                    DEATHKNIGHT = 2,
                    SHAMAN = 9,
                    MAGE = 5,
                    WARLOCK = 10,
                    MONK = 1,
                    DRUID = 3,
                }
                if id[classFilename] then
                    mainFrame.boss:SetSelected(id[classFilename])
                end
            end,             -- 铭文
            ["Alchemy"] = 1, -- 炼金
            ["Cooking"] = 1, -- 烹饪
            -- 专业制造
            [addonName .. "_Crafting"] = function()
                mainFrame.subCatSelect:SetSelected("Enchanting" .. GetVerText())
            end,
            -- 地下城和团队副本
            [addonName .. "_DungeonsAndRaids"] = function()
                mainFrame.subCatSelect:SetSelected("DragonSoul")
                ClickSelectButton(6, 1, "notRefresh")
            end,
            -- PVP
            [addonName .. "_PvP"] = function()
                mainFrame.subCatSelect:SetSelected("ArenaS11PvP")
                ClickSelectButton(14, 1, "notRefresh")
            end,
            -- 藏品
            [addonName .. "_Collections"] = function()
                mainFrame.subCatSelect:SetSelected("TierSets")
                mainFrame.boss:SetSelected(14)
                ClickSelectButton(5, 1)
            end,
        },
        [5] = {
            ["Enchanting"] = 1,      -- 附魔
            ["Blacksmithing"] = 14,  -- 锻造
            ["Engineering"] = 3,     -- 工程
            ["Tailoring"] = 10,      -- 裁缝
            ["Leatherworking"] = 10, -- 制皮
            ["Jewelcrafting"] = 4,   -- 珠宝
            ["Inscription"] = 4,     -- 铭文
            ["Alchemy"] = 1,         -- 炼金
            ["Cooking"] = 1,         -- 烹饪
            [addonName .. "_Crafting"] = function()
                -- 专业制造
                mainFrame.subCatSelect:SetSelected("Enchanting" .. GetVerText())
            end,
            [addonName .. "_DungeonsAndRaids"] = function()
                -- 地下城和团队副本
                mainFrame.subCatSelect:SetSelected("TerraceofEndlessSpring")
                ClickSelectButton(6, 1, "notRefresh")
            end,
            [addonName .. "_PvP"] = function()
                -- PVP
                mainFrame.subCatSelect:SetSelected("ArenaS12PvP")
                ClickSelectButton(18, 1, "notRefresh")
            end,
            [addonName .. "_Collections"] = function()
                -- 藏品
                mainFrame.subCatSelect:SetSelected("TierSets")
                mainFrame.boss:SetSelected(15)
                ClickSelectButton(5, 1)
            end,
        },
    }
    if addonName == "AtlasLootMY" then
        infoTbl[3] = {
            ["Enchanting"] = 1,      -- 附魔
            ["Blacksmithing"] = 20,  -- 锻造
            ["Engineering"] = 6,     -- 工程
            ["Tailoring"] = 11,      -- 裁缝
            ["Leatherworking"] = 10, -- 制皮
            ["Jewelcrafting"] = 5,   -- 珠宝
            ["Inscription"] = function()
                local id
                if classFilename == "DRUID" then
                    id = 3 + classID - 1
                else
                    id = 3 + classID
                end
                mainFrame.boss:SetSelected(id)
            end,              -- 铭文
            ["Alchemy"] = 1,  -- 炼金
            ["Cooking"] = 13, -- 烹饪
            -- 专业制造
            [addonName .. "_Crafting"] = function()
                mainFrame.subCatSelect:SetSelected("Enchanting" .. GetVerText())
            end,
            -- 地下城和团队副本
            [addonName .. "_DungeonsAndRaids"] = function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
                mainFrame.subCatSelect:SetSelected("MoltenCore80")
            end,
            -- 藏品
            [addonName .. "_Collections"] = function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
                mainFrame.subCatSelect:SetSelected("EmblemofHeroism")
            end,
        }
    else
        infoTbl[3] = {
            ["Enchanting"] = 1,      -- 附魔
            ["Blacksmithing"] = 14,  -- 锻造
            ["Engineering"] = 6,     -- 工程
            ["Tailoring"] = 11,      -- 裁缝
            ["Leatherworking"] = 10, -- 制皮
            ["Jewelcrafting"] = 5,   -- 珠宝
            ["Inscription"] = function()
                local id
                if classFilename == "DRUID" then
                    id = 3 + classID - 1
                else
                    id = 3 + classID
                end
                mainFrame.boss:SetSelected(id)
            end,              -- 铭文
            ["Alchemy"] = 1,  -- 炼金
            ["Cooking"] = 13, -- 烹饪
            -- 专业制造
            [addonName .. "_Crafting"] = function()
                mainFrame.subCatSelect:SetSelected("Enchanting" .. GetVerText())
            end,
            -- 地下城和团队副本
            -- [addonName.."_DungeonsAndRaids"] = function()
            --     mainFrame.subCatSelect:SetSelected("DragonSoul")
            --     ClickSelectButton(6, 1, "notRefresh")
            -- end,
            -- PVP
            -- [addonName.."_PvP"] = function()
            --     mainFrame.subCatSelect:SetSelected("ArenaS11PvP")
            --     ClickSelectButton(14, 1, "notRefresh")
            -- end,
            -- 藏品
            -- [addonName.."_Collections"] = function()
            --     mainFrame.subCatSelect:SetSelected("TierSets")
            --     mainFrame.boss:SetSelected(14)
            --     ClickSelectButton(5, 1)
            -- end,
        }
    end

    function ClickSelectButton(id, selectFrameID, notRefresh)
        for i, SelectButton in ipairs(_G["AtlasLoot-Select-" .. (selectFrameID or 2)].obj.buttons) do
            if SelectButton.info and SelectButton.info.id == id then
                SelectButton:Click()
                if not notRefresh then
                    AtlasLoot.GUI.ItemFrame:Refresh(true)
                end
                return
            end
        end
    end

    for _, dropDownButton in ipairs({
        _G["AtlasLoot-DropDown-1"],
        _G["AtlasLoot-DropDown-1-button"],
        _G["AtlasLoot-DropDown-2"],
        _G["AtlasLoot-DropDown-2-button"],
    }) do
        dropDownButton:HookScript("OnClick", function(self)
            for i = 1, 40 do
                local Button = _G["AtlasLoot-DropDown-Button" .. i]
                if Button then
                    Button:HookScript("OnClick", function(self)
                        if BiaoGe.options.AtlasLoot_betterChoose ~= 1 then return end
                        if BG.IsWLK_80 then
                            if AtlasLoot.db.GUI.selectedGameVersion and AtlasLoot.db.GUI.selectedGameVersion ~= verNum then return end
                            if self.id == "BlacksmithingWrath" then
                                -- 锻造
                                mainFrame.boss:SetSelected(14)
                            elseif self.id == "EngineeringWrath" then
                                -- 工程
                                mainFrame.boss:SetSelected(11)
                            elseif self.id == "TailoringWrath" then
                                -- 裁缝
                                mainFrame.boss:SetSelected(11)
                            elseif self.id == "LeatherworkingWrath" then
                                -- 制皮
                                mainFrame.boss:SetSelected(10)
                            elseif self.id == "JewelcraftingWrath" then
                                -- 珠宝
                                mainFrame.boss:SetSelected(5)
                            elseif self.id == "InscriptionWrath" then
                                -- 铭文
                                local id
                                if classFilename == "DRUID" then
                                    id = 3 + classID - 1
                                else
                                    id = 3 + classID
                                end
                                mainFrame.boss:SetSelected(id)
                            elseif self.id == "CookingWrath" then
                                -- 烹饪
                                mainFrame.boss:SetSelected(13)
                            elseif self.id == addonName .. "_DungeonsAndRaids" then
                                -- 地下城和团队副本
                                mainFrame.subCatSelect:SetSelected("IcecrownCitadel")
                                ClickSelectButton(10, 1, "notRefresh")
                                AtlasLoot.GUI.ItemFrame:Refresh(true)
                            elseif self.id == addonName .. "_Crafting" then
                                -- 专业制造
                                mainFrame.subCatSelect:SetSelected("EnchantingWrath")
                                AtlasLoot.GUI.ItemFrame:Refresh(true)
                            elseif self.id == addonName .. "_Factions" then
                                -- 声望
                                mainFrame.subCatSelect:SetSelected("TheSonsofHodir")
                                AtlasLoot.GUI.ItemFrame:Refresh(true)
                            elseif self.id == addonName .. "_PvP" then
                                -- PVP
                                -- mainFrame.subCatSelect:SetSelected("ArenaS6PvP")
                                -- AtlasLoot.GUI.ItemFrame:Refresh(true)
                            elseif self.id == addonName .. "_Collections" then
                                -- 藏品
                                ClickSelectButton(11, nil, "notRefresh")
                                ClickSelectButton(9, 1)
                                AtlasLoot.GUI.ItemFrame:Refresh(true)
                            end
                        else
                            local ver = AtlasLoot.db.GUI.selectedGameVersion
                            if infoTbl[ver] then
                                for k, v in pairs(infoTbl[ver]) do
                                    if self.id:find(k) then
                                        if type(v) == "number" then
                                            mainFrame.boss:SetSelected(v)
                                        elseif type(v) == "function" then
                                            v()
                                        end
                                        break
                                    end
                                end
                            end
                        end
                        AtlasLoot.GUI.ItemFrame:Refresh(true)
                    end)
                end
            end
        end)
    end

    -- 快捷按钮
    local last
    local buttons = {}
    local function CreateButton(text, func, height)
        local bt = BG.CreateButton(mainFrame)
        bt:SetSize(65, 24)
        if last then
            bt:SetPoint("TOP", last, "BOTTOM", 0, height or -1)
        else
            bt:SetPoint("TOPLEFT", _G["AtlasLoot-Select-1"], "TOPRIGHT", 10, height or 0)
        end
        bt:SetFrameLevel(10)
        bt:SetText(text)
        last = bt
        tinsert(buttons, bt)
        bt:SetScript("OnClick", function(self)
            AtlasLoot.db.GUI.selectedGameVersion = verNum
            mainFrame.gameVersionLogo:SetTexture(AtlasLoot.GAME_VERSION_TEXTURES[verNum])
            func()
            AtlasLoot.GUI.ItemFrame:Refresh(true)
            BG.PlaySound(1)
        end)
    end

    function BG.AtlasLootUpdateFastButton()
        for _, bt in pairs(buttons) do
            bt:SetShown(BiaoGe.options.AtlasLoot_fastChoose == 1)
        end
    end

    mainFrame:HookScript("OnShow", BG.AtlasLootUpdateFastButton)

    local info = infoTbl[verNum]
    if BG.IsTBC then
        CreateButton(L["卡拉赞"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            mainFrame.subCatSelect:SetSelected("Karazhan")
        end)
        CreateButton(L["格鲁尔"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            mainFrame.subCatSelect:SetSelected("GruulsLair")
        end)
        CreateButton(L["玛胖"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            mainFrame.subCatSelect:SetSelected("MagtheridonsLair")
        end)
        CreateButton(L["T4"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            mainFrame.subCatSelect:SetSelected("GruulsLair")
            ClickSelectButton(3, 3, "notRefresh")
        end)
        CreateButton(L["牌子"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
            mainFrame.subCatSelect:SetSelected("BadgeofJustice")
            mainFrame.boss:SetSelected(9)
        end)
    elseif BG.IsWLK_80 then
        CreateButton(L["冰冠"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            mainFrame.subCatSelect:SetSelected("IcecrownCitadel")
            ClickSelectButton(10, 1, "notRefresh")
        end)
        CreateButton(L["T10套"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            mainFrame.subCatSelect:SetSelected("IcecrownCitadel")
            ClickSelectButton(14, 3, "notRefresh")
            ClickSelectButton(15, 1, "notRefresh")
        end)
        CreateButton(L["牌子"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
            mainFrame.subCatSelect:SetSelected("EmblemofFrost")
            mainFrame.boss:SetSelected(8)
        end)
        CreateButton(L["天谴石"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
            mainFrame.subCatSelect:SetSelected("DefilersScourgestone")
            mainFrame.boss:SetSelected(8)
        end)
    elseif BG.IsTitan then
        local offset = -10
        if addonName == "AtlasLootMY" then
            CreateButton(L["太阳井"], function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
                mainFrame.subCatSelect:SetSelected("SunwellPlateau80")
            end, 40)
            CreateButton(L["祖阿曼"], function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
                mainFrame.subCatSelect:SetSelected("ZulAman80")
            end)
            CreateButton(L["套装"], function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
                mainFrame.subCatSelect:SetSelected("SunwellPlateau80")
                ClickSelectButton(9, 3, "notRefresh")
            end)
            CreateButton(L["牌子"], function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
                mainFrame.subCatSelect:SetSelected("EmblemofHeroismP5")
                mainFrame.boss:SetSelected(11)
            end)

            CreateButton(L["十字军"], function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
                mainFrame.subCatSelect:SetSelected("TrialoftheCrusader")
            end, offset)
            CreateButton(L["套装"], function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
                mainFrame.subCatSelect:SetSelected("TrialoftheCrusader")
                ClickSelectButton(8, 3, "notRefresh")
            end)
            CreateButton(L["祖格"], function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
                mainFrame.subCatSelect:SetSelected("Zul'Gurub80")
            end)
            CreateButton(L["套装"], function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
                mainFrame.subCatSelect:SetSelected("Zul'Gurub80")
                ClickSelectButton(15, 3, "notRefresh")
            end)
            CreateButton(L["牌子"], function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
                mainFrame.subCatSelect:SetSelected("EmblemofHeroismP4")
                mainFrame.boss:SetSelected(8)
            end)
            CreateButton("NAXX", function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
                mainFrame.subCatSelect:SetSelected("NaxxramasWrath")
            end, offset)
            CreateButton(L["黑曜石"], function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
                mainFrame.subCatSelect:SetSelected("ObsidianSanctum")
            end)
            CreateButton(L["永恒"], function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
                mainFrame.subCatSelect:SetSelected("TheEyeOfEternity")
            end)
            CreateButton(L["套装"], function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
                mainFrame.subCatSelect:SetSelected("NaxxramasWrath")
                ClickSelectButton(16, 3, "notRefresh")
                -- ClickSelectButton(9, 1, "notRefresh")
            end)
            CreateButton(L["牌子"], function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
                mainFrame.subCatSelect:SetSelected("EmblemofHeroismP3")
            end)

            -- CreateButton(L["毒蛇"], function()
            --     mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            --     mainFrame.subCatSelect:SetSelected("SerpentshrineCavern80")
            -- end, offset)
            -- CreateButton(L["风暴"], function()
            --     mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            --     mainFrame.subCatSelect:SetSelected("TempestKeep80")
            -- end)
            -- CreateButton(L["世界"], function()
            --     mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            --     mainFrame.subCatSelect:SetSelected("WorldBossesBC80")
            -- end)
            -- CreateButton(L["套装"], function()
            --     mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            --     mainFrame.subCatSelect:SetSelected("TempestKeep80")
            --     ClickSelectButton(7, 3, "notRefresh")
            -- end)
            -- CreateButton("MC", function()
            --     mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            --     mainFrame.subCatSelect:SetSelected("MoltenCore80")
            -- end, offset)
            -- CreateButton(L["世界"], function()
            --     mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            --     mainFrame.subCatSelect:SetSelected("WorldBosses81")
            -- end)
            -- CreateButton(L["套装"], function()
            --     mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            --     mainFrame.subCatSelect:SetSelected("MoltenCore80")
            --     ClickSelectButton(12, 3, "notRefresh")
            -- end)
        end
    elseif BG.IsCTM then
        CreateButton(L["巨龙"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            mainFrame.subCatSelect:SetSelected("DragonSoul")
            ClickSelectButton(6, 1, "notRefresh")
        end)
        CreateButton(L["T13套"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
            mainFrame.subCatSelect:SetSelected("TierSets")
            mainFrame.boss:SetSelected(14)
            ClickSelectButton(5, 1)
        end)
        CreateButton(L["正义"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
            mainFrame.subCatSelect:SetSelected("ValorPoints" .. GetVerText())
            mainFrame.boss:SetSelected(4)
        end, -20)
        CreateButton(L["裂隙石"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
            mainFrame.subCatSelect:SetSelected("ObsidianFragments")
            mainFrame.boss:SetSelected(10)
        end)
        CreateButton(L["荣誉"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_PvP")
            mainFrame.subCatSelect:SetSelected("ArenaS11PvP")
            ClickSelectButton(14, 1, "notRefresh")
            mainFrame.boss:SetSelected(14)
        end)
    elseif BG.IsMOP then
        CreateButton(L["雷电"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            mainFrame.subCatSelect:SetSelected("ThroneofThunder")
            ClickSelectButton(6, 1, "notRefresh")
        end)
        CreateButton(L["T15"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
            mainFrame.subCatSelect:SetSelected("TierSets")
            mainFrame.boss:SetSelected(16)
            ClickSelectButton(5, 1)
        end)
        CreateButton(L["天神"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
            mainFrame.subCatSelect:SetSelected("AugustStoneShardVendor" .. GetVerText())
            ClickSelectButton(21, 1, "notRefresh")
            mainFrame.boss:SetSelected(6)
        end)

        CreateButton(L["魔古山"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            mainFrame.subCatSelect:SetSelected("MoguShanVaults")
            ClickSelectButton(6, 1, "notRefresh")
        end, -20)
        CreateButton(L["恐惧"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            mainFrame.subCatSelect:SetSelected("HeartofFear")
            ClickSelectButton(6, 1, "notRefresh")
        end)
        CreateButton(L["永春台"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_DungeonsAndRaids")
            mainFrame.subCatSelect:SetSelected("TerraceofEndlessSpring")
            ClickSelectButton(6, 1, "notRefresh")
        end)
        CreateButton(L["T14"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
            mainFrame.subCatSelect:SetSelected("TierSets")
            mainFrame.boss:SetSelected(15)
            ClickSelectButton(5, 1)
        end)
        CreateButton(L["天神"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
            mainFrame.subCatSelect:SetSelected("AugustStoneFragmentVendor" .. GetVerText())
            ClickSelectButton(21, 1, "notRefresh")
            mainFrame.boss:SetSelected(6)
        end)

        CreateButton(L["勇气"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
            mainFrame.subCatSelect:SetSelected("ValorPoints" .. GetVerText())
            mainFrame.boss:SetSelected(8)
        end, -20)
        CreateButton(L["正义"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Collections")
            mainFrame.subCatSelect:SetSelected("JusticePoints" .. GetVerText())
            mainFrame.boss:SetSelected(8)
        end)
    end

    -- 专业技能
    do
        CreateButton(AddTexture("Interface/Icons/trade_engraving") .. L["附魔"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Crafting")
            mainFrame.subCatSelect:SetSelected("Enchanting" .. GetVerText())
            mainFrame.boss:SetSelected(info["Enchanting"])
        end, BG.IsTitan and -10 or -20)
        CreateButton(AddTexture("Interface/Icons/inv_misc_gem_01") .. L["珠宝"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Crafting")
            mainFrame.subCatSelect:SetSelected("Jewelcrafting" .. GetVerText())
            mainFrame.boss:SetSelected(info["Jewelcrafting"])
        end)
        CreateButton(AddTexture("Interface/Icons/trade_blacksmithing") .. L["锻造"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Crafting")
            mainFrame.subCatSelect:SetSelected("Blacksmithing" .. GetVerText())
            mainFrame.boss:SetSelected(info["Blacksmithing"])
        end)
        CreateButton(AddTexture("Interface/Icons/trade_tailoring") .. L["裁缝"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Crafting")
            mainFrame.subCatSelect:SetSelected("Tailoring" .. GetVerText())
            mainFrame.boss:SetSelected(info["Tailoring"])
        end)
        CreateButton(AddTexture("Interface/Icons/trade_leatherworking") .. L["制皮"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Crafting")
            mainFrame.subCatSelect:SetSelected("Leatherworking" .. GetVerText())
            mainFrame.boss:SetSelected(info["Leatherworking"])
        end)
        CreateButton(AddTexture("Interface/Icons/trade_engineering") .. L["工程"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Crafting")
            mainFrame.subCatSelect:SetSelected("Engineering" .. GetVerText())
            mainFrame.boss:SetSelected(info["Engineering"])
        end)
        if BG.verOver3 then
            CreateButton(AddTexture("Interface/Icons/inv_inscription_tradeskill01") .. L["铭文"], function()
                mainFrame.moduleSelect:SetSelected(addonName .. "_Crafting")
                mainFrame.subCatSelect:SetSelected("Inscription" .. GetVerText())
                if BG.IsMOP then
                    mainFrame.boss:SetSelected(info["Inscription"])
                else
                    info["Inscription"]()
                end
            end)
        end
        CreateButton(AddTexture("Interface/Icons/trade_alchemy") .. L["炼金"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Crafting")
            mainFrame.subCatSelect:SetSelected("Alchemy" .. GetVerText())
            mainFrame.boss:SetSelected(info["Alchemy"])
        end)
        CreateButton(AddTexture("Interface/Icons/inv_misc_food_15") .. L["烹饪"], function()
            mainFrame.moduleSelect:SetSelected(addonName .. "_Crafting")
            mainFrame.subCatSelect:SetSelected("Cooking" .. GetVerText())
            mainFrame.boss:SetSelected(info["Cooking"])
        end)
    end
end)
