local PREFIX_LENGTH = 2

FDKP_DEFAULT_TIMEOUT = 2

FDKP_CHANNEL_ADMIN_PING = 'AP'
FDKP_CHANNEL_ADMIN_SIGN = 'AS'
FDKP_CHANNEL_BINLOG_RECORD = 'BR'
FDKP_CHANNEL_SNAPSHOT_VERIONING = 'SV'
FDKP_CHANNEL_SNAPSHOT_REPLICATION = 'SR'
FDKP_CHANNEL_VERSION_NOTIFICATION = 'VN'
FDKP_CHANNEL_ITEM_ROLL_START = 'RS'
FDKP_CHANNEL_ITEM_ROLL_BET_CREATED = 'BC'
FDKP_CHANNEL_ITEM_ROLL_BET_VERIFIED = 'BV'
FDKP_CHANNEL_ITEM_ROLL_END = 'RE'
FDKP_CHANNEL_ITEM_ROLL_TIMER = 'RT'

local CHANNELS = {
    [FDKP_CHANNEL_ADMIN_PING] = {
        'WHISPER',
        function(sender, parsed, callbackID)
            if callbackID == 0 or parsed ~= false or not FDKP:isAdmin() or not FDKP:isOfficer(sender) then return end
            FDKP_ADDON:ResponseCallback(sender, true, callbackID)
        end
    },
    [FDKP_CHANNEL_ADMIN_SIGN] = {
        'WHISPER',
        function(sender, parsed, callbackID)
            if callbackID == 0 or not FDKP:isAdmin() or not FDKP:isOfficer(sender) then return end
            local signed = false
            if FDKP_BINLOG:IsSignableForOfficers(parsed[1]) then
                signed = FDKP:encryptAdmin(parsed)
                FDKP:logInfo('Вы подписали запрос от %s.', sender)
            else
                FDKP:logError('%s запросил подпись запроса, который доступен лишь администраторам.', sender)
            end
            FDKP_ADDON:ResponseCallback(sender, signed, callbackID)
        end
    },
    [FDKP_CHANNEL_BINLOG_RECORD] = {
        nil,
        function(sender, parsed, callbackID, distribution)
            if distribution == 'WHISPER' and not FDKP:isAdmin(sender) and not FDKP:isOfficer(sender) then return end
            if not FDKP_BINLOG:NewBinlogRecordReceived(parsed, distribution) then
                FDKP:logError('Получена некорректная запись бинлога от %s.', sender)
            end
        end
    },
    [FDKP_CHANNEL_SNAPSHOT_VERIONING] = {
        'GUILD',
        function(sender, parsed)
            if FDKP_BINLOG:getSnapshotTiming() >= parsed then return end
            FDKP:logInfo('Запрашиваю обновление снэпшота у %s.', sender)
            FDKP_ADDON:SendDataWithCallback(FDKP_CHANNEL_SNAPSHOT_REPLICATION, sender, false, function(sender, parsed)
                if parsed then
                    FDKP:logInfo('Обновление снэпшота успешно получено от %s. Пересчитываю бинлог.', sender)
                    FDKP_SNAPSHOT = parsed
                    FDKP_BINLOG:load()
                else
                    FDKP:logError('Обновление снэпшота от %s завершилось неудачей.', sender)
                end
            end, 120, function()
                FDKP:logError('Обновление снэпшота от %s так и не было получено :(', sender)
            end)
        end
    },
    [FDKP_CHANNEL_SNAPSHOT_REPLICATION] = {
        'WHISPER',
        function(sender, parsed, callbackID)
            FDKP:logInfo('%s запросил у вас обновление снэпшота. Передаю ему данные..', sender)
            FDKP_ADDON:ResponseCallback(sender, FDKP_SNAPSHOT, callbackID)
        end
    },
    [FDKP_CHANNEL_VERSION_NOTIFICATION] = {
        nil,
        function(sender, parsed, callbackID, distribution)
            if sender == UnitName("player") or (distribution ~= 'GUILD' and distribution ~= 'RAID') then return end
            local myVersion = FDKP:explode(FDKP.version, '.')
            local remoteVersion = FDKP:explode(parsed, '.')
            for i = 1, min(#myVersion, #remoteVersion) do
                if myVersion[i] > remoteVersion[i] then break end
                if myVersion[i] < remoteVersion[i] then
                    local time = time()
                    if time - FDKP.lastVersionCheckFailed > 300 then
                        FDKP.lastVersionCheckFailed = time
                        FDKP:logInfo('У &a%s &eновая версия аддона, а у вас - нет! Скачайте &av%s&e в канале дискорда Hord Hub.', sender, parsed)
                    end
                    break
                end
            end
        end
    },
    [FDKP_CHANNEL_ITEM_ROLL_START] = {
        'RAID',
        function(sender, parsed)
            if not FDKP:isAdmin(sender) and not FDKP:isOfficer(sender) then return end
            local rollID, itemLink, dkpType = parsed[1], parsed[2], parsed[3]
            FDKP_ROLL:started(rollID, sender, itemLink, dkpType)
        end
    },
    [FDKP_CHANNEL_ITEM_ROLL_TIMER] = {
        'RAID',
        function(sender, parsed)
            if not FDKP:isAdmin(sender) and not FDKP:isOfficer(sender) then return end
            local rollID, seconds = parsed[1], parsed[2]
            FDKP_ROLL:startedTimer(rollID, seconds)
        end
    },
    [FDKP_CHANNEL_ITEM_ROLL_END] = {
        'RAID',
        function(sender, parsed)
            if not FDKP:isAdmin(sender) and not FDKP:isOfficer(sender) then return end
            FDKP_ROLL:ended(parsed)
        end
    },
    [FDKP_CHANNEL_ITEM_ROLL_BET_VERIFIED] = {
        'RAID',
        function(sender, parsed)
            if not FDKP:isAdmin(sender) and not FDKP:isOfficer(sender) then return end
            local rollID, playerName, colorPrefix, sum = parsed[1], parsed[2], parsed[3], parsed[4]
            FDKP_ROLL:betMade(rollID, playerName, colorPrefix, sum)
        end
    },
    [FDKP_CHANNEL_ITEM_ROLL_BET_CREATED] = {
        'WHISPER',
        function(sender, parsed)
            if not FDKP:isAdmin() and not FDKP:isOfficer() then return end
            local rollID, playerName, sum = parsed[1], parsed[2], parsed[4]
            local dkpType = FDKP_ROLL:getRollDkpType(rollID)
            if not dkpType then return end
            local playerDkp = FDKP:getDKP(playerName, dkpType)
            if playerDkp < sum then
                FDKP:logDebug('%s попытался поставить в ролле за предмет %d DKP типа %s, однако у него есть всего %d.', sender, sum, dkpType, playerDkp)
                return
            end
            FDKP_ADDON:SendData(FDKP_CHANNEL_ITEM_ROLL_BET_VERIFIED, 'RAID', nil, parsed)
        end
    }
}

local CALLBACKS = {}
local CALLBACKS_TIMER = nil

local function logNetworkError(message, ...)
    FDKP:logError('Сетевая проблема: %s', FDKP:format(message, ...))
end

local function initCallbacksTimer()
    local time = 0
    return FDKP:initTimer('Callbacks', function(sinceLastUpdate)
        if sinceLastUpdate - time < 0.05 then return false end
        time = sinceLastUpdate
        local toBeRemoved = {}
        for key, callbackData in pairs(CALLBACKS) do
            if callbackData[2] == 0 then
                callbackData[2] = time
            elseif time - callbackData[2] >= callbackData[3] then
                toBeRemoved[key] = {true, callbackData[4]}
            end
        end
        for callbackID, _ in pairs(toBeRemoved) do
            CALLBACKS[callbackID] = nil
        end
        for _, data in pairs(toBeRemoved) do
            if data[2] then data[2]() end
        end
        return false
    end)
end

local function sendRawData(techChannel, ingameChannel, target, data)
    if ingameChannel == 'GUILD' and not FDKP:isInGuild() then return end
    local libS = LibStub:GetLibrary("AceSerializer-3.0")
	local libC = LibStub:GetLibrary("LibCompress")
	local libCE = libC:GetAddonEncodeTable()
	local encoded = libS:Serialize(data)
	encoded = libC:CompressHuffman(encoded)
    encoded = libCE:Encode(encoded)
    local channel = 'FDKP'
    if FDKP_USE_TEST_DISTRIBUTION then channel = channel .. 'T' end
	FDKP_ADDON:SendCommMessage(channel, techChannel .. '-' .. encoded, ingameChannel, target, "BULK")
end

function FDKP_ADDON:SendData(techChannel, ingameChannel, target, data)
    sendRawData(techChannel, ingameChannel, target, {0, data})
end

function FDKP_ADDON:SendDataWithCallback(techChannel, target, data, callback, timeout, timeoutHandler)
    local callbackID = math.random(1, 1000000000)
    while CALLBACKS[callbackID] do
        callbackID = math.random(1, 1000000000)
    end
    CALLBACKS[callbackID] = {callback, 0, timeout or FDKP_DEFAULT_TIMEOUT, timeoutHandler}
    if not CALLBACKS_TIMER then CALLBACKS_TIMER = initCallbacksTimer() end
    sendRawData(techChannel, 'WHISPER', target, {callbackID, data})
end

function FDKP_ADDON:ResponseCallback(target, data, callbackID)
    sendRawData('00', 'WHISPER', target, {callbackID, data})
end

function FDKP_ADDON:DecodeData(data)
    local libS = LibStub:GetLibrary("AceSerializer-3.0")
	local libC = LibStub:GetLibrary("LibCompress")
	local libCE = libC:GetAddonEncodeTable()
	data = libCE:Decode(data)
	local decrypted, err = libC:Decompress(data)
    if not decrypted then
        logNetworkError('ошибка декомпрессии пакета (%s)', err)
		return nil
	end
	local success, result = libS:Deserialize(decrypted)
    if not success then
        logNetworkError('ошибка десериализации пакета')
		return nil
	end
	return result
end

function FDKP_ADDON:OnCommReceived(channel, message, distribution, sender)
    if FDKP_USE_TEST_DISTRIBUTION then
        if channel ~= 'FDKPT' then return end
    else
        if channel ~= 'FDKP' then return end
    end
    if FDKP:isBlacklisted(sender) then return end
	local prefix = string.sub(message, 1, PREFIX_LENGTH)
	local suffix = string.sub(message, PREFIX_LENGTH + 2)
	local parsed = FDKP_ADDON:DecodeData(suffix)
	if parsed == nil then return end
    local callbackID, parsed = parsed[1], parsed[2]
    if prefix == '00' then
        if callbackID == 0 or not CALLBACKS[callbackID] or distribution ~= 'WHISPER' then return end
        CALLBACKS[callbackID][1](sender, parsed)
        CALLBACKS[callbackID] = nil
    else
        local channelData = CHANNELS[prefix]
        if not channelData or channelData[1] ~= nil and distribution ~= channelData[1] then return end
        if channelData[2] then channelData[2](sender, parsed, callbackID, distribution) end
    end
end

function FDKP_ADDON:OnEnable()
	self:RegisterComm("FDKP")
end