local BINLOG_RECORD_NEW_ADMIN_KEY = 1
local BINLOG_RECORD_ADMIN_NAME_CHANGE = 2
local BINLOG_RECORD_OFFICER_NAMES_CLEAR = 3
local BINLOG_RECORD_OFFICER_NAME_CHANGE = 4
local BINLOG_RECORD_DKP_CHANGE = 5
local BINLOG_RECORD_SNAPSHOT = 6
local BINLOG_RECORD_BLACKLIST_CHANGE = 7
local BINLOG_RECORD_PLAYER_CLASS_AND_GUILD = 8

local VERIFICATION_MODE_MASTER = 1
local VERIFICATION_MODE_ADMIN = 2
local VERIFICATION_MODE_OFFICER = 3
local VERIFICATION_MODE_NONE = 4

local SAVEABLE = true
local NOT_SAVEABLE = false

local binlogLoaded = false
FDKP_BINLOG = {}
FDKP_BINLOG_RECORDS = FDKP_BINLOG_RECORDS or {}

local snapshotDefaultValue = {
    lastRecord = nil,
    adminPublicKey = '173450472044463403624596599419487332873',
    adminNames = {'Махич', 'Коровобог'},
    officerNames = {},
    blacklist = {},
    dkp = {},
    logs = {},
    playerData = {}
}
FDKP_SNAPSHOT = FDKP_SNAPSHOT or FDKP:copyTable(snapshotDefaultValue)

FDKP_CURRENT_STATE = FDKP:copyTable(snapshotDefaultValue)

