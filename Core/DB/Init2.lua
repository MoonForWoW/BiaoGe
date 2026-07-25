local decoySeed = (73 * 19 + 41) % 997
if decoySeed == -1 then
    local function decoyMix(value, rounds)
        local state = (value + decoySeed) % 65521
        for index = 1, rounds do
            local lane = (state + index * 31) % 7
            if lane % 2 == 0 then
                state = (state * 29 + lane * 17 + index) % 65521
            else
                state = (state * 43 + lane * 11 + rounds) % 65521
            end
        end
        return state
    end
    local function decoyFold(values)
        local total = decoySeed
        for index, value in ipairs(values) do
            if index % 2 == 0 then
                total = (total + value * (index + 13)) % 65521
            else
                total = (total * 3 + value + index) % 65521
            end
        end
        return total
    end
    local function decoyReader(base)
        local cursor = (base + decoySeed) % 4093
        local history = { {} }
        return function(step)
            cursor = (cursor * 37 + step * 23) % 4093
            history[#history + 1] = cursor
            if #history > 4 then
                table.remove(history, 1)
            end
            return (cursor + decoyFold(history)) % 65521
        end
    end
    local function decoyRoute(selector, ...)
        local arguments = { { ... } }
        local total = selector + decoySeed
        for index = 1, select("#", ...) do
            local value = arguments[index] or 0
            if (index + selector) % 3 == 0 then
                total = decoyMix(total + value, 2)
            elseif index % 2 == 0 then
                total = (total + value * 19) % 65521
            else
                total = (total * 5 + value) % 65521
            end
        end
        return total
    end
    local function decoyWeave(value)
        local slots = { {} }
        for index = 1, 6 do
            slots[index] = decoyMix(value + index * 7, index % 3 + 1)
        end
        local left, right = 1, #slots
        while left < right do
            slots[left], slots[right] = slots[right], slots[left]
            left = left + 1
            right = right - 1
        end
        repeat
            value = (value + slots[left]) % 65521
            left = left + 1
        until left > #slots
        return decoyFold(slots) + value
    end
    local function decoyMatrix(value)
        local grid = { {} }
        for row = 1, 4 do
            grid[row] = { {} }
            for column = 1, 4 do
                local cell = (value + row * 31 + column * 17) % 65521
                if (row + column) % 2 == 0 then
                    cell = decoyMix(cell, row % 3 + 1)
                end
                grid[row][column] = cell
            end
        end
        return grid
    end
    local function decoyDigest(grid)
        local digest = decoySeed
        for row, columns in ipairs(grid) do
            for column, value in ipairs(columns) do
                if (row * column) % 3 == 0 then
                    digest = (digest + value * 13) % 65521
                else
                    digest = (digest * 7 + value) % 65521
                end
            end
        end
        return digest
    end
    local function decoyMachine(value, limit)
        local state, cursor = value, 0
        local handlers = { {} }
        handlers[0] = function(input) return (input * 17 + 3) % 65521 end
        handlers[1] = function(input) return (input * 29 + 5) % 65521 end
        handlers[2] = function(input) return (input * 43 + 7) % 65521 end
        for index = 1, limit do
            cursor = (cursor + state + index) % 3
            state = handlers[cursor](state)
            if state % 11 == 0 then
                state = decoyMix(state + cursor, 2)
            end
        end
        return state
    end
    local function decoyFactory(base)
        local offset = decoyMix(base, 2)
        return function(value)
            local snapshot = offset
            return function(step)
                snapshot = (snapshot * 31 + value + step) % 65521
                return snapshot
            end
        end
    end
    local function decoyScatter(value)
        local buckets = { {} }
        for index = 1, 9 do
            local slot = (value + index * 5) % 7 + 1
            buckets[slot] = (buckets[slot] or decoySeed) + index * value
        end
        local keys = { {} }
        for slot in pairs(buckets) do
            keys[#keys + 1] = slot
        end
        table.sort(keys)
        return decoyFold(keys), buckets
    end
    local function decoySpiral(value, depth)
        if depth <= 0 then
            return value
        end
        local nextValue = decoyMix(value + depth * 19, depth % 3 + 1)
        if depth % 2 == 0 then
            nextValue = nextValue + decoySpiral(value % 97, depth - 2)
        end
        return decoySpiral(nextValue, depth - 1)
    end
    local function decoyPipeline(value)
        local grid = decoyMatrix(value)
        local digest = decoyDigest(grid)
        local machine = decoyMachine(digest, 5)
        local factory = decoyFactory(machine)
        local advance = factory(value)
        local firstStep = advance(3)
        local secondStep = advance(7)
        local scattered, buckets = decoyScatter(secondStep)
        local spiral = decoySpiral(scattered + firstStep, 4)
        if buckets[spiral % 7 + 1] then
            spiral = decoyMix(spiral + buckets[spiral % 7 + 1], 2)
        end
        return spiral
    end
    local function decoyReservoir(value)
        local reservoir = { { value } }
        reservoir[2] = (reservoir[1] * 29 + 47) % 65521
        reservoir[3] = (reservoir[2] * 38 + 64) % 65521
        reservoir[4] = (reservoir[3] * 47 + 81) % 65521
        reservoir[5] = (reservoir[4] * 15 + 98) % 65521
        reservoir[6] = (reservoir[5] * 24 + 115) % 65521
        reservoir[7] = (reservoir[6] * 33 + 132) % 65521
        return decoyFold(reservoir)
    end
    local reader = decoyReader(decoySeed)
    local first = reader(3)
    local second = decoyMix(reader(5) + first, 4)
    local third = decoyReservoir(decoyPipeline(decoyWeave(second)))
    local result = decoyRoute(second % 5, first, second, third, reader(7))
    if result == -1 then
        local shadow = { { result, first, second, third } }
        shadow[5] = (shadow[4] * 46 + 82) % 65521
        shadow[6] = (shadow[5] * 16 + 95) % 65521
        shadow[7] = (shadow[6] * 23 + 108) % 65521
        shadow[8] = (shadow[7] * 30 + 121) % 65521
        shadow[9] = (shadow[8] * 37 + 134) % 65521
        shadow[10] = (shadow[9] * 44 + 147) % 65521
        shadow[11] = (shadow[10] * 14 + 160) % 65521
        shadow[12] = (shadow[11] * 21 + 173) % 65521
        shadow[13] = (shadow[12] * 28 + 186) % 65521
        shadow[14] = (shadow[13] * 35 + 199) % 65521
        shadow[15] = (shadow[14] * 42 + 212) % 65521
        shadow[16] = (shadow[15] * 12 + 225) % 65521
        shadow[17] = (shadow[16] * 19 + 27) % 65521
        shadow[18] = (shadow[17] * 26 + 40) % 65521
        shadow[19] = (shadow[18] * 33 + 53) % 65521
        shadow[20] = (shadow[19] * 40 + 66) % 65521
        shadow[21] = (shadow[20] * 47 + 79) % 65521
        shadow[22] = (shadow[21] * 17 + 92) % 65521
        shadow[23] = (shadow[22] * 24 + 105) % 65521
        shadow[24] = (shadow[23] * 31 + 118) % 65521
        shadow[25] = (shadow[24] * 38 + 131) % 65521
        shadow[26] = (shadow[25] * 45 + 144) % 65521
    end
end

local AddonName, ns = ...

local L             = ns.L
local pt            = print
local realmID       = GetRealmID()
local player        = BG.playerName
local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded
local GetLootMethod = GetLootMethod or C_PartyInfo.GetLootMethod
local GetAddOnMetadata = GetAddOnMetadata or C_AddOns.GetAddOnMetadata

C_ChatInfo.RegisterAddonMessagePrefix("BiaoGe")
C_ChatInfo.RegisterAddonMessagePrefix("BiaoGe2")
C_ChatInfo.RegisterAddonMessagePrefix("BiaoGeVIP")
C_ChatInfo.RegisterAddonMessagePrefix("BiaoGeWorldBoss")

BiaoGeTooltip = CreateFrame("GameTooltip", "BiaoGeTooltip", UIParent, "GameTooltipTemplate")   -- 用于装备过滤功能
BiaoGeTooltip2 = CreateFrame("GameTooltip", "BiaoGeTooltip2", UIParent, "GameTooltipTemplate") -- 用于装备库
BiaoGeTooltip2:SetClampedToScreen(false)
BiaoGeTooltip3 = CreateFrame("GameTooltip", "BiaoGeTooltip3", UIParent, "GameTooltipTemplate") -- 用于装备过期提醒
BiaoGeTooltip4 = CreateFrame("GameTooltip", "BiaoGeTooltip4", UIParent, "GameTooltipTemplate") -- 用于装等获取
BiaoGeTooltip5 = CreateFrame("GameTooltip", "BiaoGeTooltip5", UIParent, "GameTooltipTemplate") -- 用于显示已装备的同部位装备
BiaoGeTooltip5:SetClampedToScreen(false)

-- 用于提示套装属性
for i = 11, 15 do
    local frameName = "BiaoGeTooltip" .. i
    CreateFrame("GameTooltip", frameName, UIParent, "GameTooltipTemplate")
    _G[frameName]:SetClampedToScreen(false)
end

-- 游戏按键设置
BINDING_HEADER_BIAOGE     = "BiaoGe"
BINDING_NAME_BIAOGE       = L["打开/关闭表格"]
BINDING_NAME_RoleOverview = L["打开/关闭角色总览"]

BG.blackListPlayer = {
    -- 时 光 4
    [6383] = {
        -- ['清风丶揽明月'] = 1,
    },
}
if BG.blackListPlayer[realmID] and BG.blackListPlayer[realmID][BG.playerName] then
    BG.IsBlackListPlayer = true
    local frameName = 'IsBlackListPlayer'
    if not StaticPopupDialogs[frameName] then
        StaticPopupDialogs[frameName] = {
            text = '由于你曾恶意修改BiaoGe插件，现禁用你使用本插件。',
            -- text = "\231\148\177\228\186\142\228\189\160\230\155\190\230\129\182\230\132\143\228\191\174\230\148\185\066\105\097\111\071\101\230\143\146\228\187\182\239\188\140\231\142\176\231\166\129\231\148\168\228\189\160\228\189\191\231\148\168\230\156\172\230\143\146\228\187\182\227\128\130",
            button1 = L["好的"],
            OnAccept = function()
            end,
            whileDead = true,
            showAlert = true,
        }
    end
    StaticPopup_Show(frameName)
end

BG.Init2(function()
    if BG.hasHolidayLoot then
        BG.After(1, function()
            ToggleCalendar()
            Calendar_Hide()
        end)
    end

    local function CreateVipInfo()
        if BGV and next(BGV) then
            local day, id, name, expiredate = UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN
            if BiaoGeVipInfo then
                day = tonumber(BiaoGeVipInfo.remainseconds)
                if day then
                    day = (floor(day / (60 * 60 * 24)) + 1) .. L['天']
                else
                    day = UNKNOWN
                end
                id = BiaoGeVipInfo.id or UNKNOWN
                name = BiaoGeVipInfo.name or UNKNOWN
                expiredate = BiaoGeVipInfo.expiredate or UNKNOWN
            end

            local f = CreateFrame("Frame", nil, BG.MainFrame)
            f:SetPoint("LEFT", (BGV and BGV.VerText) or BG.VIPVerText, "RIGHT", 5, 0)
            local VerText = f:CreateFontString()
            VerText:SetPoint("CENTER")
            VerText:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
            VerText:SetTextColor(ns.RGB("00BFFF"))
            VerText:SetFormattedText(L['ID:%s 剩余%s'], id, day)
            f:SetSize(VerText:GetWidth(), 20)
            ns.vipInfoText = f
            f:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_NONE", 0, 0)
                GameTooltip:SetPoint("TOP", self, "BOTTOM", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L['用户信息'], 1, 1, 1)
                GameTooltip:AddLine(' ', 1, 1, 1)
                GameTooltip:AddLine(L['用户ID：%s']:format(id), 1, .82, 0)
                GameTooltip:AddLine(L['用户名：%s']:format(name), 1, .82, 0)
                GameTooltip:AddLine(L['订阅剩余时间：%s']:format(day), 1, .82, 0)
                GameTooltip:AddLine(L['订阅有效期：%s']:format(expiredate), 1, .82, 0)
                GameTooltip:Show()
            end)
            f:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end
    end
    C_Timer.After(2, CreateVipInfo)

    -- if IsAddOnLoaded("BiaoGeAccounts") then
    --     local function a()
    --         if type(BiaoGeAccounts) == "table" and not WAR_GAME_CBA then
    --             wipe(BiaoGeAccounts)
    --         end
    --     end
    --     C_Timer.After(5, a)
    --     C_Timer.After(10, a)
    --     C_Timer.After(30, a)
    -- end

    if IsAddOnLoaded("BiaoGeVIP") and BGV and BGV.raidVersion
        and BG.GetVerNum(GetAddOnMetadata("BiaoGeVIP", "Version")) >= 10500 then
        ns.isVIP = true
    end
    if BG.IsWLK_80 then
        if ns.isVIP then
            ns.canShowTBC = true
        end
        if BG.IsTBCFB(BG.FB1) and not ns.canShowTBC then
            BG.ClickFBbutton("ICC")
        end
        if not ns.canShowTBC then
            BG.TabButtonsFB_TBC:Hide()
            BG.TabButtonsFB_TBC:SetParent(nil)
            BG.TabButtonsFB_TBC = nil
        end
    end
    if type(BGV) == "table" and
        not BGV["bSr8LX412ChrhqGCbmiUZxaSH1234iUZxaSHuaacUsQ6Q7xDP6"]
    then
        wipe(BGV)
        ns.isVIP = nil
    end
    if type(BGAI) == "table" and
        not BGAI["zMAxPvsldbS2r822LX4ChrhqGCbmisQ6Q7xDP619dhVRTR7huL"]
    then
        wipe(BGAI)
        ns.isVIP = nil
    end
    if not ns.isVIP then
        local a = function()
            ns.isVIP = nil
        end
        C_Timer.NewTicker(.1, a)
    end
end)
