local AddonName, ns = ...

local L = ns.L

local BOARD_PREFIX = "TuanJianBoard2"
local BAR_WIDTH = 300
local BAR_HEIGHT = 30
local BAR_SPACING = 4

local Receiver = {
    active = false,
    tasks = {},
    tasksByBoss = {},
    tasksByPlayer = {},
    bars = {},
    barPool = {},
    serial = 0,
}
BG.BoardReceiver = Receiver

local function CancelTimer(timer)
    if timer and timer.Cancel then
        timer:Cancel()
    end
end

local function GetFullPlayerName()
    local name, realm
    if UnitFullName then
        name, realm = UnitFullName("player")
    end
    if name and realm and realm ~= "" then
        return name .. "-" .. realm
    end
    return GetUnitName("player", true) or UnitName("player")
end

local function SplitName(name)
    if not name then return end
    name = name:gsub("%s", "")
    local shortName, realm = strsplit("-", name)
    return shortName, realm
end

local function IsSamePlayer(name1, name2)
    local shortName1, realm1 = SplitName(name1)
    local shortName2, realm2 = SplitName(name2)
    if not shortName1 or not shortName2 or shortName1 ~= shortName2 then
        return false
    end
    return not realm1 or realm1 == "" or not realm2 or realm2 == "" or realm1 == realm2
end

local function FindRaidUnit(name)
    if IsSamePlayer(name, Receiver.myName) then
        return "player"
    end
    for i = 1, GetNumGroupMembers() do
        local unit = "raid" .. i
        if UnitExists(unit) and IsSamePlayer(name, GetUnitName(unit, true)) then
            return unit
        end
    end
end

local function IsLeaderOrAssistant(name)
    local unit = FindRaidUnit(name)
    return unit and (UnitIsGroupLeader(unit) or (UnitIsGroupAssistant and UnitIsGroupAssistant(unit)))
end

local function IsLocalLeaderOrAssistant()
    return UnitIsGroupLeader("player") or (UnitIsGroupAssistant and UnitIsGroupAssistant("player"))
end

local function GetPlayerClassColor(name)
    local unit = FindRaidUnit(name)
    local class = unit and select(2, UnitClass(unit))
    if class then
        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then
            local colorStr = color.colorStr or format("ff%02x%02x%02x",
                math.floor(color.r * 255 + .5), math.floor(color.g * 255 + .5), math.floor(color.b * 255 + .5))
            return color.r, color.g, color.b, colorStr
        end
        if _G.GetClassColor then
            local r, g, b, colorStr = _G.GetClassColor(class)
            return r, g, b, colorStr
        end
    end
    return 1, 1, 1, "ffffffff"
end

local function GetSpellTextureByID(spellID)
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellID)
    elseif GetSpellTexture then
        return GetSpellTexture(spellID)
    end
end

local function GetSpellLinkByID(spellID)
    if C_Spell and C_Spell.GetSpellLink then
        return C_Spell.GetSpellLink(spellID)
    elseif GetSpellLink then
        return GetSpellLink(spellID)
    end
end

local function ParseAbilityIDs(text)
    if type(text) ~= "string" or text == "" then return end
    local abilities = {}
    for _, token in ipairs({ strsplit("^", text) }) do
        local kind, id = token:match("^([si])(%d+)$")
        id = tonumber(id)
        if id and id > 0 then
            abilities[#abilities + 1] = {
                kind = kind,
                id = id,
            }
        end
    end
    if next(abilities) then
        return abilities
    end
end

local function GetAbilityTexture(ability)
    if ability.kind == "s" then
        return GetSpellTextureByID(ability.id)
    end
    return select(5, GetItemInfoInstant(ability.id))
end

local function GetAbilityLink(ability)
    if ability.kind == "s" then
        return GetSpellLinkByID(ability.id) or (GetSpellInfo and GetSpellInfo(ability.id)) or ("spell:" .. ability.id)
    end
    return select(2, GetItemInfo(ability.id)) or ("item:" .. ability.id)
end

local function GetAbilityIconText(abilities)
    local text = ""
    for _, ability in ipairs(abilities) do
        local texture = GetAbilityTexture(ability)
        if texture then
            text = text .. format("|T%s:25:25:0:0:100:100:7:93:7:93|t", texture)
        end
    end
    return text
end