local BINLOG_RECORDS = {}
BINLOG_RECORDS[BINLOG_RECORD_NEW_ADMIN_KEY] = {
    VERIFICATION_MODE_MASTER,
    SAVEABLE,
    function(record, snapshot)
        snapshot.adminPublicKey = record[4]
    end,
    function(record)
        return {'NAK', {key = record[4]}}
    end
}
BINLOG_RECORDS[BINLOG_RECORD_ADMIN_NAME_CHANGE] = {
    VERIFICATION_MODE_MASTER,
    SAVEABLE,
    function(record, snapshot)
        local adminName, addOrRemove = record[4], record[5]
        FDKP:changeTable(snapshot.adminNames, adminName, addOrRemove, nil, function()
            FDKP:markAdmin(adminName, false)
        end)
    end,
    function(record)
        local mode
        if record[5] then mode = 'add' else mode = 'remove' end
        return {'ANC', {mode = mode, name = record[4]}}
    end
}
BINLOG_RECORDS[BINLOG_RECORD_OFFICER_NAMES_CLEAR] = {
    VERIFICATION_MODE_MASTER,
    SAVEABLE,
    function(record, snapshot)
        snapshot.officerNames = {}
    end,
    function(record)
        return {'ONW', {}}
    end
}
BINLOG_RECORDS[BINLOG_RECORD_SNAPSHOT] = {
    VERIFICATION_MODE_MASTER,
    SAVEABLE,
    function(record, _)
        local lastRecordTime, recordsSinceLastSnapshot = record[4], record[5]
        local applicableRecords = 0
        for _, rec in pairs(FDKP_BINLOG_RECORDS) do
            if rec[2] <= lastRecordTime then
                local typeID = rec[1]
                applicableRecords = applicableRecords + 1
            end
        end
        if applicableRecords == 0 then return end
        if applicableRecords ~= recordsSinceLastSnapshot then
            FDKP:logError('Получен запрос на генерацию снэпшота, но ваши данные неполны (%d строк, а требуется %d). Бинлог будет обнулен.', applicableRecords, recordsSinceLastSnapshot)
            FDKP_BINLOG:clear()
            return
        end
        local snapshot = {
            lastRecord = FDKP_SNAPSHOT.lastRecord,
            adminPublicKey = FDKP_SNAPSHOT.adminPublicKey,
            adminNames = FDKP_SNAPSHOT.adminNames,
            officerNames = FDKP_SNAPSHOT.officerNames
        }
        local dkp = {}
        for dkpType, players in pairs(FDKP_SNAPSHOT.dkp) do
            if not dkp[dkpType] then dkp[dkpType] = {} end
            local dkps = dkp[dkpType]
            for playerName, playerDkp in pairs(players) do
                dkps[playerName] = playerDkp
            end
        end
        snapshot.dkp = dkp
        local rewrittenLogs = {}
        for _, rec in pairs(FDKP_BINLOG_RECORDS) do
            if rec[2] <= lastRecordTime then
                local typeID = rec[1]
                if typeID ~= BINLOG_RECORD_SNAPSHOT then
                    local data = BINLOG_RECORDS[typeID]
                    if data then data[3](rec, snapshot) end
                end
            else
                rewrittenLogs[#rewrittenLogs + 1] = rec
            end
        end
        FDKP_BINLOG_RECORDS = rewrittenLogs
        snapshot.lastRecord = {0, lastRecordTime, 0}
        FDKP_SNAPSHOT = snapshot
    end,
    function(record)
        return {'SNAP', {time = record[4], records = record[5]}}
    end
}
BINLOG_RECORDS[BINLOG_RECORD_OFFICER_NAME_CHANGE] = {
    VERIFICATION_MODE_ADMIN,
    SAVEABLE,
    function(record, snapshot)
        local officerName, addOrRemove = record[4], record[5]
        FDKP:changeTable(snapshot.officerNames, officerName, addOrRemove)
    end,
    function(record)
        local mode
        if record[5] then mode = 'add' else mode = 'remove' end
        return {'ONC', {mode = mode, name = record[4]}}
    end
}
BINLOG_RECORDS[BINLOG_RECORD_BLACKLIST_CHANGE] = {
    VERIFICATION_MODE_ADMIN,
    SAVEABLE,
    function(record, snapshot)
        local name, addOrRemove = record[4], record[5]
        FDKP:changeTable(snapshot.blacklist, name, addOrRemove)
    end,
    function(record)
        local mode
        if record[5] then mode = 'add' else mode = 'remove' end
        return {'BNC', {mode = mode, name = record[4]}}
    end
}
BINLOG_RECORDS[BINLOG_RECORD_DKP_CHANGE] = {
    VERIFICATION_MODE_OFFICER,
    SAVEABLE,
    function(record, snapshot)
        local dkpStorage = snapshot.dkp
        local logStorage = snapshot.logs
        local authorName, targetNames, dkpType, dkpDelta, reason = record[4], record[5], record[6], record[7], record[8]
        for _, targetName in pairs(targetNames) do
            if not dkpStorage[dkpType] then dkpStorage[dkpType] = {} end
            if not logStorage[dkpType] then logStorage[dkpType] = {} end
            local dkps = dkpStorage[dkpType]
            local logs = logStorage[dkpType]
            local dkp = dkps[targetName] or 0
            dkps[targetName] = dkp + dkpDelta
            logs[#logs + 1] = {record[2], targetName, dkpDelta, dkps[targetName], reason, authorName}
        end
    end,
    function(record)
        local targets
        if #record[5] == 1 then targets = record[5][1] else targets = #(record[5]) .. ' игроков' end
        return {'DKP', {author = record[4], targets = targets, type = record[6], delta = record[7], reason = record[8]}}
    end
}
BINLOG_RECORDS[BINLOG_RECORD_PLAYER_CLASS_AND_GUILD] = {
    VERIFICATION_MODE_OFFICER,
    SAVEABLE,
    function(record, snapshot)
        local playerName, classID, guildName = record[4], record[5], record[6]
        snapshot.playerData[playerName] = {classID, guildName}
    end,
    function(record)
        return {'PD', {name = record[4], class = record[5], guild = record[6]}}
    end
}

local handledRecords = {}
DEBUG = handledRecords

local function handleRecord(record, forcefully)
    if not record then return false end
    local typeID = record[1]
    local data = BINLOG_RECORDS[typeID]
    if not data then return false end
    if handledRecords[record[#record]] and not forcefully then return false end
    handledRecords[record[#record]] = true
    if FDKP_CURRENT_STATE.lastRecord and FDKP_CURRENT_STATE.lastRecord[2] >= record[2] then return false end
    if binlogLoaded then FDKP:logDebug('Запись бинлога обработана.') end
    data[3](record, FDKP_CURRENT_STATE)
    return true
end

function FDKP_BINLOG:load()
    FDKP_CURRENT_STATE = {
        lastRecord = FDKP:copyTable(FDKP_SNAPSHOT.lastRecord),
        adminPublicKey = FDKP_SNAPSHOT.adminPublicKey,
        adminNames = FDKP:copyTable(FDKP_SNAPSHOT.adminNames),
        officerNames = FDKP:copyTable(FDKP_SNAPSHOT.officerNames),
        blacklist = FDKP:copyTable(FDKP_SNAPSHOT.blacklist),
        playerData = FDKP:copyTable(FDKP_SNAPSHOT.playerData)
    }
    local dkp = {}
    local log = {}
    local logTime = 0
    if FDKP_SNAPSHOT.lastRecord then
        logTime = FDKP_SNAPSHOT.lastRecord[2]
    end
    for dkpType, players in pairs(FDKP_SNAPSHOT.dkp) do
        if not dkp[dkpType] then dkp[dkpType] = {} end
        if not log[dkpType] then log[dkpType] = {} end
        local dkps = dkp[dkpType]
        local logs = log[dkpType]
        for playerName, playerDkp in pairs(players) do
            dkps[playerName] = playerDkp
            logs[#logs + 1] = {logTime, playerName, playerDkp, playerDkp, 'Старое значение'}
        end
    end
    FDKP_CURRENT_STATE.dkp = dkp
    FDKP_CURRENT_STATE.logs = log

    local lastRecord = FDKP_SNAPSHOT.lastRecord
    for _, record in pairs(FDKP_BINLOG_RECORDS) do
        if not lastRecord or record[2] > lastRecord[2] then
            if record[1] == BINLOG_RECORD_SNAPSHOT then
                handledRecords[record[#record]] = true
            else
                handleRecord(record, true)
            end
        end
    end

    FDKP:updateMenuList()
    FDKP:updateMenuLogs()
end

function FDKP_BINLOG:clear()
    handledRecord = {}
    FDKP_BINLOG_RECORDS = {}
    FDKP_SNAPSHOT = FDKP:copyTable(snapshotDefaultValue)
    FDKP_CURRENT_STATE = FDKP:copyTable(snapshotDefaultValue)
end

function FDKP_BINLOG:NewBinlogRecordReceived(record, distribution)
    if not binlogLoaded or handledRecords[record[#record]] then return true end
    local typeID = record[1]
    local data = BINLOG_RECORDS[typeID]
    if not data then return false end
    if data[1] == VERIFICATION_MODE_MASTER then
        if not FDKP:verifyMaster(record) then return false end
        FDKP:logDebug('Новая запись бинлога верифицирована (master mode).')
    elseif data[1] ~= VERIFICATION_MODE_NONE then
        if not FDKP:verifyAdmin(record) then return false end
        FDKP:logDebug('Новая запись бинлога верифицирована (admin mode).')
    end
    if handleRecord(record) then
        if data[2] == SAVEABLE then
            FDKP_BINLOG_RECORDS[#FDKP_BINLOG_RECORDS + 1] = record
            local t0 = FDKP:millis()
            table.sort(FDKP_BINLOG_RECORDS, function(a, b)
                local timeDelta = a[2] - b[2]
                if timeDelta ~= 0 then return timeDelta < 0 end
                return a[3] < b[3]
            end)
            FDKP:logDebug('Сортировка бинлога заняла ' .. FDKP:millis(t0) .. ' мс.')
        end
        FDKP_BINLOG:distribute(record, distribution)
    end
    return true
end

function FDKP_BINLOG:IsSignableForOfficers(typeID)
    local data = BINLOG_RECORDS[typeID]
    if not data then return false end
    return data[1] == VERIFICATION_MODE_OFFICER
end

local function postCompileRecord(typeID, record, sign, callback, verify)
    if sign then
        record[#record + 1] = sign
        if verify and not FDKP:verifyAdmin(record) then
            FDKP:logError('Получена некорректная подпись запроса от администратора.')
            callback()
        else
            callback(typeID, record)
        end
    else
        callback()
    end
end

local function compileRecord(record, callback)
    local typeID = record[1]
    local data = BINLOG_RECORDS[typeID]
    if not data then return end
    if data[1] == VERIFICATION_MODE_MASTER then
        if not FDKP:isMaster() then
            FDKP:logError('Этот запрос может исполнить лишь Махич.')
            callback()
            return
        end
        postCompileRecord(typeID, record, FDKP:encryptMaster(record), callback)
    elseif data[1] == VERIFICATION_MODE_ADMIN then
        if not FDKP:isAdmin() then
            FDKP:logError('Этот запрос могут исполнить лишь администраторы аддона.')
            callback()
            return
        end
        postCompileRecord(typeID, record, FDKP:encryptAdmin(record), callback)
    elseif data[1] == VERIFICATION_MODE_OFFICER then
        if FDKP:isAdmin() then
            postCompileRecord(typeID, record, FDKP:encryptAdmin(record), callback)
        elseif FDKP:isOfficer() then
            FDKP:requestAdminSign(record, function(record, sign)
                postCompileRecord(typeID, record, sign, callback, true)
            end)
        else
            FDKP:logError('Этот запрос могут исполнить лишь администраторы и офицеры аддона.')
            callback()
        end
    else
        postCompileRecord(typeID, record, 'nosign', callback)
    end
end

local function defaultCallback(typeID, record)
    FDKP_BINLOG:distribute(record)
    -- will be instantly received from the guild channel
end

local function preCompileRecord(typeID, record, callback)
    local result = {typeID, GetServerTime(), math.random(1, 1000)}
    for _, param in pairs(record) do result[#result + 1] = param end
    compileRecord(result, callback or defaultCallback)
end

function FDKP_BINLOG:compileDkpChangeRecord(targetNames, dkpType, dkpDelta, reason, callback)
    preCompileRecord(BINLOG_RECORD_DKP_CHANGE, {FDKP:filterPlayerName(), targetNames, dkpType, dkpDelta, reason or ''}, callback)
end

function FDKP_BINLOG:compileNewAdminKeyRecord(adminPublicKey, callback)
    preCompileRecord(BINLOG_RECORD_NEW_ADMIN_KEY, {adminPublicKey}, callback)
end

function FDKP_BINLOG:compileAdminNameChangeRecord(adminName, addOrRemove, callback)
    preCompileRecord(BINLOG_RECORD_ADMIN_NAME_CHANGE, {adminName, addOrRemove}, callback)
end

function FDKP_BINLOG:compileOfficerNameChangeRecord(officerName, addOrRemove, callback)
    preCompileRecord(BINLOG_RECORD_OFFICER_NAME_CHANGE, {officerName, addOrRemove}, callback)
end

function FDKP_BINLOG:compileOfficerNamesClearRecord(callback)
    preCompileRecord(BINLOG_RECORD_OFFICER_NAMES_CLEAR, {}, callback)
end

function FDKP_BINLOG:compileSnapshotRecord(lastRecordTime, recordsSinceLastSnapshot, callback)
    preCompileRecord(BINLOG_RECORD_SNAPSHOT, {lastRecordTime, recordsSinceLastSnapshot}, callback)
end

function FDKP_BINLOG:compileBlacklistChangeRecord(playerName, addOrRemove, callback)
    preCompileRecord(BINLOG_RECORD_BLACKLIST_CHANGE, {playerName, addOrRemove}, callback)
end

function FDKP_BINLOG:compilePlayerClassAndGuildRecord(playerName, classID, guildName, callback)
    preCompileRecord(BINLOG_RECORD_PLAYER_CLASS_AND_GUILD, {playerName, classID, guildName}, callback)
end

local function distribute(record, names, limit)
    local size = table.getn(names)
    local used = {}
    for _ = 1, math.min(limit, size) do
        local index = math.random(1, size)
        while used[index] do index = math.random(1, size) end
        local name = names[index]
        FDKP_ADDON:SendData(FDKP_CHANNEL_BINLOG_RECORD, 'WHISPER', name, record)
    end
end

function FDKP_BINLOG:distribute(record, ignoredDistribution)
    if ignoredDistribution ~= 'GUILD' then
        FDKP_ADDON:SendData(FDKP_CHANNEL_BINLOG_RECORD, 'GUILD', nil, record)
    end
    if ignoredDistribution ~= 'RAID' and GetNumGroupMembers() > 5 then
        FDKP_ADDON:SendData(FDKP_CHANNEL_BINLOG_RECORD, 'RAID', nil, record)
    end
    if FDKP:isAdmin() then
        distribute(record, FDKP_CURRENT_STATE.officerNames, 3)
    elseif FDKP:isOfficer() then
        distribute(record, FDKP_CURRENT_STATE.officerNames, 2)
        distribute(record, FDKP_CURRENT_STATE.adminNames, 2)
    end
end

function FDKP_BINLOG:getSnapshotTiming()
    local time = 0
    if FDKP_SNAPSHOT.lastRecord then
        time = FDKP_SNAPSHOT.lastRecord[2]
    end
    return time
end

function FDKP_BINLOG:getLogs()
    local logs = {}
    for _, record in pairs(FDKP_BINLOG_RECORDS) do
        local data = BINLOG_RECORDS[record[1]]
        if data then
            local log = data[4](record)
            local logType, logParams = log[1], log[2]
            local params = {}
            for key, value in pairs(logParams) do
                params[#params + 1] = key .. ': ' .. value
            end
            logs[#logs + 1] = {record[2], logType, FDKP:implode(params, ', ')}
        end
    end
    table.sort(logs, function(a, b)
        return a[1] > b[1]
    end)
    return logs
end

local lastRecordIndex = 1
FDKP:initTimer('BinlogReplication', function(sinceLastUpdate)
    if not binlogLoaded then
        local t0 = FDKP:millis()
        FDKP_BINLOG:load()
        FDKP:logDebug('Инициализация бинлога (%d записей) заняла %d мс.', #FDKP_BINLOG_RECORDS, FDKP:millis(t0))
        binlogLoaded = true
        FDKP:updateMiniMapPosition()
        FDKP:initAdminsRetrieverTimer()
    end
    if sinceLastUpdate < 5 then return false end
    if #FDKP_BINLOG_RECORDS == 0 then return true end
    if lastRecordIndex > #FDKP_BINLOG_RECORDS then lastRecordIndex = 1 end
    FDKP_BINLOG:distribute(FDKP_BINLOG_RECORDS[lastRecordIndex])
    lastRecordIndex = lastRecordIndex + 1
    return true
end)
FDKP:initTimer('SnapshotUpdater', function(sinceLastUpdate)
    if not binlogLoaded then
        return false
    end
    if sinceLastUpdate < 600 then return false end
    FDKP_ADDON:SendData(FDKP_CHANNEL_SNAPSHOT_VERIONING, 'GUILD', nil, FDKP_BINLOG:getSnapshotTiming())
    return true
end)