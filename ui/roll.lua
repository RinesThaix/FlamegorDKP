local rollFrames = {}
local rollTimer = nil

FDKP_MIN_BET = 100

FDKP_BET_MODE_DEFAULT = 1
FDKP_BET_MODE_ALL_IN = 2

FDKP_ROLL = {}

local function getRollFrame(rollID)
    if rollFrames[rollID] then return rollFrames[rollID] end
	local gui = LibStub("AceGUI-3.0")
	local initialFrame = gui:Create("FDRollFrame")
	initialFrame:SetTitle('Item Roll')

	local frame = initialFrame.frame
	frame:SetFrameStrata("LOW")
	frame:EnableMouse(true)
	frame:EnableMouseWheel(false)
	frame:SetMovable(true)
	frame:EnableKeyboard(false)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	local item = gui:Create("FDSlotItem")
	initialFrame:AddChild(item)

	local tooltip = CreateFrame("GameTooltip", "FDKPRollFrameTooltip", null, "GameTooltipTemplate")
	ShowUIPanel(tooltip)

	item:SetCallback('OnEnter', function()
		if initialFrame.rollLink ~= nil then
			tooltip:SetOwner(item.frame, 'ANCHOR_LEFT')
			tooltip:SetHyperlink(initialFrame.rollLink)
			tooltip:Show()
		end
	end)

	item:SetCallback('OnLeave', function()
		tooltip:Hide()
    end)
    
    initialFrame:Hide()
    initialFrame.rollID = rollID
    initialFrame.item = item
    initialFrame.tooltip = tooltip

    rollFrames[rollID] = initialFrame
    
    return initialFrame
end

local function setupRollFrameItem(rollID, itemLink)
	local frame = getRollFrame(rollID);
	frame.rollLink = itemLink;
	local itemId = FDKP:explode(itemLink, ':')[2]
	local item = Item:CreateFromItemID(tonumber(itemId))
	item:ContinueOnItemLoad(function()
		frame.item:SetText(itemLink)
	end)
	if frame.tooltip:IsShown() then
		frame.tooltip:SetHyperlink(itemLink);
	end
end

function FDKP_ROLL:started(rollID, rollerName, itemLink, dkpType)
    if rollFrames[rollID] then
        FDKP:logError('Попытка начать ролл с уже существующим идентификатором!')
        return
    end
    local frame = getRollFrame(rollID)
    frame.rollerName = rollerName
    frame.dkpType = dkpType
    local dkpTypeName = FDKP.types[dkpType]
    if not dkpTypeName then
        FDKP:logError('Начался ролл с неизвестным типом DKP: %s.', dkpType)
        return
    end
    local playerName = FDKP:filterPlayerName()
    frame:SetTitle(FDKP:format('%s - DKP ROLL (У вас %d DKP)', dkpTypeName, FDKP:getDKP(playerName, dkpType)))
    frame:Show()
    if playerName ~= rollerName then
		frame.endButton:Hide()
		frame.timerButton10:Hide()
		frame.timerButton20:Hide()
    end
	setupRollFrameItem(rollID, itemLink)
	frame.preparation = true
	frame:SetLastBet(nil)

	local itemId = FDKP:explode(itemLink, ':')[2]
	local item = Item:CreateFromItemID(tonumber(itemId))
	item:ContinueOnItemLoad(function()
		frame:SetCanRoll(FDKP:isItemEquippable(itemLink))
		FDKP_ROLL:startedTimer(rollID, 3)
	end)
end

function FDKP_ROLL:startedTimer(rollID, value)
	if not rollTimer then
		rollTimer = FDKP:initTimer('RollTimer', function(sinceLastUpdate)
            if sinceLastUpdate < 1 then return false end
            for rid, frame in pairs(rollFrames) do
                local val = frame.timerStr:GetText()
                if val ~= '' and val ~= nil then
                    if val == '0' then
                        if frame.preparation then
                            frame.preparation = false
                            frame.timerStr:SetText('')
                            frame:CheckBetButtons(frame.canRoll);
                        end
                    else
                        frame.timerStr:SetText(val - 1)
                    end
                end
            end
			return true
		end)
    end
    local frame = rollFrames[rollID]
    if frame then frame.timerStr:SetText(value) end
end

function FDKP_ROLL:makeBet(rollID, rollerName, betMode, betParams)
    local frame = rollFrames[rollID]
    if not frame then return end
    if frame.lastBetTime >= GetServerTime() then
        FDKP:logError('Прошло слишком мало времени с момента последней ставки. Попробуйте еще раз!')
		return
    end
    local playerName = FDKP:filterPlayerName()
    local sum = 0
    if betMode == FDKP_BET_MODE_DEFAULT then
        sum = frame.currentBet + betParams[1]
    elseif betMode == FDKP_BET_MODE_ALL_IN then
        sum = FDKP:getDKP(playerName, frame.dkpType)
    else
        FDKP:logError('Неизвестный режим ставки при ролле по DKP.')
        return
    end
    local dkp = FDKP:getDKP(playerName, frame.dkpType)
    if dkp < sum then
        FDKP:logError('У вас недостаточно DKP для этого действия. Как вы вообще нажали на кнопку?')
        return
    end
    local playerData = FDKP_CURRENT_STATE.playerData[playerName]
    local colorPrefix
    if not playerData then
        colorPrefix = FDKP:colorize('&7')
    else
        colorPrefix = FDKP:getClassColorById(playerData[1])
    end
    FDKP_ADDON:SendData(FDKP_CHANNEL_ITEM_ROLL_BET_CREATED, 'WHISPER', rollerName, {rollID, playerName, colorPrefix, sum})
end

function FDKP_ROLL:verifyBet(rollID, playerName, colorPrefix, sum)
    if not FDKP:isOfficer() and not FDKP:isAdmin() then return end
    if FDKP_ROLL:betMade(rollID, playerName, colorPrefix, sum) then
        FDKP_ADDON:SendData(FDKP_CHANNEL_ITEM_ROLL_BET_VERIFIED, 'RAID', nil, {rollID, playerName, colorPrefix, sum})
    end
end

function FDKP_ROLL:betMade(rollID, playerName, colorPrefix, sum)
    local frame = rollFrames[rollID]
    if not frame then return false end
	if sum <= frame.currentBet or frame.rollEndedStr:GetText() then return false end
	frame.lastBetTime = GetServerTime()
    frame:SetLastBet(playerName, colorPrefix, sum)
    return true
end

function FDKP_ROLL:ended(rollID)
    local frame = rollFrames[rollID]
    if not frame then return end
	frame:EndTheRoll()
	rollFrames[rollID] = nil 
end

function FDKP_ROLL:getRollDkpType(rollID)
    local frame = rollFrames[rollID]
    if not frame then return nil end
    return frame.dkpType
end

function FDKP_ROLL:toggleFrames()
    local allHidden = true
    local size = 0
    for _, frame in pairs(rollFrames) do
        size = size + 1
        if frame:IsShown() then
            allHidden = false
        end
    end
    if size == 0 then
        FDKP:logError('В данный момент нет активных DKP аукционов.')
        return
    end
    for _, frame in pairs(rollFrames) do
        if allHidden then frame:Show() else frame:Hide() end
    end
end
