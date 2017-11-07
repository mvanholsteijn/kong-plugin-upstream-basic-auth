
local SCHEMA = {
  primary_key = {"id"},
  table = "upstreambasicauth_credentials",
  cache_key = { "consumer_id" },
  fields = {
    id = {type = "id", dao_insert_value = true},
    created_at = {type = "timestamp", immutable = true, dao_insert_value = true},
    consumer_id = {type = "id", unique = true, required = true, foreign = "consumers:id"},
    username = {type = "string", required = true},
    password = {type = "string", required = true}
  },
}

return {upstreambasicauth_credentials = SCHEMA}
