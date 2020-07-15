function FDKP:isMaster()
    return FDKP_MASTER_PRIVATE_KEY:len() > 0
end

function FDKP:isAdmin(playerName, checkKey)
    if checkKey == nil then checkKey = true end
    if checkKey and not playerName and FDKP_ADMIN_PRIVATE_KEY:len() == 0 then return false end
    playerName = FDKP:filterPlayerName(playerName)
    for _, value in pairs(FDKP_CURRENT_STATE.adminNames) do
        if value == playerName then
            return true
        end
    end
    return false
end

function FDKP:isOfficer(playerName)
    playerName = FDKP:filterPlayerName(playerName)
    for _, value in pairs(FDKP_CURRENT_STATE.officerNames) do
        if value == playerName then
            return true
        end
    end
    return false
end

function FDKP:isBlacklisted(playerName)
    playerName = FDKP:filterPlayerName(playerName)
    for _, value in pairs(FDKP_CURRENT_STATE.blacklist) do
        if value == playerName then
            return true
        end
    end
    return false
end