return {
  postgres = {
    up = [[
      ALTER TABLE IF EXISTS ONLY "upstreambasicauth_credentials"
        ALTER "created_at" TYPE TIMESTAMP WITH TIME ZONE USING "created_at" AT TIME ZONE 'UTC',
        ALTER "created_at" SET DEFAULT CURRENT_TIMESTAMP(0) AT TIME ZONE 'UTC';
    ]],
  },

  cassandra = {
    up = [[
    ]],
  },
}
