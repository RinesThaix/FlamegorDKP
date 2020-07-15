FDKP = {
    debug = false,
    version = '1.0.0',
    lastVersionCheckFailed = 0,
    types = {
        WB = 'Мировые боссы'
    }
}

local BYTES_PER_PLAYER_NAME_CHARACTER = 2

function FDKP:getDKP(playerName, dkpType)
    playerName = FDKP:filterPlayerName(playerName)
    if not dkpType then return false end
    local dkp = FDKP_CURRENT_STATE.dkp[dkpType]
    if not dkp then return 0 end
    if dkp[playerName] then return dkp[playerName] end
    return 0
end

local function verify(value, publicKey)
    local sign = value[#value]
    table.remove(value, #value)
    local crc = FDKP_ENCRYPTION:crc(value)
    value[#value + 1] = sign
    return FDKP_ENCRYPTION:decrypt(sign, publicKey) == crc
end

function FDKP:verifyMaster(value)
    return verify(value, FDKP_MASTER_PUBLIC_KEY)
end

function FDKP:verifyAdmin(value)
    return verify(value, FDKP_CURRENT_STATE.adminPublicKey)
end

function FDKP:encryptMaster(value)
    local t0 = FDKP:millis()
    local crc = FDKP_ENCRYPTION:crc(value)
    FDKP:logDebug('Подсчет CRC для подписи мастер-ключом занял ' .. FDKP:millis(t0) .. ' мс.')
    t0 = FDKP:millis()
    local signature = FDKP_ENCRYPTION:encrypt(crc, FDKP_MASTER_PRIVATE_KEY, FDKP_MASTER_PUBLIC_KEY)
    FDKP:logDebug('Подпись запроса мастер-ключом заняла ' .. FDKP:millis(t0) .. ' мс.')
    return signature;
end

function FDKP:encryptAdmin(value)
    local t0 = FDKP:millis()
    local crc = FDKP_ENCRYPTION:crc(value)
    FDKP:logDebug('Подсчет CRC для подписи приватным ключом занял ' .. FDKP:millis(t0) .. ' мс.')
    t0 = FDKP:millis()
    local signature = FDKP_ENCRYPTION:encrypt(crc, FDKP_ADMIN_PRIVATE_KEY, FDKP_CURRENT_STATE.adminPublicKey)
    FDKP:logDebug('Подпись запроса приватным ключом заняла ' .. FDKP:millis(t0) .. ' мс.')
    return signature;
end

function FDKP:filterPlayerName(playerName)
    if playerName then
        playerName = string.upper(string.sub(playerName, 1, BYTES_PER_PLAYER_NAME_CHARACTER)) .. string.sub(playerName, BYTES_PER_PLAYER_NAME_CHARACTER + 1, playerName:len())
    else
        playerName = UnitName('player')
    end
    return FDKP:explode(playerName, '-')[1]
end

function FDKP:explode(strings, delimiter)
	if delimiter == nil then
		delimiter = "%s"
	end
	local result = {}
	for str in string.gmatch(strings, "([^" .. delimiter .. "]+)") do
		result[#result + 1] = str
	end
	return result
end

function FDKP:implode(strings, delimiter, fromIndex, toIndex)
	fromIndex = fromIndex or 1
	toIndex = (toIndex or #strings) + 1
	local result = ''
	for i, str in pairs(strings) do
		if i == fromIndex then
			result = str
		elseif i == toIndex then
			break
		elseif i > fromIndex then
			result = result .. delimiter .. str
		end
	end
	return result
end

function FDKP:initTimer(timerName, timerFunction)
	local frame = CreateFrame("Frame", "FDKPTimer" .. timerName, UIParent)
	frame:SetScript('OnUpdate', function(self, sinceLastUpdate)
		self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
		if timerFunction(self.sinceLastUpdate) then
			self.sinceLastUpdate = 0
		end
	end)
	return frame
end

function FDKP:changeTable(theTable, value, addOrRemove, onAddition, onRemoval)
    if addOrRemove then
        for index, val in pairs(theTable) do
            if val == value then return end
        end
        theTable[#theTable + 1] = value
        if onAddition then onAddition() end
    else
        local toBeRemoved = 0
        for index, val in pairs(theTable) do
            if val == value then
                toBeRemoved = index
                break
            end
        end
        if toBeRemoved ~= 0 then
            table.remove(theTable, toBeRemoved)
            if onRemoval then onRemoval() end
        end
    end
end

local colors = {}
colors['&a'] = '|cff00ff00'
colors['&6'] = '|cfffac414'
colors['&e'] = '|cfffff000'
colors['&c'] = '|cffff0000'
colors['&7'] = '|cffaaaaaa'
colors['&3'] = '|cff30d5c8'
colors['&r'] = '|r'

local function strReplace(str, this, that)
	local result, amount = string.gsub(str, this, that)
	return result
end

function FDKP:colorize(str)
    for tag, color in pairs(colors) do
		str = strReplace(str, tag, color)
	end
	return str
end

function FDKP:format(message, ...)
    if ... == nil then return message end
    return FDKP:colorize(string.format(message, ...))
end

function FDKP:log(message, ...)
    print(FDKP:format(message, ...))
end

function FDKP:logPrefixed(message, ...)
    FDKP:log('&7[&6Пламягорыш&7] %s', FDKP:format(message, ...))
end

function FDKP:logError(message, ...)
    if not FDKP_LOG_ERROR then return end
    FDKP:logPrefixed('&c%s', FDKP:format(message, ...))
end

function FDKP:logInfo(message, ...)
    if not FDKP_LOG_INFO then return end
    FDKP:logPrefixed('&e%s', FDKP:format(message, ...))
end

function FDKP:logDebug(message, ...)
    if not FDKP_LOG_DEBUG then return end
    FDKP:logPrefixed('%s', FDKP:format(message, ...))
end

function FDKP:millis(from)
    local time = debugprofilestop()
    if not from then return time end
    return math.floor(time - from)
end

function FDKP:copyTable(tabl)
    if type(tabl) ~= 'table' then return tabl end
    local result = {}
    for key, value in pairs(tabl) do
        if type(key) == 'table' then key = FDKP:copyTable(key) end
        if type(value) == 'table' then value = FDKP:copyTable(value) end
        result[key] = value
    end
    return result
end

function FDKP:isItemEquippable(itemLink)
	if not FDTestTooltip then
		CreateFrame('GameTooltip', 'FDTestTooltip')
		FDTestTooltip:AddFontStrings(
		    FDTestTooltip:CreateFontString("$parentTextLeft1", nil, "GameTooltipText"),
		    FDTestTooltip:CreateFontString("$parentTextRight1", nil, "GameTooltipText")
		)
	end
	local tooltip = FDTestTooltip
	local function IsTextRed(text)
	    if text and text:GetText() then
	    	local r,g,b = text:GetTextColor()
	    	return math.floor(r * 256) == 255 and math.floor(g * 256) == 32 and math.floor(b * 256) == 32
	    end
	end
	local name = tooltip:GetName()
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetHyperlink(itemLink)
	for i = 1, tooltip:NumLines() do
		if IsTextRed(_G[name .. 'TextLeft' .. i]) or IsTextRed(_G[name .. 'TextRight' .. i]) then
			return false
		end
	end
	tooltip:Hide()
	return true
end

local inGuild = nil

function FDKP:isInGuild()
    if inGuild == nil then
        local guildName = GetGuildInfo('player')
        if guildName then
            inGuild = true
        else
            inGuild = false
        end
    end
    return inGuild
end