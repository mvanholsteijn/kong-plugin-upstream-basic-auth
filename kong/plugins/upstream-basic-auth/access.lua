local singletons = require "kong.singletons"
local constants = require "kong.constants"
local responses = require "kong.tools.responses"
local req_get_headers = ngx.req.get_headers
local req_set_header = ngx.req.set_header
local req_clear_header = ngx.req.clear_header
local encode_base64 = ngx.encode_base64

local _M = {}

local function load_credential_into_memory(consumer_id)
  local credentials, err = singletons.dao.upstreambasicauth_credentials:find_all {consumer_id = consumer_id}
  if err then
    return nil, err
  end
  return credentials[1]
end

local function load_credential_from_db(consumer_id)
  local credential_cache_key = singletons.dao.upstreambasicauth_credentials:cache_key(consumer_id)
  local credential, err      = singletons.cache:get(credential_cache_key, nil,
                                                    load_credential_into_memory,
                                                    consumer_id)
  return credential, err
end

local function transform_headers(conf)
  local consumer_id = req_get_headers()[constants.HEADERS.CONSUMER_ID]
  if consumer_id then
    local credential = load_credential_from_db(consumer_id)
    if credential then
	req_clear_header("authorization")
	local token = encode_base64(credential.username .. ":" .. credential.password)
	req_set_header("authorization", "Basic " .. token )
    else
      responses.send(403, "no basic auth credentials available for consumer")
    end
  else
    responses.send(403, "no unauthenticated access allowed")
  end
end

function _M.execute(conf)
  transform_headers(conf)
end

return _M
