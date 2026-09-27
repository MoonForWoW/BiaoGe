if BG.IsBlackListPlayer then return end
local AddonName, ns = ...
local LibBG = ns.LibBG
local L = ns.L

local RR = ns.RR
local NN = ns.NN
local RN = ns.RN

local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
if not ldb then return end

local pt = print

local plugin = ldb:NewDataObject(AddonName, { text = AddonName, type = "data source", icon = ns.Interface .. "Media\\icon\\icon" })

function plugin:OnClick(button) --function plugin.OnClick(self, button)
    if button == "LeftButton" then
        BG.MainFrame:SetShown(not BG.MainFrame:IsVisible())
    elseif button == "RightButton" then
        if SettingsPanel:IsVisible() then
            HideUIPanel(SettingsPanel)
        else
            BG.OpenOption()
            BG.MainFrame:Hide()
        end
    end
    BG.PlaySound(1)
end

function plugin:OnEnter(button)
    if BG.ButtonIsInRight(self) then
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    else
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    end
    GameTooltip:ClearLines()
    GameTooltip:AddLine(L["%s"]:format(AddonName), 0,.75, 1, true)
    GameTooltip:AddLine(L["|cffFFFFFF左键：|r打开表格"],1, 0.82, 0, true)
    GameTooltip:AddLine(L["|cffFFFFFF右键：|r打开设置"],1, 0.82, 0, true)
    GameTooltip:AddLine(L["|cffFFFFFF提示：|r角色总览功能已独立到ZongLan插件，可在各平台免费下载"], 1, 0.82, 0, true)
    GameTooltip:Show()
end

function plugin:OnLeave(button)
    if BG.FBCDFrame and not BG.FBCDFrame.click then
        BG.FBCDFrame:Hide()
    end
    GameTooltip:Hide()
end

BG.Init(function()
    local icon = LibStub("LibDBIcon-1.0", true)
    if not icon then return end

    BiaoGe.minimapPos = BiaoGe.minimapPos or 200
    icon:Register(AddonName, plugin, BiaoGe)

    C_Timer.After(1, function()
        if BiaoGe.options["miniMap"] == 0 then
            icon:Hide(AddonName)
        end
    end)
end)