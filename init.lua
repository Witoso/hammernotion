local HammerNotion = {}
HammerNotion.__index = HammerNotion

HammerNotion.name = "HammerNotion"
HammerNotion.version = "0.1"
HammerNotion.author = "Witek Socha"
HammerNotion.license = "MIT - https://opensource.org/licenses/MIT"
HammerNotion.homepage = ""

function HammerNotion:loadConfig(debug)
    if debug then
        self.debug = true
    end
    local secretFilename = "notion-secret.json"
    local configFilename = "notion-config.json"
    local hammerspoonPath = hs.spoons.scriptPath(3)
    local secrets = hs.json.read(hammerspoonPath .. secretFilename)
    self.apiKey = secrets["api_key"]
    self.config = hs.json.read(hammerspoonPath .. configFilename)
end

function HammerNotion:sendNotionPostRequest(jsonData)

    local url = "https://api.notion.com/v1/pages"
    local headers = {}
    headers["Content-Type"] = "application/json"
    headers["Notion-Version"] = "2022-06-28"
    headers["Authorization"] = "Bearer " .. self.apiKey

    local statusCode, response, headers = hs.http.post(url, jsonData, headers)
    return statusCode, response, headers
end

function HammerNotion:createPage(databaseName, properties)
    local data = {}
    data.parent = {}
    data.parent.type = self.config[databaseName].type
    data.parent["database_id"] = self.config[databaseName]["database_id"]
    data.properties = properties
    local jsonData = hs.json.encode(data)

    local statusCode, _response, _headers = self:sendNotionPostRequest(jsonData)
    if debug then
        print(statusCode)
        print(_response)
        print(jsonData)
    end
    if statusCode == 200 then
        hs.alert.show("New page added to database: " .. databaseName)
    else
        hs.alert.show("Error adding task. Status Code: " .. statusCode)
    end
end

local function split(str, pat)
    local t = {} -- NOTE: use {n = 0} in Lua-5.0
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t, cap)
        end
        last_end = e + 1
        s, e, cap = str:find(fpat, last_end)
    end
    if last_end <= #str then
        cap = str:sub(last_end)
        table.insert(t, cap)
    end
    return t
end

local function trim(string)
    return (string:gsub("^%s*(.-)%s*$", "%1"))
end

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function processProperty(propertyInfo, input)
    if propertyInfo.type == "title" then
        return {
            title = {{
                text = {
                    content = input
                }
            }}
        }
    elseif propertyInfo.type == "select" then
        return {
            select = {
                name = input
            }
        }
    elseif propertyInfo.type == "url" then
        local urlField = propertyInfo.key
        return {
            url = input
        }
    end
end

function HammerNotion:getProperties(string, splitPattern, databaseName)

    local t = split(string, splitPattern)
    local databaseProperties = deepcopy(self.config[databaseName].properties)

    local propertyInfo = {}
    local properties = {}
    for index, value in ipairs(t) do
        local content = trim(value)
        if index == 1 then
            propertyInfo = databaseProperties["$first"]
            properties[propertyInfo.key] = processProperty(propertyInfo, content)
            databaseProperties["$first"] = nil
        end
        --  iterate if it maches any pattern in properties
        local t = split(content, "->")
        for key, value2 in pairs(databaseProperties) do
            if key == t[1] then
                propertyInfo = databaseProperties[t[1]]
                properties[propertyInfo.key] = processProperty(propertyInfo, trim(t[2]))
                databaseProperties[key] = nil
            end
        end
    end
    -- print(hs.json.encode(properties))
    return properties
end

return HammerNotion
