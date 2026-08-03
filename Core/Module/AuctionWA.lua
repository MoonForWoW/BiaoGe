if BG.IsBlackListPlayer then return end
local AddonName, ns = ...
local LibBG = ns.LibBG
local L = ns.L
local GetClassColor = ns.GetClassColor

local pt = print
local After = C_Timer.After
local _auctionID_ = "auctionID"

local aura = {}
aura.ver = "v4.0"

function aura.GetVerNum(str)
    return tonumber(string.match(str, "v(%d+%.%d+)")) or 0
end

BGA = BGA or {}
BGA.Frames = {}
BGA.ver = aura.ver
BGA.aura_env = aura

aura.AddonChannel = "BiaoGeAuction"
aura.AddonChannel2 = "BiaoGeAuction(%d+)"
C_ChatInfo.RegisterAddonMessagePrefix(aura.AddonChannel)
aura.addonChannelCount = 10
for i = 1, aura.addonChannelCount do
    local channelName = aura.AddonChannel .. i
    C_ChatInfo.RegisterAddonMessagePrefix(channelName)
end

aura.currentChannelIndex = 0
function aura.GetAddonChannelName()
    aura.currentChannelIndex = aura.currentChannelIndex % aura.addonChannelCount + 1
    return aura.AddonChannel .. aura.currentChannelIndex
end

--[[
1万-3万，每手加价1000
3万-10万，每手加价2000
10万-30万，每手加价5000
30万-100万，每手加价1万
100万以上，每手加价5万

1万-2万，每手加价1000
2万-5万，每手加价2000
5万-10万，每手加价5000
10万-20万，每手加价1万
20万-50万，每手加价2万
50万-100万，每手加价5万
100万以上，每手加价10万
 ]]

