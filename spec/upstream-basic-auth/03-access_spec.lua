local helpers = require "spec.helpers"
local cjson = require "cjson"

describe("Plugin: upstream-basic-auth (access)", function()

  local client

  setup(function()
    helpers.run_migrations()

    local api1 = assert(helpers.dao.apis:insert {
      name         = "api-1",
      hosts        = { "upstream-basic-auth1.com" },
      upstream_url = helpers.mock_upstream_url,
    })
    assert(helpers.dao.plugins:insert {
      name   = "basic-auth",
      api_id = api1.id,
    })

    assert(helpers.dao.plugins:insert {
      name   = "upstream-basic-auth",
      api_id = api1.id,
    })

    local api2 = assert(helpers.dao.apis:insert {
      name         = "api-2",
      hosts        = { "upstream-basic-auth2.com" },
      upstream_url = helpers.mock_upstream_url,
    })
    assert(helpers.dao.plugins:insert {
      name   = "upstream-basic-auth",
      api_id = api2.id,
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

    local consumer = assert(helpers.dao.consumers:insert {
      username = "nancy",
    })
    assert(helpers.dao.basicauth_credentials:insert {
      username    = "nancy",
      password    = "reagan",
      consumer_id = consumer.id,
    })

    assert(helpers.start_kong({
      nginx_conf = "spec/fixtures/custom_nginx.template",
    }))
    client = helpers.proxy_client()
  end)


  teardown(function()
    if client then client:close() end
    helpers.stop_kong()
  end)


  describe("Insert basic-auth header", function()

    it("sends a new basic authorization header to upstream", function()
      local res = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          ["Authorization"] = "Basic Ym9iOmtvbmc=",
          ["Host"] = "upstream-basic-auth1.com"
        }
      })
      local body = assert.res_status(200, res)
      local json = cjson.decode(body)
      assert.is_string(json.headers["x-consumer-id"])
      assert.equal("bob", json.headers["x-consumer-username"])
      assert.equal("Basic a2luZzprb25n", json.headers["authorization"])
    end)

    it("sends refuse to forward if no upstream-basic-auth credentials are present", function()
      local res = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          ["Authorization"] = "Basic bmFuY3k6cmVhZ2Fu",
          ["Host"] = "upstream-basic-auth1.com"
        }
      })
      local body = assert.res_status(403, res)
      local json = cjson.decode(body)
      assert.same({ message = "no basic auth credentials available for consumer" }, json)
    end)

    it("sends refuse to forward unauthenticated consumers", function()
      local res = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          ["Host"] = "upstream-basic-auth2.com"
        }
      })
      local body = assert.res_status(403, res)
      local json = cjson.decode(body)
      assert.same({ message = "no unauthenticated access allowed" }, json)
    end)


  end)
end)

