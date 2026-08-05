local AddonName, ns = ...

local L = ns.L
local SetClassCFF = ns.SetClassCFF

local BOARD_PREFIX = "TuanJianBoard"
local BOARD_PREFIX_COUNT = 5
local BOARD_PREFIXES = {}
local BAR_WIDTH = 300
local BAR_HEIGHT = 30
local BAR_SPACING = 0
local ICON_SIZE = BAR_HEIGHT
local ICON_GAP = 0
local ICON_SPACING = 0
local BAR_COLOR_NORMAL = { 1, 1, 0, .85 }
local BAR_COLOR_LOW_TIME = { 1, 0, 0, .85 }
local PREVIEW_FRAME_STRATA = "FULLSCREEN_DIALOG"
local PREVIEW_FRAME_LEVEL = 140
local VOICE_SOUND_FILE = "Interface\\AddOns\\BiaoGe\\Media\\sound\\other\\BoxingArenaSound.ogg"
local VOICE_TEXT_DELAY = .3

for i = 1, BOARD_PREFIX_COUNT do
    local prefix = BOARD_PREFIX .. i
    BOARD_PREFIXES[prefix] = true
    C_ChatInfo.RegisterAddonMessagePrefix(prefix)
end

local Receiver = {
    tasks = {},
    tasksByBoss = {},
    tasksByPlayer = {},
    bars = {},
    barPool = {},
    serial = 0,
}
BG.BoardReceiver = Receiver

-- 安全取消一个可能存在的计时器。
local function CancelTimer(timer)
    if timer and timer.Cancel then
        timer:Cancel()
    end
end

-- 比较两个可能省略服务器名的玩家名是否指向同一角色。
local function IsMe(name1, name2)
    return name1 == name2
end

local function IsLeader(player)
    -- return UnitIsGroupLeader(player) or UnitIsGroupAssistant(player)
    return BGDEBUG or UnitIsGroupLeader(player) or UnitIsGroupAssistant(player)
end

local function ImLeader()
    -- return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    return BGDEBUG or UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
end

-- 生成进度条中的玩家显示文本，本人使用绿色“你”，其他人使用职业颜色。
local function GetPlayerDisplayText(name)
    if IsMe(name, Receiver.myName) then
        return "|cff00ff00>>" .. L["你"] .. "<<|r"
    end
    return SetClassCFF(name)
end

-- 兼容不同客户端 API 获取法术图标。
local function GetSpellTextureByID(spellID)
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellID)
    elseif GetSpellTexture then
        return GetSpellTexture(spellID)
    end
end

-- 兼容不同客户端 API 获取法术链接。
local function GetSpellLinkByID(spellID)
    if C_Spell and C_Spell.GetSpellLink then
        return C_Spell.GetSpellLink(spellID)
    elseif GetSpellLink then
        return GetSpellLink(spellID)
    end
end

-- 解析通讯消息中的法术和物品 ID 列表。
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

-- 获取一个减伤技能或物品的图标。
local function GetAbilityTexture(ability)
    if ability.texture then
        return ability.texture
    end
    if ability.kind == "s" then
        return GetSpellTextureByID(ability.id)
    end
    return select(5, GetItemInfoInstant(ability.id))
end

-- 获取一个减伤技能或物品的可点击链接。
local function GetAbilityLink(ability)
    if ability.kind == "s" then
        return GetSpellLinkByID(ability.id) or (GetSpellInfo and GetSpellInfo(ability.id)) or ("spell:" .. ability.id)
    end
    return select(2, GetItemInfo(ability.id)) or ("item:" .. ability.id)
end

-- 把任务中的所有减伤技能组合为链接文本。
local function GetAbilityLinks(abilities)
    local text = ""
    for _, ability in ipairs(abilities) do
        text = text .. GetAbilityLink(ability)
    end
    return text
end

-- 先播放提示音，再短暂延迟播放游戏内文字转语音。
local function SpeakText(text)
    PlaySoundFile(VOICE_SOUND_FILE, "Master")
    -- 提示音起奏后再启动文字转语音。
    C_Timer.After(VOICE_TEXT_DELAY, function()
        if not C_VoiceChat or not C_VoiceChat.SpeakText then return end
        local success
        if Enum and Enum.VoiceTtsDestination and Enum.VoiceTtsDestination.LocalPlayback then
            success = pcall(C_VoiceChat.SpeakText, 0, text, Enum.VoiceTtsDestination.LocalPlayback, 3, 100)
        end
        if not success then
            pcall(C_VoiceChat.SpeakText, 0, text, 3, 100)
        end
    end)