local function GetAbilityLinks(abilities)
    local text = ""
    for _, ability in ipairs(abilities) do
        text = text .. GetAbilityLink(ability)
    end
    return text
end

local function SpeakText(text)
    if not C_VoiceChat or not C_VoiceChat.SpeakText then return end
    local success
    if Enum and Enum.VoiceTtsDestination and Enum.VoiceTtsDestination.LocalPlayback then
        success = pcall(C_VoiceChat.SpeakText, 0, text, Enum.VoiceTtsDestination.LocalPlayback, 3, 100)
    end
    if not success then
        pcall(C_VoiceChat.SpeakText, 0, text, 3, 100)
    end
end

local function HasLegacyWAReceiver()
    return _G.TJBoardVer and _G.TJBoardVer.ver
end

local function SaveAnchorPoint()
    if not Receiver.frame then return end
    local point, _, relativePoint, x, y = Receiver.frame:GetPoint(1)
    BiaoGe.options.boardReceiverPoint = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }
end

local function RestoreAnchorPoint()
    if not Receiver.frame then return end
    local point = BiaoGe.options.boardReceiverPoint
    Receiver.frame:ClearAllPoints()
    if type(point) == "table" and point.point and point.relativePoint and tonumber(point.x) and tonumber(point.y) then
        Receiver.frame:SetPoint(point.point, UIParent, point.relativePoint, point.x, point.y)
    else
        Receiver.frame:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
    end
end

local function CreateAnchorFrame()
    local frame = CreateFrame("Frame", "BiaoGeBoardReceiverFrame", UIParent, "BackdropTemplate")
    frame:SetSize(BAR_WIDTH, BAR_HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if BiaoGe.options.boardReceiverLocked ~= 1 then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveAnchorPoint()
    end)

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, .55)
    frame.dragBackground = background

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER")
    text:SetFont(BIAOGE_TEXT_FONT or STANDARD_TEXT_FONT, 15, "OUTLINE")
    text:SetText(L["减伤链进度条位置"])
    text:SetTextColor(0, 1, 0)
    frame.dragText = text

    Receiver.frame = frame
    RestoreAnchorPoint()
end

local function CreateBar()
    local bar = CreateFrame("StatusBar", nil, Receiver.frame, "BackdropTemplate")
    bar:SetSize(BAR_WIDTH, BAR_HEIGHT)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    bar:SetStatusBarColor(.1, .55, 1, .8)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    bar:SetBackdropColor(0, 0, 0, .75)
    bar:SetBackdropBorderColor(.2, .8, 1, 1)

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", bar, "LEFT", 5, 0)
    text:SetPoint("RIGHT", bar, "RIGHT", -48, 0)
    text:SetFont(BIAOGE_TEXT_FONT or STANDARD_TEXT_FONT, 15, "OUTLINE")
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    bar.text = text

    local timeText = bar:CreateFontString(nil, "OVERLAY")
    timeText:SetPoint("RIGHT", bar, "RIGHT", -5, 0)
    timeText:SetFont(BIAOGE_TEXT_FONT or STANDARD_TEXT_FONT, 15, "OUTLINE")
    timeText:SetTextColor(1, 1, 1)
    bar.timeText = timeText

    bar:Hide()
    return bar
end

local function AcquireBar(player)
    local bar = Receiver.bars[player]
    if bar then return bar end
    bar = tremove(Receiver.barPool) or CreateBar()
    bar.player = player
    Receiver.bars[player] = bar
    return bar
end

