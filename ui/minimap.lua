-----------------------------------------------------------------------------------------------------------------------------------
-- MINI MAP
-----------------------------------------------------------------------------------------------------------------------------------
local minimapTooltip = CreateFrame("GameTooltip", "FDMinimapTooltip", UIParent, "GameTooltipTemplate")
minimapTooltip:ClearLines()
minimapTooltip:AddFontStrings(minimapTooltip:CreateFontString("$parentTextLeft1", nil, "GameTooltipText"), minimapTooltip:CreateFontString("$parentTextRight1", nil, "GameTooltipText"))

local minimap = CreateFrame("Button", "FDMinimapButton", Minimap)
minimap:EnableMouse(true)
minimap:SetMovable(true)
minimap:SetSize(33, 33)
minimap:SetPoint("TOPLEFT")
minimap:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
minimap:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimap:RegisterForDrag("LeftButton")

local t = minimap:CreateTexture(nil, "OVERLAY")
t:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
t:SetSize(56, 56)
t:SetPoint("TOPLEFT")

local t = minimap:CreateTexture(nil, "background")
t:SetTexture("Interface\\Icons\\inv_misc_head_dragon_red")
t:SetSize(21, 21)
t:SetPoint("CENTER")

function FDKP:updateMiniMapPosition()
	if not FDKPMiniMapPosition then return end
    minimap:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 52 - (80 * cos(FDKPMiniMapPosition)), (80 * sin(FDKPMiniMapPosition)) - 52)
end

local minimapFrame = CreateFrame("FRAME", nil, minimap);
minimapFrame:SetScript("OnUpdate", function()
    local xpos, ypos = GetCursorPosition()
    local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()

    xpos = xmin - xpos / UIParent:GetScale() + 70
    ypos = ypos / UIParent:GetScale() - ymin - 70

    FDKPMiniMapPosition = math.deg(math.atan2(ypos, xpos))
    FDKP:updateMiniMapPosition()
end)
minimapFrame:Hide()

minimap:SetScript("OnDragStart", function(self)
    self:LockHighlight()
    minimapFrame:Show()
    minimapTooltip:Hide()
end);

minimap:SetScript("OnDragStop", function(self)
    self:UnlockHighlight()
    minimapFrame:Hide()
end);

minimap:SetScript("OnEnter", function()
    minimapTooltip:ClearLines()
    minimapTooltip:SetOwner(minimap, "ANCHOR_LEFT")
    local title = FDKP:format('Пламягорыш &a%s', FDKP.version)
    if FDKP.debug then
        title = title .. FDKP:colorize(' &cDEBUG')
    end
    minimapTooltip:SetText(title);
    minimapTooltip:AddLine(FDKP:colorize('&7Левая кнопка мыши: &eоткрыть/скрыть окна аукциона (если активны)'))
    minimapTooltip:AddLine(FDKP:colorize('&7Правая кнопка мыши: &eоткрыть/скрыть список и логи DKP'))
    if FDKP:isOfficer() or FDKP:isAdmin() then
        minimapTooltip:AddLine(FDKP:colorize('&7Шифт + ЛКМ: &eоткрыть/скрыть окно изменения DKP'))
        if FDKP:isAdmin() then
            minimapTooltip:AddLine(FDKP:colorize('&7Шифт + ПКМ: &eоткрыть/скрыть административное окно'))
        end
    end
    minimapTooltip:AddLine(' ')
    minimapTooltip:AddLine(FDKP:colorize('&3Специально для гильдий орды Пламегора :)'))
    minimapTooltip:Show();
end);

minimap:SetScript("OnLeave", function()
    minimapTooltip:Hide();
end);

minimap:SetScript("OnClick", function(self, button)
    if IsShiftKeyDown() then
        if not FDKP:isOfficer() and not FDKP:isAdmin() then return end
        if button == 'LeftButton' then
            FDKP:toggleDkpAdditionFrame()
        elseif button == 'RightButton' then
            if not FDKP:isAdmin() then return end
            FDKP:toggleAdministrativeFrame()
        end
        return
    end
	if button == 'RightButton' then
		FDKPMenuFrame:updateVisibility(nil)
    elseif button == 'LeftButton' then
        FDKP_ROLL:toggleFrames()
	end
end);

minimap:Show()