BG.Init(function()
    local FONT = BIAOGE_TEXT_FONT or STANDARD_TEXT_FONT

    -- 获取名字函数
    local realmName = GetRealmName():gsub(" ", ""):gsub("%-", "")
    do
        function aura.GN(unit)
            unit = unit or "player"
            if unit == "t" then
                unit = "target"
            end
            return GetUnitName(unit, true)
        end

        function aura.IsMe(f)
            return f.player and (f.player == aura.GN() or f.player == f.playerID) or false
        end

        function aura.GFN(name)
            if not name then return end
            local name, realm = strsplit("-", name)
            realm = realm or realmName
            return name .. "-" .. realm
        end

        function aura.GSN(name)
            if not name then return end
            local name, realm = strsplit("-", name)
            if not realm or realm == "" or realm == realmName then
                return name
            else
                return name .. "-" .. realm
            end
        end

        function aura.SPN(name)
            if not name then return end
            return strsplit("-", name)
        end

        function aura.RGB(hex, Alpha)
            local red = string.sub(hex, 1, 2)
            local green = string.sub(hex, 3, 4)
            local blue = string.sub(hex, 5, 6)

            red = tonumber(red, 16) / 255
            green = tonumber(green, 16) / 255
            blue = tonumber(blue, 16) / 255

            if Alpha then
                return red, green, blue, Alpha
            else
                return red, green, blue
            end
        end
    end

    -- 常量
    do
        aura.sound1 = SOUNDKIT.GS_TITLE_OPTION_OK
        aura.sound2 = 569593
        aura.GREEN1 = "00FF00"
        aura.RED1 = "FF0000"

        aura.maxNumFrame = 20
        aura.WIDTH = 310
        aura.HEIGHT = 105
        aura.SMALL_HEIGHT = 23
        aura.REPEAT_TIME = 20
        aura.HIDEFRAME_TIME = 1
        aura.edgeSize = 2.5
        aura.backdropColor = { 0, 0, 0, .6 }
        aura.backdropBorderColor = { 1, 1, 0, 1 }
        aura.backdropColor_filter = { .5, .5, .5, .5 }
        aura.backdropBorderColor_filter = { .5, .5, .5, 1 }
        aura.barColor_filter = { .5, .5, .5, .8 }
        aura.backdropColor_IsMe = { 0, .6, 0, .6 }
        aura.backdropBorderColor_IsMe = { 0, 1, 0, 1 }
        aura.raidRosterInfo = {}
        aura.endMsg = {}
        aura.tooLateTime = 3

        -- 加价幅度
        aura.MiniMoneyTbl = {
            -- 小于该价格时，每次加价幅度，最低加价幅度
            { 50, 1, 1 },
            { 100, 10, 1 },
            { 2000, 100, 100 },
            { 5000, 200, 100 },
            { 1 * 10000, 500, 100 },
            { 2 * 10000, 1000, 500 },
            { 5 * 10000, 2000, 500 },
            { 10 * 10000, 5000, 500 },
            { 20 * 10000, 10000, 1000 },
            { 50 * 10000, 20000, 1000 },
            { 100 * 10000, 50000, 1000 },
            { nil, 100000, 5000 },
        }
    end

    -- 字体
    do
        local color = "Gold18" -- BGA.FontGold18
        BGA.FontGold18 = CreateFont("BGA.Font" .. color)
        BGA.FontGold18:SetTextColor(1, 0.82, 0)
        BGA.FontGold18:SetFont(FONT, 18, "OUTLINE")

        local color = "Dis18" -- BGA.FontDis18
        BGA.FontDis18 = CreateFont("BGA.Font" .. color)
        BGA.FontDis18:SetTextColor(.5, .5, .5)
        BGA.FontDis18:SetFont(FONT, 18, "OUTLINE")
        local color = "Dis15" -- BGA.FontDis15
        BGA.FontDis15 = CreateFont("BGA.Font" .. color)
        BGA.FontDis15:SetTextColor(.5, .5, .5)
        BGA.FontDis15:SetFont(FONT, 15, "OUTLINE")

        local color = "Green15" -- BGA.FontGreen15
        BGA.FontGreen15 = CreateFont("BGA.Font" .. color)
        BGA.FontGreen15:SetTextColor(0, 1, 0)
        BGA.FontGreen15:SetFont(FONT, 15, "OUTLINE")

        local color = "white15" -- BGA.Fontwhite15
        BGA.FontWhite15 = CreateFont("BGA.Font" .. color)
        BGA.FontWhite15:SetTextColor(1, 1, 1)
        BGA.FontWhite15:SetFont(FONT, 15, "OUTLINE")
    end

    -- 基础函数
    do
        function aura.SetClassCFF(name, player, type)
            if type then return name end
            local _, class
            if player then
                _, class = UnitClass(player)
            else
                _, class = UnitClass(aura.GSN(name))
            end
            local colorname = ""
            if class then
                local color = select(4, GetClassColor(class))
                colorname = "|c" .. color .. name .. "|r"
                return colorname, color
            else
                return name, ""
            end
        end

        function aura.SetEditBg(edit)
            -- edit.Left = edit:CreateTexture()
            -- edit.Left:SetPoint("LEFT", -5, 0)
            -- edit.Left:SetSize(8, 20)
            -- edit.Left:SetTexture("interface/common/commonsearch")
            -- edit.Left:SetTexCoord(.88, .95, .01, .31)

            -- edit.Right = edit:CreateTexture()
            -- edit.Right:SetPoint("RIGHT", 0, 0)
            -- edit.Right:SetSize(8, 20)
            -- edit.Right:SetTexture("interface/common/commonsearch")
            -- edit.Right:SetTexCoord(0, .07, .338, .638)

            -- edit.Middle = edit:CreateTexture()
            -- edit.Middle:SetSize(10, 20)
            -- edit.Middle:SetPoint("LEFT", edit.Left, "RIGHT", 0, 0)
            -- edit.Middle:SetPoint("RIGHT", edit.Right, "LEFT", 0, 0)
            -- edit.Middle:SetTexture("interface/common/commonsearch")
            -- edit.Middle:SetTexCoord(0, .8, .01, .31)

            edit:SetFont(FONT, 14, "OUTLINE")
            -- edit:SetScript("OnTabPressed", EditBox_OnTabPressed)
            -- edit:SetScript("OnEscapePressed", EditBox_ClearFocus)
            -- edit:SetScript("OnEditFocusLost", EditBox_ClearHighlight)
            -- edit:SetScript("OnEditFocusGained", EditBox_HighlightText)
        end

        function aura.FormatNumber(num)
            if not tonumber(num) then return num end
            if Locale == "enUS" then
                local formatted = tostring(num)
                formatted = formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
                return formatted
            else
                num = tostring(num)
                local len = strlen(num)
                if len < 5 then return num end
                local k = num:sub(-4, -1)
                local w = num:sub(1, -5)
                if tonumber(k) == 0 then
                    return w .. L["万"]
                else
                    for i = 1, 4 do
                        local len = strlen(k)
                        local last = k:sub(len, len)
                        if last == "0" then
                            k = k:sub(1, len - 1)
                        else
                            break
                        end
                    end
                    return w .. "." .. k .. L["万"]
                end
            end
        end

        function aura.IsRight(self)
            if self.owner:GetCenter() > UIParent:GetCenter() then
                return true
            end
        end

        function aura.OnLeave(self)
            GameTooltip_Hide()
            self.isOnEnter = false
        end

        function aura.OnEditFocusGained(self)
            aura.lastFocus = self
            self:HighlightText()
        end

        function aura.IsRaidLeader()
            return IsInRaid(1) and UnitIsGroupLeader("player")
        end

        function aura.IsML(player)
            if not player then
                player = aura.GN()
            end
            if (player == aura.raidLeader) or (player == aura.masterLooter) then
                return true
            end
        end

        function aura.UpdateRaidRosterInfo(canSend)
            wipe(aura.raidRosterInfo)
            aura.raidLeader = nil
            aura.masterLooter = nil
            aura.onlineCount = 0
            if IsInRaid(1) then
                for i = 1, GetNumGroupMembers() do
                    local name, rank, subgroup, level, class2, class, zone, online,
                    isDead, role, isML, combatRole = GetRaidRosterInfo(i)
                    if name then
                        local a = {
                            name = name,
                            rank = rank,
                            subgroup = subgroup,
                            level = level,
                            class2 = class2,
                            class = class,
                            zone = zone,
                            online = online,
                            isDead = isDead,
                            role = role,
                            isML = isML,
                            combatRole = combatRole
                        }
                        tinsert(aura.raidRosterInfo, a)
                        if rank == 2 then
                            aura.raidLeader = name
                        end
                        if isML then
                            aura.masterLooter = name
                        end
                    end
                end
                if canSend then
                    C_ChatInfo.SendAddonMessage(aura.AddonChannel, "MyVer" .. "," .. aura.ver, "RAID")
                end
            end
            for _, f in pairs(BGA.Frames) do
                aura.UpdateButtonState(f)
            end
        end

        function aura.IsSecret(value)
            return issecretvalue and issecretvalue(value)
        end

        function aura.InBoss()
            return issecretvalue and C_InstanceEncounter.IsEncounterInProgress()
        end

        local lastNum = 0
        function aura.canSend()
            local n
            local canSend = true
            if IsInRaid(1) then
                n = GetNumGroupMembers(1)
                if lastNum >= n then
                    canSend = false
                end
            else
                canSend = false
                n = 0
            end
            lastNum = n
            return canSend
        end

        function aura.GetAuctioningFromRaid()
            if not IsInRaid(1) then return end
            aura.canGetAuctioning = true
            C_ChatInfo.SendAddonMessage(aura.AddonChannel, "GetAuctioning", "RAID")
            After(1, function()
                aura.canGetAuctioning = false
            end)
        end

        function aura.SetFrameColor(f, num)
            local c1, c2, font
            if num == 1 then
                c1 = aura.backdropColor_IsMe
                c2 = aura.backdropBorderColor_IsMe
                font = BGA.FontGreen15
            elseif num == 2 then
                c1 = aura.backdropColor_filter
                c2 = aura.backdropBorderColor_filter
                font = BGA.FontDis15
            else
                c1 = aura.backdropColor
                c2 = aura.backdropBorderColor
                font = BGA.FontGreen15
            end
            for _, frame in ipairs({ f, f.autoFrame }) do
                frame:SetBackdropColor(unpack(c1))
                frame:SetBackdropBorderColor(unpack(c2))
            end
            for _, name in ipairs({ 'hide', 'cancelButton', 'puaseButton', 'autoTextButton', 'logTextButton', }) do
                if f[name] then
                    f[name]:SetNormalFontObject(font)
                end
            end
        end
    end

    -- 折叠
    do
        local function SetBigWindos(f)
            if not f.hide:IsEnabled() then return end
            f.IsSmallWindow = false
            f.hide:SetText(L["折叠"])

            aura.UpdateButtonState(f)
            -- f.cancelButton:SetShown(aura.IsML())
            -- f.autoTextButton:Show()
            -- f.logTextButton:Show()
            f.topMoneyFrame:Show()
            if not f.IsEnd and not f.isPaused then
                f.myMoneyEdit:Show()
            end
            f.itemFrame2:Show()

            f:SetSize(aura.WIDTH, aura.HEIGHT)
            f.itemFrame:ClearAllPoints()
            f.itemFrame:SetPoint("TOPLEFT", f, "TOPLEFT", aura.edgeSize + 1, -f.hide:GetHeight() - 3)
            f.itemFrame:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -aura.edgeSize, -55)
            f.itemFrame.iconFrame:ClearAllPoints()
            f.itemFrame.iconFrame:SetPoint("TOPLEFT", f.itemFrame, "TOPLEFT", 0, 0)
            f.itemFrame.iconFrame:SetPoint("BOTTOMRIGHT", f.itemFrame, "TOPLEFT", f.itemFrame:GetHeight(), -f.itemFrame:GetHeight())
            f.itemFrame.iconFrame:SetBackdropBorderColor(unpack(f.itemFrame.iconFrame.color))
            f.itemFrame.itemNameText:ClearAllPoints()
            f.itemFrame.itemNameText:SetPoint("TOPLEFT", f.itemFrame.iconFrame, "TOPRIGHT", 2, -2)
            f.itemFrame.bg:ClearAllPoints()
            f.itemFrame.bg:SetAllPoints()
            f.bar:ClearAllPoints()
            f.bar:SetPoint("TOPLEFT", f.itemFrame.iconFrame, "TOPRIGHT", 0, 0)
            f.bar:SetPoint("BOTTOMRIGHT", f.itemFrame, "BOTTOMRIGHT", 0, 0)

            f.currentMoneyFrame:ClearAllPoints()
            f.currentMoneyFrame:SetPoint("TOPLEFT", f.itemFrame, "BOTTOMLEFT", 3, -3)
            if f.start then
                f.currentMoneyText:SetText(L["|cffFFD100起拍价：|r"] .. aura.FormatNumber(f.money))
            else
                f.currentMoneyText:SetText(L["|cffFFD100当前价格：|r"] .. aura.FormatNumber(f.money))
            end
            f.currentMoneyText:SetJustifyH("LEFT")
        end
        local function SetSmallWindos(f)
            if not f.hide:IsEnabled() then return end
            f.IsSmallWindow = true
            f.hide:SetText(L["展开"])

            aura.UpdateButtonState(f)
            f.autoFrame:Hide()
            -- f.cancelButton:Hide()
            -- f.autoTextButton:Hide()
            -- f.logTextButton:Hide()
            f.topMoneyFrame:Hide()
            f.myMoneyEdit:Hide()
            f.itemFrame2:Hide()

            f:SetSize(aura.WIDTH, aura.SMALL_HEIGHT)
            f.itemFrame:ClearAllPoints()
            f.itemFrame:SetAllPoints()
            f.itemFrame.iconFrame:ClearAllPoints()
            f.itemFrame.iconFrame:SetPoint("TOPLEFT", aura.edgeSize, -aura.edgeSize)
            f.itemFrame.iconFrame:SetPoint("BOTTOMRIGHT", f.itemFrame, "TOPLEFT", f.itemFrame:GetHeight() - aura.edgeSize, -f.itemFrame:GetHeight() + aura.edgeSize)
            f.itemFrame.iconFrame:SetBackdropBorderColor(1, 1, 1, 0)
            f.itemFrame.itemNameText:ClearAllPoints()
            f.itemFrame.itemNameText:SetPoint("LEFT", f.itemFrame.iconFrame, "RIGHT", 2, 0)
            f.itemFrame.bg:ClearAllPoints()
            f.itemFrame.bg:SetPoint("TOPLEFT", aura.edgeSize, -aura.edgeSize)
            f.itemFrame.bg:SetPoint("BOTTOMRIGHT", -aura.edgeSize, aura.edgeSize)
            f.bar:ClearAllPoints()
            f.bar:SetPoint("TOPLEFT", f.itemFrame.iconFrame, "TOPRIGHT", 0, 0)
            f.bar:SetPoint("BOTTOMRIGHT", f.itemFrame, "BOTTOMRIGHT", -aura.edgeSize, aura.edgeSize)

            f.currentMoneyFrame:ClearAllPoints()
            f.currentMoneyFrame:SetPoint("RIGHT", f.hide, "LEFT", -5, -0)
            if f.start then
                f.currentMoneyText:SetText("")
            else
                f.currentMoneyText:SetText(aura.FormatNumber(f.money))
            end
            f.currentMoneyText:SetJustifyH("RIGHT")
        end
        function aura.Hide_OnClick(self, button)
            local f = self.owner
            local func = f.IsSmallWindow and SetBigWindos or SetSmallWindos
            if (IsAltKeyDown() or button == "RightButton") and not f.notClick then
                for _, f in pairs(BGA.Frames) do
                    func(f)
                end
            else
                func(f)
            end
            if not f.notClick then
                aura.UpdateAllOnEnters()
                aura.UpdateAllFrames()
                PlaySound(aura.sound1)
            end
        end

        function aura.Hide_OnEnter(self)
            local f = self.owner
            if aura.IsRight(self) then
                GameTooltip:SetOwner(f, "ANCHOR_LEFT", 0, 0)
            else
                GameTooltip:SetOwner(f, "ANCHOR_RIGHT", 0, 0)
            end
            GameTooltip:ClearLines()
            if f.IsSmallWindow then
                GameTooltip:AddLine(L["展开"], 1, 1, 1, true)
                GameTooltip:AddLine(L["左键：单个展开"], 1, 0.82, 0, true)
                GameTooltip:AddLine(L["右键：全部展开"], 1, 0.82, 0, true)
            else
                GameTooltip:AddLine(L["折叠"], 1, 1, 1, true)
                GameTooltip:AddLine(L["左键：单个折叠"], 1, 0.82, 0, true)
                GameTooltip:AddLine(L["右键：全部折叠"], 1, 0.82, 0, true)
            end
            GameTooltip:Show()
            self.isOnEnter = true
        end
    end

    function aura.SendAddonMessage(f, ...)
        local s = f.isGen2 and "^" or ","
        local str = ''
        for i, v in ipairs({ ... }) do
            str = str .. (i == 1 and '' or s) .. v
        end
        C_ChatInfo.SendAddonMessage(f.isGen2 and aura.GetAddonChannelName() or aura.AddonChannel, str, "RAID")
    end

    aura.onlineCount = 0
    function aura.GetAnonymousMinMan()
        return aura.onlineCount >= 2 and 2 or 1
    end

    local function GetOtherMan()
        local myClass = select(2, UnitClass('player'))
        local otherClassPlayer = {}
        local allPlayer = {}
        aura.onlineCount = 0
        for i = 1, GetNumGroupMembers() do
            local name, rank, subgroup, level, class2, class, zone, online = GetRaidRosterInfo(i)
            if name and online and BG.raidBiaoGeNewVersion[name] then
                name = aura.GFN(name)
                if class ~= myClass then
                    tinsert(otherClassPlayer, name)
                end
                tinsert(allPlayer, name)
                aura.onlineCount = aura.onlineCount + 1
            end
        end
        local names = {}
        local tbl = #otherClassPlayer >= 2 and otherClassPlayer or allPlayer
        for i = 1, aura.GetAnonymousMinMan() do
            local result, index = pcall(random, #tbl)
            if not result then return end
            tinsert(names, tbl[index])
            tremove(tbl, index)
        end
        return names
    end

    local long = 20
    local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz123456789"
    local sum = #letters
    local function RandomLetter()
        local res = ""
        for _ = 1, long do
            local idx = math.random(1, sum)
            res = res .. letters:sub(idx, idx)
        end
        return res
    end

    function aura.SendAnonymousMessage(f, title, ...)
        local s = "^"
        local str = ''
        for i, v in ipairs({ title, ... }) do
            str = str .. (i == 1 and '' or s) .. v
        end
        if title == 'AnonymousWhisperMyMoney' then
            local names = GetOtherMan()
            if names then
                local playerID = RandomLetter()
                f.playerID = playerID
                f.playerStr[playerID] = aura.GN()
                str = str .. s .. playerID
                for i, name in ipairs(names) do
                    C_ChatInfo.SendAddonMessage(aura.GetAddonChannelName(), str, "WHISPER", name)
                end
            end
        else
            C_ChatInfo.SendAddonMessage(aura.GetAddonChannelName(), str, "RAID")
        end
    end

    -- 取消拍卖
    do
        function aura.Cancel_OnClick(self)
            local f = self.owner
            aura.SendAddonMessage(f, 'CancelAuction', f[_auctionID_])
            PlaySound(aura.sound1)
        end

        function aura.Cancel_OnEnter(self)
            local f = self.owner
            if aura.IsRight(self) then
                GameTooltip:SetOwner(f, "ANCHOR_LEFT", 0, 0)
            else
                GameTooltip:SetOwner(f, "ANCHOR_RIGHT", 0, 0)
            end
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
            GameTooltip:AddLine(L["Alt+点击才能生效"], 1, 0.82, 0, true)
            GameTooltip:AddLine(L["只有团长或物品分配者有权限取消拍卖"], 0.5, 0.5, 0.5, true)
            GameTooltip:Show()
        end
    end

    -- 暂停拍卖
    do
        function aura.Pause_OnClick(self)
            local f = self.owner
            aura.SendAddonMessage(f, f.isPaused and "ResumeAuction" or "PauseAuction", f.itemID)
            PlaySound(aura.sound1)
        end

        function aura.PauseAuction(f)
            if f.IsEnd or f.isPaused then return end
            f.isPaused = true
            f.pausedRemaining = f.endTime - GetTime()
            f.myMoneyEdit:Hide()
            f.ButtonJian:Hide()
            f.ButtonJia:Hide()
            f.ButtonSendMyMoney:Hide()
            f.remainingTime:SetText(L["已暂停"])
            f.remainingTime:SetTextColor(1, 1, 0)
            aura.UpdateButtonState(f)
        end

        function aura.ResumeAuction(f)
            if f.IsEnd or not f.isPaused then return end
            f.isPaused = false
            f.endTime = GetTime() + f.pausedRemaining
            f.pausedRemaining = nil
            f.myMoneyEdit:Show()
            f.ButtonJian:Show()
            f.ButtonJia:Show()
            f.ButtonSendMyMoney:Show()
            aura.RefreshTimer(f)
            aura.AutoSendMyMoney(f)
            aura.UpdateButtonState(f)
        end
    end

    -- 出价记录
    do
        local function AddLine(f, i)
            local t = f.logs[i].time and L['剩余%s秒时出价']:format(f.logs[i].time) or ''
            GameTooltip:AddLine(format(L['%s、%s（%s）|cffff0000%s'], i, f.logs[i].money, f.logs[i].player, t), 1, .82, 0, true)
        end
        function aura.LogTextButton_OnEnter(self)
            self.isOnEnter = true
            local f = self.owner
            if aura.IsRight(self) then
                GameTooltip:SetOwner(f, "ANCHOR_LEFT", 0, 0)
            else
                GameTooltip:SetOwner(f, "ANCHOR_RIGHT", 0, 0)
            end
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["出价记录"], 1, 1, 1, true)

            if #f.logs == 0 then
                GameTooltip:AddLine(L["没有人出价"], .5, .5, .5, true)
            elseif #f.logs > 15 then
                GameTooltip:AddLine("......", .5, .5, .5, true)
                for i = #f.logs - 14, #f.logs do
                    AddLine(f, i)
                end
            else
                for i = 1, #f.logs do
                    AddLine(f, i)
                end
            end
            GameTooltip:Show()
        end
    end

    -- 物品提示
    do
        function aura.itemOnEnter(self)
            local f = self.owner
            if f.IsSmallWindow then return end
            local point
            if aura.IsRight(self) then
                GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
                point = 'LEFT'
            else
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                point = 'RIGHT'
            end
            GameTooltip:ClearLines()
            GameTooltip:SetHyperlink(self.link)
            if BG and BG.SetZUGSetTooltip then
                BG.SetZUGSetTooltip(self.itemID, point)
            end
            if IsControlKeyDown() then
                SetCursor("Interface/Cursor/Inspect")
            end
            self.isOnEnter = true
            aura.itemIsOnEnter = true
            if BG then
                if BG.Show_AllHighlight then
                    BG.Show_AllHighlight(self.link)
                end
                if BG.SetHistoryMoney then
                    BG.SetHistoryMoney(self.itemID)
                end
            end
        end

        function aura.itemOnLeave(self)
            GameTooltip:Hide()
            self.isOnEnter = false
            aura.itemIsOnEnter = false
            SetCursor(nil)
            if BG then
                if BG.Hide_AllHighlight then
                    BG.Hide_AllHighlight()
                end
                if BG.HideHistoryMoney then
                    BG.HideHistoryMoney()
                end
            end
        end
    end

    -- 价格增减
    do
        function aura.JiaJian(money, fudu, _type)
            if _type == "+" then
                return money + fudu
            elseif _type == "-" then
                if money - fudu > 0 then
                    return money - fudu
                elseif (money == fudu) and money ~= 1 then
                    return money - 10
                else
                    return 0
                end
            end
        end

        function aura.Addmoney(money, _type)
            local money = tonumber(money) or 0
            local fudu
            for i, v in ipairs(aura.MiniMoneyTbl) do
                if not v[1] or money < v[1] then
                    fudu = v[2]
                    break
                end
            end
            return aura.JiaJian(money, fudu, _type), fudu
        end

        function aura.TooSmallMoney(myMoney, currentMoney)
            local money = myMoney - currentMoney
            for i, v in ipairs(aura.MiniMoneyTbl) do
                if not v[1] or currentMoney < v[1] then
                    if money < v[3] then
                        return v[3]
                    else
                        return false
                    end
                end
            end
        end

        function aura.TooSmall(self)
            local myMoney = tonumber(self:GetText()) or 0
            local currentMoney = self.owner.money
            return aura.TooSmallMoney(myMoney, currentMoney)
        end

        function aura.currentMoney_OnMouseDown(self)
            self.owner:GetScript("OnMouseDown")(BGA.AuctionMainFrame)
        end

        function aura.currentMoney_OnMouseUp(self)
            local f = self.owner
            f:GetScript("OnMouseUp")(BGA.AuctionMainFrame)
        end

        function aura.myMoney_OnTextChanged(self)
            local f = self.owner
            local money = tonumber(self:GetText()) or 0
            if f.start then
                if money < f.money then
                    self:SetTextColor(1, 0, 0)
                    f.ButtonSendMyMoney:Disable()
                    if not aura.IsMe(f) then
                        f.ButtonSendMyMoney.disf:Show()
                        f.ButtonSendMyMoney.disf.text = L["需高于或等于起拍价"]
                    end
                else
                    self:SetTextColor(1, 1, 1)
                    f.ButtonSendMyMoney:Enable()
                    f.ButtonSendMyMoney.disf:Hide()
                end
            elseif money <= f.money then
                f.ButtonSendMyMoney:Disable()
                if aura.IsMe(f) then
                    self:SetTextColor(1, 1, 1)
                else
                    self:SetTextColor(1, 0, 0)
                    f.ButtonSendMyMoney.disf:Show()
                    f.ButtonSendMyMoney.disf.text = L["需高于当前价格"]
                end
            elseif aura.TooSmall(self) then
                self:SetTextColor(1, 0, 0)
                f.ButtonSendMyMoney:Disable()
                f.ButtonSendMyMoney.disf:Show()
                f.ButtonSendMyMoney.disf.text = format(L["最小加价幅度为%s"], aura.TooSmall(self))
            else
                self:SetTextColor(1, 1, 1)
                f.ButtonSendMyMoney:Enable()
                f.ButtonSendMyMoney.disf:Hide()
            end
            if money <= f.money then
                f.ButtonJian:Disable()
            else
                f.ButtonJian:Enable()
            end
            aura.UpdateAllOnEnters()
        end

        function aura.myMoney_OnMouseWheel(self, delta)
            local _type = "-"
            if delta == 1 then
                _type = "+"
            end
            if _type == "-" then
                local f = self.owner
                local myMoney = tonumber(self:GetText())
                if myMoney and myMoney <= f.money then
                    return
                end
            end
            self:SetText(aura.Addmoney(self:GetText(), _type))
        end

        function aura.myMoney_OnEnter(self)
            GameTooltip:SetOwner(self.owner, "ANCHOR_BOTTOM", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(aura.FormatNumber(self:GetText()), 1, 1, 1)
            GameTooltip:AddLine(L["滚轮：快速调整价格"], 1, 0.82, 0, true)
            GameTooltip:Show()
            self.isOnEnter = true
        end

        function aura.JiaJian_OnEnter(self)
            local f = self.owner
            local myMoney = tonumber(self.edit:GetText()) or 0
            local _, fudu = aura.Addmoney(myMoney, self._type)
            GameTooltip:SetOwner(f, "ANCHOR_BOTTOM", 0, 0)
            GameTooltip:ClearLines()
            if not f.start and not f.IsEnd and not aura.IsMe(f) and self._type == "+" and myMoney <= f.money then
                GameTooltip:AddLine(L["出价设为："] .. "|cffffffff" .. aura.FormatNumber(aura.Addmoney(f.money, "+")), 1, 0.82, 0, true)
            else
                local r, g, b = 1, 0, 0
                if self._type == "+" then
                    r, g, b = 0, 1, 0
                end
                GameTooltip:AddLine(self._type .. " " .. aura.FormatNumber(fudu), r, g, b, true)
                GameTooltip:AddLine(L["根据你的出价动态改变增减幅度"], 1, 0.82, 0, true)
                GameTooltip:AddLine(L["长按：快速调整价格"], 1, 0.82, 0, true)
            end
            GameTooltip:Show()
            self.isOnEnter = true
        end

        function aura.JiaJian_OnClick(self)
            local f = self.owner
            local myMoney = tonumber(self.edit:GetText()) or 0
            if not f.start and not f.IsEnd and not aura.IsMe(f) and self._type == "+" and myMoney <= f.money then
                self.edit:SetText(aura.Addmoney(f.money, "+"))
            else
                self.edit:SetText(aura.Addmoney(myMoney, self._type))
            end
            aura.UpdateAllOnEnters()
            PlaySound(aura.sound1)
        end

        function aura.JiaJian_OnMouseDown(self)
            local t = 0
            local t_do = 0.5
            self:SetScript("OnUpdate", function(self, elapsed)
                t = t + elapsed
                if not self:IsEnabled() then
                    self:SetScript("OnUpdate", nil)
                    return
                end
                if t >= t_do then
                    t = t_do - 0.1
                    self.edit:SetText(aura.Addmoney(self.edit:GetText(), self._type))
                    aura.JiaJian_OnEnter(self)
                end
            end)
        end

        function aura.JiaJian_OnMouseUp(self)
            self:SetScript("OnUpdate", nil)
        end
    end

    -- 出价
    do
        local function SendMyMoney(f)
            if f.ButtonSendMyMoney:IsEnabled() then
                local money = tonumber(f.myMoneyEdit:GetText()) or 0
                if f.mod == 'anonymous' then
                    aura.SendAnonymousMessage(f, 'AnonymousWhisperMyMoney', f[_auctionID_], money)
                else
                    aura.SendAddonMessage(f, 'SendMyMoney', f[_auctionID_], money)
                end
                f.myMoneyEdit:ClearFocus()
                PlaySound(aura.sound1)
                -- if not f.start and BiaoGe and BiaoGe.options and BiaoGe.options.Sound then
                --     if random(10) <= 1 then
                --         BG.PlaySound("HusbandComeOn")
                --     end
                -- end
            end
        end
        function aura.SendMyMoney_OnClick(self)
            local f = self.owner
            if f.ButtonSendMyMoney:IsEnabled() then
                self.cd = self.cd or 0
                if GetTime() - self.cd < 1 then return end
                self.cd = GetTime()
                if aura.IsMe(f) then
                    if not StaticPopupDialogs["BiaoGeAuction_RepeatSend"] then
                        StaticPopupDialogs["BiaoGeAuction_RepeatSend"] = {
                            text = L["你已是%s的出价最高者，|cffff0000没必要自己顶自己|r。真的要继续出价到 %s ？"],
                            button1 = YES,
                            button2 = NO,
                            OnCancel = function()
                            end,
                            timeout = 0,
                            whileDead = true,
                            hideOnEscape = true,
                            showAlert = true,
                        }
                    end
                    StaticPopupDialogs["BiaoGeAuction_RepeatSend"].OnAccept = function()
                        SendMyMoney(f)
                    end
                    StaticPopup_Show("BiaoGeAuction_RepeatSend", f.link, tonumber(f.myMoneyEdit:GetText()) or 0)
                else
                    SendMyMoney(f)
                end
            end
        end

        function aura.SetMoney(f, money, player)
            if not f.IsSmallWindow then
                f.updateFrame:Show()
                f.autoFrame.updateFrame:Show()
            end
            if not f.isAuto and BG and BG.PlayTopPriceSound then
                BG.PlayTopPriceSound(f, player)
            end

            f.money = money
            if f.IsSmallWindow then
                f.currentMoneyText:SetText(aura.FormatNumber(money))
            else
                f.currentMoneyText:SetText(L["|cffFFD100当前价格：|r"] .. aura.FormatNumber(money))
                f.myMoneyEdit:Show()
            end
            f.player = player
            f.colorplayer = aura.SetClassCFF(player)
            f.start = false
            local rTime = ((f.remaining or 10) <= aura.tooLateTime) and format('%.1f', f.remaining) or nil
            if player == aura.GN() or player == f.playerID then
                f.topMoneyText:SetText(L["|cffFFD100出价最高者：|r"] .. "|cff" .. aura.GREEN1 .. L[">> 你 <<"])
                aura.SetFrameColor(f, 1)
                tinsert(f.logs, { money = money, player = "|cff" .. aura.GREEN1 .. L["你"] .. "|r", time = rTime })
                if rTime then
                    if f.mod ~= "anonymous" then
                        SendChatMessage(format(L["%s的剩余时间不到%s秒时我出价%s。卡秒出价可能导致拍卖出错！"], f.link, rTime, f.money), "RAID")
                    end
                    if BG and BG.PlaySound then
                        BG.PlaySound("tooLate")
                    end
                end
            else
                if f.mod == "anonymous" then
                    f.topMoneyText:SetText(L["|cffFFD100出价最高者：|r"] .. L["別人(匿名)"])
                    tinsert(f.logs, { money = money, player = L["匿名"], time = rTime })
                else
                    f.topMoneyText:SetText(L["|cffFFD100出价最高者：|r"] .. f.colorplayer)
                    tinsert(f.logs, { money = money, player = f.colorplayer, time = rTime })
                end
                if f.filter then
                    aura.SetFrameColor(f, 2)
                else
                    aura.SetFrameColor(f, 0)
                end
                if f.isAuto then
                    f.autoSendDelayFrame.t = 0
                    f.autoSendDelayFrame.delay = aura.AutoSendLate()
                    f.autoSendDelayFrame:SetScript('OnUpdate', function(self, t)
                        self.t = self.t + t
                        if self.t >= self.delay then
                            aura.AutoSendMyMoney(f)
                            self:SetScript('OnUpdate', nil)
                        end
                    end)
                end
            end
            aura.myMoney_OnTextChanged(f.myMoneyEdit)

            if f.isAuto and (f.money >= f.autoMoney or aura.TooSmallMoney(f.autoMoney, f.money)) then
                f.autoTitleText:SetText(L["设置心理价格"])
                f.autoTitleText:SetTextColor(1, .82, 0)
                f.isAutoTex:Hide()
                f.autoButton:SetText(L["开启自动出价"])
                f.autoButton:Enable()
                f.autoMoneyEdit.Left:SetAlpha(1)
                f.autoMoneyEdit.Right:SetAlpha(1)
                f.autoMoneyEdit.Middle:SetAlpha(1)
                f.isAuto = false
                f.autoSendDelayFrame:SetScript('OnUpdate', nil)
                f.autoTextButton:SetText(L["自动出价"])
                f.autoTextButton:SetWidth(f.autoTextButton:GetFontString():GetWidth())
                f.autoMoneyEdit:SetTextColor(1, 1, 1)
                f.autoMoneyEdit:SetEnabled(true)
                f.autoMoneyEdit.isLocked = false
                f.hide:Enable()
                aura.AutoSendEndPlaySound()
            end

            aura.Auto_OnTextChanged(f.autoMoneyEdit)
            aura.RefreshTimer(f)
            -- 相同物品ID联动刷新
            if f.isGen2 then
                for _, _f in pairs(BGA.Frames) do
                    if _f ~= f and _f.itemID == f.itemID then
                        aura.RefreshTimer(_f)
                    end
                end
            end
        end

        function aura.SendMyMoney_OnEnter(self)
            local f = self.owner
            GameTooltip:SetOwner(self.owner, "ANCHOR_BOTTOM", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self.text, 1, 0, 0, true)
            GameTooltip:Show()
        end
    end

    -- 更新界面
    do
        function aura.UpdateAllOnEnters()
            for _, f in pairs(BGA.Frames) do
                if f.myMoneyEdit.isOnEnter then
                    aura.myMoney_OnEnter(f.myMoneyEdit)
                end
                if f.ButtonJian.isOnEnter then
                    aura.JiaJian_OnEnter(f.ButtonJian)
                end
                if f.ButtonJia.isOnEnter then
                    aura.JiaJian_OnEnter(f.ButtonJia)
                end
                if f.logTextButton.isOnEnter then
                    f.logTextButton:GetScript("OnEnter")(f.logTextButton)
                end
                if f.autoMoneyEdit.isOnEnter then
                    aura.AutoEdit_OnEnter(f.autoMoneyEdit)
                end
                if f.hide.isOnEnter then
                    aura.Hide_OnEnter(f.hide)
                end
            end
        end

        function aura.GetFrameTotolHeight(num)
            local height = 0
            for i = 1, num - 1 do
                local f = BGA.Frames[i]
                if f then
                    if f.IsSmallWindow then
                        height = height + aura.SMALL_HEIGHT + 5
                    else
                        height = height + aura.HEIGHT + 5
                    end
                end
            end
            return height
        end

        local function UpdateAllFrameNum()
            local num = 0
            local tbl = {}
            for i = 1, aura.maxNumFrame do
                local f = BGA.Frames[i]
                if f then
                    num = num + 1
                    f.num = num
                    tbl[num] = f
                end
            end
            BGA.Frames = tbl
        end

        function aura.UpdateAllFrames()
            UpdateAllFrameNum()
            for _, f in pairs(BGA.Frames) do
                if f.showCantClickFrame and not f.IsSmallWindow then
                    f.cantClickFrame:Show()
                    f.cantClickFrame.t = 0
                    f.cantClickFrame:SetScript("OnUpdate", function(self, elapsed)
                        self.t = self.t + elapsed
                        if self.t >= .8 then
                            self:SetScript("OnUpdate", nil)
                            self:Hide()
                        end
                    end)
                end
                f:ClearAllPoints()
                f:SetPoint("TOP", 0, -aura.GetFrameTotolHeight(f.num))
            end
        end

        function aura.UpdateFrame(f)
            local t = 1
            f:SetScript("OnUpdate", function(self, elapsed)
                t = t - elapsed
                if t >= 0 then
                    f:SetAlpha(t)
                else
                    f:SetScript("OnUpdate", nil)
                    BGA.Frames[f.num] = nil
                    f:Hide()
                    BGA.AuctionMainFrame:StopMovingOrSizing()
                    if BG and BG.options and BiaoGe.options.autoAuctionUp == 1 then
                        for _, _f in pairs(BGA.Frames) do
                            if _f.num < f.num then
                                _f.showCantClickFrame = false
                            else
                                _f.showCantClickFrame = true
                            end
                        end
                        aura.UpdateAllFrames()
                    end
                end
            end)
        end

        function aura.UpdateButtonState(f)
            local bt = f.cancelButton
            bt:ClearAllPoints()
            if f.isGen2 then
                bt:SetText(CANCEL)
                -- bt:SetPoint("TOP", f, "TOPLEFT", aura.WIDTH / 10 * 2.8, -2)
                bt:SetPoint("TOP", f, "TOPLEFT", aura.WIDTH / 10 * 3, -2)
            else
                bt:SetText(L["取消拍卖"])
                bt:SetPoint("TOP", f, "TOPLEFT", aura.WIDTH / 10 * 3.3, -2)
            end
            bt:SetSize(bt:GetFontString():GetWidth() + 10, 18)
            bt:SetShown(aura.IsML() and not f.IsEnd and not f.IsSmallWindow)

            local bt = f.puaseButton
            if bt then
                bt:SetText(f.isPaused and L["恢复"] or L["暂停"])
                bt:SetSize(bt:GetFontString():GetWidth() + 10, 18)
                bt:SetShown(aura.IsML() and not f.IsEnd and not f.IsSmallWindow)
            end

            local bt = f.autoTextButton
            bt:ClearAllPoints()
            if aura.IsML() then
                if f.isGen2 then
                    -- bt:SetPoint("TOP", f, "TOPLEFT", aura.WIDTH / 10 * 7.2, -2)
                    bt:SetPoint("TOP", f, "TOPLEFT", aura.WIDTH / 10 * 7, -2)
                    bt:SetText(L["自动"])
                else
                    bt:SetPoint("TOP", f, "TOPLEFT", bt.offset, -2)
                    bt:SetText(L["自动出价"])
                end
            else
                bt:SetPoint("TOP", 0, -2)
                bt:SetText(L["自动出价"])
            end
            bt:SetSize(bt:GetFontString():GetWidth() + 10, 18)
            bt:SetShown(not f.IsSmallWindow)

            local bt = f.logTextButton
            bt:SetShown(not f.IsSmallWindow)
        end
    end

    -- 入场动画
    do
        local function CheckAllFrameOverlap()
            for j = 1, aura.maxNumFrame do
                local f = BGA.Frames[j]
                if f and not f.animing then
                    local top = f:GetTop()
                    local bottom = f:GetBottom()
                    for i = 1, aura.maxNumFrame do
                        local _f = BGA.Frames[i]
                        if _f and not _f.animing and f.num ~= _f.num then
                            local _top = _f:GetTop()
                            local _bottom = _f:GetBottom()
                            if (top <= _top and top >= _bottom) or (bottom <= _top and bottom >= _bottom) then
                                aura.UpdateAllFrames()
                                return
                            end
                        end
                    end
                end
            end
        end

        function aura.anim(parent)
            parent.alltime = 0.5
            parent.t = 0.5
            parent.animing = true
            parent:SetScript("OnUpdate", function(self, t)
                self.t = self.t - t
                if self.t <= 0 then self.t = 0 end
                self:SetAlpha(max(1 - self.t / self.alltime, 0.01))
                -- self:SetScale(max(1 - self.t / self.alltime, 0.01))
                self.myMoneyEdit:SetCursorPosition(0)
                if self.t <= 0 then
                    self.animing = nil
                    self:SetScript("OnUpdate", nil)
                    After(0, function()
                        CheckAllFrameOverlap()
                    end)
                end
            end)
        end
    end

    -- 自动出价函数
    do
        function aura.AutoText_OnClick(self)
            self.owner.autoFrame:SetShown(not self.owner.autoFrame:IsVisible())
            self.owner.autoFrame.isClicked = true
            PlaySound(aura.sound1)
        end

        function aura.Auto_OnTextChanged(self)
            local f = self.owner
            local money = tonumber(self:GetText()) or 0
            f.autoMoney = money

            f.autoButton:Enable()
            f.autoButton.disf:Hide()
            if not f.isAuto then
                local isMe = aura.IsMe(f)
                local isInvalid = money == 0
                local useErrorColor = isInvalid and (f.start or not isMe)
                local errorText
                if not isInvalid then
                    if f.start and money < f.money then
                        isInvalid = true
                        useErrorColor = true
                        if not isMe then
                            errorText = L["心理价格需高于或等于起拍价"]
                        end
                    elseif not f.start and money <= f.money then
                        isInvalid = true
                        useErrorColor = not isMe
                        if not isMe then
                            errorText = L["心理价格需高于当前价格"]
                        end
                    elseif not f.start then
                        local miniMoney = aura.TooSmallMoney(money, f.money)
                        if miniMoney then
                            isInvalid = true
                            useErrorColor = true
                            errorText = format(L["最小加价幅度为%s"], miniMoney)
                        end
                    end
                end

                if isInvalid then
                    f.autoButton:Disable()
                    if errorText then
                        f.autoButton.onEnterText = errorText
                        f.autoButton.disf:Show()
                    end
                end
                if useErrorColor then
                    self:SetTextColor(1, 0, 0)
                else
                    self:SetTextColor(1, 1, 1)
                end
            end
            aura.UpdateAllOnEnters()
        end

        function aura.AutoEdit_OnEnter(self)
            local f = self.owner
            GameTooltip:SetOwner(f.autoFrame, "ANCHOR_BOTTOM", 0, 0)
            GameTooltip:ClearLines()
            if self.isLocked then
                local money = self:GetText()
                if tonumber(money) then
                    GameTooltip:AddLine(L["心理价格锁定中"] .. format(L["（%s）"], aura.FormatNumber(money)), 1, 0, 0, true)
                else
                    GameTooltip:AddLine(L["心理价格锁定中"], 1, 0, 0, true)
                end
                GameTooltip:AddLine(L["取消自动出价后才能修改。"], 1, 0.82, 0, true)
            else
                local money = self:GetText()
                if tonumber(money) then
                    GameTooltip:AddLine(L["自动出价"], 1, 1, 1, true)
                    GameTooltip:AddLine(L["心理价格："] .. aura.FormatNumber(money), 1, 1, 1, true)
                else
                    GameTooltip:AddLine(L["自动出价"], 1, 1, 1, true)
                end
                GameTooltip:AddLine(L["如果别人出价比你高时，自动帮你出价，每次加价为最低幅度，出价不会高于你设定的心理价格。"], 1, 0.82, 0, true)
            end
            GameTooltip:Show()
            self.isOnEnter = true
        end

        function aura.AutoButton_OnClick(self)
            local f = self.owner
            if not f.autoButton:IsEnabled() then return end
            if f.isAuto then
                f.isAuto = false
                f.autoSendDelayFrame:SetScript('OnUpdate', nil)
                f.autoTitleText:SetText(L["设置心理价格"])
                f.autoTitleText:SetTextColor(1, .82, 0)
                f.isAutoTex:Hide()
                f.autoButton:SetText(L["开启自动出价"])
                f.autoMoneyEdit.Left:SetAlpha(1)
                f.autoMoneyEdit.Right:SetAlpha(1)
                f.autoMoneyEdit.Middle:SetAlpha(1)
                f.autoTextButton:SetWidth(f.autoTextButton:GetFontString():GetWidth())
                f.autoMoneyEdit:SetTextColor(1, 1, 1)
                f.autoMoneyEdit:SetEnabled(true)
                f.autoMoneyEdit.isLocked = false
                f.hide:Enable()
            else
                f.isAuto = true
                f.autoTitleText:SetText(L["心理价格"])
                f.autoTitleText:SetTextColor(0, 1, 0)
                f.isAutoTex:Show()
                f.autoButton:SetText(L["取消自动出价"])
                f.autoMoneyEdit:ClearFocus()
                f.autoMoneyEdit.Left:SetAlpha(f.autoMoneyEdit.alpha)
                f.autoMoneyEdit.Right:SetAlpha(f.autoMoneyEdit.alpha)
                f.autoMoneyEdit.Middle:SetAlpha(f.autoMoneyEdit.alpha)
                f.autoTextButton:SetWidth(f.autoTextButton:GetFontString():GetWidth())
                f.autoMoneyEdit:SetTextColor(0, 1, 0)
                f.autoMoneyEdit:SetEnabled(false)
                f.autoMoneyEdit.isLocked = true
                aura.AutoSendMyMoney(f)
                f.hide:Disable()
            end
            aura.UpdateAllOnEnters()
            PlaySound(aura.sound1)
        end

        function aura.AutoButton_OnEnter(self)
            local f = self.owner
            GameTooltip:SetOwner(f.autoFrame, "ANCHOR_BOTTOM", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(f.autoButton.onEnterText, 1, 0, 0, true)
            GameTooltip:Show()
        end

        function aura.AutoSendMyMoney(f)
            if f.IsEnd or not f.isAuto or f.isPaused then return end

            if aura.IsMe(f) then return end

            local newmoney
            if f.start then
                newmoney = f.money
            else
                newmoney = aura.Addmoney(f.money, "+")
                if newmoney > f.autoMoney and f.money < f.autoMoney then
                    if aura.TooSmallMoney(f.autoMoney, f.money) then return end
                    newmoney = f.autoMoney
                end
            end

            if newmoney <= f.autoMoney then
                if f.mod == 'anonymous' then
                    aura.SendAnonymousMessage(f, 'AnonymousWhisperMyMoney', f[_auctionID_], newmoney)
                else
                    aura.SendAddonMessage(f, 'SendMyMoney', f[_auctionID_], newmoney)
                end
            end
        end

        function aura.AutoSendEndPlaySound()
            if BiaoGe and BiaoGe.options and BiaoGe.options.autoAuctionAutoEndTips == 1 then
                BG.PlaySound("autoAuctionAutoEndTips")
            end
        end

        function aura.AutoSendLate()
            if BiaoGe and BiaoGe.options and BiaoGe.options.aotoSendLate == 1 then
                local num = tonumber(BiaoGe.Auction.aotoSendLate)
                if num then
                    num = min(max(num, 1), 5)
                    num = random(1 * 10, num * 10) / 10
                    return num
                end
            end
            if BG and BG.IsTitan then
                return 1.5 + random(-5, 5) / 100
            end
            return 0.5 + random(-5, 5) / 100
        end
    end

    function aura.SetEndState(f, text, r, g, b, barNotHide)
        if not f.endText then
            f.endText = f.itemFrame2:CreateFontString()
            f.endText:SetFont(FONT, 30, "OUTLINE")
            f.endText:SetPoint("TOPRIGHT", f.itemFrame, "BOTTOMRIGHT", -10, -5)
        end
        f.endText:SetText(text)
        f.endText:SetTextColor(r, g, b)
        f.remainingTime:Hide()
        if not barNotHide then
            f.bar:Hide()
        end
        f.IsEnd = true
        f.autoSendDelayFrame:SetScript('OnUpdate', nil)
        f.myMoneyEdit:Hide()
        f.cancelButton:Hide()
        f.hide:Disable()
        aura.UpdateButtonState(f)
        return f.endText
    end

    local function AuctionToEnd(f)
        if f.player and f.player ~= "" then
            aura.SetEndState(f, L["拍卖成功"], 0, 1, 0)
            if f.IsSmallWindow then
                f.currentMoneyText:SetText("|cff00FF00" .. aura.FormatNumber(f.money))
            else
                f.currentMoneyText:SetText(L["|cff00FF00成交价：|r"] .. aura.FormatNumber(f.money))
            end
            if f.player == aura.GN() then
                f.topMoneyText:SetText(L["|cff00FF00买家：|r"] .. "|cff" .. aura.GREEN1 .. L[">> 你 <<"])
            else
                f.topMoneyText:SetText(L["|cff00FF00买家：|r"] .. f.colorplayer)
            end
            if aura.IsRaidLeader() then
                After(.2, function()
                    if not aura.InBoss() then
                        SendChatMessage(format(L["{rt6}拍卖成功{rt6} %s %s %s"], f.link, f.player, f.money), "RAID")
                    end
                end)
            end
            if BG and BG.AuctionWAEnd then
                BG.AuctionWAEnd(1, f.link, f.player, f.money, f.logs, f.mod == 'anonymous')
            end
        else
            aura.SetEndState(f, L["流拍"], 1, 0, 0)
            if f.IsSmallWindow then
                f.currentMoneyText:SetText(L["|cffFF0000流拍"])
            else
                f.currentMoneyText:SetText(L["|cffFF0000流拍：|r"] .. aura.FormatNumber(f.money))
            end
            f.topMoneyText:SetText("")
            if aura.IsRaidLeader() then
                if not aura.InBoss() then
                    SendChatMessage(format(L["{rt7}流拍{rt7} %s"], f.link), "RAID")
                end
            end
            if BG and BG.AuctionWAEnd then
                BG.AuctionWAEnd(2, f.link, f.player, f.money)
            end
        end
        After(aura.HIDEFRAME_TIME, function()
            aura.UpdateFrame(f)
        end)
    end
    function aura.Auctioning(f, duration)
        f.bar:Show()
        f.endTime = GetTime() + duration
        f.bar:SetScript("OnUpdate", function(self, elapsed)
            if f.ending then
                self.t = self.t + elapsed
                if self.t >= 1 then
                    f.endText:SetText(L["正在核对"])
                end
                if self.t >= 3 then
                    if next(f.winnerInfo) then
                        local last = 0
                        local winner
                        for sender, v in pairs(f.winnerInfo) do
                            if v.t > last then
                                last = v.t
                                winner = v.winner
                            end
                        end
                        if winner then
                            f.IsEnd = true
                            f.player = winner
                            f.colorplayer = aura.SetClassCFF(winner)
                            f.ending = nil
                            AuctionToEnd(f)
                            return
                        end
                    end
                    f.player = nil
                    f.ending = nil
                    AuctionToEnd(f)
                    return
                end
                local names = {}
                for sender, v in pairs(f.winnerInfo) do
                    local winner = v.winner
                    names[winner] = (names[winner] or 0) + 1
                    if names[winner] >= aura.GetAnonymousMinMan() then
                        f.IsEnd = true
                        f.player = winner
                        f.colorplayer = aura.SetClassCFF(winner)
                        f.ending = nil
                        AuctionToEnd(f)
                        return
                    end
                end
                return
            end

            local remaining = tonumber(format("%.3f", f.endTime - GetTime()))
            if f.isPaused then
                return
            end
            local a = remaining / duration
            local _, max = f.bar:GetMinMaxValues()
            local v = a * max
            f.bar:SetValue(v)
            if remaining <= 10 then
                if f.filter and not aura.IsMe(f) then
                    f.bar:SetStatusBarColor(unpack(BGA.aura_env.barColor_filter))
                else
                    f.bar:SetStatusBarColor(1, 0, 0, 0.6)
                end
                f.remainingTime:SetTextColor(1, 0, 0)
                f.remainingTime:SetFont(FONT, 20, "OUTLINE")
            else
                if f.filter and not aura.IsMe(f) then
                    f.bar:SetStatusBarColor(unpack(BGA.aura_env.barColor_filter))
                else
                    f.bar:SetStatusBarColor(1, 1, 0, 0.6)
                end
                f.remainingTime:SetTextColor(1, 1, 1)
                f.remainingTime:SetFont(FONT, 15, "OUTLINE")
            end
            f.remainingTime:SetText((remaining <= 0 and 0 or (format("%d", remaining) + 1)) .. "s")
            f.remaining = remaining

            if remaining <= 1 then
                f.myMoneyEdit:Hide()
            end
            if remaining <= -0.5 then
                if f.mod == 'anonymous' and f.player and f.player ~= "" then
                    aura.SetEndState(f, '', 1, 1, 0, true)
                    f.ending = true
                    f.bar.t = 0
                    local winner = f.playerStr[f.player]
                    if winner then
                        winner = aura.GFN(winner)
                        aura.SendAnonymousMessage(f, 'AnonymousWinner', f[_auctionID_], winner)
                    end
                else
                    AuctionToEnd(f)
                end
            end
        end)
    end

    function aura.RefreshTimer(f)
        if f.IsEnd or f.isPaused then return end
        if f.remaining and f.remaining <= f.resetThreshold then
            aura.Auctioning(f, f.resetThreshold)
        end
    end
end)
