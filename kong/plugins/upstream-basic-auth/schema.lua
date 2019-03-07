local typedefs = require "kong.db.schema.typedefs"


return {
  name = "upstream-basic-auth",
  fields = {
    { consumer = typedefs.no_consumer },
    { config = {
      type = "record",
      fields = {},
    }, },
  }
}
