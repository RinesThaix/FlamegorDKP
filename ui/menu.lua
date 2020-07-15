local gui = LibStub("AceGUI-3.0")

local initialFrame = gui:Create("Frame")
initialFrame:SetTitle('Пламягорыш: ' .. FDKP.types[FDKP_SELECTED_DKP_TYPE])
initialFrame:SetStatusText('hello there')
initialFrame.statustext:GetParent():Hide()
initialFrame:EnableResize(false);

local frame = initialFrame.frame
frame.width  = 935
frame.height = 80 + 15 * 25
frame:SetFrameStrata("LOW")
frame:SetSize(frame.width, frame.height)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetBackdrop({
	bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile     = true,
	tileSize = 32,
	edgeSize = 32,
	insets   = { left = 8, right = 8, top = 8, bottom = 8 }
})
frame:SetBackdropColor(0, 0, 0, 1)
frame:EnableMouse(true)
frame:EnableMouseWheel(true)

frame:SetMovable(true)
frame:SetResizable(enable)
frame:SetMinResize(100, 100)
frame:EnableKeyboard(false)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

FDKPMenuFrame = frame

local function compareColoredPlayerName(a, b, direction)
	local as, bs = string.sub(a, 11), string.sub(b, 11)
	if direction == 1 then
		return as < bs
	else
		return as > bs
	end
end

ScrollingTable = LibStub("ScrollingTable");
local dkpTable = ScrollingTable:CreateST(
	{
		{
			["name"] = 'Ник игрока',
			["width"] = 80,
			["comparesort"] = function(table, cella, cellb, sortby)
				local column = table.cols[1]
                local direction = column.sort or column.defaultsort or 1
				return compareColoredPlayerName(table.data[cella][1], table.data[cellb][1], direction)
			end
		},
		{
			["name"] = 'Класс',
			["width"] = 90,
			["sortnext"] = 4
		},
		{
			['name'] = 'Гильдия',
			['width'] = 100,
			['sortnext'] = 4
		},
		{
			["name"] = "DKP",
			["width"] = 40,
			["defaultsort"] = "asc",
			["sortnext"] = 1
		}
	},
	24, nil, nil, frame
)
dkpTable:EnableSelection(true)
frame.dkpTable = dkpTable

dkpTable.frame:SetPoint("TOPLEFT", 15, -40)

local logsTable = ScrollingTable:CreateST(
	{
		{
			["name"] = 'Время',
			["width"] = 125,
			["defaultsort"] = 'asc'
		},
		{
			["name"] = 'Автор',
			["width"] = 80,
			["sortnext"] = 1
		},
		{
			["name"] = 'Цель',
			["width"] = 80,
			["sortnext"] = 1
		},
		{
			["name"] = 'Изменение',
			["width"] = 70,
			["sortnext"] = 1
		},
		{
			["name"] = 'Баланс',
			["width"] = 40,
			["sortnext"] = 1
		},
		{
			["name"] = 'Причина',
			["width"] = 135,
			["sortnext"] = 1
		},
	},
	24, nil, nil, frame
)
logsTable:EnableSelection(true)
frame.logsTable = logsTable

local tooltip = CreateFrame("GameTooltip", "FDKPMenuItemTooltip", null, "GameTooltipTemplate");
ShowUIPanel(tooltip)

