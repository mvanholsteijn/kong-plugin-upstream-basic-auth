local helpers = require "spec.helpers"
local cjson = require "cjson"

for _, strategy in helpers.each_strategy() do
  describe("Plugin: upstream-basic-auth (access) [#" .. strategy .. "]", function()
    local proxy_client

    lazy_setup(function()
      local bp, db = helpers.get_db_utils(strategy, {
        "routes",
        "services",
        "plugins",
        "consumers",
        "basicauth_credentials",
        "upstreambasicauth_credentials",
      }, {"upstream-basic-auth"})

      local service1 = bp.services:insert {
        path = "/request",
      }
      local route1 = bp.routes:insert {
        hosts   = { "upstream-basic-auth1.com" },
        service = service1,
      }
      bp.plugins:insert {
        name  = "basic-auth",
        route = { id = route1.id },
      }
      bp.plugins:insert {
        name  = "upstream-basic-auth",
        route = { id = route1.id },
      }

      local service2 = bp.services:insert {
        path = "/request",
      }
      local route2 = bp.routes:insert {
        hosts        = { "upstream-basic-auth2.com" },
        service = service2,
      }
      bp.plugins:insert {
        name  = "upstream-basic-auth",
        route = { id = route2.id },
      }

      local consumer1 = bp.consumers:insert {
        username = "bob",
      }
      bp.basicauth_credentials:insert {
        username = "bob",
        password = "kong",
        consumer = { id = consumer1.id },
      }
      assert(db.upstreambasicauth_credentials:insert {
        username = "king",
        password = "kong",
        consumer = { id = consumer1.id },
      })

      local consumer2 = bp.consumers:insert {
        username = "nancy",
      }
      bp.basicauth_credentials:insert {
        username = "nancy",
        password = "reagan",
        consumer = { id = consumer2.id },
      }

      assert(helpers.start_kong({
        log_level  = "debug",
        database   = strategy,
        plugins    = "bundled,upstream-basic-auth",
        nginx_conf = "spec/fixtures/custom_nginx.template",
      }))

      proxy_client = helpers.proxy_client()
    end)


    lazy_teardown(function()
      if proxy_client then
        proxy_client:close()
      end

      helpers.stop_kong()
    end)


    describe("Insert basic-auth header", function()

      it("sends a new basic authorization header to upstream", function()
        local res = assert(proxy_client:send {
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
        local res = assert(proxy_client:send {
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
        local res = assert(proxy_client:send {
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
end
