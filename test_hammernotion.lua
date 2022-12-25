lu = require("luaunit")
hn = require("init")

-- mock config
hn.config = {
	todo = {
		properties = {
			first = {
				key = "Name",
				type = "title",
			},
			s = {
				key = "Status",
				type = "select",
			},
		},
	},
}

-- processing properties

function testProcessingTitleProperty()
	lu.assertEquals(hn:processProperty("title", "Title"), { title = { { text = { content = "Title" } } } })
end

function testProcessingSelectProperty()
	lu.assertEquals(hn:processProperty("select", "Category"), { select = { name = "Category" } })
end

function testProcessingUrlProperty()
	lu.assertEquals(hn:processProperty("url", "https://example.com"), { url = "https://example.com" })
end

-- getting properties

function testFirst()
	query = "Title"
	result = { Name = { title = { { text = { content = "Title" } } } } }
	lu.assertEquals(hn:getProperties(query, "|", ":", "todo"), result)
end

function testSplit()
	query = "Title | s: Todo"
	result = {
		Name = { title = { { text = { content = "Title" } } } },
		Status = { select = { name = "Todo" } },
	}
	lu.assertEquals(hn:getProperties(query, "|", ":", "todo"), result)
end

os.exit(lu.LuaUnit.run())
