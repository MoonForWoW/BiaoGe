local AddonName, ns = ...

if not( BG.IsWLK or BG.IsMOP) then return end

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
local After = C_Timer.After
local player = UnitName("player")
local realmID = GetRealmID()
local classFilename = select(2, UnitClass("player"))

local realmIDandPlayer = realmID .. player

local mainFrame

local function CreateCheckButton(name, text, parent, ontext)
    local bt = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    bt:SetSize(30, 30)
    bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    bt.Text:SetText(text)
    bt:SetHitRectInsets(0, -bt.Text:GetWidth(), 0, 0)
    bt.name = name
    bt.ontext = ontext
    BG.options["button" .. name] = bt
    bt:SetChecked(BiaoGe.options[name] == 1)
    bt:SetScript("OnClick", function(self)
        BiaoGe.options[self.name] = self:GetChecked() and 1 or 0
        if self.child then
            for _, child in pairs(self.child) do
                child:SetShown(self:GetChecked())
            end
        end
        BG.PlaySound(1)
    end)
    bt:SetScript("OnEnter", function(self)
        if not self.ontext then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
        GameTooltip:ClearLines()
        if type(self.ontext) == "table" then
            for i, tipText in ipairs(self.ontext) do
                if i == 1 then
                    GameTooltip:AddLine(tipText, 1, 1, 1, true)
                else
                    GameTooltip:AddLine(tipText, 1, .82, 0, true)
                end
            end
        else
            GameTooltip:SetText(self.ontext)
        end
        GameTooltip:Show()
    end)
    bt:SetScript("OnLeave", GameTooltip_Hide)
    bt:SetScript("OnShow", function(self)
        self:SetChecked(BiaoGe.options[self.name] == 1)
    end)
    return bt
end

local function UpdateScrollButtonState(bar)
    local value = bar:GetValue()
    local down = bar.ScrollDownButton or (bar.GetName and bar:GetName() and _G[bar:GetName() .. "ScrollDownButton"])
    local up = bar.ScrollUpButton or (bar.GetName and bar:GetName() and _G[bar:GetName() .. "ScrollUpButton"])
    local minValue, maxValue = bar:GetMinMaxValues()
    if up then
        up:SetEnabled(value > minValue)
    end
    if down then
        down:SetEnabled(value < maxValue)
    end
end

