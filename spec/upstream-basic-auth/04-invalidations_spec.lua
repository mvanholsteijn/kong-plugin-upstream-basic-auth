local helpers = require "spec.helpers"
local cjson = require "cjson"

describe("Plugin: upstream-basic-auth (invalidations)", function()
  local admin_client, proxy_client

  before_each(function()
    helpers.dao:truncate_tables()
    helpers.run_migrations()
    local api = assert(helpers.dao.apis:insert {
      name         = "api-1",
      hosts        = { "basic-auth.com" },
      upstream_url = helpers.mock_upstream_url,
    })
    assert(helpers.dao.plugins:insert {
      name   = "basic-auth",
      api_id = api.id,
    })
    assert(helpers.dao.plugins:insert {
      name   = "upstream-basic-auth",
      api_id = api.id,
    })

    local consumer = assert(helpers.dao.consumers:insert {
      username = "bob",
    })
    assert(helpers.dao.basicauth_credentials:insert {
      username    = "bob",
      password    = "kong",
      consumer_id = consumer.id,
    })
    assert(helpers.dao.upstreambasicauth_credentials:insert {
      username    = "king",
      password    = "kong",
      consumer_id = consumer.id,
    })


    assert(helpers.start_kong({
      nginx_conf = "spec/fixtures/custom_nginx.template",
    }))
    proxy_client = helpers.proxy_client()
    admin_client = helpers.admin_client()
  end)

  after_each(function()
    if admin_client and proxy_client then
      admin_client:close()
      proxy_client:close()
    end
    helpers.stop_kong()
  end)

  it("invalidates credentials when the Consumer is deleted", function()
    -- populate cache
    local res = assert(proxy_client:send {
      method = "GET",
      path = "/",
      headers = {
        ["Authorization"] = "Basic Ym9iOmtvbmc=",
        ["Host"] = "basic-auth.com"
      }
    })
    local body = assert.res_status(200, res)
    local json = cjson.decode(body)
    local consumer_id = json.headers["x-consumer-id"]

    -- ensure cache is populated
    local cache_key = helpers.dao.upstreambasicauth_credentials:cache_key(consumer_id)
    res = assert(admin_client:send {
      method = "GET",
      path = "/cache/" .. cache_key
    })
    assert.res_status(200, res)

    -- delete Consumer entity
    res = assert(admin_client:send {
      method = "DELETE",
      path = "/consumers/bob"
    })
    assert.res_status(204, res)

    -- ensure cache is invalidated
    helpers.wait_until(function()
      local res = assert(admin_client:send {
        method = "GET",
        path = "/cache/" .. cache_key
      })
      res:read_body()
      return res.status == 404
    end)

    res = assert(proxy_client:send {
      method = "GET",
      path = "/",
      headers = {
        ["Authorization"] = "Basic Ym9iOmtvbmc=",
        ["Host"] = "basic-auth.com"
      }
    })
    assert.res_status(403, res)
  end)

  it("invalidates credentials from cache when deleted", function()
    -- populate cache
    local res = assert(proxy_client:send {
      method = "GET",
      path = "/",
      headers = {
        ["Authorization"] = "Basic Ym9iOmtvbmc=",
        ["Host"] = "basic-auth.com"
      }
    })
    local body = assert.res_status(200, res)
    local json = cjson.decode(body)
    local consumer_id = json.headers["x-consumer-id"]

    -- ensure cache is populated
    local cache_key = helpers.dao.upstreambasicauth_credentials:cache_key(consumer_id)
    res = assert(admin_client:send {
      method = "GET",
      path = "/cache/" .. cache_key
    })
    local body = assert.res_status(200, res)
    local credential = cjson.decode(body)

    -- delete credential entity
    res = assert(admin_client:send {
      method = "DELETE",
      path = "/consumers/bob/upstream-basic-auth/" .. credential.id
    })
    assert.res_status(204, res)

    -- ensure cache is invalidated
    helpers.wait_until(function()
      local res = assert(admin_client:send {
        method = "GET",
        path = "/cache/" .. cache_key
      })
      res:read_body()
      return res.status == 404
    end)

    res = assert(proxy_client:send {
      method = "GET",
      path = "/",
      headers = {
        ["Authorization"] = "Basic Ym9iOmtvbmc=",
        ["Host"] = "basic-auth.com"
      }
    })
    local body = assert.res_status(403, res)
    local json = cjson.decode(body)
    assert.same({ message = "no basic auth credentials available for consumer" }, json)
  end)

  it("invalidated credentials from cache when updated", function()
    -- populate cache
    local res = assert(proxy_client:send {
      method = "GET",
      path = "/",
      headers = {
        ["Authorization"] = "Basic Ym9iOmtvbmc=",
        ["Host"] = "basic-auth.com"
      }
    })
    local body = assert.res_status(200, res)
    local json = cjson.decode(body)
    local consumer_id = json.headers["x-consumer-id"]

    -- ensure cache is populated
    local cache_key = helpers.dao.upstreambasicauth_credentials:cache_key(consumer_id)
    res = assert(admin_client:send {
      method = "GET",
      path = "/cache/" .. cache_key
    })
    local body = assert.res_status(200, res)
    local credential = cjson.decode(body)

    -- delete credential entity
    res = assert(admin_client:send {
      method = "PATCH",
      path = "/consumers/bob/upstream-basic-auth/" .. credential.id,
      body = {
        username = "king",
        password = "kong-updated"
      },
      headers = {
        ["Content-Type"] = "application/json"
      }
    })
    assert.res_status(200, res)

    -- ensure cache is invalidated
    helpers.wait_until(function()
      local res = assert(admin_client:send {
        method = "GET",
        path = "/cache/" .. cache_key
      })
      res:read_body()
      return res.status == 404
    end)

    res = assert(proxy_client:send {
      method = "GET",
      path = "/",
      headers = {
        ["Authorization"] = "Basic Ym9iOmtvbmc=",
        ["Host"] = "basic-auth.com"
      }
    })
    local body = assert.res_status(200, res)
    local json = cjson.decode(body)
    assert.is_string(json.headers["x-consumer-id"])
    assert.equal("bob", json.headers["x-consumer-username"])
    assert.equal("Basic a2luZzprb25nLXVwZGF0ZWQ=", json.headers["authorization"])
  end)
end)
