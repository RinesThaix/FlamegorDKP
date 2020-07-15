local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0")
local tableName = 'Административные действия'

local rowWidth = 2.7
local maxButtonsPerRow = 3

local gui = AceGUI:Create('FDRaidingHelperFrame')
gui:Hide()
gui:SetWidth(495)
gui:SetHeight(400)

local contents = {
    masterHeader = {
        name = 'Подпись мастер-ключом',
        type = 'header',
        order = 1
    },
    adminPublicKey = {
        name = 'Публичный административный ключ',
        type = 'input',
        desc = 'Изменение ключа здесь обновит его у всех пользователей аддона.',
        set = function(info, val) FDKP_BINLOG:compileNewAdminKeyRecord(val) end,
        get = function(info) return FDKP_CURRENT_STATE.adminPublicKey end,
        disabled = function() return not FDKP:isMaster() end,
        width = rowWidth,
        order = 2
    },
    addAdmin = {
        name = 'Добавить администратора',
        type = 'input',
        desc = 'Укажите здесь ник нового администратора.',
        set = function(info, val)
            if not FDKP:isAdmin(val) then
                FDKP_BINLOG:compileAdminNameChangeRecord(val, true)
            else
                FDKP:logError('Этот человек и так является администратором аддона.')
            end
        end,
        get = function(info) return '' end,
        disabled = function() return not FDKP:isMaster() end,
        width = rowWidth / 3,
        order = 3
    },
    removeAdmin = {
        name = 'Удалить администратора',
        type = 'input',
        desc = 'Укажите здесь ник администратора, подлежащего удалению.',
        set = function(info, val)
            if FDKP:isAdmin(val) then
                FDKP_BINLOG:compileAdminNameChangeRecord(val, false)
            else
                FDKP:logError('Этот человек не является администратором аддона.')
            end
        end,
        get = function(info) return '' end,
        disabled = function() return not FDKP:isMaster() end,
        width = rowWidth / 3,
        order = 4
    },
    listAdmins = {
        name = 'Администраторы',
        type = 'execute',
        desc = 'Вывести в чат список администраторов аддона.',
        func = function()
            FDKP:logInfo('&eСписок администраторов аддона: &r%s&e.', FDKP:implode(FDKP_CURRENT_STATE.adminNames, ', '))
        end,
        disabled = function() return not FDKP:isAdmin() end,
        width = rowWidth / 3,
        order = 5
    },
    clearOfficers = {
        name = 'Обнулить всех офицеров',
        type = 'execute',
        func = function() FDKP_BINLOG:compileOfficerNamesClearRecord() end,
        disabled = function() return not FDKP:isMaster() end,
        width = rowWidth,
        order = 6
    },
    createSnapshot = {
        name = 'Создать снэпшот',
        type = 'input',
        desc = 'Укажите через запятую время последней записи и кол-во записей в снэпшоте.',
        set = function(info, val)
            local exploded = FDKP:explode(val)
            local time, rows = math.floor(exploded[1]), math.floor(exploded[2])
            if time ~= 0 and rows ~= 0 then
                FDKP_BINLOG:compileSnapshotRecord(time, rows)
            else
                FDKP:logError('Введены некорректные данные.')
            end
        end,
        get = function(info) return '' end,
        disabled = function() return not FDKP:isMaster() end,
        width = rowWidth,
        order = 7
    },
    adminHeader = {
        name = 'Подпись приватным административным ключом',
        type = 'header',
        order = 8
    },
    addOfficer = {
        name = 'Добавить офицера',
        type = 'input',
        desc = 'Укажите здесь ник нового офицера аддона.',
        set = function(info, val)
            if not FDKP:isOfficer(val) then
                FDKP_BINLOG:compileOfficerNameChangeRecord(val, true)
            else
                FDKP:logError('Этот человек и так является офицером аддона.')
            end
        end,
        get = function(info) return '' end,
        disabled = function() return not FDKP:isAdmin() end,
        width = rowWidth / 3,
        order = 9
    },
    removeOfficer = {
        name = 'Удалить офицера',
        type = 'input',
        desc = 'Укажите здесь ник офицера аддона, подлежащего удалению.',
        set = function(info, val)
            if FDKP:isOfficer(val) then
                FDKP_BINLOG:compileOfficerNameChangeRecord(val, false)
            else
                FDKP:logError('Этот человек не является офицером аддона.')
            end
        end,
        get = function(info) return '' end,
        disabled = function() return not FDKP:isAdmin() end,
        width = rowWidth / 3,
        order = 10
    },
    listOfficers = {
        name = 'Офицеры',
        type = 'execute',
        desc = 'Вывести в чат список офицеров аддона.',
        func = function()
            local names = FDKP:implode(FDKP_CURRENT_STATE.officerNames, ', ')
            if names:len() == 0 then names = 'здесь пусто' end
            FDKP:logInfo('&eСписок офицеров аддона: &r%s&e.', names)
        end,
        disabled = function() return not FDKP:isAdmin() end,
        width = rowWidth / 3,
        order = 11
    },
    addBlacklisted = {
        name = 'Добавить игрока в ЧС',
        type = 'input',
        desc = 'Укажите здесь ник игрок, подлежащего добавлению в черный список.',
        set = function(info, val)
            if not FDKP:isBlacklisted(val) then
                FDKP_BINLOG:compileBlacklistChangeRecord(val, true)
            else
                FDKP:logError('Этот игрок уже находится в черном списке аддона.')
            end
        end,
        get = function(info) return '' end,
        disabled = function() return not FDKP:isAdmin() end,
        width = rowWidth / 3,
        order = 12
    },
    removeBlacklisted = {
        name = 'Удалить игрока из ЧСа',
        type = 'input',
        desc = 'Укажите здесь ник игрока, подлежащего удалению из черного списка.',
        set = function(info, val)
            if FDKP:isBlacklisted(val) then
                FDKP_BINLOG:compileBlacklistChangeRecord(val, false)
            else
                FDKP:logError('Этот игрок и так не находится в черном списке аддона.')
            end
        end,
        get = function(info) return '' end,
        disabled = function() return not FDKP:isAdmin() end,
        width = rowWidth / 3,
        order = 13
    },
    listBlacklisted = {
        name = 'Черный список',
        type = 'execute',
        desc = 'Вывести в чат ники игроков, находящихся в черном списке аддона.',
        func = function()
            local names = FDKP:implode(FDKP_CURRENT_STATE.blacklist, ', ')
            if names:len() == 0 then names = 'здесь пусто' end
            FDKP:logInfo('&eЧерный список аддона: &r%s&e.', names)
        end,
        disabled = function() return not FDKP:isAdmin() end,
        width = rowWidth / 3,
        order = 14
    },
}
LibStub:GetLibrary("AceConfig-3.0"):RegisterOptionsTable(tableName, {
    type = "group",
    args = contents
})

function FDKP:toggleAdministrativeFrame()
    if gui:IsShown() then
        gui:Hide()
    else
        AceConfigDialog:Open(tableName, gui)
    end
end