end

-- 保存减伤链进度条锚点位置。
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

-- 恢复已保存的进度条锚点，缺省时从屏幕顶部向下偏移 250 像素。
local function RestoreAnchorPoint()
    if not Receiver.frame then return end
    local point = BiaoGe.options.boardReceiverPoint
    Receiver.frame:ClearAllPoints()
    if type(point) == "table" and point.point and point.relativePoint and tonumber(point.x) and tonumber(point.y) then
        Receiver.frame:SetPoint(point.point, UIParent, point.relativePoint, point.x, point.y)
    else
        Receiver.frame:SetPoint("BOTTOM", UIParent, "TOP", 0, -250)
    end
end

-- 仅在通知移动模式显示预览条时允许拖动进度条框架。
local function CanDragReceiver()
    return Receiver.previewTasks ~= nil and not (InCombatLockdown and InCombatLockdown())
end

-- 获取换算到 UIParent 坐标系中的鼠标位置。
local function GetCursorUIPosition()
    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    return x / scale, y / scale
end

-- 根据鼠标相对拖动起点的位移更新接收端锚点。
local function UpdateReceiverDrag()
    local drag = Receiver.drag
    if not drag then return end
    local cursorX, cursorY = GetCursorUIPosition()
    Receiver.frame:ClearAllPoints()
    Receiver.frame:SetPoint(drag.point, UIParent, drag.relativePoint,
        drag.x + cursorX - drag.cursorX, drag.y + cursorY - drag.cursorY)
end

-- 从锚点或任意进度条开始拖动整个接收端框架。
local function StartReceiverDrag()
    if not CanDragReceiver() then return end
    local point, _, relativePoint, x, y = Receiver.frame:GetPoint(1)
    local cursorX, cursorY = GetCursorUIPosition()
    Receiver.drag = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
        cursorX = cursorX,
        cursorY = cursorY,
    }
    Receiver.dragUpdater = Receiver.dragUpdater or CreateFrame("Frame")
    Receiver.dragUpdater:SetScript("OnUpdate", UpdateReceiverDrag)
end

-- 停止拖动整个接收端框架并保存位置。
local function StopReceiverDrag()
    if not Receiver.drag then return end
    Receiver.drag = nil
    Receiver.dragUpdater:SetScript("OnUpdate", nil)
    SaveAnchorPoint()
end

-- 为预览进度条准备拖动交互；真实进度条会保持鼠标禁用。
local function EnableReceiverInteraction(frame)
    frame:EnableMouse(false)
    -- 左键按下时开始拖动通知移动模式中的预览条。
    frame:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            StartReceiverDrag()
        end
    end)
    -- 左键松开时停止拖动并保存位置，右键松开时恢复默认位置。
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            StopReceiverDrag()
        elseif button == "RightButton" and Receiver.previewTasks and
            not (InCombatLockdown and InCombatLockdown()) then
            if BG.ResetBoardReceiverPosition then
                BG.ResetBoardReceiverPosition()
                BG.PlaySound(1)
            end
        end
    end)
end

-- 创建用于承载和定位所有进度条的锚点框架。
local function CreateAnchorFrame()
    local frame = CreateFrame("Frame", "BiaoGeBoardReceiverFrame", UIParent, "BackdropTemplate")
    frame:SetSize(BAR_WIDTH, BAR_HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    EnableReceiverInteraction(frame)
    frame.normalFrameLevel = frame:GetFrameLevel()

    Receiver.frame = frame
    RestoreAnchorPoint()
end

-- 创建一个可复用的减伤链状态条及其文字和边框。
local function CreateBar()
    local bar = CreateFrame("StatusBar", nil, Receiver.frame, "BackdropTemplate")
    bar:SetSize(BAR_WIDTH, BAR_HEIGHT)
    EnableReceiverInteraction(bar)
    bar.normalFrameLevel = Receiver.frame.normalFrameLevel + 1
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    bar:SetStatusBarColor(unpack(BAR_COLOR_NORMAL))
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    bar:SetBackdropColor(0, 0, 0, .75)

    local border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    border:SetAllPoints()
    border:SetFrameLevel(bar:GetFrameLevel() + 2)
    border.normalFrameLevel = bar.normalFrameLevel + 2
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0, 0, 0, 1)
    bar.border = border

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
    bar.abilityIcons = {}

    bar:Hide()
    return bar
