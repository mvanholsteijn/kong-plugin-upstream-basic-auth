local endpoints = require "kong.api.endpoints"


local kong               = kong
local credentials_schema = kong.db.upstreambasicauth_credentials.schema
local consumers_schema   = kong.db.consumers.schema

return {
  ["/consumers/:consumers/upstream-basic-auth/"] = {
    schema = credentials_schema,
    methods = {
      GET = endpoints.get_collection_endpoint(
        credentials_schema, consumers_schema, "consumer"),

      POST = endpoints.post_collection_endpoint(
        credentials_schema, consumers_schema, "consumer"),
    },
  },
  ["/consumers/:consumers/upstream-basic-auth/:upstreambasicauth_credentials"] = {
    schema = credentials_schema,
    methods = {
      before = function(self, db)
        local consumer, _, err_t = endpoints.select_entity(self, db, consumers_schema)
        if err_t then
          return endpoints.handle_error(err_t)
        end
        if not consumer then
          return kong.response.exit(404, { message = "Not found" })
        end

        self.consumer = consumer

        if self.req.method ~= "PUT" then
          local cred, _, err_t = endpoints.select_entity(self, db, credentials_schema)
          if err_t then
            return endpoints.handle_error(err_t)
          end

          if not cred or cred.consumer.id ~= consumer.id then
            return kong.response.exit(404, { message = "Not found" })
          end

          self.upstreambasicauth_credential = cred
          self.params.upstreambasicauth_credentials = cred.id
        end
      end,

      GET  = endpoints.get_entity_endpoint(credentials_schema),
      PUT  = function(self, ...)
        self.args.post.consumer = { id = self.consumer.id }
        return endpoints.put_entity_endpoint(credentials_schema)(self, ...)
      end,
      PATCH  = endpoints.patch_entity_endpoint(credentials_schema),
      DELETE = endpoints.delete_entity_endpoint(credentials_schema),
    }
  }
}