local function ReleaseBar(player)
    local bar = Receiver.bars[player]
    if not bar then return end
    Receiver.bars[player] = nil
    bar.player = nil
    bar.task = nil
    bar:Hide()
    bar:ClearAllPoints()
    Receiver.barPool[#Receiver.barPool + 1] = bar
end

local function ShouldShowTask(task)
    if BiaoGe.options.boardReceiverEnabled ~= 1 then return false end
    local mode = tonumber(BiaoGe.options.boardReceiverWhoShow) or 1
    if task.isMe then return true end
    if mode == 3 then return false end
    if mode == 1 and not IsLocalLeaderOrAssistant() then return false end
    return true
end

local function GetFirstVisibleTask(player)
    local selected
    local tasks = Receiver.tasksByPlayer[player]
    if not tasks then return end
    for _, task in pairs(tasks) do
        if task.active and not task.removed and ShouldShowTask(task) then
            if not selected or task.expirationTime < selected.expirationTime or
                (task.expirationTime == selected.expirationTime and task.serial < selected.serial) then
                selected = task
            end
        end
    end
    return selected
end

local function ReflowBars()
    local list = {}
    for _, bar in pairs(Receiver.bars) do
        if bar:IsShown() and bar.task then
            list[#list + 1] = bar
        end
    end
    sort(list, function(a, b)
        if a.task.isMe ~= b.task.isMe then
            return a.task.isMe
        end
        if a.task.expirationTime ~= b.task.expirationTime then
            return a.task.expirationTime < b.task.expirationTime
        end
        return a.player < b.player
    end)
    for i, bar in ipairs(list) do
        bar:ClearAllPoints()
        bar:SetPoint("BOTTOM", Receiver.frame, "BOTTOM", 0, (i - 1) * (BAR_HEIGHT + BAR_SPACING))
    end
    Receiver.visibleBarCount = #list
    if not Receiver.active then
        Receiver.frame.dragBackground:Hide()
        Receiver.frame.dragText:Hide()
        Receiver.frame:Hide()
        Receiver.frame:SetScript("OnUpdate", nil)
        return
    end
    local unlocked = BiaoGe.options.boardReceiverLocked ~= 1
    Receiver.frame.dragBackground:SetShown(unlocked and #list == 0)
    Receiver.frame.dragText:SetShown(unlocked and #list == 0)
    Receiver.frame:SetShown(#list > 0 or unlocked)
    if #list > 0 then
        Receiver.frame:SetScript("OnUpdate", Receiver.OnUpdate)
    else
        Receiver.frame:SetScript("OnUpdate", nil)
    end
end

local function RefreshPlayer(player)
    local task = GetFirstVisibleTask(player)
    if not task then
        ReleaseBar(player)
        return
    end
    local bar = AcquireBar(player)
    bar.task = task
    local _, _, _, colorStr = GetPlayerClassColor(task.player)
    local playerText = task.isMe and "|cff00ff00>> " .. L["你"] .. " <<|r" or
        "|c" .. colorStr .. task.player .. "|r"
    bar.text:SetText(task.iconText .. " " .. playerText)
    if task.isMe then
        bar:SetStatusBarColor(0, .75, .2, .85)
        bar:SetBackdropBorderColor(0, 1, 0, 1)
    else
        bar:SetStatusBarColor(.1, .55, 1, .8)
        bar:SetBackdropBorderColor(.2, .8, 1, 1)
    end
    bar:Show()
end

local function RefreshAll()
    local players = {}
    for player in pairs(Receiver.tasksByPlayer) do
        players[player] = true
        RefreshPlayer(player)
    end
    local release = {}
    for player in pairs(Receiver.bars) do
        if not players[player] then
            release[#release + 1] = player
        end
    end
    for _, player in ipairs(release) do
        ReleaseBar(player)
    end
    ReflowBars()
end

local function RemoveTask(task, skipRefresh)
    if not task or task.removed then return end
    task.removed = true
    CancelTimer(task.showTimer)
    CancelTimer(task.expiryTimer)
    CancelTimer(task.castVoiceTimer)
    if task.notificationTimers then
        for _, timer in ipairs(task.notificationTimers) do
            CancelTimer(timer)
        end
    end
    Receiver.tasks[task.key] = nil
    if Receiver.tasksByBoss[task.bossSpellID] then
        Receiver.tasksByBoss[task.bossSpellID][task.key] = nil
        if not next(Receiver.tasksByBoss[task.bossSpellID]) then
            Receiver.tasksByBoss[task.bossSpellID] = nil
        end
    end
    if Receiver.tasksByPlayer[task.player] then
        Receiver.tasksByPlayer[task.player][task.key] = nil
        if not next(Receiver.tasksByPlayer[task.player]) then
            Receiver.tasksByPlayer[task.player] = nil
        end
    end
    if not skipRefresh then
        RefreshPlayer(task.player)
        ReflowBars()
    end
end

local function HideBoss(bossSpellID)
    local tasks = Receiver.tasksByBoss[bossSpellID]
    if not tasks then return end
    local remove = {}
    for _, task in pairs(tasks) do
        remove[#remove + 1] = task
    end
    for _, task in ipairs(remove) do
        RemoveTask(task, true)
    end
    RefreshAll()
end

local function HideAll()
    local remove = {}
    for _, task in pairs(Receiver.tasks) do
        remove[#remove + 1] = task
    end
    for _, task in ipairs(remove) do
        RemoveTask(task, true)
    end
    wipe(Receiver.tasks)
    wipe(Receiver.tasksByBoss)
    wipe(Receiver.tasksByPlayer)
    local release = {}
    for player in pairs(Receiver.bars) do
        release[#release + 1] = player
    end
    for _, player in ipairs(release) do
        ReleaseBar(player)
    end
    ReflowBars()
end
Receiver.HideAll = HideAll

local function SendWhisper(task, remaining, now)
    if not Receiver.active or task.removed or BiaoGe.options.boardReceiverWhisper ~= 1 then return end
    if not IsLocalLeaderOrAssistant() or not IsSamePlayer(task.sender, Receiver.myName) then return end
    local links = GetAbilityLinks(task.abilities)
    if now then
        SendChatMessage(format(L["提醒：你需立刻施放%s"], links), "WHISPER", nil, task.player)
    else
        SendChatMessage(format(L["提醒：%s秒后你需施放%s"], remaining, links), "WHISPER", nil, task.player)
    end
end

local function ScheduleWhisper(task)
    local remaining
    if task.now then
        remaining = 0
    elseif task.duration >= 5 then
        remaining = 5
    elseif task.duration >= 3 then
        remaining = 3
    elseif task.duration > 0 then
        remaining = 1
    else
        return
    end
    task.notificationTimers = task.notificationTimers or {}
    local delay = max(0, task.duration - remaining)
    local timer = C_Timer.NewTimer(delay, function()
        if task.removed then return end
        SendWhisper(task, remaining, task.now)
        if remaining > 1 and not task.now then
            local finalTimer = C_Timer.NewTimer(remaining - 1, function()
                SendWhisper(task, 1, false)
            end)
            task.notificationTimers[#task.notificationTimers + 1] = finalTimer
        end
    end)
    task.notificationTimers[#task.notificationTimers + 1] = timer
end

local function ActivateTask(task)
    if task.removed then return end
    task.active = true
    task.showTimer = nil
    if task.isMe and BiaoGe.options.boardReceiverVoice == 1 then
        local remaining = max(0, task.expirationTime - GetTime())
        if task.now or remaining <= 1 then
            C_Timer.After(.3, function()
                if not task.removed and BiaoGe.options.boardReceiverVoice == 1 then
                    SpeakText(L["交减伤技能"])
                end
            end)
        else
            C_Timer.After(.3, function()
                if not task.removed and BiaoGe.options.boardReceiverVoice == 1 then
                    SpeakText(L["技能准备"])
                end
            end)
            task.castVoiceTimer = C_Timer.NewTimer(max(0, remaining - 1), function()
                if not task.removed and BiaoGe.options.boardReceiverVoice == 1 then
                    SpeakText(L["交减伤技能"])
                end
            end)
        end
    end
    RefreshPlayer(task.player)
    ReflowBars()
end

local function AddTask(sender, bossSpellID, index, player, duration, abilities, autoHide, now)
    Receiver.serial = Receiver.serial + 1
    local key = table.concat({ sender, bossSpellID, index, player }, "\031")
    if Receiver.tasks[key] then
        RemoveTask(Receiver.tasks[key])
    end
    local currentTime = GetTime()
    local task = {
        key = key,
        serial = Receiver.serial,
        sender = sender,
        bossSpellID = bossSpellID,
        index = index,
        player = player,
        duration = duration,
        expirationTime = currentTime + duration,
        abilities = abilities,
        iconText = GetAbilityIconText(abilities),
        autoHide = autoHide,
        now = now,
        isMe = IsSamePlayer(player, Receiver.myName),
    }
    Receiver.tasks[key] = task
    Receiver.tasksByBoss[bossSpellID] = Receiver.tasksByBoss[bossSpellID] or {}
    Receiver.tasksByBoss[bossSpellID][key] = task
    Receiver.tasksByPlayer[player] = Receiver.tasksByPlayer[player] or {}
    Receiver.tasksByPlayer[player][key] = task

    if autoHide then
        task.expiryTimer = C_Timer.NewTimer(duration, function()
            RemoveTask(task)
        end)
    end

    local remainingTime = tonumber(BiaoGe.options.boardReceiverRemainingTime) or 10
    if duration > remainingTime then
        task.showTimer = C_Timer.NewTimer(duration - remainingTime, function()
            ActivateTask(task)
        end)
    else
        ActivateTask(task)
    end
    ScheduleWhisper(task)
end

local function ParseSender(arg4, arg5)
    if arg4 and IsLeaderOrAssistant(arg4) then
        return arg4
    end
    if arg5 and IsLeaderOrAssistant(arg5) then
        return arg5
    end
end

local function HandleBoardMessage(message, sender)
    if type(message) ~= "string" or #message > 255 then return end
    local msgType, bossSpellID, index, player, duration, abilityText, autoHide, now = strsplit(",", message)
    if msgType == "show" then
        bossSpellID = tonumber(bossSpellID)
        index = tonumber(index)
        duration = tonumber(duration)
        local abilities = ParseAbilityIDs(abilityText)
        if not bossSpellID or not index or not duration or duration < 0 or duration > 3600 or
            type(player) ~= "string" or player == "" or #player > 80 or not abilities then
            return
        end
        AddTask(sender, bossSpellID, index, player, duration, abilities,
            autoHide == "autoHide", now == "now")
    elseif msgType == "hide" then
        bossSpellID = tonumber(bossSpellID)
        if bossSpellID then
            HideBoss(bossSpellID)
        end
    elseif msgType == "hideAll" then
        HideAll()
    end
end

local function EnableNativeReceiver()
    if HasLegacyWAReceiver() then
        Receiver.usingWeakAuras = true
        return
    end
    Receiver.active = true
    RefreshAll()
end

function Receiver.OnUpdate(_, elapsed)
    Receiver.updateElapsed = (Receiver.updateElapsed or 0) + elapsed
    if Receiver.updateElapsed < .05 then return end
    Receiver.updateElapsed = 0
    local now = GetTime()
    local expired = {}
    for _, bar in pairs(Receiver.bars) do
        local task = bar.task
        if task and not task.removed then
            local remaining = max(0, task.expirationTime - now)
            bar:SetMinMaxValues(0, max(.01, task.duration))
            bar:SetValue(remaining)
            if task.now and remaining <= 0 then
                bar.timeText:SetText(L["现在"])
            else
                bar.timeText:SetText(format("%.1f", remaining))
            end
            if remaining <= 0 and task.autoHide then
                expired[#expired + 1] = task
            end
        end
    end
    if next(expired) then
        for _, task in ipairs(expired) do
            RemoveTask(task, true)
        end
        RefreshAll()
    end
end

function BG.UpdateBoardReceiverSettings()
    if not Receiver.frame then return end
    Receiver.frame:SetScale(tonumber(BiaoGe.options.boardReceiverScale) or 1)
    local unlocked = BiaoGe.options.boardReceiverLocked ~= 1
    Receiver.frame:EnableMouse(unlocked)
    RefreshAll()
end

function BG.ResetBoardReceiverPosition()
    BiaoGe.options.boardReceiverPoint = nil
    RestoreAnchorPoint()
end

pcall(C_ChatInfo.RegisterAddonMessagePrefix, BOARD_PREFIX)

BG.Init(function()
    local defaults = {
        boardReceiverEnabled = 1,
        boardReceiverWhoShow = 1,
        boardReceiverRemainingTime = 10,
        boardReceiverVoice = 1,
        boardReceiverWhisper = 1,
        boardReceiverScale = 1,
        boardReceiverLocked = 1,
    }
    for name, value in pairs(defaults) do
        BG.options[name .. "reset"] = value
        if BiaoGe.options[name] == nil then
            BiaoGe.options[name] = value
        end
    end
    Receiver.myName = GetFullPlayerName()
    CreateAnchorFrame()
    BG.UpdateBoardReceiverSettings()
end)

BG.RegisterEvent("CHAT_MSG_ADDON", function(_, _, prefix, message, distribution, arg4, arg5)
    if not Receiver.active or distribution ~= "RAID" then return end
    if prefix ~= BOARD_PREFIX then return end
    local sender = ParseSender(arg4, arg5)
    if sender then
        HandleBoardMessage(message, sender)
    end
end)

BG.RegisterEvent("GROUP_ROSTER_UPDATE", function()
    RefreshAll()
end)

BG.RegisterEvent({ "ENCOUNTER_START", "ENCOUNTER_END", "RAID_INSTANCE_WELCOME" }, function()
    HideAll()
end)

BG.Init3(function()
    EnableNativeReceiver()
end)
