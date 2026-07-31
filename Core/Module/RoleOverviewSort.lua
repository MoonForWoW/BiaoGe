if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local L = ns.L
local Round = ns.Round
local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded

local realmID = GetRealmID()
local player = BG.playerName
local class = select(2, UnitClass("player"))
local MONEY = "MONEY"

local mainFrame
local info = {}
local buttons = {}
local position = {}
local height = 20
local width = 150
local h = 50
local w = 15
local maxCount = 20
local chooseID
local chooseBT
local dragOffsetX
local dragOffsetY
local defaultBackground = { 0.25, 0.25, 0.25, 0.3 }
local selectedBackground = { 1, 1, 0, 0.8 }

local function DefaultSort(a, b)
    for _, key in ipairs({ "iLevel", "class", "player" }) do
        local aValue = a[key] or (key == "iLevel" and 0 or "")
        local bValue = b[key] or (key == "iLevel" and 0 or "")
        if aValue ~= bValue then
            return aValue > bValue
        end
    end
    return false
end

local function GetSortDB()
    BiaoGe.RoleOverviewSort = BiaoGe.RoleOverviewSort or {}
    BiaoGe.RoleOverviewSort[realmID] = BiaoGe.RoleOverviewSort[realmID] or {}
    return BiaoGe.RoleOverviewSort[realmID]
end

local function SetButtonPoint(f, i)
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", mainFrame, "TOPLEFT",
        w + floor((i - 1) / maxCount) * width,
        -h - floor((i - 1) % maxCount) * height)
end

local function RefreshPosition()
    wipe(position)
    for i, f in ipairs(buttons) do
        position[i] = {
            top = f:GetTop(),
            bottom = f:GetBottom(),
            left = f:GetLeft(),
            right = f:GetRight(),
        }
    end
end

local function OnUpdate()
    local uiScale, cursorX, cursorY = UIParent:GetEffectiveScale(), GetCursorPosition()
    local x, y = cursorX / uiScale, cursorY / uiScale
    local isRemove
    for i = #buttons, 1, -1 do
        local p = position[i]
        if i ~= chooseID and p and x > p.left and x < p.right and y < p.top and y > p.bottom then
            tremove(buttons, chooseID)
            chooseID = i
            isRemove = true
            break
        end
    end
    if isRemove then
        tinsert(buttons, chooseID, chooseBT)
    end
    for i, f in ipairs(buttons) do
        if i == chooseID then
            f:ClearAllPoints()
            f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x - dragOffsetX, y - dragOffsetY)
        else
            SetButtonPoint(f, i)
        end
    end
end

local function OnMouseDown(self)
    BG.PlaySound(1)
    chooseID = self.i
    chooseBT = self
    local uiScale, cursorX, cursorY = UIParent:GetEffectiveScale(), GetCursorPosition()
    dragOffsetX = cursorX / uiScale - self:GetLeft()
    dragOffsetY = cursorY / uiScale - self:GetBottom()
    self:SetBackdropColor(unpack(selectedBackground))
    self:SetFrameLevel(mainFrame:GetFrameLevel() + 2)
    mainFrame:SetScript("OnUpdate", OnUpdate)
end

local function OnMouseUp()
    BG.PlaySound(1)
    mainFrame:SetScript("OnUpdate", nil)
    local sortDB = GetSortDB()
    wipe(sortDB)
    for i, f in ipairs(buttons) do
        f:SetFrameLevel(mainFrame:GetFrameLevel() + 1)
        SetButtonPoint(f, i)
        f.i = i
        sortDB[i] = {
            player = f.player,
            colorplayer = f.colorplayer,
            class = f.class,
            talent = f.talent,
            iLevel = f.iLevel,
        }
    end
    RefreshPosition()
    chooseBT:SetBackdropColor(unpack(defaultBackground))
    chooseID = nil
    chooseBT = nil
    dragOffsetX = nil
    dragOffsetY = nil
    BG.RefreshFBCDFrame()
end

