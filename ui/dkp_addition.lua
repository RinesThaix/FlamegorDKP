local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0")
local mainTableName = 'Изменение DKP'

local rowWidth = 2.7
local maxButtonsPerRow = 3

local tableNames = {}
local types = {
    WB = {
        {'Азурегос', 100},
        {'Каззак', 100},
        {'Летон', 100},
        {'Эмерисс', 100},
        {'Таэрар', 100},
        {'Исондра', 100}
    }
}

local gui = AceGUI:Create('FDRaidingHelperFrame')
gui:Hide()
gui:SetWidth(495)
gui:SetHeight(375)

local function openDkpTypeAdditionFrame(dkpType)
    AceConfigDialog:Open(tableNames[dkpType], gui)
end

local function collectRaidMemberNames()
    local partyMembers = GetNumGroupMembers()
    if partyMembers <= 5 then
        FDKP:logError('Вы не состоите в рейдовой группе.')
		return false
	end
	local result = {}
    for i = 1, partyMembers do
		local playerName = GetRaidRosterInfo(i)
        result[#result + 1] = playerName
    end
    return result
end

local mainContent = {
    typeSelection = {
        name = 'Тип DKP',
        type = "header",
        order = 1
    }
}
local mainOrder = 2
for techName, _ in pairs(types) do
    mainOrder = mainOrder + 1
    mainContent[techName] = {
        name = FDKP.types[techName],
        width = rowWidth,
        type = 'execute',
        func = function()
            openDkpTypeAdditionFrame(techName)
        end,
        order = mainOrder
    }
end
LibStub:GetLibrary("AceConfig-3.0"):RegisterOptionsTable(mainTableName, {
    type = "group",
    args = mainContent
})

for techName, data in pairs(types) do
    local content = {
        minusHeader = {
            name = 'Забрать DKP',
            type = 'header',
            order = 1
        },
        minus100 = {
            name = '-100 DKP',
            desc = 'Забрать у всех участников рейда 100 DKP.',
            type = 'execute',
            func = function()
                local playerNames = collectRaidMemberNames()
                if not playerNames then return end
                FDKP_BINLOG:compileDkpChangeRecord(playerNames, techName, -100, 'Ошибка')
            end,
            width = rowWidth,
            order = 2
        },
        plusHeader = {
            name = 'Выдать DKP',
            type = 'header',
            order = 3
        }
    }
    local order = 4
    local totalButtons = #data
    local lastRow = floor((totalButtons - 1) / maxButtonsPerRow)
    local buttonsInLastRow = totalButtons % maxButtonsPerRow
    if buttonsInLastRow == 0 then buttonsInLastRow = maxButtonsPerRow end
    for index, button in pairs(data) do
        local reason, delta = button[1], button[2]
        local row = floor((index - 1) / maxButtonsPerRow)
        local width = 0
        if row == lastRow then
            width = rowWidth / buttonsInLastRow
        else
            width = rowWidth / maxButtonsPerRow
        end
        content[reason] = {
            name = reason .. ' (+' .. delta .. ' DKP)',
            desc = 'Выдать всем участникам рейда ' .. delta .. ' DKP.',
            type = 'execute',
            func = function()
                local playerNames = collectRaidMemberNames()
                if not playerNames then return end
                FDKP_BINLOG:compileDkpChangeRecord(playerNames, techName, delta, reason)
            end,
            width = width,
            order = order
        }
        order = order + 1
    end
    local tableName = 'Изменение DKP: ' .. FDKP.types[techName]
    tableNames[techName] = tableName
    LibStub:GetLibrary("AceConfig-3.0"):RegisterOptionsTable(tableName, {
        type = "group",
        args = content
    })
end

function FDKP:toggleDkpAdditionFrame()
    if gui:IsShown() then
        gui:Hide()
    else
        AceConfigDialog:Open(mainTableName, gui)
    end
end