end

-- 按当前任务更新进度条左侧的技能图标列表。
local function UpdateAbilityIcons(bar, abilities)
    local textures = {}
    for _, ability in ipairs(abilities) do
        local texture = GetAbilityTexture(ability)
        if texture then
            textures[#textures + 1] = texture
        end
    end
    for i, texture in ipairs(textures) do
        local icon = bar.abilityIcons[i]
        if not icon then
            icon = CreateFrame("Frame", nil, bar, "BackdropTemplate")
            icon:SetSize(ICON_SIZE, ICON_SIZE)
            -- icon:SetBackdrop({
            --     bgFile = "Interface\\Buttons\\WHITE8x8",
            --     edgeFile = "Interface\\Buttons\\WHITE8x8",
            --     edgeSize = 1,
            -- })
            -- icon:SetBackdropColor(0, 0, 0, 1)
            -- icon:SetBackdropBorderColor(0, 0, 0, 1)
            icon.texture = icon:CreateTexture(nil, "ARTWORK")
            icon.texture:SetPoint("TOPLEFT", 0, -0)
            icon.texture:SetPoint("BOTTOMRIGHT", -0, 0)
            icon.texture:SetTexCoord(.07, .93, .07, .93)
            bar.abilityIcons[i] = icon
        end
        icon:ClearAllPoints()
        icon:SetPoint("RIGHT", bar, "LEFT",
            -ICON_GAP - (#textures - i) * (ICON_SIZE + ICON_SPACING), 0)
        icon.texture:SetTexture(texture)
        icon:Show()
    end
    for i = #textures + 1, #bar.abilityIcons do
        bar.abilityIcons[i]:Hide()
    end
end

-- 根据剩余时间在黄色和最后三秒红色之间切换填充色。
local function UpdateBarColor(bar, remaining)
    local isLowTime = remaining < 3
    if bar.isLowTime == isLowTime then return end
    bar.isLowTime = isLowTime
    if isLowTime then
        bar:SetStatusBarColor(unpack(BAR_COLOR_LOW_TIME))
    else
        bar:SetStatusBarColor(unpack(BAR_COLOR_NORMAL))
    end
end

-- 获取指定玩家正在使用的进度条，没有时从对象池创建或取出。
local function AcquireBar(player)
    local bar = Receiver.bars[player]
    if bar then return bar end
    bar = tremove(Receiver.barPool) or CreateBar()
    bar.player = player
    Receiver.bars[player] = bar
    return bar
end

-- 释放指定玩家的进度条并放回对象池。
local function ReleaseBar(player)
    local bar = Receiver.bars[player]
    if not bar then return end
    Receiver.bars[player] = nil
    bar.player = nil
    bar.task = nil
    bar.isLowTime = nil
    bar:Hide()
    bar:ClearAllPoints()
    Receiver.barPool[#Receiver.barPool + 1] = bar
end

-- 根据接收端设置和玩家身份判断任务是否应显示。
local function ShouldShowTask(task)
    if BiaoGe.options.boardReceiverEnabled ~= 1 then return false end
    local mode = tonumber(BiaoGe.options.boardReceiverWhoShow) or 1
    if task.isMe then return true end
    if mode == 3 then return false end
    if mode == 1 and not ImLeader() then return false end
    return true
end

-- 从指定玩家的任务中选择当前最优先显示的一项。
local function GetFirstVisibleTask(player)
    if Receiver.previewTasks and Receiver.previewTasks[player] then
        return Receiver.previewTasks[player]
    end
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

-- 重新排序和定位所有可见进度条，并控制锚点框架状态。
local function ReflowBars()
    local list = {}
    for _, bar in pairs(Receiver.bars) do
        if bar:IsShown() and bar.task then
            list[#list + 1] = bar
        end
    end
    -- 预览条按示例序号优先排列；真实任务本人优先，其余按到期时间、玩家名排序。
    sort(list, function(a, b)
        if a.task.isPreview and b.task.isPreview then
            return a.task.previewOrder < b.task.previewOrder
        elseif a.task.isPreview ~= b.task.isPreview then
            return a.task.isPreview
        end
        if a.task.isMe ~= b.task.isMe then
            return a.task.isMe
        end
        if a.task.expirationTime ~= b.task.expirationTime then
            return a.task.expirationTime < b.task.expirationTime
        end
        return a.player < b.player
    end)
    local previewMode = Receiver.previewTasks ~= nil
    local normalStrata = BiaoGe.options.boardReceiverFrameStrata or "HIGH"
    Receiver.frame:SetFrameStrata(previewMode and PREVIEW_FRAME_STRATA or normalStrata)
    Receiver.frame:SetFrameLevel(previewMode and PREVIEW_FRAME_LEVEL or Receiver.frame.normalFrameLevel)
    -- 第一条位于锚点，后续进度条使用正 Y 偏移从下往上生成。
    for i, bar in ipairs(list) do
        local isPreview = bar.task and bar.task.isPreview
        bar:ClearAllPoints()
        bar:SetPoint("BOTTOM", Receiver.frame, "BOTTOM", 0, (i - 1) * (BAR_HEIGHT + BAR_SPACING))
        bar:EnableMouse(isPreview or false)
        bar:SetFrameStrata(isPreview and PREVIEW_FRAME_STRATA or normalStrata)
        bar:SetFrameLevel(isPreview and PREVIEW_FRAME_LEVEL or bar.normalFrameLevel)
        bar.border:SetFrameLevel(isPreview and PREVIEW_FRAME_LEVEL + 2 or bar.border.normalFrameLevel)
    end
    Receiver.visibleBarCount = #list
    Receiver.frame:EnableMouse(false)
    Receiver.frame:SetShown(#list > 0)
    if #list > 0 then
        Receiver.frame:SetScript("OnUpdate", Receiver.OnUpdate)
    else
        Receiver.frame:SetScript("OnUpdate", nil)
    end
end

-- 刷新指定玩家的进度条内容、图标、颜色和初始进度。
local function RefreshPlayer(player)
    local task = GetFirstVisibleTask(player)
    if not task then
        ReleaseBar(player)
        return
    end
    local bar = AcquireBar(player)
    bar.task = task
    local playerText = GetPlayerDisplayText(task.player)
    local previewText = task.isPreview and "|cffff0000" .. L["（测试）"] .. "|r" or ""
    local targetText = task.target and " => " .. GetPlayerDisplayText(task.target) or ""
    bar.text:SetText("#" .. task.index .. " " .. playerText .. previewText .. targetText)
    UpdateAbilityIcons(bar, task.abilities)
    bar:Show()
    local remaining = max(0, task.expirationTime - GetTime())
    local displayDuration = task.displayDuration or task.duration
    bar:SetMinMaxValues(0, max(.01, displayDuration))
    bar:SetValue(max(0, displayDuration - remaining))
    UpdateBarColor(bar, remaining)
    if remaining <= 0 then
        bar.timeText:SetText(L["随时"])
    else
        bar.timeText:SetText(format("%.1f", remaining))
    end
end

-- 刷新所有玩家的进度条并释放不再需要的条目。
local function RefreshAll()
    local players = {}
    if Receiver.previewTasks then
        for player in pairs(Receiver.previewTasks) do
            players[player] = true
            RefreshPlayer(player)
        end
    end
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

-- 删除一个任务，取消相关计时器并按需刷新界面。
local function RemoveTask(task, skipRefresh)
    if not task or task.removed then return end
    task.removed = true
    CancelTimer(task.showTimer)
    CancelTimer(task.expiryTimer)
    CancelTimer(task.castVoiceTimer)
    CancelTimer(task.prepareVoiceTimer)
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

-- 删除指定首领技能关联的全部减伤任务。
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

-- 删除全部减伤任务并隐藏所有进度条。
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

-- 由团长或助理向责任人发送一次减伤密语提醒。
local function SendWhisper(task, remaining, now)
    if task.removed or BiaoGe.options.boardReceiverEnabled ~= 1 or
        BiaoGe.options.boardReceiverWhisper ~= 1 then
        return
    end
    if not ImLeader() or not IsMe(task.sender, Receiver.myName) then return end
    if not UnitInRaid(task.player) then return end
    local links = GetAbilityLinks(task.abilities)
    if now then
        SendChatMessage(format(L["提醒：你需立刻施放%s"], links), "WHISPER", nil, task.player)
    else
        SendChatMessage(format(L["提醒：%s秒后你需施放%s"], remaining, links), "WHISPER", nil, task.player)
    end
end

-- 根据任务时长安排提前提醒和最后一秒密语。
local function ScheduleWhisper(task)
    local remaining
    if task.now then
        remaining = 1
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
    -- 到达预定提醒时间时发送首次密语。
    local timer = C_Timer.NewTimer(delay, function()
        if task.removed then return end
        SendWhisper(task, remaining, task.now)
        if remaining > 1 and not task.now then
            -- 首次提前提醒后，在剩余一秒时再次提醒。
            local finalTimer = C_Timer.NewTimer(remaining - 1, function()
                SendWhisper(task, 1, false)
            end)
            task.notificationTimers[#task.notificationTimers + 1] = finalTimer
        end
    end)
    task.notificationTimers[#task.notificationTimers + 1] = timer
end

-- 激活已进入提前显示时间范围的任务，并安排本人的语音提醒。
local function ActivateTask(task)
    if task.removed then return end
    task.active = true
    task.showTimer = nil
    task.displayDuration = max(.01, task.expirationTime - GetTime())
    if task.isMe and BiaoGe.options.boardReceiverEnabled == 1 and
        BiaoGe.options.boardReceiverVoice == 1 then
        local remaining = max(0, task.expirationTime - GetTime())
        if task.now then
            -- now 任务进入最后一秒后播放施放提示。
            task.castVoiceTimer = C_Timer.NewTimer(max(0, remaining - 1), function()
                if not task.removed and BiaoGe.options.boardReceiverEnabled == 1 and
                    BiaoGe.options.boardReceiverVoice == 1 then
                    SpeakText(L["交技能"])
                end
            end)
        else
            -- 非 now 任务进入最后三秒后播放技能准备提示。
            task.prepareVoiceTimer = C_Timer.NewTimer(max(0, remaining - 3), function()
                if not task.removed and BiaoGe.options.boardReceiverEnabled == 1 and
                    BiaoGe.options.boardReceiverVoice == 1 then
                    SpeakText(L["技能准备"])
                end
            end)
        end
    end
    RefreshPlayer(task.player)
    ReflowBars()
end

-- 创建并登记一项减伤任务，同时安排显示、隐藏和提醒计时器。
local function AddTask(sender, bossSpellID, index, player, duration, abilities, autoHide, now, target)
    if BiaoGe.options.boardReceiverEnabled ~= 1 then return end
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
        autoHide = autoHide,
        now = now,
        target = target,
        isMe = IsMe(player, Receiver.myName),
    }
    Receiver.tasks[key] = task
    Receiver.tasksByBoss[bossSpellID] = Receiver.tasksByBoss[bossSpellID] or {}
    Receiver.tasksByBoss[bossSpellID][key] = task
    Receiver.tasksByPlayer[player] = Receiver.tasksByPlayer[player] or {}
    Receiver.tasksByPlayer[player][key] = task

    if autoHide then
        -- 自动隐藏任务在持续时间结束后直接移除。
        task.expiryTimer = C_Timer.NewTimer(duration, function()
            RemoveTask(task)
        end)
    end

    local remainingTime = tonumber(BiaoGe.options.boardReceiverRemainingTime) or 10
    if duration > remainingTime then
        -- 较远的任务延迟到设定的最后若干秒再显示。
        task.showTimer = C_Timer.NewTimer(duration - remainingTime, function()
            ActivateTask(task)
        end)
    else
        ActivateTask(task)
    end
    ScheduleWhisper(task)
end

-- 解析并处理 show、hide 和 hideAll 三类减伤链消息。
local function HandleBoardMessage(message, sender)
    if type(message) ~= "string" or #message > 255 then return end
    local msgType, bossSpellID, index, player, duration, abilityText, autoHide, now, target =
        strsplit(",", message)
    if msgType == "show" then
        bossSpellID = tonumber(bossSpellID)
        index = tonumber(index)
        duration = tonumber(duration)
        local abilities = ParseAbilityIDs(abilityText)
        if not bossSpellID or not index or not duration or duration < 0 or duration > 3600 or
            type(player) ~= "string" or player == "" or #player > 80 or not abilities then
            return
        end
        if target == "" then
            target = nil
        elseif target and (type(target) ~= "string" or #target > 80) then
            return
        end
        sender = BG.GSN(sender)
        player = BG.GSN(player)
        if target then
            target = BG.GSN(target)
        end
        AddTask(sender, bossSpellID, index, player, duration, abilities,
            autoHide == "autoHide", now == "now", target)
    elseif msgType == "hide" then
        bossSpellID = tonumber(bossSpellID)
        if bossSpellID then
            HideBoss(bossSpellID)
        end
    elseif msgType == "hideAll" then
        HideAll()
    end
end

-- 每帧更新进度填充，并按较低频率更新倒计时文字。
function Receiver.OnUpdate(_, elapsed)
    Receiver.updateElapsed = (Receiver.updateElapsed or 0) + elapsed
    local updateText = Receiver.updateElapsed >= .05
    if updateText then
        Receiver.updateElapsed = Receiver.updateElapsed % .05
    end
    local now = GetTime()
    local expired = {}
    for _, bar in pairs(Receiver.bars) do
        local task = bar.task
        if task and not task.removed then
            local remaining = max(0, task.expirationTime - now)
            if task.isPreview and remaining <= 0 then
                task.expirationTime = now + task.duration
                remaining = task.duration
            end
            local displayDuration = task.displayDuration or task.duration
            bar:SetValue(max(0, displayDuration - remaining))
            UpdateBarColor(bar, remaining)
            if updateText or remaining <= 0 then
                if remaining <= 0 then
                    bar.timeText:SetText(L["随时"])
                else
                    bar.timeText:SetText(format("%.1f", remaining))
                end
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

-- 应用启用状态、显示范围、缩放和 UI 层级等接收端设置。
function BG.UpdateBoardReceiverSettings()
    if not Receiver.frame then return end
    if InCombatLockdown and InCombatLockdown() then return end
    Receiver.frame:SetScale(tonumber(BiaoGe.options.boardReceiverScale) or 1)
    if BiaoGe.options.boardReceiverEnabled ~= 1 then
        HideAll()
    end
    RefreshAll()
end

-- 清除已保存位置并恢复默认锚点。
function BG.ResetBoardReceiverPosition()
    if InCombatLockdown and InCombatLockdown() then return end
    BiaoGe.options.boardReceiverPoint = nil
    RestoreAnchorPoint()
end

-- 显示通知移动模式使用的两条循环示例进度条，不创建真实减伤任务。
function BG.ShowBoardReceiverMovePreview()
    if not Receiver.frame then return end
    local duration = 10
    local expirationTime = GetTime() + duration
    Receiver.previewTasks = {
        boardReceiverPreview1 = {
            player = Receiver.myName,
            index = 1,
            duration = duration,
            expirationTime = expirationTime,
            abilities = {
                { texture = 135966 },
            },
            isMe = true,
            isPreview = true,
            previewOrder = 1,
        },
        boardReceiverPreview2 = {
            player = L["玩家A"],
            index = 2,
            duration = duration,
            expirationTime = expirationTime,
            abilities = {
                { texture = 135966 },
            },
            isMe = false,
            isPreview = true,
            previewOrder = 2,
        },
    }
    RefreshAll()
end

-- 退出通知移动模式并恢复真实任务的进度条显示。
function BG.HideBoardReceiverMovePreview()
    if not Receiver.previewTasks then return end
    StopReceiverDrag()
    Receiver.previewTasks = nil
    RefreshAll()
end

-- 初始化默认设置、玩家信息和进度条锚点框架。
BG.Init(function()
    local defaults = {
        boardReceiverEnabled = 1,
        boardReceiverWhoShow = 1,
        boardReceiverRemainingTime = 10,
        boardReceiverVoice = 1,
        boardReceiverWhisper = 1,
        boardReceiverScale = 1,
        boardReceiverFrameStrata = "MEDIUM",
    }
    for name, value in pairs(defaults) do
        BG.options[name .. "reset"] = value
        if BiaoGe.options[name] == nil then
            BiaoGe.options[name] = value
        end
    end
    Receiver.myName = BG.playerName
    CreateAnchorFrame()
    BG.UpdateBoardReceiverSettings()
end)

-- 接收并校验团队频道中的减伤链插件消息。
BG.RegisterEvent("CHAT_MSG_ADDON", function(_, _, prefix, message, distribution, _, sender)
    if distribution ~= "RAID" then return end
    if not BOARD_PREFIXES[prefix] then return end
    if not IsLeader(sender) then return end
    HandleBoardMessage(message, sender)
end)

-- 进入或结束战斗场景时清空全部减伤任务。
BG.RegisterEvent({ "ENCOUNTER_START", "ENCOUNTER_END", "RAID_INSTANCE_WELCOME" }, function()
    HideAll()
end)

-- 进入战斗时立即终止可能正在进行的预览条拖动。
BG.RegisterEvent("PLAYER_REGEN_DISABLED", function()
    StopReceiverDrag()
end)