dkpTable:RegisterEvents({
    ["OnClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
    	if not (row or realrow) then
    		return false
    	end
    	if dkpTable:GetSelection() == realrow then
			dkpTable:ClearSelection();
		else
			dkpTable:SetSelection(realrow);
		end
    	if dkpTable:GetSelection() then
	    	local playerName = data[realrow][1]
	    	playerName = string.sub(playerName, 11)
	    	FDKPMenuFrameTarget = playerName
	    else
	    	FDKPMenuFrameTarget = nil
    	end
	    FDKP:updateMenuLogs()
    	return true
    end
});
logsTable:RegisterEvents({
    ["OnEnter"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
    	if not (row or realrow) or column ~= 6 then
    		return false
		end
		tooltip:SetOwner(rowFrame, 'ANCHOR_RIGHT');
		local itemID = tonumber(data[realrow][6]:match("item:(%d+)"))
		if itemID then
			tooltip:SetHyperlink('item:' .. itemID)
		end
		tooltip:Show();
    	return false
    end,
    ["OnLeave"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
    	if not (row or realrow) or column ~= 6 then
    		return false
		end
		tooltip:Hide()
    	return false
    end,
});

logsTable.frame:SetPoint("TOPRIGHT", -15, -40)

FDKPMenuFrame.initialized = false
FDKPMenuFrame:SetScript("OnUpdate", function(self, sinceLastUpdate) FDKPMenuFrame:onUpdate(sinceLastUpdate); end);
function FDKPMenuFrame:onUpdate(sinceLastUpdate)
    self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
	if not self.initialized then
    	if FDKPMenuShown and not FDKPMenuFrame:IsShown() then
    		FDKPMenuFrame:Show()
    	elseif not FDKPMenuShown and FDKPMenuFrame:IsShown() then
    		FDKPMenuFrame:Hide()
    	end
    end
    if not FDKPMenuFrame:IsShown() then
    	return
    end
    if not self.initialized or self.sinceLastUpdate >= 60 then
    	self.sinceLastUpdate = 0
    	FDKP:updateMenuList()
    	FDKP:updateMenuLogs()
    end
end

initialFrame:SetCallback("OnClose", function(widget) FDKPMenuFrame:updateVisibility(false) end)

local function setupTypeSelector()
	local typeSelectorButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	typeSelectorButton:SetPoint("BOTTOMRIGHT", -341, 17)
	typeSelectorButton:SetSize(100, 20)

	local typeSelectorUp = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	typeSelectorUp:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
	typeSelectorUp:GetNormalTexture():SetTexCoord(0.2, 0.25, 0.2, 0.75, 0.8, 0.25, 0.8, 0.75)
	typeSelectorUp:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
	typeSelectorUp:GetHighlightTexture():SetTexCoord(0.2, 0.25, 0.2, 0.75, 0.8, 0.25, 0.8, 0.75)
	typeSelectorUp:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
	typeSelectorUp:GetPushedTexture():SetTexCoord(0.2, 0.25, 0.2, 0.75, 0.8, 0.25, 0.8, 0.75)
	typeSelectorUp:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled")
	typeSelectorUp:GetDisabledTexture():SetTexCoord(0.2, 0.25, 0.2, 0.75, 0.8, 0.25, 0.8, 0.75)
	typeSelectorUp:SetPoint("BOTTOMRIGHT", -445, 29)
	typeSelectorUp:SetSize(18, 16)

	local typeSelectorDown = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	typeSelectorDown:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
	typeSelectorDown:GetNormalTexture():SetTexCoord(0.2, 0.25, 0.2, 0.75, 0.8, 0.25, 0.8, 0.75)
	typeSelectorDown:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
	typeSelectorDown:GetHighlightTexture():SetTexCoord(0.2, 0.25, 0.2, 0.75, 0.8, 0.25, 0.8, 0.75)
	typeSelectorDown:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
	typeSelectorDown:GetPushedTexture():SetTexCoord(0.2, 0.25, 0.2, 0.75, 0.8, 0.25, 0.8, 0.75)
	typeSelectorDown:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")
	typeSelectorDown:GetDisabledTexture():SetTexCoord(0.2, 0.25, 0.2, 0.75, 0.8, 0.25, 0.8, 0.75)
	typeSelectorDown:SetPoint("BOTTOMRIGHT", -445, 11)
	typeSelectorDown:SetSize(18, 16)

    local type = FDKP_SELECTED_DKP_TYPE
    local first = 'WB'
    local last = 'WB'

	local function update()
		if first == last then
			typeSelectorUp:Hide()
			typeSelectorDown:Hide()
			typeSelectorButton:Hide()
			return
		end
		if type == first then
			typeSelectorUp:SetEnabled(false)
			typeSelectorDown:SetEnabled(#FDKP.types > 1)
		elseif type == last then
			typeSelectorUp:SetEnabled(true)
			typeSelectorDown:SetEnabled(false)
		else
			typeSelectorUp:SetEnabled(true)
			typeSelectorDown:SetEnabled(true)
		end
		typeSelectorButton:SetText(FDKP.types[type])
		typeSelectorButton:SetEnabled(type ~= FDKP_SELECTED_DKP_TYPE)
	end

	update()
	typeSelectorButton:SetEnabled(false)

	typeSelectorUp:SetScript("OnClick", function(self)
		type = type - 1
		update()
	end)
	typeSelectorDown:SetScript("OnClick", function(self)
		type = type + 1
		update()
	end)
	typeSelectorButton:SetScript("OnClick", function(self)
		FDKP_SELECTED_DKP_TYPE = type
        initialFrame:SetTitle('Пламягорыш: ' .. FDKP.types[FDKP_SELECTED_DKP_TYPE])
    	FDKP:updateMenuList()
    	FDKP:updateMenuLogs()
		typeSelectorButton:SetEnabled(false)
	end)
end

setupTypeSelector()

local infoString = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
infoString:SetPoint('BOTTOMLEFT', 15, 30)
infoString:SetText('Помните, что у вас отображаются лишь те логи и данные, что произошли,')
infoString = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
infoString:SetPoint('BOTTOMLEFT', 15, 17)
infoString:SetText('пока вы были в сети, и те, которыми с вами поделились другие игроки.')

local function getDKPListData(dkpType)
    local dkps = FDKP_CURRENT_STATE.dkp[FDKP_SELECTED_DKP_TYPE] or {}
    local result = {}
	local classesMapping = {}
	local guilds = {}
	local playerName, playerClassName = '', ''
	local guildName = GetGuildInfo('player')
	for i = 1, GetNumGuildMembers() do
        playerName, _, _, _, playerClassName = GetGuildRosterInfo(i)
        playerName = FDKP:filterPlayerName(playerName)
        if dkps[playerName] ~= nil then
			classesMapping[playerName] = FDKP:getClassIdByName(playerClassName)
        end
    end
    for playerName, _ in pairs(dkps) do
        local playerData = FDKP_CURRENT_STATE.playerData[playerName]
        if playerData then
			classesMapping[playerName] = playerData[1]
			guilds[playerName] = playerData[2]
        elseif classesMapping[playerName] and (FDKP:isOfficer() or FDKP:isAdmin()) then
            FDKP_BINLOG:compilePlayerClassAndGuildRecord(playerName, classesMapping[playerName], guildName)
        end
    end
    for playerName, dkp in pairs(dkps) do
        local classID = classesMapping[playerName]
		if classesMapping[playerName] then
            result[#result + 1] = {FDKP:getClassColorById(classID) .. playerName, FDKP:getClassNameById(classID), guilds[playerName] or guildName, dkp}
        else
            result[#result + 1] = {FDKP:colorize('&7' .. playerName), 'Неизвестно', 'Неизвестно', dkp}
        end
    end
    table.sort(result, function(a, b)
        return a[4] > b[4]
    end)
    return result
end

function FDKP:updateMenuList()
    local data = getDKPListData(FDKP_SELECTED_DKP_TYPE)
	if #data > 0 then
		FDKPMenuFrame.initialized = true
    end
	FDKPMenuFrame.dkpTable:SetData(data, true)
end

function FDKP:updateMenuLogs()
	local data = {}
	for _, row in pairs(FDKP_CURRENT_STATE.logs[FDKP_SELECTED_DKP_TYPE] or {}) do
		if not FDKPMenuFrameTarget or row[2] == FDKPMenuFrameTarget then
			data[#data + 1] = {
				date("%Y/%m/%d %H:%M:%S", row[1]),
				row[6],
				row[2],
				row[3],
				row[4],
				row[5]
			}
		end
	end
	table.sort(data, function(a, b)
		return a[1] > b[1]
	end)
	FDKPMenuFrame.initialized = true
	FDKPMenuFrame.logsTable:SetData(data, true)
end

function FDKPMenuFrame:updateVisibility(val)
	if val ~= nil then
		if val then
			FDKPMenuShown = true
			if not FDKPMenuFrame:IsShown() then
				FDKPMenuFrame:Show()
			end
		else
			FDKPMenuShown = false
			if FDKPMenuFrame:IsShown() then
				FDKPMenuFrame:Hide()
			end
		end
	else
		if FDKPMenuFrame:IsShown() then
			FDKPMenuShown = false
			FDKPMenuFrame:Hide()
		else
			FDKPMenuShown = true
			FDKPMenuFrame:Show()
		end
	end
end