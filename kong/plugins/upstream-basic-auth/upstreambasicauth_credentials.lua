local _M = {}

function _M:select_by_consumer(consumer_id)
  local credentials, err = self.super.page_for_consumer(self, {id = consumer_id}, 1)
  if err then
    return nil, err
  end
  if 0 < #credentials then
    return credentials[1]
  else
    return nil
  end
end


--- As of Kong v1.0.3, DAO framework doesn't support `cache_key` set to a field of type `foreign`.
-- That's why we provide a fake `cache_key` definition inside `daos.lua`,
-- while the actual caching behavior is implemented in here.
function _M:cache_key(key)
  if type(key) == "table" then
    return self.super.cache_key(self, key.consumer and key.consumer.id or "")
  else
    return self.super.cache_key(self, key)
  end
end


return _M
