function Initialize()
    wwingUserFolder = os.getenv("USERPROFILE") .. "\\wwing\\"
    userVarsPath = wwingUserFolder .. "variables.inc"
end

function WriteUserKey(key, newValue)
    local fileIn = io.open(userVarsPath, "r")
    local fileTemp = {}
    for line in fileIn:lines() do
        if not line:match("^" .. key .. "=") then
            fileTemp[#fileTemp + 1] = line
        else
            fileTemp[#fileTemp + 1] = key .. "=" .. newValue
        end
    end
    fileIn:close()
    local fileOut = io.open(userVarsPath, "w")
    for i = 1, #fileTemp do
        fileOut:write(fileTemp[i] .. "\n")
    end
    fileOut:close()
    return true
end

function Update()
end
