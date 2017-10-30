package = "kong-plugin-upstream-basic-auth" 
                                  
version = "0.1.0-1"               
-- The version '0.1.0' is the source code version, the trailing '1' is the version of this rockspec.
-- whenever the source version changes, the rockspec should be reset to 1. The rockspec version is only
-- updated (incremented) when this file changes, but the source remains the same.

supported_platforms = {"linux", "macosx"}
source = {
  url = "git://github.com/mvanholsteijn/kong-plugin-upstream-basic-auth",
  tag = "0.1.0"
}

description = {
  summary = "A plugin to insert basic authentication headers to the upstream.",
  home = "https://github.com/mvanholsteijn/kong-plugin-upstream-basic-auth",
  license = "MIT"
}

dependencies = {
}

local pluginName = "upstream-basic-auth" 
build = {
  type = "builtin",
  modules = {
    ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
    ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua",
  }
}