BG.Init2(function()
    mainFrame = BG.DungeonMainFrame
    BiaoGe.dungeon = BiaoGe.dungeon or {}
    BiaoGe.dungeon.saveDuration = BiaoGe.dungeon.saveDuration or 7
    BiaoGe.dungeon.isChooseRealm = BiaoGe.dungeon.isChooseRealm or 1
    BiaoGe.dungeon[realmID] = BiaoGe.dungeon[realmID] or {}
    BiaoGe.dungeon[realmID][player] = BiaoGe.dungeon[realmID][player] or {
        name = player,
        realmID = realmID,
        info = {},
    }
    BiaoGe.dungeon[realmID][player].class = select(2, UnitClass("player"))

    if BiaoGe.disabledModules["Dungeon"] then return end

    local info
    local isNewDungeon
    local SetTargetFrame
    local autoRollItemID
    local lastChoose
    local ArmorList = {
        DEATHKNIGHT = 4,
        PALADIN = 4,
        WARRIOR = 4,
        SHAMAN = 3,
        HUNTER = 3,
        MONK = 2,
        DRUID = 2,
        ROGUE = 2,
        MAGE = 1,
        WARLOCK = 1,
        PRIEST = 1,
    }

    local function CanSave()
        if info then
            local name, instanceType, difficultyID, difficultyName, maxPlayers,
            dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
            if LfgDungeonID and LfgDungeonID ~= 0 and instanceType == "party" and maxPlayers == 5 then
                return true
            end
        end
    end
    local function SaveSystemMsg(tbl, msg)
        if tbl then
            tinsert(tbl.msg, {
                time = GetServerTime(),
                event = "CHAT_MSG_SYSTEM",
                text = msg,
            })
        end
    end
    local function SavePlayers(tbl, print)
        tbl = tbl or info
        if tbl then
            if print then
                local msg = L["队员信息如下："]
                SendSystemMessage(msg)
                SaveSystemMsg(tbl, msg)
            end
            for i = 1, GetNumGroupMembers(2) do
                local name, rank, subgroup, level, class,
                fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i)
                if name and not tbl.players[name] then
                    local guildName = GetGuildInfo(name)
                    if not guildName or guildName == 0 then
                        guildName = ""
                    end
                    local level = UnitLevel(name) or ""
                    tbl.players[name] = {
                        name = name,
                        class = fileName,
                        guild = guildName,
                        level = level,
                        guid = UnitGUID(name),
                        combatRole = combatRole,
                    }
                    if print then
                        local guildText = ""
                        if guildName ~= "" then
                            guildText = "<" .. guildName .. ">"
                        end
                        local msg = format(L["%s：%s级%s%s%s"],
                            i, level, AddTexture(combatRole), SetClassCFF(name), guildText)
                        _G.SendSystemMessage(msg)
                        SaveSystemMsg(tbl, msg)
                    end
                end
            end
        end
    end
    local function New(dungeonID)
        local name, typeID, subtypeID, minLevel, maxLevel,
        recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID,
        textureFilename, difficulty, maxPlayers, description, isHoliday,
        bonusRepAmount, minPlayers, isTimeWalker, name2, minGearLevel,
        isScalingDungeon, instanceID = GetLFGDungeonInfo(dungeonID)
        local tbl = {
            time = GetServerTime(),
            players = {},
            role = {},
            msg = {},
            dungeon = {
                name = name,
                instanceID = instanceID,
                diffID = difficulty,
                dungeonID = dungeonID,
            },
        }
        SavePlayers(tbl, true)
        tinsert(BiaoGe.dungeon[realmID][player].info, 1, tbl)
        lastChoose = 1
        BG.DungeonMainFrame:UpdateFrameDelay()
        return tbl
    end
    local function SaveMsg(event, ...)
        local msg, playerName, languageName, channelName, playerName2,
        specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid = ...
        local colorName = playerName2
        if guid and guid ~= "" then
            local class = select(2, GetPlayerInfoByGUID(guid))
            local color = select(4, GetClassColor(class))
            colorName = "|c" .. color .. playerName2 .. "|r"
        end
        local nameLink = "|Hplayer:" .. playerName2 .. "|h[" .. colorName .. "]|h"
        tinsert(info.msg, {
            time = GetServerTime(),
            event = event,
            nameLink = nameLink,
            text = msg,
        })
    end
    local function SendDungeonDurTime()
        After(.5, function()
            if info and info.endTime and info.time then
                local t = info.endTime - info.time
                local xpText = ""
                if info.xp and info.xp ~= 0 then
                    xpText = format(L["，经验%s"], BG.FormatNumber(info.xp))
                end
                local msg = format(L["本次副本已完成，用时%s%s。"], SecondsToTime(t), xpText)
                SendSystemMessage(msg)
                SaveSystemMsg(info, L["本次副本已完成。"])
            end
        end)
    end
    local systemMsg = {
        ERR_UNINVITE_YOU,
        ERR_PARTY_LFG_BOOT_VOTE_FAILED,
        ERR_PARTY_LFG_BOOT_VOTE_SUCCEEDED,
        ERR_INSTANCE_GROUP_ADDED_S,
        ERR_INSTANCE_GROUP_REMOVED_S,
    }
    local xpSting = GARRISON_FOLLOWER_XP_LEFT:gsub("%%d", "(%%d+)")

    local matchStr = ITEM_CLASSES_ALLOWED:gsub("%%s", "(.+)")
    local className = UnitClass("player")
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("LFG_PROPOSAL_SHOW")
    eventFrame:RegisterEvent("LFG_PROPOSAL_DONE")
    eventFrame:RegisterEvent("START_LOOT_ROLL")
    eventFrame:RegisterEvent("LOOT_HISTORY_ROLL_CHANGED")
    eventFrame:RegisterEvent("LOOT_HISTORY_ROLL_COMPLETE")
    eventFrame:RegisterEvent("LOOT_HISTORY_FULL_UPDATE")
    eventFrame:RegisterEvent("LFG_COMPLETION_REWARD")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "LFG_PROPOSAL_SHOW" then
            self:RegisterEvent("LFG_PROPOSAL_DONE")
        elseif event == "LFG_PROPOSAL_DONE" then
            isNewDungeon = true
            self.entering = true
            After(3, function()
                self.entering = nil
            end)
        elseif event == "GROUP_ROSTER_UPDATE" and info then
            After(1, function()
                SavePlayers()
            end)
        elseif (event == "CHAT_MSG_INSTANCE_CHAT_LEADER"
                or event == "CHAT_MSG_INSTANCE_CHAT"
                or event == "CHAT_MSG_SAY") and CanSave() then
            SaveMsg(event, ...)
            BG.DungeonMainFrame:UpdateFrameDelay()
        elseif (event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM") and info then
            local msg, playerName, languageName, channelName, playerName2,
            specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid = ...
            if info.players[playerName2] then
                SaveMsg(event, ...)
                BG.DungeonMainFrame:UpdateFrameDelay()
            end
        elseif event == "CHAT_MSG_SYSTEM" and info then
            local msg = ...
            for _, text in pairs(systemMsg) do
                local _text = text:gsub("%%s", "(.+)")
                if msg:match(_text) then
                    SaveSystemMsg(info, msg)
                    BG.DungeonMainFrame:UpdateFrameDelay()
                    return
                end
            end
        elseif event == "START_LOOT_ROLL" then
            local name, instanceType, difficultyID, difficultyName, maxPlayers,
            dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
            if instanceType == "party" and maxPlayers == 5
            then
                local rollID = ...
                local link = GetLootRollItemLink(rollID)
                if link then
                    local itemID = GetItemID(link)
                    local canRoll = true
                    if BiaoGe.options["autoRollBlueGem"] == 1 and itemID == autoRollItemID then
                        RollOnLoot(rollID, 1)
                        canRoll = nil
                    end
                    if canRoll and BiaoGe.options["autoRollGreen" .. realmIDandPlayer] == 1 then
                        local quality = C_Item.GetItemQualityByID(link)
                        if quality == 2 then
                            RollOnLoot(rollID, 2)
                            canRoll = nil
                        end
                    end
                    if canRoll and BiaoGe.options["autoRollBlue" .. realmIDandPlayer] == 1 then
                        local quality = C_Item.GetItemQualityByID(link)
                        if quality == 3 then
                            RollOnLoot(rollID, 2)
                            canRoll = nil
                        end
                    end
                    if canRoll and BiaoGe.options["autoRollNotCanUse" .. realmIDandPlayer] == 1 and BG.IsMOP then
                        local quality, bindOnPickUp = select(4, GetLootRollItemInfo(rollID))
                        if bindOnPickUp or quality < 4 then
                            BG.Tooltip_SetItemByID(itemID)
                            for i = 1, BiaoGeTooltip:NumLines() do
                                local str = _G["BiaoGeTooltipTextLeft" .. i]:GetText()
                                if str then
                                    local classStr = str:match(matchStr)
                                    if classStr and not classStr:find(className) then
                                        RollOnLoot(rollID, 2)
                                        canRoll = nil
                                        break
                                    end
                                end
                            end
                            if canRoll then
                                local equipLoc, _, typeID, subTypeID = select(4, GetItemInfoInstant(itemID))
                                if typeID == 4 and BG.ValueInTable({ 1, 2, 3, 4 }, subTypeID) and equipLoc ~= "INVTYPE_CLOAK" then
                                    if ArmorList[classFilename] and ArmorList[classFilename] ~= subTypeID then
                                        RollOnLoot(rollID, 2)
                                        canRoll = nil
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if CanSave() then
                local itemIndex = 1
                local rollID, itemLink, numPlayers, isDone, winnerIdx = C_LootHistory.GetItem(itemIndex)
                local players = {}
                for playerIndex = 1, numPlayers do
                    local name, class, rollType, roll, isWinner, isMe = C_LootHistory.GetPlayerInfo(itemIndex, playerIndex);
                    if not isMe then
                        isMe = nil
                    end
                    players[playerIndex] = { name = name, class = class, isMe = isMe }
                end
                local _, _, quality, level, _, _, _, _, EquipLoc, _,
                _, typeID, subclassID, bindType = GetItemInfo(itemLink)
                tinsert(info, 1, {
                    rollID = rollID,
                    itemLink = itemLink,
                    quality = quality,
                    level = level,
                    bindType = bindType,
                    numPlayers = numPlayers,
                    isDone = isDone,
                    winnerIdx = winnerIdx,
                    players = players,
                    time = GetServerTime(),
                })
                BG.DungeonMainFrame:UpdateFrameDelay()
            end
        elseif event == "LOOT_HISTORY_ROLL_CHANGED" and CanSave() then
            local itemIndex, playerIndex = ...
            local name, class, rollType, roll, isWinner, isMe = C_LootHistory.GetPlayerInfo(itemIndex, playerIndex)
            local rollID = C_LootHistory.GetItem(itemIndex)
            for i, v in ipairs(info) do
                if v.rollID == rollID then
                    if not isWinner then
                        isWinner = nil
                    end
                    if not isMe then
                        isMe = nil
                    end
                    info[i].players[playerIndex] = {}
                    info[i].players[playerIndex].name = name
                    info[i].players[playerIndex].class = class
                    info[i].players[playerIndex].rollType = rollType
                    info[i].players[playerIndex].roll = roll
                    info[i].players[playerIndex].isWinner = isWinner
                    info[i].players[playerIndex].isMe = isMe
                    return
                end
            end
            BG.DungeonMainFrame:UpdateFrameDelay()
        elseif event == "LOOT_HISTORY_ROLL_COMPLETE" and CanSave() then
            for i, v in ipairs(info) do
                if not v.isDone then
                    for itemIndex = 1, C_LootHistory.GetNumItems() do
                        local rollID, itemLink, numPlayers, isDone, winnerIdx = C_LootHistory.GetItem(itemIndex)
                        if rollID == v.rollID and isDone then
                            info[i].isDone = isDone
                            info[i].winnerIdx = winnerIdx
                            for playerIndex = 1, numPlayers do
                                local name, class, rollType, roll, isWinner, isMe = C_LootHistory.GetPlayerInfo(itemIndex, playerIndex)
                                if not isWinner then
                                    isWinner = nil
                                end
                                if not isMe then
                                    isMe = nil
                                end
                                info[i].players[playerIndex] = {}
                                info[i].players[playerIndex].name = name
                                info[i].players[playerIndex].class = class
                                info[i].players[playerIndex].rollType = rollType
                                info[i].players[playerIndex].roll = roll
                                info[i].players[playerIndex].isWinner = isWinner
                                info[i].players[playerIndex].isMe = isMe
                            end
                            break
                        end
                    end
                end
            end
            BG.DungeonMainFrame:UpdateFrameDelay()
        elseif event == "CHAT_MSG_COMBAT_XP_GAIN" and info then
            local msg = ...
            local xp = msg:match(xpSting)
            if xp then
                self.xp = self.xp + xp
                info.xp = self.xp
                BG.DungeonMainFrame:UpdateFrameDelay()
            end
        elseif event == "LFG_COMPLETION_REWARD" and info and not info.endTime then
            self:Complete()
        elseif event == "PLAYER_ENTERING_WORLD" then
            if GetLFGMode(1) then
                local name, instanceType, difficultyID, difficultyName, maxPlayers,
                dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
                if instanceType == "party" and maxPlayers == 5 then
                    if BiaoGe.options["autoRollGreen" .. realmIDandPlayer] == 1
                        or BiaoGe.options["autoRollBlue" .. realmIDandPlayer] == 1 then
                        SendSystemMessage(L["已开启绿装或蓝装自动贪婪功能。如需取消，可在表格右下角随机本记录里取消。"])
                    end
                end
                After(3, function()
                    if isNewDungeon then
                        local name, instanceType, difficultyID, difficultyName, maxPlayers,
                        dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, dungeonID = GetInstanceInfo()
                        if dungeonID and dungeonID ~= 0 and instanceType == "party" and maxPlayers == 5 then
                            isNewDungeon = nil
                            info = New(dungeonID)
                            self:RegisterEvent("GROUP_ROSTER_UPDATE")
                            self:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER")
                            self:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
                            self:RegisterEvent("CHAT_MSG_SAY")
                            self:RegisterEvent("CHAT_MSG_WHISPER")
                            self:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
                            self:RegisterEvent("CHAT_MSG_SYSTEM")
                            self:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
                            self:UnregisterEvent("LFG_PROPOSAL_DONE")
                            self:StartCheckComplete()
                            self.xp = 0
                            SetTargetFrame:Start()
                        end
                    end
                end)
            else
                info = nil
                self:UnregisterEvent("GROUP_ROSTER_UPDATE")
                self:UnregisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER")
                self:UnregisterEvent("CHAT_MSG_INSTANCE_CHAT")
                self:UnregisterEvent("CHAT_MSG_SAY")
                self:UnregisterEvent("CHAT_MSG_WHISPER")
                self:UnregisterEvent("CHAT_MSG_WHISPER_INFORM")
                self:UnregisterEvent("CHAT_MSG_SYSTEM")
                self:UnregisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
                self:SetScript("OnUpdate", nil)
                SetTargetFrame:Stop()
            end
        end
    end)
    function eventFrame:StartCheckComplete()
        self.t = 0
        self:SetScript("OnUpdate", function(self, t)
            self.t = self.t + t
            if self.t >= 1 then
                self.t = 0
                if info and not info.endTime and IsPartyLFG() and IsLFGComplete() then
                    self:Complete()
                end
            end
        end)
    end

    function eventFrame:Complete()
        info.endTime = GetServerTime()
        BG.DungeonMainFrame:UpdateFrameDelay()
        SendDungeonDurTime()
        self:SetScript("OnUpdate", nil)
    end

    for i, frameName in ipairs({ "MiniMapLFGFrame", "LFGMinimapFrame" }) do
        if _G[frameName] then
            _G[frameName]:HookScript("OnHide", function(self)
                if eventFrame.entering then return end
                isNewDungeon = nil
                eventFrame:SetScript("OnUpdate", nil)
            end)
        end
    end

    -- UI
    do
        local db = {}
        local BUTTONHEIGHT = 40
        local MAXBUTTONS = 13
        local HEIGHT = MAXBUTTONS * BUTTONHEIGHT + 5
        local dungeonframe, dungeonscroll, dungeonchild, dungeonbar
        local lootframe, lootscroll, lootchild, lootbar
        local msgframe, msgscroll, msgchild, msgbar
        local GetDB, UpdateScrollFrame, UpdateButtons, GetLastChoose, GetChooseInfo
        local dropDown
        local choose = {
            realmID = realmID,
            player = player,
        }
        if BiaoGe.dungeon.isChooseRealm == 1 then choose = { realmID = realmID, } end
        -- 副本框体
        do
            dungeonframe = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
            dungeonframe:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            dungeonframe:SetBackdropColor(0, 0, 0, 0.4)
            dungeonframe:SetBackdropBorderColor(1, 1, 1, .8)
            dungeonframe:SetPoint("TOPLEFT", BG.MainFrame, "TOPLEFT", 10, -65)
            dungeonframe:SetSize(385, HEIGHT)
            dungeonframe:EnableMouse(true)
            dungeonframe.buttons = {}
            mainFrame.dungeonframe = dungeonframe
            dungeonframe:SetScript("OnShow", function(self)
                mainFrame:UpdateFrame()
            end)

            dungeonscroll = CreateFrame("ScrollFrame", nil, dungeonframe, BG.scrollTemplate)
            dungeonscroll:SetPoint("TOPLEFT", 0, -2)
            dungeonscroll:SetPoint("BOTTOMRIGHT", -25, 2)
            dungeonbar = dungeonscroll.ScrollBar
            dungeonbar.scrollStep = 4
            BG.CreateSrollBarBackdrop(dungeonbar)
            -- BG.HookScrollBarShowOrHide(dungeonscroll)
            dungeonbar:HookScript("OnValueChanged", function(self)
                UpdateButtons()
                UpdateScrollButtonState(dungeonbar)
            end)

            dungeonchild = CreateFrame("Frame", nil, dungeonframe)
            dungeonchild:SetWidth(dungeonscroll:GetWidth())
            dungeonchild:SetHeight(dungeonscroll:GetHeight())
            dungeonscroll:SetScrollChild(dungeonchild)

            -- 提示
            local t = dungeonframe:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("TOP", 0, -5)
            t:SetTextColor(.5, .5, .5)
            t:SetText(L["该角色没有随机本记录。"])
            dungeonframe.notText = t

            local function OnClick(self, button)
                BG.PlaySound(1)
                if button == "RightButton" then
                    local value = floor(dungeonbar:GetValue()) or 0
                    local num = value + self.num
                    local menu = {
                        {
                            text = self.info.colorPlayer,
                            isTitle = true,
                            notCheckable = true,
                        },
                        {
                            text = "   ",
                            isTitle = true,
                            notCheckable = true,
                        },
                        {
                            text = L["删除该条记录"],
                            notCheckable = true,
                            func = function()
                                local i = db[num].i
                                local player = db[num].player
                                local realmID = choose.realmID
                                tremove(BiaoGe.dungeon[realmID][player].info, i)
                                lastChoose = nil
                                mainFrame:UpdateFrame()
                                BG.PlaySound(1)
                            end
                        },
                        {
                            text = CANCEL,
                            notCheckable = true,
                            func = LibBG.CloseDropDownMenus,
                        }
                    }
                    LibBG:EasyMenu(menu, BG.dropDown, "cursor", 0, 0, "MENU", 2)
                else
                    lastChoose = self.index
                    dungeonframe:UpdateChooseTex()
                    lootframe:Show()
                    lootframe:UpdateInfo()
                end
            end

            function dungeonframe:CreateButton(ii)
                local bt = CreateFrame("Frame", nil, dungeonscroll)
                bt:SetSize(dungeonchild:GetWidth() - 2, BUTTONHEIGHT)
                if ii == 1 then
                    bt:SetPoint("TOPLEFT", dungeonscroll, 2, 0)
                else
                    bt:SetPoint("TOPLEFT", dungeonframe.buttons[(ii - 1)], "BOTTOMLEFT", 0, 0)
                end
                bt.num = ii
                dungeonframe.buttons[ii] = bt

                bt.Text1 = bt:CreateFontString()
                bt.Text1:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                bt.Text1:SetPoint("TOPLEFT", 5, -1)
                bt.Text1:SetTextColor(1, 1, 1)
                bt.Text1:SetWidth(bt:GetWidth() - 5)
                bt.Text1:SetHeight(bt:GetHeight() / 2)
                bt.Text1:SetWordWrap(false)
                bt.Text1:SetJustifyH("LEFT")

                bt.Text2 = bt:CreateFontString()
                bt.Text2:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                bt.Text2:SetPoint("BOTTOMLEFT", 5, 1)
                bt.Text2:SetTextColor(.6, .6, .6)
                bt.Text2:SetWidth(bt:GetWidth() - 5)
                bt.Text2:SetHeight(bt:GetHeight() / 2)
                bt.Text2:SetWordWrap(false)
                bt.Text2:SetJustifyH("LEFT")
                bt:SetScript("OnEnter", function(self)
                    for i, bt in ipairs(dungeonframe.buttons) do
                        bt.ds:Hide()
                    end
                    bt.ds:Show()
                end)
                bt:SetScript("OnLeave", function(self)
                    bt.ds:Hide()
                    GameTooltip:Hide()
                end)
                bt:SetScript("OnMouseUp", OnClick)
                CreateLine(bt, 0, bt:GetWidth(), 1, nil, 0.5)

                -- 底色材质
                bt.ds = bt:CreateTexture()
                bt.ds:SetAllPoints()
                bt.ds:SetColorTexture(1, 1, 1, 0.1)
                bt.ds:Hide()

                bt.chooseds = bt:CreateTexture()
                bt.chooseds:SetAllPoints()
                bt.chooseds:SetColorTexture(0, .75, 1, .8)
                bt.chooseds:Hide()
            end

            function dungeonframe:UpdateChooseTex()
                for i, bt in ipairs(self.buttons) do
                    if lastChoose and bt.index == lastChoose then
                        bt.chooseds:Show()
                    else
                        bt.chooseds:Hide()
                    end
                end
            end

            for ii = 1, MAXBUTTONS do
                dungeonframe:CreateButton(ii)
            end
        end

        -- 掉落详情
        do
            lootframe = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
            lootframe:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            lootframe:SetBackdropColor(0, 0, 0, 0.4)
            lootframe:SetBackdropBorderColor(1, 1, 1, .8)
            lootframe:SetPoint("TOPLEFT", dungeonframe, "TOPRIGHT", 5, 0)
            lootframe:SetSize(430, HEIGHT)
            lootframe:EnableMouse(true)
            lootframe.buttons = {}
            mainFrame.lootframe = lootframe

            lootscroll = CreateFrame("ScrollFrame", nil, lootframe, BG.scrollTemplate)
            lootscroll:SetPoint("TOPLEFT", 0, -2)
            lootscroll:SetPoint("BOTTOMRIGHT", -25, 2)
            lootbar = lootscroll.ScrollBar
            lootbar.scrollStep = 80
            BG.CreateSrollBarBackdrop(lootbar)
            BG.HookScrollBarShowOrHide(lootscroll)

            lootchild = CreateFrame("Frame", nil, lootframe) -- 子框架
            lootchild:SetWidth(lootscroll:GetWidth())
            lootchild:SetHeight(lootscroll:GetHeight())
            lootscroll:SetScrollChild(lootchild)

            local t = lootframe:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("BOTTOM", lootframe, "TOP", 0, 2)
            t:SetTextColor(1, .82, 0)
            t:SetText(L["装备roll点明细"])

            local function CreateRollInfoFrame(bt, info, rollInfo)
                local r, g, b = 1, 1, 1
                if rollInfo.class then
                    r, g, b = GetClassColor(rollInfo.class)
                end
                local alpha = 1
                local yesTex = ""
                if not rollInfo.isWinner then
                    alpha = 0.5
                else
                    yesTex = AddTexture("YES")
                end
                local role = ""
                if info.players and info.players[rollInfo.name] and info.players[rollInfo.name].combatRole then
                    role = AddTexture(info.players[rollInfo.name].combatRole)
                end
                local playerText = bt:CreateFontString()
                playerText:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                if next(bt.rollInfoFrames) then
                    playerText:SetPoint("TOPRIGHT", bt.rollInfoFrames[#bt.rollInfoFrames], "BOTTOMRIGHT", 0, 0)
                else
                    playerText:SetPoint("TOPRIGHT", 0, -3)
                end
                playerText:SetTextColor(r, g, b)
                playerText:SetText(role .. rollInfo.name .. yesTex)
                playerText:SetWidth(160)
                playerText:SetWordWrap(false)
                playerText:SetJustifyH("LEFT")
                playerText:SetAlpha(alpha)
                tinsert(bt.rollInfoFrames, playerText)
                local offset = 25
                local rollText = bt:CreateFontString()
                rollText:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                rollText:SetPoint("LEFT", playerText, "LEFT", -offset, 0)
                rollText:SetTextColor(1, 1, 1)
                rollText:SetJustifyH("LEFT")
                rollText:SetText(rollInfo.roll or (not rollInfo.rollType and "...") or "")
                rollText:SetAlpha(alpha)
                local rollIcon = bt:CreateTexture()
                rollIcon:SetPoint("RIGHT", playerText, "LEFT", -offset, 0)
                rollIcon:SetSize(12, 12)
                rollIcon:SetAlpha(alpha)
                if (rollInfo.rollType == LOOT_ROLL_TYPE_NEED) then
                    rollIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up");
                elseif (rollInfo.rollType == LOOT_ROLL_TYPE_GREED) then
                    rollIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Coin-Up");
                elseif (rollInfo.rollType == LOOT_ROLL_TYPE_DISENCHANT) then
                    rollIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-DE-Up");
                elseif (rollInfo.rollType == LOOT_ROLL_TYPE_PASS) then
                    rollIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up");
                end
            end

            function lootframe:CreateButton(info, itemInfo)
                local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID = GetItemInfoInstant(itemInfo.itemLink)
                local bt = CreateFrame("Frame", nil, lootchild)
                bt:SetSize(lootchild:GetWidth(), 75)
                if next(lootframe.buttons) then
                    bt:SetPoint("TOPLEFT", lootframe.buttons[#lootframe.buttons], "BOTTOMLEFT", 0, 0)
                else
                    bt:SetPoint("TOPLEFT", lootchild, 0, 0)
                end
                bt.rollInfoFrames = {}
                tinsert(lootframe.buttons, bt)
                -- 图标
                local r, g, b = 1, 1, 1
                if itemInfo.quality then
                    r, g, b = GetItemQualityColor(itemInfo.quality)
                end
                local iconFrame = CreateFrame("Frame", nil, bt, "BackdropTemplate")
                iconFrame:SetBackdrop({
                    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = 1,
                })
                iconFrame:SetBackdropBorderColor(r, g, b, 1)
                iconFrame:SetPoint("TOPLEFT", 3, -3)
                iconFrame:SetSize(35, 35)
                iconFrame:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                    GameTooltip:ClearLines()
                    GameTooltip:SetHyperlink(itemInfo.itemLink)
                end)
                iconFrame:SetScript("OnLeave", GameTooltip_Hide)
                iconFrame.tex = iconFrame:CreateTexture(nil, "BACKGROUND")
                iconFrame.tex:SetAllPoints()
                iconFrame.tex:SetTexture(icon)
                iconFrame.tex:SetTexCoord(unpack(BG.iconTexCoord))
                -- 装备等级
                local t = iconFrame:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                t:SetPoint("BOTTOM", iconFrame, "BOTTOM", 0, 1)
                t:SetText(itemInfo.level)
                t:SetTextColor(r, g, b)
                -- 装绑
                if itemInfo.bindType == 2 then
                    local t = iconFrame:CreateFontString()
                    t:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
                    t:SetPoint("TOP", iconFrame, 0, -2)
                    t:SetText(L["装绑"])
                    t:SetTextColor(0, 1, 0)
                end
                -- 装备名称
                local t = bt:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 2, -2)
                t:SetWidth(lootframe:GetWidth() - 270)
                t:SetText(itemInfo.itemLink:gsub("%[", ""):gsub("%]", ""))
                t:SetJustifyH("LEFT")
                t:SetWordWrap(false)
                -- 装备类型
                local t = bt:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                t:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMRIGHT", 2, 2)
                t:SetHeight(12)
                if _G[itemEquipLoc] then
                    if classID == 2 then
                        t:SetText(itemSubType)
                    else
                        t:SetText(_G[itemEquipLoc] .. " " .. itemSubType)
                    end
                end
                t:SetJustifyH("LEFT")
                -- 时间
                if itemInfo.time then
                    local t = bt:CreateFontString()
                    t:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                    t:SetPoint("TOPLEFT", iconFrame, "BOTTOMLEFT", 0, -3)
                    t:SetText(date("%m-%d %H:%M", itemInfo.time))
                    t:SetTextColor(.5, .5, .5)
                end
                if itemInfo.winnerIdx then
                    local playerInfo = itemInfo.players[itemInfo.winnerIdx]
                    local t = bt:CreateFontString()
                    t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                    t:SetPoint("TOPLEFT", iconFrame, "BOTTOMLEFT", 0, -15)
                    local role = ""
                    -- if info.players[playerInfo.name] and info.players[playerInfo.name].combatRole then
                    --     role = AddTexture(info.players[playerInfo.name].combatRole)
                    -- end
                    t:SetText(role .. playerInfo.name)
                    if playerInfo.class then
                        local r, g, b = GetClassColor(playerInfo.class)
                        t:SetTextColor(r, g, b)
                    end
                end

                -- ROLL点详情
                for playerIndex, rollInfo in ipairs(itemInfo.players) do
                    CreateRollInfoFrame(bt, info, rollInfo)
                end

                CreateLine(bt, 0, bt:GetWidth(), 1, nil, 0.5)
            end

            function lootframe:UpdateInfo()
                for i, bt in ipairs(lootframe.buttons) do
                    bt:Hide()
                end
                wipe(lootframe.buttons)
                local info = GetChooseInfo()
                if info then
                    for i, itemInfo in ipairs(info) do
                        lootframe:CreateButton(info, itemInfo)
                    end
                end
                msgframe:UpdateInfo(info)
            end
        end

        -- 聊天记录
        do
            msgframe = CreateFrame("Frame", nil, lootframe, "BackdropTemplate")
            msgframe:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            msgframe:SetBackdropColor(0, 0, 0, 0.4)
            msgframe:SetBackdropBorderColor(1, 1, 1, .8)
            msgframe:SetPoint("TOPLEFT", lootframe, "TOPRIGHT", 5, 0)
            msgframe:SetSize(430, HEIGHT)
            msgframe:EnableMouse(true)
            mainFrame.msgframe = msgframe
            msgscroll = CreateFrame("ScrollFrame", nil, msgframe, BG.scrollTemplate)
            msgscroll:SetPoint("TOPLEFT", 0, -2)
            msgscroll:SetPoint("BOTTOMRIGHT", -25, 2)
            msgbar = msgscroll.ScrollBar
            msgbar.scrollStep = 80
            BG.CreateSrollBarBackdrop(msgbar)
            BG.HookScrollBarShowOrHide(msgscroll)
            msgchild = CreateFrame("EditBox", nil, eventFrame)
            msgchild:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
            msgchild:SetWidth(msgscroll:GetWidth())
            msgchild:SetAutoFocus(false)
            msgchild:EnableMouse(false)
            msgchild:SetTextInsets(3, 3, 3, 3)
            msgchild:SetMultiLine(true)
            msgchild:SetHyperlinksEnabled(true)
            msgscroll:SetScrollChild(msgchild)
            msgchild:SetScript("OnHyperlinkEnter", function(self, link, text, button)
                GameTooltip:SetOwner(self, "ANCHOR_NONE", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:SetPoint("TOPRIGHT", msgframe, "TOPLEFT")
                local itemID = GetItemID(link)
                if itemID then
                    GameTooltip:SetHyperlink(link)
                end
                if (strsub(link, 1, 5) == "spell") then
                    GameTooltip:SetHyperlink(link)
                end
            end)
            msgchild:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
            msgchild:SetScript("OnHyperlinkClick", function(self, link, text, button)
                if (strsub(link, 1, 6) == "player") then
                    local _, name, lineID, chatType = strsplit(":", link)
                    if button == "LeftButton" then
                        ChatFrame_SendTell(name, ChatFrame1)
                    elseif button == "RightButton" then
                        FriendsFrame_ShowDropdown(name, 1, nil, "INSTANCE", nil)
                    end
                elseif (strsub(link, 1, 4) == "item") or (strsub(link, 1, 5) == "spell") then
                    if IsShiftKeyDown() then
                        BG.InsertLink(text)
                    else
                        ShowUIPanel(ItemRefTooltip)
                        if (not ItemRefTooltip:IsShown()) then
                            ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
                        end
                        ItemRefTooltip:SetHyperlink(link)
                    end
                end
            end)
            local t = msgframe:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            t:SetPoint("BOTTOM", msgframe, "TOP", 0, 2)
            t:SetTextColor(1, .82, 0)
            t:SetText(L["聊天记录"])
            local bt = CreateFrame("Button", nil, msgframe)
            bt:SetSize(18, 18)
            bt:SetNormalAtlas("AzeriteReady")
            bt:SetHighlightAtlas("AzeriteReady")
            bt:SetPoint("BOTTOMRIGHT", msgframe, "TOPRIGHT", -0, -0)
            bt:RegisterForClicks("AnyUp")
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                BG.CreateExportFrame(L["导出聊天记录"], msgchild:GetText():gsub("|T.-|t", ""):gsub("|A.-|a", ""))
            end)
            bt:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["导出聊天记录"], 1, 1, 1, true)
                GameTooltip:Show()
            end)
            bt:SetScript("OnLeave", GameTooltip_Hide)

            function msgframe:UpdateInfo(info)
                msgchild:SetText("")
                if info and info.msg then
                    for i, v in ipairs(info.msg) do
                        local msg, channel, color
                        local time = date("%H:%M", v.time)
                        if v.event == "CHAT_MSG_INSTANCE_CHAT_LEADER" then
                            channel = INSTANCE
                            color = "FF4500"
                            msg = format(L["|cff808080%s|r |cff%s[%s]%s：%s|r"], time, color, channel, v.nameLink, v.text)
                        elseif v.event == "CHAT_MSG_INSTANCE_CHAT" then
                            channel = INSTANCE
                            color = "FF7F50"
                            msg = format(L["|cff808080%s|r |cff%s[%s]%s：%s|r"], time, color, channel, v.nameLink, v.text)
                        elseif v.event == "CHAT_MSG_SAY" then
                            channel = SAY
                            color = "FFFFFF"
                            msg = format(L["|cff808080%s|r |cff%s%s%s：%s|r"], time, color, v.nameLink, channel, v.text)
                        elseif v.event == "CHAT_MSG_WHISPER" then
                            channel = L["来自"]
                            color = "FF66FF"
                            msg = format(L["|cff808080%s|r |cff%s%s%s：%s|r"], time, color, channel, v.nameLink, v.text)
                        elseif v.event == "CHAT_MSG_WHISPER_INFORM" then
                            channel = L["告诉"]
                            color = "FF99CC"
                            msg = format(L["|cff808080%s|r |cff%s%s%s：%s|r"], time, color, channel, v.nameLink, v.text)
                        elseif v.event == "CHAT_MSG_SYSTEM" then
                            channel = UNKNOWN
                            color = "FFFF00"
                            msg = format(L["|cff808080%s|r |cff%s%s|r"], time, color, v.text)
                        else
                            channel = UNKNOWN
                            color = "FFFFFF"
                            msg = format(L["|cff808080%s|r |cff%s[%s]%s：%s|r"], time, color, channel, v.nameLink, v.text)
                        end
                        msg = BG.GsubRaidTargetingIcons(msg)
                        if i ~= #info.msg then
                            msg = msg .. "\n"
                        end
                        msgchild:Insert(msg)
                    end
                end
            end
        end

        -- 选择角色
        do
            local text = mainFrame:CreateFontString()
            text:SetPoint("BOTTOMLEFT", dungeonframe, "TOPLEFT", 0, 10)
            text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            text:SetTextColor(RGB(BG.y2))
            text:SetText(L["角色："])
            dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
            dropDown:SetPoint("LEFT", text, "RIGHT", -15, -3)
            LibBG:UIDropDownMenu_SetWidth(dropDown, 180)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
            BG.dropDownToggle(dropDown)
            mainFrame.dropDown = dropDown
            if BiaoGe.dungeon.isChooseRealm == 1 then
                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[realmID] or realmID) .. " - " .. L["全部角色"]))
            else
                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[realmID] or realmID) .. " - ") .. SetClassCFF(player, "player"))
            end

            LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
                for _realmID, v in pairs(BiaoGe.dungeon) do
                    if type(v) == "table" then
                        if next(BiaoGe.dungeon[_realmID]) then
                            local info = LibBG:UIDropDownMenu_CreateInfo()
                            info.text = BG.STC_y2(BiaoGe.realmName[_realmID] or _realmID)
                            if not choose.player and _realmID == choose.realmID then
                                info.checked = true
                            end
                            info.func = function()
                                choose = {
                                    realmID = _realmID,
                                    player = nil,
                                }
                                BiaoGe.dungeon.isChooseRealm = 1
                                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[_realmID] or _realmID) .. " - " .. L["全部角色"]))
                                lastChoose = nil
                                mainFrame:UpdateFrame()
                            end
                            LibBG:UIDropDownMenu_AddButton(info)
                        end

                        for _, v in pairs(BiaoGe.dungeon[_realmID]) do
                            local info = LibBG:UIDropDownMenu_CreateInfo()
                            local playerName = "|c" .. select(4, GetClassColor(v.class)) .. v.name
                            info.text = "  " .. playerName .. (v.level and " (" .. v.level .. ")" or "")
                            info.arg1 = v.realmID .. "-" .. v.name
                            info.arg2 = "|cffFFD100" .. (BiaoGe.realmName[_realmID] or _realmID)
                                .. "-|r|c" .. select(4, GetClassColor(v.class)) .. v.name .. "|r"
                            if v.name == choose.player and v.realmID == choose.realmID then
                                info.checked = true
                            end
                            info.func = function()
                                choose = {
                                    realmID = v.realmID,
                                    player = v.name,
                                }
                                BiaoGe.dungeon.isChooseRealm = 0
                                LibBG:UIDropDownMenu_SetText(dropDown, BG.STC_y2((BiaoGe.realmName[v.realmID] or v.realmID) .. " - ") .. playerName)
                                lastChoose = nil
                                mainFrame:UpdateFrame()
                            end
                            LibBG:UIDropDownMenu_AddButton(info)
                        end
                    end
                end
            end)

            -- 删除角色
            local buttonName = "deleteDungenoPlayer"
            for i = 1, L_UIDROPDOWNMENU_MAXBUTTONS do
                local button = _G["L_DropDownList1Button" .. i]
                button:HookScript("OnEnter", function()
                    if L_DropDownList1.dropdown ~= mainFrame.dropDown then return end
                    if not button[buttonName] then
                        local bt = CreateFrame("Button", nil, button)
                        bt:SetSize(15, 15)
                        bt:SetPoint("RIGHT", -2, 0)
                        bt:SetNormalTexture("interface/raidframe/readycheck-notready")
                        bt:SetHighlightTexture("interface/raidframe/readycheck-notready")
                        bt:RegisterForClicks("AnyUp")
                        bt.num = i
                        bt:Hide()
                        button[buttonName] = bt
                        bt:SetScript("OnClick", function(self)
                            dropDown.realmID, dropDown.player = strsplit("-", button.arg1)
                            dropDown.realmID = tonumber(dropDown.realmID)
                            dropDown.colorPlayer = button.arg2
                            LibBG:CloseDropDownMenus()
                            StaticPopup_Show("BiaoGe_" .. buttonName, dropDown.colorPlayer)
                        end)
                        bt:SetScript("OnEnter", function(self)
                            button.isOnEnter = true
                            LibBG:UIDropDownMenu_StopCounting(self:GetParent():GetParent())
                            button.Highlight:Show()
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                            GameTooltip:ClearLines()
                            GameTooltip:AddLine(L["删除该角色"], 1, 1, 1, true)
                            GameTooltip:Show()
                        end)
                        bt:SetScript("OnLeave", function(self)
                            LibBG:UIDropDownMenu_StartCounting(self:GetParent():GetParent())
                            button.Highlight:Hide()
                            GameTooltip:Hide()
                        end)
                        bt:SetScript("OnHide", function(self)
                            self:Hide()
                        end)
                    end
                    button.isOnEnter = true
                    for ii = 1, _G['L_DropDownList1'].numButtons do
                        local bt = _G["L_DropDownList1Button" .. ii]
                        if bt[buttonName] then
                            bt[buttonName]:Hide()
                        end
                    end
                    if button.arg1 then
                        button[buttonName]:Show()
                    end
                end)
                button:HookScript("OnLeave", function()
                    if L_DropDownList1.dropdown ~= mainFrame.dropDown then return end
                    button.isOnEnter = false
                    After(0, function()
                        if not button.isOnEnter then
                            button[buttonName]:Hide()
                        end
                    end)
                end)
            end
            StaticPopupDialogs["BiaoGe_" .. buttonName] = {
                text = L["确认删除%s的随机本记录？"],
                button1 = L["是"],
                button2 = L["否"],
                OnAccept = function()
                    LibBG:ToggleDropDownMenu(nil, nil, mainFrame.dropDown)
                    for i = 1, _G['L_DropDownList1'].numButtons do
                        local button = _G["L_DropDownList1Button" .. i]
                        if button.arg1 then
                            local _realmID, _player = strsplit("-", button.arg1)
                            _realmID = tonumber(_realmID)
                            if _realmID == realmID and _player == player then
                                button:Click()
                                break
                            end
                        end
                    end
                    local _realmID, _player = dropDown.realmID, dropDown.player
                    BiaoGe.dungeon[_realmID][_player] = nil
                    SendSystemMessage(format(L["已删除%s的随机本记录。"], dropDown.colorPlayer))
                end,
                OnCancel = function()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
        end

        -- 保存时长
        do
            local function DeleteTradeData()
                local time = GetServerTime()
                for realmID in pairs(BiaoGe.dungeon) do
                    if type(BiaoGe.dungeon[realmID]) == "table" then
                        for player in pairs(BiaoGe.dungeon[realmID]) do
                            for i = #BiaoGe.dungeon[realmID][player].info, 1, -1 do
                                local v = BiaoGe.dungeon[realmID][player].info[i]
                                if BiaoGe.dungeon.saveDuration > 0 and time - (v.time or 0) > 86400 * BiaoGe.dungeon.saveDuration then
                                    tremove(BiaoGe.dungeon[realmID][player].info, i)
                                end
                            end
                        end
                    end
                end
            end
            DeleteTradeData()

            local text = mainFrame:CreateFontString()
            text:SetPoint("BOTTOMLEFT", dungeonframe, "TOPLEFT", 260, 10)
            text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            text:SetTextColor(RGB(BG.y2))
            text:SetText(L["保存时长："])
            local dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
            dropDown:SetPoint("LEFT", text, "RIGHT", -15, -3)
            LibBG:UIDropDownMenu_SetWidth(dropDown, 80)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
            for i, v in ipairs(BG.saveDays) do
                if v.day == BiaoGe.dungeon.saveDuration then
                    LibBG:UIDropDownMenu_SetText(dropDown, v.text)
                    break
                end
            end
            BG.dropDownToggle(dropDown)
            LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
                for i, v in ipairs(BG.saveDays) do
                    local info = LibBG:UIDropDownMenu_CreateInfo()
                    info.text = v.text
                    if v.day == BiaoGe.dungeon.saveDuration then
                        info.checked = true
                    end
                    info.func = function()
                        BiaoGe.dungeon.saveDuration = v.day
                        DeleteTradeData()
                        LibBG:UIDropDownMenu_SetText(dropDown, v.text)
                        UpdateScrollFrame()
                        UpdateButtons()
                    end
                    LibBG:UIDropDownMenu_AddButton(info)
                end
            end)
        end

        function mainFrame:UpdateFrame()
            if not self:IsVisible() then return end
            UpdateScrollFrame()
            UpdateButtons()
            if next(db) then
                lootframe:Show()
                lootframe:UpdateInfo()
                dungeonframe:UpdateChooseTex()
            else
                lootframe:Hide()
            end
        end

        function mainFrame:UpdateFrameDelay()
            if not self:IsVisible() then return end
            self.t = 0
            self:SetScript("OnUpdate", function(self, t)
                self.t = self.t + t
                if self.t >= .5 then
                    self:UpdateFrame()
                    self:SetScript("OnUpdate", nil)
                    return
                end
            end)
        end

        function GetLastChoose()
            if not lastChoose then
                lastChoose = 1
            end
            if next(db) and not db[lastChoose] then
                lastChoose = 1
            end
            return lastChoose
        end

        function GetChooseInfo()
            return db[GetLastChoose()]
        end

        function GetDB()
            local realmID = choose.realmID
            local playerTbl = {}
            wipe(db)
            if choose.player then
                playerTbl = { choose.player }
            else
                for player, v in pairs(BiaoGe.dungeon[realmID]) do
                    tinsert(playerTbl, player)
                end
            end

            for _, player in pairs(playerTbl) do
                if BiaoGe.dungeon[realmID][player] then
                    local class = BiaoGe.dungeon[realmID][player].class
                    local colorPlayer = "|c" .. select(4, GetClassColor(class)) .. player .. "|r"
                    for i, v in ipairs(BiaoGe.dungeon[realmID][player].info) do
                        tinsert(db, BG.Copy(v))
                        db[#db].i = i
                        db[#db].player = player
                        db[#db].colorPlayer = colorPlayer
                    end
                end
            end

            sort(db, function(a, b)
                local key = "time"
                if a[key] and b[key] then
                    if a[key] ~= b[key] then
                        return a[key] > b[key]
                    end
                end
                return false
            end)
        end

        function UpdateScrollFrame()
            GetDB()
            local m = #db - MAXBUTTONS
            dungeonbar:SetMinMaxValues(0, max(0, m))
            if dungeonscroll.SetScrollExtent then
                dungeonscroll:SetScrollExtent(MAXBUTTONS, #db)
            end
            UpdateScrollButtonState(dungeonbar)
            dungeonframe.notText:SetShown(not next(db))
        end

        function UpdateButtons()
            local value = floor(dungeonbar:GetValue()) or 0
            for ii = 1, MAXBUTTONS do
                local index = value + ii
                local v = db[index]
                local bt = dungeonframe.buttons[ii]
                if v then
                    bt:Show()
                    local diffName = GetDifficultyInfo(v.dungeon.diffID)
                    local name, typeID, subtypeID, minLevel, maxLevel,
                    recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID,
                    textureFilename, difficulty, maxPlayers, description, isHoliday,
                    bonusRepAmount, minPlayers, isTimeWalker, name2, minGearLevel,
                    isScalingDungeon, lfgMapID = GetLFGDungeonInfo(v.dungeon.dungeonID)
                    bt.Text1:SetText(format(L["%s：%s-%s（%s）"], index, v.dungeon.name, diffName, v.colorPlayer))
                    local durTime = ""
                    if v.endTime then
                        durTime = format(L["（用时%s）"], SecondsToTime(v.endTime - v.time))
                    end
                    local xpText = ""
                    if v.xp and v.xp ~= 0 then
                        xpText = format(L["（经验%s）"], BG.FormatNumber(v.xp))
                    end
                    bt.Text2:SetText(format("%s%s%s", date("%m-%d %H:%M", v.time), durTime, xpText))
                    bt.info = v
                    bt.index = index
                else
                    bt:Hide()
                end
            end
            dungeonframe:UpdateChooseTex()
            GameTooltip:Hide()
        end
    end

    -- 选项
    do
        -- 投票踢人确认框的玩家上色
        local last
        do
            local name = "voteColor"
            BG.options[name .. "reset"] = 1
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["投票确认框玩家上色"]
            local ontext = {
                text,
                L["对投票确认框的玩家名字增加职业颜色，方便辨认。"],
            }
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint("TOPLEFT", mainFrame.dungeonframe, "BOTTOMLEFT", 0, -10)
            last = bt
        end
        -- 一键填写踢人理由
        do
            local name = "voteFastEdit"
            BG.options[name .. "reset"] = 1
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["一键填写踢人理由"]
            local ontext = {
                text,
                L["在你发起投票踢人时，一键填写踢人理由。"],
            }
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -0)
            last = bt
        end
        -- 显示所有职责的平均排队时长
        do
            local name = "LFDwait"
            BG.options[name .. "reset"] = 1
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["显示全职责的平均排队时长"]
            local ontext = {
                text,
                L["排本时，小地图的眼睛图标会显示所有职责的平均排队时长，了解什么职责最紧缺。"],
            }
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -0)
            last = bt
        end
        -- -- 在自己头像的菜单里增加退出副本按钮
        -- do
        --     local name = "LFDleave"
        --     BG.options[name .. "reset"] = 1
        --     BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
        --     local text = L["在自己头像的菜单里增加离开副本按钮"]
        --     local ontext = {
        --     }
        --     local bt = CreateCheckButton(name, text, mainFrame, ontext)
        --     bt:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -0)
        --     last = bt
        -- end
        -- 排本职责确认框自动确认
        do
            local name = "LFDRoleCheckPopup"
            BG.options[name .. "reset"] = 0
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["组队排本的职责确认框自动确认"]
            local ontext = {
                text,
                L["队长发起排本时，会弹窗让你选择职责，勾选后不再弹窗并自动确认。"],
            }
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -0)
            last = bt
        end
        -- 在5人本自动把坦克标记为
        do
            local name = "LFDtankTarget"
            BG.options[name .. "reset"] = 0
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["在5人本自动把坦克标记为"] .. BG.SetRaidTargetingIcons(nil, "dabing")
            local ontext = {
            }
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint("TOPLEFT", mainFrame.lootframe, "BOTTOMLEFT", 0, -10)
            last = bt
        end
        -- 在5人本自动把治疗标记为
        do
            local name = "LFDhealerTarget"
            BG.options[name .. "reset"] = 0
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["在5人本自动把治疗标记为"] .. BG.SetRaidTargetingIcons(nil, "xingxing")
            local ontext = {
            }
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -0)
            last = bt
        end
        -- 在5人本自动贪婪蓝色宝珠
        if BG.IsWLK or BG.IsCTM then
            local link
            if BG.IsWLK then
                autoRollItemID = 43102
                link = "|c" .. select(4, GetItemQualityColor(3)) .. L["冰冻宝珠"] .. "|r"
            elseif BG.IsCTM then
                autoRollItemID = 52078
                link = "|c" .. select(4, GetItemQualityColor(3)) .. L["混乱宝珠"] .. "|r"
            end

            local name = "autoRollBlueGem"
            BG.options[name .. "reset"] = 0
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["在5人本自动需求"] .. link
            local ontext = {
            }
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -0)
            last = bt
        end
        -- 在5人本自动贪婪绿装
        do
            local name = "autoRollGreen" .. realmIDandPlayer
            BG.options[name .. "reset"] = 0
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["在5人本自动贪婪绿装"]
            local ontext = {
            }
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -0)
            last = bt
        end
        -- 在5人本自动贪婪蓝装
        do
            local name = "autoRollBlue" .. realmIDandPlayer
            BG.options[name .. "reset"] = 0
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["在5人本自动贪婪蓝装"]
            local ontext = {
            }
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -0)
            last = bt
        end
        -- 在5人本自动贪婪无用装备
        if BG.IsMOP then
            local name = "autoRollNotCanUse" .. realmIDandPlayer
            BG.options[name .. "reset"] = 0
            BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
            local text = L["在5人本自动贪婪不可用的护甲装备"]
            local ontext = {
                L["在5人本自动贪婪不可用的护甲装备"],
                L["比如我是板甲职业，会自动贪婪锁甲、皮甲、布甲装备。"],
                L["该功能仅对护甲装备有效，武器是无效的。"],
                " ",
                L["另外也会贪婪有职业限制但你不能用的装备，比如你不能用的套装兑换物。"],
            }
            local bt = CreateCheckButton(name, text, mainFrame, ontext)
            bt:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -0)
            last = bt
        end
    end

    -- 踢人增强
    do
        local fastEdit = CreateFrame("Frame", nil, UIParent)
        fastEdit:SetSize(100, 100)
        fastEdit:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        fastEdit:Hide()
        fastEdit.buttons = {}

        local function CreateButton(text)
            local bt = CreateFrame("Button", nil, fastEdit)
            if next(fastEdit.buttons) then
                bt:SetPoint("TOPLEFT", fastEdit.buttons[#fastEdit.buttons], "BOTTOMLEFT", 0, 0)
            else
                bt:SetPoint("TOPLEFT", fastEdit, "TOPLEFT", 0, 0)
            end
            bt:SetNormalFontObject(BG.FontGreen15)
            bt:SetDisabledFontObject(BG.FontDis15)
            bt:SetHighlightFontObject(BG.FontWhite15)
            bt:SetText(text)
            local string = bt:GetFontString()
            string:SetPoint("LEFT")
            bt:SetSize(string:GetWidth(), 20)
            tinsert(fastEdit.buttons, bt)
            bt:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                fastEdit.edit:SetText(text)
            end)
        end

        local tbl = {
            L["全需狗"],
            L["划水/挂机"],
            L["DPS太低"],
            L["太脆抗不住"],
            L["奶不住"],
        }
        for i, text in ipairs(tbl) do
            CreateButton(text)
        end

        local function GetCombatRole(name)
            if info and info.players and info.players[name] and info.players[name].combatRole then
                return AddTexture(info.players[name].combatRole) or ""
            end
            return ""
        end

        local wh = "VOTE_BOOT_REASON_REQUIRED"
        -- local wh = "DELETE_ITEM"
        local text1 = VOTE_BOOT_PLAYER:gsub("%%1%$s", "(.+)"):gsub("%%2%$s", "(.+)")
        local text2 = VOTE_BOOT_PLAYER_NO_REASON:gsub("%%1%$s", "(.+)")
        local text3 = VOTE_BOOT_REASON_REQUIRED:gsub("%%s", "(.+)")
        hooksecurefunc("StaticPopup_Show", function(whick)
            if whick == "VOTE_BOOT_PLAYER" then
                local _, dialog = StaticPopup_Visible("VOTE_BOOT_PLAYER")
                if dialog and dialog.Text then
                    local name, reason = dialog.Text:GetText():match(text1)
                    if name and reason then
                        local colorName = GetCombatRole(name) .. SetClassCFF(name)
                        if BiaoGe.options["voteColor"] == 1 then
                            dialog.Text:SetText(VOTE_BOOT_PLAYER:format(colorName, reason))
                        end
                        SaveSystemMsg(info, L["有人发起了一个将%s从队伍中移出的投票。理由为：%s"]:format(colorName, reason))
                    else
                        local name = dialog.Text:GetText():match(text2)
                        if name then
                            local colorName = GetCombatRole(name) .. SetClassCFF(name)
                            if BiaoGe.options["voteColor"] == 1 then
                                dialog.Text:SetText(VOTE_BOOT_PLAYER_NO_REASON:format(colorName))
                            end
                            SaveSystemMsg(info, L["有人发起了一个将%s从队伍中移出的投票。"]:format(colorName))
                        end
                    end
                end
            elseif whick == wh then
                local _, dialog = StaticPopup_Visible(wh)
                if dialog then
                    local name = dialog.Text:GetText():match(text3)
                    if name then
                        if BiaoGe.options["voteColor"] == 1 then
                            local colorName = GetCombatRole(name) .. SetClassCFF(name)
                            dialog.Text:SetText(VOTE_BOOT_REASON_REQUIRED:format(colorName))
                        end
                    end
                    if BiaoGe.options["voteFastEdit"] == 1 then
                        fastEdit:ClearAllPoints()
                        fastEdit:SetPoint("TOPLEFT", dialog, "TOPRIGHT", 2, -2)
                        fastEdit:SetParent(dialog)
                        fastEdit:Show()
                        fastEdit.edit = dialog.EditBox or dialog.editBox
                        if not dialog.hookHide then
                            dialog.hookHide = true
                            dialog:HookScript("OnHide", function()
                                if fastEdit:GetParent() == dialog then
                                    fastEdit:Hide()
                                end
                            end)
                        end
                    end
                end
            end
        end)
    end

    -- 各职责的排队时长
    if QueueStatusFrame then
        local function D(timeString)
            if timeString == "" then
                return UNKNOWN
            else
                return timeString
            end
        end
        QueueStatusFrame:HookScript("OnShow", function()
            if BiaoGe.options["LFDwait"] ~= 1 then return end
            local hasData, leaderNeeds, tankNeeds, healerNeeds, dpsNeeds,
            totalTanks, totalHealers, totalDPS, instanceType, instanceSubType,
            instanceName, averageWait, tankWait, healerWait, damageWait,
            myWait, queuedTime, activeID = GetLFGQueueStats(1)
            if activeID then
                GameTooltip:SetOwner(QueueStatusFrame, "ANCHOR_NONE", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:SetPoint("TOPLEFT", QueueStatusFrame, "BOTTOMLEFT", 0, 0)
                GameTooltip:AddLine(AddTexture('logo')..L["平均等待时长"], 1, 1, 1)
                local tankTime = 1
                GameTooltip:AddLine(L["坦克："] .. D(SecondsToTime(tankWait)))
                GameTooltip:AddLine(L["治疗："] .. D(SecondsToTime(healerWait)))
                GameTooltip:AddLine(L["输出："] .. D(SecondsToTime(damageWait)))
                GameTooltip:Show()
            end
        end)
        QueueStatusFrame:HookScript("OnHide", function()
            GameTooltip_Hide()
        end)
    end

    -- 确认职位的时候自动点确定
    if LFDRoleCheckPopup then
        LFDRoleCheckPopup:HookScript("OnShow", function(self)
            if BiaoGe.options["LFDRoleCheckPopup"] ~= 1 then return end
            LFDRoleCheckPopupAcceptButton:Click()
        end)
    end

    -- -- 离开副本
    -- Menu.ModifyMenu("MENU_UNIT_SELF", function(owner, description, contextData)
    --     if BiaoGe.options["LFDleave"] == 1 and IsPartyLFG() then
    --         description:CreateDivider()
    --         if (IsAllowedToUserTeleport()) then
    --             if (IsInLFGDungeon()) then
    --                 description:CreateButton(TELEPORT_OUT_OF_DUNGEON, function()
    --                     LFGTeleport(true);
    --                 end);
    --             else
    --                 description:CreateButton(TELEPORT_TO_DUNGEON, function()
    --                     LFGTeleport(false);
    --                 end)
    --             end
    --         end
    --         description:CreateButton(INSTANCE_PARTY_LEAVE, function()
    --             LeaveInstanceParty()
    --         end)
    --     end
    -- end)

    -- 标记TN
    do
        SetTargetFrame = CreateFrame("Frame")

        function SetTargetFrame:Start()
            self.t = 0
            self:SetScript("OnUpdate", function(self, t)
                self.t = self.t + t
                if self.t >= 1 then
                    self.t = 0
                    if IsInGroup(2) then
                        for i = 1, GetNumGroupMembers(2) do
                            local name, rank, subgroup, level, class,
                            fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i)
                            if name then
                                if combatRole == "TANK" and BiaoGe.options["LFDtankTarget"] == 1 then
                                    local iconIndex = GetRaidTargetIndex(name)
                                    if iconIndex ~= 2 then
                                        SetRaidTarget(name, 2)
                                    end
                                elseif combatRole == "HEALER" and BiaoGe.options["LFDhealerTarget"] == 1 then
                                    local iconIndex = GetRaidTargetIndex(name)
                                    if iconIndex ~= 1 then
                                        SetRaidTarget(name, 1)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

        function SetTargetFrame:Stop()
            self:SetScript("OnUpdate", nil)
        end
    end
end)
