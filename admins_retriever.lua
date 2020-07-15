local adminsOnline = {}
local lastPingIndex = 1

local function checkPlayerNotFound(msg, names)
    for _, name in pairs(names) do
        if msg == 'Персонаж по имени "' .. name .. '" в игре не найден.' then return true end
    end
    return false
end

local lastAccessCheckTime = 0
local lastAccessCheck = false

local function checkAccess()
    local time = time()
    if lastAccessCheckTime == 0 or time - lastAccessCheckTime > 5 then
        lastAccessCheckTime = time
        lastAccessCheck = FDKP:isOfficer() or FDKP:isAdmin()
    end
    return lastAccessCheck
end

function FDKP:initAdminsRetrieverTimer()
    FDKP:initTimer('AdminsRetriever', function(sinceLastUpdate)
        if not checkAccess() or sinceLastUpdate < 2 then return false end
        local size = table.getn(FDKP_CURRENT_STATE.adminNames)
        if size == 0 then return true end
        if lastPingIndex > size then lastPingIndex = 1 end
        local adminName = FDKP_CURRENT_STATE.adminNames[lastPingIndex]
        FDKP_ADDON:SendDataWithCallback(FDKP_CHANNEL_ADMIN_PING, adminName, false, function(sender, parsed)
            FDKP:markAdmin(adminName, parsed)
        end, FDKP_DEFAULT_TIMEOUT, function()
            FDKP:markAdmin(adminName, false)
        end)
        lastPingIndex = lastPingIndex + 1
        return true
    end)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_SYSTEM', function(self, event, msg)
        if not checkAccess() then return false end
        return checkPlayerNotFound(msg, FDKP_CURRENT_STATE.adminNames) or checkPlayerNotFound(msg, FDKP_CURRENT_STATE.officerNames)
    end)
end

function FDKP:markAdmin(adminName, onlineOrOffline)
    if onlineOrOffline then
        if not adminsOnline[adminName] then
            adminsOnline[adminName] = true
            FDKP:logDebug('Администратор %s помечен онлайн.', adminName)
        end
    else
        if adminsOnline[adminName] then
            adminsOnline[adminName] = nil
            FDKP:logDebug('Администратор %s помечен оффлайн.', adminName)
        end
    end
end

function FDKP:requestAdminSign(data, callback, retries)
    retries = retries or 0
    if retries >= 3 then
        FDKP:logError('Неввозможно получить административную подпись. В сети точно есть хоть один администратор аддона?')
        callback()
        return
    end
    if retries > 0 then
        FDKP:logError('Не удалось получить административную подпись. Пробую еще раз.')
    end
    local size = 0
    for _, _ in pairs(adminsOnline) do
        size = size + 1
    end
    if size == 0 then
        FDKP:logError('Не замечено администраторов в сети. Запрос не будет выполнен.')
        return
    end
    local index = math.random(1, size)
    for adminName, _ in pairs(adminsOnline) do
        index = index - 1
        if index == 0 then
            FDKP:logInfo('Запрашиваю подпись запроса у %s.', adminName)
            FDKP_ADDON:SendDataWithCallback(FDKP_CHANNEL_ADMIN_SIGN, adminName, data, function(sender, parsed)
                if parsed == false then
                    FDKP:logError('Этот запрос не может быть подписан администратором по запросу. Не пытаетесь ли вы взломать аддон?..')
                    callback()
                else
                    callback(data, parsed)
                end
            end, FDKP_DEFAULT_TIMEOUT, function()
                FDKP:requestAdminSign(data, callback, retries + 1)
            end)
            return
        end
    end
end