# HammerNotion

A plugin for automating page creation in Notion via [Hammerspoon](https://www.hammerspoon.org/).

Works only on MacOS.

## Why?

I often find myself with a need of recording something with as little context switching as possible. For example, I'm on a call, listening to my stakeholder, and I want to quickly record a task for myself without changing the apps. I use Notion as a task db, so I needed something that works with it.

With HammerNotion, I use a keyboard shortcut <kbd>CMD</kbd> + <kbd>CTRL</kbd> + <kbd>Q</kbd>, write `todo this is an important task!` in the opened modal, and a page gets created in Notion.

## Installation

**It's not an official Spoon yet.** I plan to add it when I finish some of the todos, therefor installation and configuration might take some additional steps.

1. Install Hammerspoon.
2. Create a 'Spoons' dir in your `.hammerspoon` dir.
3. Create a `HammerNotion.spoon` dir in `Spoons`.
4. Download and copy `init.lua` to `HammerNotion.spoon` dir.
5. (Optional) Download and install [Seal](https://www.hammerspoon.org/Spoons/Seal.html) spoon to get launch bar capabilities.

## Configuration

1. Create your integration in Notion https://www.notion.so/my-integrations and get your secret token. Remember to add create permissions.
2. Connect this integration to the database page you wish to automate.
3. Create two files in your `.hammerspoon` dir: `notion-config.json` and `notion-secret.json`

`notion-secret.json` keeps your API secret and should look like this:

```json
{
  "api_key": "YOUR_SECRET"
}
```

`notion-config.json` stores your HammerNotion config.

```json
{
  "NAME_OF_DB": {
    "type": "database_id",
    "database_id": "YOUR_DATABASE_ID",
    "properties": {
      "first": {
        "key": "Name",
        "type": "title"
      },
      "s": {
        "key": "Status",
        "type": "select"
      },
      "u": {
        "key": "Url",
        "type": "url"
      }
    }
  }
}
```

- NAME_OF_DB - name you will use to in the code.
- type - keep it as is.
- database_id - id of our database.
- properties - hash with your properties. It has the key used in your query (`first` is an exception), `key` expected by Notion API (name of the field), and `type` (property type in Notion). Right now HammerNotion supports 3 properties: title, select, url.

Examples in the usage section.

## Usage and Examples

_Remember that this only works when you are online as Notion API is used to save new pages._

The scanarios below use Seal spoon.

### Simple scenario

Create a config file.

```json
{
  "todo": {
    "type": "database_id",
    "database_id": "YOUR_DATABASE_ID",
    "properties": {
      "first": {
        "key": "Name",
        "type": "title"
      },
      "s": {
        "key": "Status",
        "type": "select"
      }
    }
  }
}
```

In your `.hammerspoon/init.lua` prepare the code for automation.

```lua
hs.loadSpoon("Seal")
hs.loadSpoon("HammerNotion")

hn = spoon.HammerNotion
hn:loadConfig(true) -- this loads config, true flag start debug mode, additional info is printed to the console.

spoon.Seal:loadPlugins({ "useractions" })
spoon.Seal:bindHotkeys({
	toggle = { { "cmd", "ctrl" }, "Q" }, -- map keys from Seal.
})

spoon.Seal.plugins.useractions.actions = {
	["Todo"] = {
		keyword = "todo",
		fn = function(query)
			local query = query .. "|s:Todo" -- manually add the status to query.
			local properties = hn:getProperties(query, "|", ":", "todo") -- get the table with properties prepared for notion.
			hn:createPage("todo", properties) -- create a page in todo database.
		end,
	},
}
spoon.Seal:start()

```

After hitting the key combination, the Seal launcher will open, and you need to type `todo {your page title}` + <kbd>ENTER</kbd>, and the page will be created in status Todo.

### Advanced scenario

Hammernotion let's you write queries that will setup multiple fields on your page, you need to set up properties in the config file as well as seperators for query.

```json
{
  "talkwith": {
    "type": "database_id",
    "database_id": "YOUR_DATABASE_ID",
    "properties": {
      "first": {
        "key": "Name",
        "type": "title"
      },
      "w": {
        "key": "With",
        "type": "select"
      }
    }
  }
}
```

In your `.hammerspoon/init.lua` prepare the code for automation.

```lua
hs.loadSpoon("Seal")
hs.loadSpoon("HammerNotion")

hn = spoon.HammerNotion
hn:loadConfig(true) -- this loads config, true flag start debug mode, additional info is printed to the console.

spoon.Seal:loadPlugins({ "useractions" })
spoon.Seal:bindHotkeys({
	toggle = { { "cmd", "ctrl" }, "Q" }, -- map keys from Seal.
})

spoon.Seal.plugins.useractions.actions = {
	["Talk With"] = {
		keyword = "talk",
		fn = function(query)
			local properties = hn:getProperties(query, "|", ":", "talkwith") -- | seperator defines how fields are split, : defines key value seperator.
			hn:createPage("talkwith", properties) -- create a page in todo database.
		end,
	},
}
spoon.Seal:start()

```

After hitting the key combination, the Seal launcher will open, and you can type `talk {your page title} | w:Adam` + <kbd>ENTER</kbd>, and the page will be created with property `With` with value `Adam`.

## Todo

- [ ] Add more Notion API properties
