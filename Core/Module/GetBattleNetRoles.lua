local AddonName, ns = ...

if BG.IsBlackListPlayer then return end
if not BG.IsTitan then return end

local L = ns.L

local After = C_Timer.After
local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded

local function GetShortRealmName(realmName)
    if realmName:find("时光III") then
        return "时光III"
    elseif realmName:find("时光II") then
        return "时光II"
    elseif realmName:find("时光IV") then
        return "时光IV"
    elseif realmName:find("时光VI") then
        return "时光VI"
    elseif realmName:find("时光V") then
        return "时光V"
    end
    return realmName
end

-- ==================== 依赖库 ====================
local LibCommSocket = LibStub('LibCommSocket-3.0')
local AceSerializer = LibStub('AceSerializer-3.0')
local LibDeflate = LibStub('LibDeflate')

BG.Init(function()
    if not LibCommSocket then
        return
    end

    -- ==================== 数据存储 ====================
    local BattleNetRoles = {}
    BiaoGe.battleNetRoles = nil -- 清理移植期间误写入 SavedVariables 的旧缓存
    BiaoGe.blacklist = BiaoGe.blacklist or {}
    BiaoGe.migrations = BiaoGe.migrations or {}

    -- 兼容从 BiaoGeVIP 迁移黑名单，采用合并方式且不删除旧数据。
    BG.Init2(function()
        if BiaoGeVIP then
            local migrated = BiaoGe.migrations.blacklistFromVIP
                or BiaoGe.migrations.battleNetRolesFromVIP
            if not migrated and BiaoGeVIP.options and BiaoGeVIP.options.blacklist then
                for name in pairs(BiaoGeVIP.options.blacklist) do
                    BiaoGe.blacklist[name] = true
                end
            end
            BiaoGe.migrations.blacklistFromVIP = true
        end
    end)

    local ShowCopyRolesPopup

    -- ==================== Socket 初始化 ====================
    local Socket = {}
    LibCommSocket:Embed(Socket)
    Socket:ListenSocket('MEETINGHORN')
    local target = 'S1' .. UnitFactionGroup('player') .. (time() % 5 + 1)
    Socket:ConnectServer(target)

    -- ==================== 内部状态 ====================
    local pending = {}
    local REQUEST_TIMEOUT = 5
    local isConnected = false

    -- ==================== 辅助函数 ====================
    local function GetShortName(roleName)
        if not roleName or roleName == '' then return nil end
        return roleName:match("([^%-]+)") or roleName
    end

    local function GetMeetingHornBlackList(names, groupKey)
        if not IsAddOnLoaded("MeetingHorn") then return end
        local notBlackList = {}
        local needClearGroupKey = false
        local MeetingHorn = LibStub("AceAddon-3.0"):GetAddon("MeetingHorn")
        if MeetingHorn then
            local MeetingHornDB = MeetingHorn.db.realm
            local blockedLeaders = MeetingHornDB.blockedLeaders or {}
            local blockedAccounts = MeetingHornDB.blockedAccounts or {}
            for k, name in pairs(names) do
                if not blockedLeaders[name] then
                    notBlackList[name] = true
                end
            end
            needClearGroupKey = not blockedAccounts[groupKey]
        end
        return notBlackList, needClearGroupKey
    end
    local function ClearMeetingHornBlackList(notBlackList, needClearGroupKey, groupKey)
        if not IsAddOnLoaded("MeetingHorn") then return end
        local MeetingHorn = LibStub("AceAddon-3.0"):GetAddon("MeetingHorn")
        if MeetingHorn then
            local MeetingHornDB = MeetingHorn.db.realm
            local blockedLeaders = MeetingHornDB.blockedLeaders or {}
            for name in pairs(notBlackList) do
                blockedLeaders[name] = nil
            end
            if needClearGroupKey and MeetingHornDB.blockedAccounts then
                MeetingHornDB.blockedAccounts[groupKey] = nil
            end
        end
    end

    -- ==================== 服务器事件注册 ====================
    Socket:RegisterServer('SERVER_CONNECTED', function()
        isConnected = true
    end)

    Socket:RegisterServer('SQRL', function(_, data, dataLen)
        if dataLen and dataLen > 0 then
            data = ns.NetEaseBase64:DeCode(data)
            data = LibDeflate:DecompressDeflate(data)
            local isDeserialize
            isDeserialize, data = AceSerializer:Deserialize(data)
            if not isDeserialize then return end
        end

        local roleList = type(data) == 'table' and (data.role_list or data) or nil
        if type(roleList) ~= 'table' or #roleList == 0 then return end

        local allShorts = {}
        local allRoles = {}
        for _, roleName in ipairs(roleList) do
            if type(roleName) == 'string' and roleName ~= '' then
                local short = GetShortName(roleName)
                table.insert(allShorts, short)
                table.insert(allRoles, roleName)
            end
        end
        if #allShorts == 0 then return end

        local groupKey = allShorts[1]
        local notBlackList, needClearGroupKey = GetMeetingHornBlackList(allShorts, groupKey)
        After(.2, function()
            ClearMeetingHornBlackList(notBlackList, needClearGroupKey, groupKey)
        end)

        local matchedKey
        -- 找到匹配的查询请求
        for shortName, info in pairs(pending) do
            for _, s in ipairs(allShorts) do
                if s == shortName then
                    matchedKey = shortName
                    break
                end
            end
            if matchedKey then break end
        end

        if matchedKey and pending[matchedKey] then
            -- 打印角色列表到聊天框，末尾附加[复印]链接
            local requesterName = matchedKey and pending[matchedKey] and pending[matchedKey].requester
            local roleListStr = table.concat(allShorts, "、")
            local copyLink = L["|Hgarrmission:BiaoGeBattleNetRoles:%s|h[复制]|h"]:format(requesterName or allShorts[1])
            local msg = L["该玩家一共%s个满级角色：|cffFFFFFF%s|r %s"]:format(#allShorts, roleListStr, copyLink)
            BG.SendSystemMessage(msg)
            ShowCopyRolesPopup(allRoles, requesterName)

            local info = pending[matchedKey]
            BattleNetRoles[matchedKey] = allRoles
            if info.callback then
                info.callback(allRoles)
            end
            if info.timer then
                info.timer:Cancel()
            end
            pending[matchedKey] = nil
        end
    end)

    -- ==================== 公共 API ====================

    --- 查询团长的所有战网角色（异步）
    function BG.QueryBattleNetRoles(roleName, callback)
        if not roleName or roleName == '' then return nil end

        local shortName = GetShortName(roleName)
        if not shortName then return nil end

        local cached = BattleNetRoles[shortName]
        if cached then
            if callback then callback(cached) end
            ShowCopyRolesPopup(cached, roleName)
            return cached
        end

        pending[shortName] = {
            requester = shortName,
            callback = callback,
            timer = C_Timer.NewTimer(REQUEST_TIMEOUT, function()
                if pending[shortName] then pending[shortName] = nil end
            end),
        }

        if isConnected then
            UIErrorsFrame:AddMessage(L['正在查询战网角色'], 1, 1, 0)
            Socket:SendServer('CQRL', roleName)
        else
            UIErrorsFrame:AddMessage(L['服务器连接失败，请尝试重载游戏'], 1, 0, 0)
        end
        return nil
    end

    --- 获取已缓存的团长战网角色列表（同步）
    function BG.GetCachedBattleNetRoles(roleName)
        if not roleName or roleName == '' then return nil end
        local shortName = GetShortName(roleName)
        if not shortName then return nil end
        return BattleNetRoles[shortName]
    end

    --- 清除指定团长的缓存
    function BG.ClearBattleNetRolesCache(roleName)
        local shortName = GetShortName(roleName)
        if shortName then
            BattleNetRoles[shortName] = nil
        end
    end

    --- 清除当前服务器所有缓存
    function BG.ClearAllBattleNetRolesCache()
        wipe(BattleNetRoles)
    end

    -- ==================== 玩家黑名单 API ====================
    local function GetFullName(name)
        if not name then return end
        name = name:gsub(" ", "")
        local roleName, realm = strsplit("-", name)
        if not roleName or roleName == "" then return end
        realm = GetShortRealmName(realm or BG.realmName)
        return roleName .. "-" .. realm
    end

    function BG.IsBlacklisted(name)
        local fullName = GetFullName(name)
        return fullName and BiaoGe.blacklist[fullName]
    end

    function BG.SetPlayersBlacklisted(names, isBlacklisted)
        for _, name in ipairs(names) do
            local fullName = GetFullName(name)
            if fullName then
                BiaoGe.blacklist[fullName] = isBlacklisted and true or nil
            end
        end
        if BG.RefreshBlacklistUI then
            BG.RefreshBlacklistUI()
        end
    end

    -- 聊天消息里的黑名单标记
    do
        local blacklistMark = "|cffff0000[" .. L["黑"] .. "]|r"
        local function AddBlacklistMark(text)
            if type(text) ~= "string" or text:find(blacklistMark, 1, true) then
                return text
            end
            return text:gsub("(|Hplayer:([^:|]+).-|h)(%[[^%]]+%])", function(link, author, label)
                if BG.IsBlacklisted(author) then
                    return link .. blacklistMark .. label
                end
            end)
        end

        for i = 1, NUM_CHAT_WINDOWS do
            local chatFrame = _G["ChatFrame" .. i]
            if chatFrame then
                local AddMessage = chatFrame.AddMessage
                chatFrame.AddMessage = function(self, text, ...)
                    return AddMessage(self, AddBlacklistMark(text), ...)
                end
            end
        end
    end

    -- ==================== 自定义弹窗：[提取] 链接处理 ====================
    ShowCopyRolesPopup = function(data, requester)
        local function IsAllRolesBlacklisted()
            if not BG.CopyRolesPopup.roles or #BG.CopyRolesPopup.roles == 0 then return false end
            for _, name in ipairs(BG.CopyRolesPopup.roles) do
                if not BG.IsBlacklisted(name) then
                    return false
                end
            end
            return true
        end

        if not BG.CopyRolesPopup then
            local popup = CreateFrame("Frame", "BG_CopyRolesPopup", UIParent, "BackdropTemplate")
            BG.CopyRolesPopup = popup
            popup:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 2,
            })
            popup:SetBackdropColor(0, 0, 0, 0.7)
            popup:SetBackdropBorderColor(0, 0, 0, .5)
            popup:SetSize(250, 200)
            popup:SetPoint("CENTER", 0, 200)
            popup:SetFrameStrata("HIGH")
            popup:EnableMouse(true)
            popup:SetMovable(true)
            popup:SetClampedToScreen(true)
            popup:SetScript("OnMouseDown", function(self)
                if popup.edit then
                    popup.edit:ClearFocus()
                end
                popup:StartMoving()
            end)
            popup:SetScript("OnMouseUp", popup.StopMovingOrSizing)
            popup:SetScript("OnHide", function(self)
                if popup.edit then
                    popup.edit:ClearFocus()
                end
            end)
            popup:Hide()
            tinsert(UISpecialFrames, "BG_CopyRolesPopup")

            local title = popup:CreateFontString()
            title:SetPoint("TOP", 0, -10)
            title:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            title:SetTextColor(1, .82, 0)
            popup.title = title

            local editBg = CreateFrame("Frame", nil, popup, "BackdropTemplate")
            editBg:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            editBg:SetBackdropColor(0, 0, 0, 0.5)
            editBg:SetBackdropBorderColor(1, 1, 1, .5)
            editBg:SetPoint("TOPLEFT", 10, -35)
            editBg:SetPoint("BOTTOMRIGHT", -10, 45)
            editBg:EnableMouse(true)
            editBg:SetScript("OnMouseDown", function(self)
                popup.edit:SetFocus()
            end)

            local scroll = CreateFrame("ScrollFrame", nil, editBg, "UIPanelScrollFrameTemplate")
            scroll:SetPoint("TOPLEFT", 3, -2)
            scroll:SetPoint("BOTTOMRIGHT", -24, 2)
            scroll.ScrollBar.scrollStep = BG.scrollStep
            BG.CreateSrollBarBackdrop(scroll.ScrollBar)
            BG.HookScrollBarShowOrHide(scroll)

            local edit = CreateFrame("EditBox", nil, scroll)
            edit:SetMultiLine(true)
            edit:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
            edit:SetWidth(scroll:GetWidth())
            edit:SetAutoFocus(false)
            edit:SetScript("OnEscapePressed", function()
                popup:Hide()
            end)
            scroll:SetScrollChild(edit)
            popup.edit = edit

            local closeBtn = BG.CreateButton(popup)
            closeBtn:SetSize(90, 24)
            closeBtn:SetPoint("BOTTOMRIGHT", -15, 10)
            closeBtn:SetText(CLOSE)
            closeBtn:SetScript("OnClick", function()
                BG.PlaySound(1)
                popup:Hide()
            end)

            local blacklistBtn = BG.CreateButton(popup)
            blacklistBtn:SetSize(120, 24)
            blacklistBtn:SetPoint("BOTTOMLEFT", 15, 10)
            blacklistBtn:SetScript("OnClick", function(self)
                BG.PlaySound(1)
                if not popup.roles then return end
                local add = not IsAllRolesBlacklisted()
                BG.SetPlayersBlacklisted(popup.roles, add)
                self:SetText(add and L["取消黑名单"] or L["加入黑名单"])
            end)
            popup.blacklistBtn = blacklistBtn

            local sourceText = popup:CreateFontString(nil, "ARTWORK")
            sourceText:SetPoint('TOP', popup, "BOTTOM", 0, -2)
            sourceText:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
            sourceText:SetTextColor(.7, .7, .7)
            sourceText:SetText(L["说明：数据来自官方接口"])
        end
        BG.CopyRolesPopup.requester = requester
        BG.CopyRolesPopup.roles = data
        BG.CopyRolesPopup:Show()
        BG.CopyRolesPopup.edit:SetText(table.concat(data, "\n"))
        BG.CopyRolesPopup.title:SetText(L["该战网%s个满级角色"]:format(#data))
        BG.CopyRolesPopup.blacklistBtn:SetShown(requester ~= nil)
        if requester then
            BG.CopyRolesPopup.blacklistBtn:SetText(IsAllRolesBlacklisted() and L["取消黑名单"] or L["加入黑名单"])
        end
    end

    hooksecurefunc("SetItemRef", function(link, text, button)
        local requester = link:match("^garrmission:BiaoGeBattleNetRoles:(.+)$")
        if not requester then return end
        local roles = BattleNetRoles[requester]
        if roles then
            ShowCopyRolesPopup(roles, requester)
        end
    end)

    -- 右键菜单
    do
        local function GetMenuPlayerName(contextData)
            local unit = contextData.unit
            if unit and UnitIsPlayer(unit) then
                return BG.GN(unit)
            end
            local gameAccountInfo = contextData.accountInfo and contextData.accountInfo.gameAccountInfo
            if gameAccountInfo and gameAccountInfo.characterName then
                local name = gameAccountInfo.characterName
                if gameAccountInfo.realmName and gameAccountInfo.realmName ~= "" then
                    name = name .. "-" .. gameAccountInfo.realmName
                end
                return name
            end
            return contextData.chatTarget or contextData.name
        end

        local menus = {
            "MENU_UNIT_SELF",
            "MENU_UNIT_TARGET",
            "MENU_UNIT_PLAYER",
            "MENU_UNIT_FRIEND",
            "MENU_UNIT_PARTY",
            "MENU_UNIT_RAID",
            "MENU_UNIT_RAID_PLAYER",
            "MENU_UNIT_BN_FRIEND",
            "MENU_UNIT_COMMUNITIES_GUILD_MEMBER",
        }
        for _, menu in ipairs(menus) do
            Menu.ModifyMenu(menu, function(owner, description, contextData)
                local unit = contextData.unit
                local playerName = GetMenuPlayerName(contextData)
                local canQuery = unit and UnitIsPlayer(unit) and UnitLevel(unit) >= BG.fullLevel
                local isBlacklisted = playerName and BG.IsBlacklisted(playerName)
                if canQuery or isBlacklisted then
                    description:CreateDivider()
                end
                if isBlacklisted then
                    description:CreateTitle(L["|cffff0000提醒：它已被你拉黑"])
                end
                if canQuery then
                    description:CreateButton(L["查询全部角色"], function()
                        BG.QueryBattleNetRoles(playerName)
                    end)
                end
            end)
        end
    end

    -- 查询界面
    do
        local queryBg = CreateFrame("Frame", nil, WhoFrame, "BackdropTemplate")
        queryBg:SetSize(FriendsFrame:GetWidth(), 30)
        queryBg:SetPoint("BOTTOMLEFT", WhoFrame, "TOPLEFT", 0, -2)
        queryBg:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 1,
        })
        queryBg:SetBackdropColor(0, 0, 0, .5)
        queryBg:SetBackdropBorderColor(1, 1, 1, .4)

        local label = queryBg:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("LEFT", 7, 0)
        label:SetText(L["查询全部角色"] .. "：")

        local edit = CreateFrame("EditBox", nil, queryBg, BG.editTemplate)
        edit:SetHeight(22)
        edit:SetPoint("LEFT", label, "RIGHT", 5, 0)
        edit:SetAutoFocus(false)
        edit:SetMaxLetters(30)

        local instructions = edit:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        instructions:SetPoint("LEFT", 6, 0)
        instructions:SetText(L["输入玩家名字"])
        instructions:SetTextColor(.6, .6, .6)

        local function Query()
            local roleName = strtrim(edit:GetText() or "")
            if roleName == "" then
                return
            end

            edit:ClearFocus()
            BG.QueryBattleNetRoles(roleName)
        end

        edit:SetScript("OnTextChanged", function(self)
            instructions:SetShown(self:GetText() == "")
        end)
        edit:SetScript("OnEnterPressed", Query)
        edit:SetScript("OnEscapePressed", edit.ClearFocus)

        local queryBtn = BG.CreateButton(queryBg)
        queryBtn:SetSize(60, 22)
        queryBtn:SetPoint("RIGHT", queryBg, "RIGHT", -7, 0)
        edit:SetPoint("RIGHT", queryBtn, "LEFT", -5, 0)
        queryBtn:SetText(L["查询"])
        queryBtn:SetScript("OnClick", function()
            BG.PlaySound(1)
            Query()
        end)
        queryBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
            GameTooltip:AddLine(L["如果角色不存在或没满级，那么查询结果可能不准确。"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        queryBtn:SetScript("OnLeave", GameTooltip_Hide)

        function BG.UpdateBattleNetRolesQueryFrame()
            queryBg:SetShown(BiaoGe.options["searchList"] == 1)
        end
        WhoFrame:HookScript("OnShow", BG.UpdateBattleNetRolesQueryFrame)
        BG.UpdateBattleNetRolesQueryFrame()
    end
end)
