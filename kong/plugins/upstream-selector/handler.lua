local BasePlugin = require "kong.plugins.base_plugin"

local UpstreamSelectorHandler = BasePlugin:extend()

UpstreamSelectorHandler.PRIORITY = 480

function UpstreamSelectorHandler:new()
  UpstreamSelectorHandler.super.new(self, "upstream-selector")
end

function UpstreamSelectorHandler:access(conf)
  UpstreamSelectorHandler.super.access(self)
end

return UpstreamSelectorHandler
