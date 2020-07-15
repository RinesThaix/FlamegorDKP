FDKP_CLASSES = {}

FDKP_CLASSES[#FDKP_CLASSES + 1] = {'Воин', {'Воин'}, '|cffC79C6E'}
FDKP_CLASSES[#FDKP_CLASSES + 1] = {'Друид', {'Друид'}, '|cffFF7D0A'}
FDKP_CLASSES[#FDKP_CLASSES + 1] = {'Жрец', {'Жрец', 'Жрица'}, '|cffFFFFFF'}
FDKP_CLASSES[#FDKP_CLASSES + 1] = {'Маг', {'Маг'}, '|cff40C7EB'}
FDKP_CLASSES[#FDKP_CLASSES + 1] = {'Охотник', {'Охотник', 'Охотница'}, '|cffA9D271'}
FDKP_CLASSES[#FDKP_CLASSES + 1] = {'Разбойник', {'Разбойник', 'Разбойница'}, '|cffFFF569'}
FDKP_CLASSES[#FDKP_CLASSES + 1] = {'Чернокнижник', {'Чернокнижник', 'Чернокнижница'}, '|cff8787ED'}
FDKP_CLASSES[#FDKP_CLASSES + 1] = {'Шаман', {'Шаман', 'Шаманка'}, '|cff0070DE'}

function FDKP:getClassIdByName(className)
    for index, data in pairs(FDKP_CLASSES) do
        for _, name in pairs(data[2]) do
            if name == className then return index end
        end
    end
    return 0
end

function FDKP:getClassNameById(classID)
    return FDKP_CLASSES[classID][1]
end

function FDKP:getClassColorById(classID)
    return FDKP_CLASSES[classID][3]
end