local function CreateButton(i)
    local sortDB = GetSortDB()
    local v = sortDB[i]
    local f = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    f:SetBackdrop({
        bgFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeSize = 1,
    })
    f:SetBackdropColor(unpack(defaultBackground))
    f:SetBackdropBorderColor(1, 1, 1, .8)
    f:SetSize(width, height)
    f:EnableMouse(true)
    SetButtonPoint(f, i)
    f.i = i
    f.player = v.player
    f.colorplayer = v.colorplayer
    f.class = v.class
    f.talent = v.talent
    f.iLevel = v.iLevel

    f.Text = f:CreateFontString()
    f.Text:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
    f.Text:SetPoint("CENTER")
    f.Text:SetText(BG.GetTalentIcon(v.class, v.talent, 13) ..
        v.colorplayer .. "|cff808080 (" .. Round(v.iLevel) .. ")|r")
    f.Text:SetWidth(width - 5)
    f.Text:SetJustifyH("LEFT")
    f.Text:SetWordWrap(false)
    tinsert(buttons, f)

    if (i - 1) % maxCount == 0 then
        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
        t:SetWidth(width)
        t:SetPoint("BOTTOMLEFT", mainFrame, "TOPLEFT", w + floor((i - 1) / maxCount) * width, -h + 2)
        t:SetTextColor(1, 0.82, 0)
        if #sortDB <= maxCount then
            t:SetText(i .. " - " .. #sortDB)
        else
            t:SetText(i .. " - " .. min(i + maxCount - 1, #sortDB))
        end
    end

    if mainFrame.delete then
        if v.no then
            local bt = CreateFrame("Button", nil, f)
            bt:SetSize(15, 15)
            bt:SetPoint("RIGHT", -2, 0)
            bt:SetNormalTexture("interface/raidframe/readycheck-notready")
            bt:SetHighlightTexture("interface/raidframe/readycheck-notready")
            bt:RegisterForClicks("AnyUp")
            bt:SetScript("OnClick", function()
                BG.PlaySound(1)
                tremove(GetSortDB(), f.i)
                BG.CreateRoleOverviewSortFrame(nil, true)
            end)
        end
    else
        f:SetScript("OnMouseDown", OnMouseDown)
        f:SetScript("OnMouseUp", OnMouseUp)
    end
end

local function GetDB()
    local function AddDB(db, isAccounts)
        if not (db and db[MONEY] and db[MONEY][realmID]) then return end
        for playerName in pairs(db[MONEY][realmID]) do
            local localMoneyDB = BiaoGe[MONEY] and BiaoGe[MONEY][realmID]
            if not isAccounts or not (localMoneyDB and localMoneyDB[playerName]) then
                local playerInfo = db.playerInfo and db.playerInfo[realmID] and db.playerInfo[realmID][playerName]
                local level = playerInfo and playerInfo.level
                if level then
                    local classFile = playerInfo.class
                    local iLevel = playerInfo.iLevel or
                        (db.PlayerItemsLevel and db.PlayerItemsLevel[realmID] and db.PlayerItemsLevel[realmID][playerName])
                    local classColor = classFile and select(4, GetClassColor(classFile))
                    if classColor and iLevel then
                        tinsert(info, {
                            player = playerName,
                            colorplayer = "|c" .. classColor .. playerName .. (isAccounts and "*" or ""),
                            class = classFile,
                            talent = playerInfo.talent,
                            iLevel = iLevel,
                        })
                    end
                end
            end
        end
    end
    AddDB(BiaoGe)
    AddDB(BiaoGeAccounts, true)
end

local function AddCurrentPlayer(tbl, saveClass)
    for _, v in ipairs(tbl) do
        if v.player == player then
            return
        end
    end
    local classColor = class and select(4, GetClassColor(class))
    local playerInfo = BiaoGe.playerInfo and BiaoGe.playerInfo[realmID] and BiaoGe.playerInfo[realmID][player]
    local iLevel = playerInfo and playerInfo.iLevel or
        (BiaoGe.PlayerItemsLevel and BiaoGe.PlayerItemsLevel[realmID] and BiaoGe.PlayerItemsLevel[realmID][player])
    if classColor and iLevel then
        tinsert(tbl, {
            player = player,
            colorplayer = "|c" .. classColor .. player,
            class = saveClass and class or nil,
            talent = playerInfo and playerInfo.talent,
            iLevel = iLevel,
        })
    end
end

function BG.InitializeRoleOverviewCustomSort()
    local sortDB = GetSortDB()
    for _, v in ipairs(sortDB) do
        if v.class then
            return
        end
    end
    wipe(info)
    GetDB()
    AddCurrentPlayer(info, true)
    sort(info, DefaultSort)
    BiaoGe.RoleOverviewSort[realmID] = BG.Copy(info)
end

function BG.CreateRoleOverviewSortFrame(bt, update)
    if mainFrame then
        mainFrame:Hide()
    end
    if not BG.RoleOverviewSortFrame then
        local f = CreateFrame("Frame", "BGRoleOverviewSortFrame", UIParent, "BackdropTemplate")
        f:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 16,
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0, 0, 0, 0.9)
        f:SetBackdropBorderColor(1, 1, 1, 1)
        f:SetFrameStrata("HIGH")
        f:EnableMouse(true)
        f:SetMovable(true)
        f:SetToplevel(true)
        f:SetScript("OnMouseUp", function(self)
            self:StopMovingOrSizing()
            RefreshPosition()
        end)
        f:SetScript("OnMouseDown", function(self)
            self:StartMoving()
        end)
        mainFrame = f
        BG.RoleOverviewSortFrame = f
        tinsert(UISpecialFrames, "BGRoleOverviewSortFrame")

        f.CloseButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        f.CloseButton:SetPoint("TOPRIGHT", 2, 2)

        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetPoint("TOP", 0, -7)
        t:SetText(L["角色自定义排序"])

        f.deleteBT = BG.CreateButton(f)
        f.deleteBT:SetSize(80, 20)
        f.deleteBT:SetPoint("BOTTOM", 0, 10)
        f.deleteBT:SetShown(IsAddOnLoaded('BiaoGeAccounts'))
        f.deleteBT:SetScript("OnClick", function()
            BG.PlaySound(1)
            mainFrame.delete = not mainFrame.delete
            BG.CreateRoleOverviewSortFrame(nil, true)
        end)
        f.deleteBT:SetScript("OnEnter", function(self)
            if mainFrame.delete then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
            GameTooltip:AddLine(L["排序列表里记录着来自同步模块中其他子账号的角色，有一些角色可能已经不存在。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(" ", 1, 0.82, 0, true)
            GameTooltip:AddLine(L["如果你想删除这些角色，点击按钮后会在可删除角色后面显示一个删除按钮。"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        f.deleteBT:SetScript("OnLeave", GameTooltip_Hide)
    end

    mainFrame:Show()
    if not update then
        mainFrame.delete = nil
        mainFrame:ClearAllPoints()
        if bt then
            mainFrame:SetPoint("BOTTOM", bt, "TOP", 0, 5)
        else
            mainFrame:SetPoint("CENTER")
        end
    end
    if mainFrame.delete then
        mainFrame:SetBackdropBorderColor(1, 0, 0, 1)
        mainFrame.deleteBT:SetText(L["取消"])
    else
        mainFrame:SetBackdropBorderColor(1, 1, 1, 1)
        mainFrame.deleteBT:SetText(L["删除角色"])
    end

    wipe(info)
    GetDB()
    local sortDB = GetSortDB()
    local isFirstCustomSort = not next(sortDB) or (#sortDB == 1 and sortDB[1].player == player)
    if next(sortDB) then
        for _, oldInfo in ipairs(sortDB) do
            oldInfo.no = true
            for i = #info, 1, -1 do
                local newInfo = info[i]
                if oldInfo.player == newInfo.player then
                    oldInfo.colorplayer = newInfo.colorplayer
                    oldInfo.class = newInfo.class
                    oldInfo.talent = newInfo.talent
                    oldInfo.iLevel = newInfo.iLevel
                    oldInfo.no = nil
                    tremove(info, i)
                    break
                end
            end
        end
        for _, newInfo in ipairs(info) do
            tinsert(sortDB, newInfo)
        end
    else
        BiaoGe.RoleOverviewSort[realmID] = BG.Copy(info)
        sortDB = BiaoGe.RoleOverviewSort[realmID]
    end
    if isFirstCustomSort then
        sort(sortDB, DefaultSort)
    end

    mainFrame:SetHeight(height * min(#sortDB, maxCount) + h + w + 30)
    local columnCount = max(1, floor((#sortDB - 1) / maxCount) + 1)
    mainFrame:SetWidth(columnCount * width + w * 2)
    for _, oldButton in ipairs(buttons) do
        oldButton:Hide()
    end
    wipe(buttons)
    for i = 1, #sortDB do
        CreateButton(i)
    end
    RefreshPosition()
end

BG.Init(function()
    local sortDB = GetSortDB()
    AddCurrentPlayer(sortDB)
end)
