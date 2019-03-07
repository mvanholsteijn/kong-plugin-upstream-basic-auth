local constants = require "kong.constants"
local encode_base64 = ngx.encode_base64
local kong = kong

local _M = {}

local function load_credential_into_memory(customer_id)
  local credential, err = kong.db.upstreambasicauth_credentials:select_by_consumer(customer_id)
  if err then
    return nil, err
  end
  return credential
end

local function load_credential_from_db(consumer_id)
  local credential_cache_key = kong.db.upstreambasicauth_credentials:cache_key(consumer_id)
  local credential, err      = kong.cache:get(credential_cache_key, nil,
                                                    load_credential_into_memory,
                                                    consumer_id)
  return credential, err
end

local function transform_headers(conf)
  local consumer_id = kong.request.get_header(constants.HEADERS.CONSUMER_ID)
  if consumer_id then
    local credential = load_credential_from_db(consumer_id)
    if credential then
      kong.service.request.clear_header("authorization")
	  local token = encode_base64(credential.username .. ":" .. credential.password)
      kong.service.request.set_header("authorization", "Basic " .. token)
    else
      kong.response.exit(403, { message = "no basic auth credentials available for consumer" })
    end
  else
    kong.response.exit(403, { message = "no unauthenticated access allowed" })
  end
end

function _M.execute(conf)
  transform_headers(conf)
end

return _M
