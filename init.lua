local HammerNotion = {}
HammerNotion.__index = HammerNotion

HammerNotion.name = "HammerNotion"
HammerNotion.version = "0.1"
HammerNotion.author = "Witek Socha"
HammerNotion.license = "GPL v3"
HammerNotion.homepage = "https://github.com/Witoso/hammernotion"

-- HELPERS

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
	if orig_type == "table" then
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

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
local function tprint(tbl, indent)
	if not indent then
		indent = 0
	end
	for k, v in pairs(tbl) do
		local formatting = string.rep("  ", indent) .. k .. ": "
		if type(v) == "table" then
			print(formatting)
			tprint(v, indent + 1)
		elseif type(v) == "boolean" then
			print(formatting .. tostring(v))
		else
			print(formatting .. v)
		end
	end
end

-- HammerNotion helper functions

function HammerNotion:sendNotionPostRequest(jsonData)
	local url = "https://api.notion.com/v1/pages"
	local headers = {}
	headers["User-Agent"] = "HammerNotion / " .. self.version
	headers["Content-Type"] = "application/json"
	headers["Notion-Version"] = "2022-06-28"
	headers["Authorization"] = "Bearer " .. self.apiKey

	hs.http.asyncPost(url, jsonData, headers, function(statusCode, response, response_headers)
		if self.debug then
			print("Notion response:")
			print(statusCode)
			print(response)
			tprint(response_headers)
		end
		if statusCode == 200 then
			hs.notify.show("HammerNotion", "New page added!", "")
		else
			hs.notify.show("HammerNotion", "Error adding page. Status Code: " .. statusCode, "")
		end
	end)
end

function HammerNotion:processProperty(type, input)
	if type == "title" then
		return {
			title = { {
				text = {
					content = input,
				},
			} },
		}
	elseif type == "select" then
		return {
			select = {
				name = input,
			},
		}
	elseif type == "url" then
		return {
			url = input,
		}
	end
end

-- HammerNotion main functions

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

function HammerNotion:createPage(databaseName, properties)
	local data = {}
	data.parent = {}
	data.parent.type = self.config[databaseName].type
	data.parent["database_id"] = self.config[databaseName]["database_id"]
	data.properties = properties
	local jsonData = hs.json.encode(data)
	self:sendNotionPostRequest(jsonData)
end

function HammerNotion:getProperties(query, querySplitPattern, propertySplitPattern, databaseName)
	local splittedQuery = split(query, querySplitPattern)
	local databaseProperties = deepcopy(self.config[databaseName].properties)

	local properties = {}
	for index, value in ipairs(splittedQuery) do
		local content = trim(value)
		if index == 1 then
			local propertyInfo = databaseProperties["first"]
			properties[propertyInfo.key] = self:processProperty(propertyInfo.type, content)
			databaseProperties["first"] = nil
		end
		--  iterate if it maches any pattern in properties
		local splittedProperty = split(content, propertySplitPattern)
		for pattern, propertyInfo in pairs(databaseProperties) do
			if pattern == splittedProperty[1] then
				properties[propertyInfo.key] = self:processProperty(propertyInfo.type, trim(splittedProperty[2]))
				databaseProperties[pattern] = nil
			end
		end
	end
	if self.debug then
        print("Properties:")
		tprint(properties, 2)
	end
	return properties
end

return HammerNotion
