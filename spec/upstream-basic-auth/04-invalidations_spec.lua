local helpers = require "spec.helpers"
local admin_api = require "spec.fixtures.admin_api"
local cjson = require "cjson"

for _, strategy in helpers.each_strategy() do
  describe("Plugin: upstream-basic-auth (invalidations) [#" .. strategy .. "]", function()
    local admin_client
    local proxy_client
    local db

    lazy_setup(function()
      _, db = helpers.get_db_utils(strategy, {
        "routes",
        "services",
        "consumers",
        "plugins",
        "basicauth_credentials",
        "upstreambasicauth_credentials",
      }, {"upstream-basic-auth"})

      assert(helpers.start_kong({
        database   = strategy,
        plugins    = "bundled,upstream-basic-auth",
        nginx_conf = "spec/fixtures/custom_nginx.template",
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong()
    end)

    local service
    local route
    local basic_auth_plugin
    local upstream_basic_auth_plugin
    local consumer
    local credential
    local upstream_credential

    before_each(function()
      proxy_client = helpers.proxy_client()
      admin_client = helpers.admin_client()

      if not service then
        service = admin_api.services:insert {
          path = "/request",
        }
      end

      if not route then
        route = admin_api.routes:insert {
          hosts   = { "basic-auth.com" },
          service = { id = service.id },
        }
      end

      if not basic_auth_plugin then
        basic_auth_plugin = admin_api.plugins:insert {
          name = "basic-auth",
          route = { id = route.id },
        }
      end

      if not upstream_basic_auth_plugin then
        upstream_basic_auth_plugin = admin_api.plugins:insert {
          name = "upstream-basic-auth",
          route = { id = route.id },
        }
      end

      if not consumer then
        consumer = admin_api.consumers:insert {
          username = "bob",
        }
      end

      if not credential then
        credential = admin_api.basicauth_credentials:insert {
          username = "bob",
          password = "kong",
          consumer = { id = consumer.id },
        }
      end

      if not upstream_credential then
        upstream_credential = assert(db.upstreambasicauth_credentials:insert {
          username = "king",
          password = "kong",
          consumer = { id = consumer.id },
        })

        -- NOTE: since 1) Kong caches negative responses
        -- and 2) direct DB manipulations from this unit test don't trigger cache invalidation,
        -- we have to explicitly invalidate cache

        helpers.wait_until(function()
          local cache_key = db.upstreambasicauth_credentials:cache_key(consumer.id)
          local res = assert(admin_client:send {
            method = "DELETE",
            path = "/cache/" .. cache_key
          })
          res:read_body()
          return res.status == 204
        end)
      end
    end)

    after_each(function()
      if admin_client and proxy_client then
        admin_client:close()
        proxy_client:close()
      end
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
      local cache_key = db.upstreambasicauth_credentials:cache_key(consumer_id)
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
      consumer = nil
      credential = nil
      upstream_credential = nil

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
      local cache_key = db.upstreambasicauth_credentials:cache_key(consumer_id)
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
      upstream_credential = nil

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
      local cache_key = db.upstreambasicauth_credentials:cache_key(consumer_id)
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
      upstream_credential = nil

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
end
