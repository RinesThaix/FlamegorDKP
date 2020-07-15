FDKP_ADDON = LibStub("AceAddon-3.0"):NewAddon("Пламягорыш", "AceComm-3.0")

FDKP_MASTER_PRIVATE_KEY = FDKP_MASTER_PRIVATE_KEY or ''
FDKP_MASTER_PUBLIC_KEY = "43797905481298148758267874234970892250503927135953709959311813881261179797539"
FDKP_ADMIN_PRIVATE_KEY = FDKP_ADMIN_PRIVATE_KEY or ''

FDKP_RowsPerLogs = FDKP_RowsPerLogs or 12
FDKP_LogsShareLimit = FDKP_LogsShareLimit or 500
FDKP_MenuShown = FDKP_MenuShown or false
FDKP_LogsShown = FDKP_LogsShown or false

FDKPMiniMapPosition = FDKPMiniMapPosition or 39.416431121514
FDKP_SELECTED_DKP_TYPE = FDKP_SELECTED_DKP_TYPE or 'WB'

if FDKP_LOG_ERROR == nil then
    FDKP_LOG_ERROR = true
end
if FDKP_LOG_INFO == nil then
    FDKP_LOG_INFO = true
end
if FDKP_LOG_DEBUG == nil then
    FDKP_LOG_DEBUG = false
end

if FDKP_USE_TEST_DISTRIBUTION == nil then
    FDKP_USE_TEST_DISTRIBUTION = false
end

local contents = {
    headerKeys = {
        name = "Ключи доступа",
        type = "header",
        order = 1
    },
    masterPrivateKey = {
        name = "Мастер-ключ",
        desc = "Должен быть проставлен у Махича.",
        type = "input",
        set = function(info, val) FDKP_MASTER_PRIVATE_KEY = val end,
        get = function(info) return FDKP_MASTER_PRIVATE_KEY end,
        pattern = "^[A-Z0-9]+$",
        disabled = function() return not FDKP:isMaster() end,
        width = 3.3,
        order = 2
    },
    adminPrivateKey = {
        name = "Приватный ключ",
        desc = "Должен быть проставлен у администраторов аддона. Получается у Махича.",
        type = "input",
        set = function(info, val) FDKP_ADMIN_PRIVATE_KEY = val end,
        get = function(info) return FDKP_ADMIN_PRIVATE_KEY end,
        pattern = "^[A-Z0-9]+$",
        disabled = function() return not FDKP:isAdmin(nil, false) end,
        width = 1.8,
        order = 3
    },
    headerVisibility = {
        name = "Настройки отображения",
        type = "header",
        order = 5
    },
    logInfo = {
        name = "Отображать сообщения аддона",
        type = "toggle",
        set = function(info, val) FDKP_LOG_INFO = val end,
        get = function(info) return FDKP_LOG_INFO end,
        width = 1.25,
        order = 7
    },
    logErrors = {
        name = "Отображать ошибки",
        type = "toggle",
        set = function(info, val) FDKP_LOG_ERROR = val end,
        get = function(info) return FDKP_LOG_ERROR end,
        width = 0.9,
        order = 8
    },
    logDebug = {
        name = "Отображать сообщения отладки",
        type = "toggle",
        set = function(info, val) FDKP_LOG_DEBUG = val end,
        get = function(info) return FDKP_LOG_DEBUG end,
        width = 1.3,
        order = 9
    },
    binlogClear = {
        name = 'Чистка бинлога',
        desc = 'Удаляет все данные, хранимые аддоном. Используйте, если данные стали некорректными и не чинятся автоматически в течение продолжительного времени. ЭТО ДЕЙСТВИЕ НЕОБРАТИМО!',
        type = 'execute',
        func = function()
            FDKP_BINLOG:clear()
            FDKP_BINLOG:load()
        end,
        width = 3.5,
        order = 10
    },
    testHeader = {
        name = 'Тестовые настройки',
        type = 'header',
        hidden = function() return not FDKP:isMaster() end,
        order = 11
    },
    testDistributionChannel = {
        name = 'Тестовый сетевой канал',
        desc = 'Использовать тестовый сетевой канал для распространения данных.',
        type = 'toggle',
        set = function(info, val) FDKP_USE_TEST_DISTRIBUTION = val end,
        get = function(info) return FDKP_USE_TEST_DISTRIBUTION end,
        hidden = function() return not FDKP:isMaster() end,
        width = 1.3,
        order = 12
    }
}

LibStub:GetLibrary("AceConfig-3.0"):RegisterOptionsTable("Пламягорыш", {
    type = "group",
    args = contents
})
LibStub:GetLibrary("AceConfigDialog-3.0"):AddToBlizOptions("Пламягорыш")