local _M = {}

--- As of Kong v1.0.3, DAO framework doesn't support `select_by_<FIELD>` for fields of type `foreign`.
-- That's why we provide a custom best effort implementation.
function _M:select_by_consumer(consumer_id)
  -- TODO(yskopets): Totally inefficient. Must be reworked once DAO framework is improved.
  -- If scan-based approach is completely unacceptable,
  -- there is an option to introduce a synthetic `cache_key` field similarly to `plugins` entity.
  for credential, err in self.super.each(self, 1000) do
    if err then
      return nil, err
    end

    if credential and credential.consumer and credential.consumer.id == consumer_id then
      return credential
    end
  end

  return nil
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
