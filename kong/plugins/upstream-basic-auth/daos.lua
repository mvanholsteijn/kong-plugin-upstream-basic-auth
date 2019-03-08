local typedefs = require "kong.db.schema.typedefs"

return {
  upstreambasicauth_credentials = {
    name = "upstreambasicauth_credentials",
    primary_key = { "id" },

    -- NOTE: while a proper solution would be 'cache_key = { "consumer" }',
    -- as of Kong 1.0.3, it fails with 'schema violation (cache_key: a field used as a single cache key must be unique)'.
    -- TODO(yskopets): Utilize once DAO framework is improved

    -- NOTE: we have to override DAO to provide custom implementation of `select_by_consumer`
    -- TODO(yskopets): Eliminate once DAO framework is improved
    dao         = "kong.plugins.upstream-basic-auth.upstreambasicauth_credentials",

    fields = {
      { id = typedefs.uuid },
      { created_at = typedefs.auto_timestamp_s },
      { consumer = { type = "foreign", reference = "consumers", default = ngx.null, on_delete = "cascade" } },
      { username = { type = "string", required = true } },
      { password = { type = "string", required = true } },
    },
  },
}
