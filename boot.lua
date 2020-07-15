FDKP:initTimer('SnapshotUpdater', function(sinceLastUpdate)
    if not FDKP.version or FDKP.debug then return false end
    if sinceLastUpdate < 60 then return false end
    FDKP_ADDON:SendData(FDKP_CHANNEL_VERSION_NOTIFICATION, 'GUILD', nil, FDKP.version)
    if GetNumGroupMembers() > 5 then
        FDKP_ADDON:SendData(FDKP_CHANNEL_VERSION_NOTIFICATION, 'RAID', nil, FDKP.version)
    end
    return true
end)

local lastMsg = ''

local function startRoll(dkpType, itemLink)
    local partyMembers = GetNumGroupMembers()
    if partyMembers == 0 then
        FDKP:logError('Вы не состоите в группе (рейде).')
		return
    end
    if not FDKP.types[dkpType] then
        FDKP:logError('Неизвестный тип DKP.')
        return
    end
	local itemID = tonumber(itemLink:match("item:(%d+)"))
	if itemID then
        FDKP_ADDON:SendData(FDKP_CHANNEL_ITEM_ROLL_START, 'RAID', nil, {math.random(1000000, 9999999), 'item:' .. itemID, dkpType})
        FDKP:logInfo('Начинаю DKP аукцион за предмет %s&e!', itemLink)
    else
        FDKP:logError('Вы не указали предмет, который должен разыгрываться на DKP аукционе.')
	end
end

local function showDKP(targetName)
    targetName = FDKP:filterPlayerName(targetName)
    local dkp = {}
    for dkpType, naming in pairs(FDKP.types) do
        local dkps = FDKP_CURRENT_STATE.dkp[dkpType]
        if dkps and dkps[targetName] and dkps[targetName] ~= 0 then
            dkp[#dkp + 1] = {dkpType, naming, dkps[targetName]}
        end
    end
    local playerData = FDKP_CURRENT_STATE.playerData[targetName]
    local coloredTargetname, guildName
    if playerData then
        coloredTargetName, guildName = FDKP:getClassColorById(playerData[1]) .. targetName, playerData[2]
    else
        coloredTargetName, guildName = FDKP:format('&7%s', targetName), FDKP:colorize('&7Гильдия неизвестна')
    end
    if #dkp > 0 then
        FDKP:logInfo('DKP игрока %s&e (&a%s&e):', coloredTargetName, guildName)
        for _, value in pairs(dkp) do
            FDKP:logInfo('- %d %s DKP (%s)', value[3], value[1], value[2])
        end
    else
        FDKP:logInfo('У %s&e всё по нулям.', coloredTargetName)
    end
end

function FDKP:handleCommand()
	local cmd = ''
	local args = {}
	for substring in lastMsg:gmatch('%S+') do
		if cmd == '' then
			cmd = string.lower(substring)
		else
			args[#args + 1] = substring
		end
	end
    if cmd == 'change' then
        if not FDKP:isOfficer() and not FDKP:isAdmin() then
            FDKP:logError('Эта команда доступна лишь офицерам и администраторам аддона.')
            return
        end
        if #args < 3 then
            FDKP:logInfo('Корректное использование: /fdkp change <тип dkp> <ник игрока> <количество dkp> <причина или ничего>')
		else
            if string.match(args[3], "^%d+$") and math.floor(args[3]) > 0 then
                local playerName, dkpType, dkpDelta, reason = args[2], string.upper(args[1]), math.floor(args[3]), ''
                if not FDKP.types[dkpType] then
                    FDKP:logError('Неизвестный тип DKP.')
                    return
                end
                if #args >= 4 then reason = FDKP:implode(args, ' ', 4) end
                FDKP:logInfo('Создаю запись об изменении DKP..')
                FDKP_BINLOG:compileDkpChangeRecord({playerName}, dkpType, dkpDelta, reason)
            else
                FDKP:logError('Количество DKP должно быть натуральным числом. ')
			end
		end
	elseif cmd == 'roll' then
        if not FDKP:isOfficer() and not FDKP:isAdmin() then
            FDKP:logError('Эта команда доступна лишь офицерам и администраторам аддона.')
            return
        end
        if #args < 2 then
            FDKP:logInfo('Корректное использование: /fdkp roll <тип dkp> <предмет>')
			return
        end
		startRoll(string.upper(args[1]), FDKP:implode(args, ' ', 2))
    elseif cmd == 'show' then
        showDKP(args[1])
	elseif cmd == 'ver' or cmd == 'vrs' or cmd == 'version' then
        FDKP:logInfo('Версия аддона: &a%s&e.', FDKP.version)
	elseif cmd == "help" then
        print("# Пламягорыш")
        if FDKP:isOfficer() or FDKP:isAdmin() then
        print('#    - /fdkp change <тип dkp> <ник игрока> <количество dkp> <причина> - изменить DKP игрока')
        print('#    - /fdkp roll <тип dkp> <предмет> - начать DKP-аукцион за предмет среди вашего рейда')
        end
        print('#    - /fdkp show <ник игрока или ничего> - показать DKP игрока')
        print('#    - /fdkp version - узнать версию установленного аддона')
        print(FDKP:colorize('# Вопросы? Спрашивай Махича (&3https://vk.com/ks&r) :)'))
    else
        if FDKP:isOfficer() or FDKP:isAdmin() then
            FDKP:logInfo('/fdkp (change | roll | show | version) <аргументы>')
        else
            FDKP:logInfo('/fdkp (show | version) <аргументы>')
        end
	end
end

SLASH_FlamegorDKP1 = '/fdkp'
function SlashCmdList.FlamegorDKP(msg, editbox)
    lastMsg = msg
    if FDKP.debug then
        FDKP:handleCommand()
    else
        local status, err = pcall(FDKP["handleCommand"])
        if status == false then
            FDKP:logError('Ошибка при обработке команды &e%s&c: &e%s', msg, err)
        end
    end
end