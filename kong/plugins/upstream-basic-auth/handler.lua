local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.upstream-basic-auth.access"

local BasicAuthInsertHandler = BasePlugin:extend()

function BasicAuthInsertHandler:new()
  BasicAuthInsertHandler.super.new(self, "upstream-basic-auth")
end

function BasicAuthInsertHandler:access(conf)
  BasicAuthInsertHandler.super.access(self)
  access.execute(conf)
end

BasicAuthInsertHandler.PRIORITY = 500
BasicAuthInsertHandler.VERSION = "0.2.0"

return BasicAuthInsertHandler
