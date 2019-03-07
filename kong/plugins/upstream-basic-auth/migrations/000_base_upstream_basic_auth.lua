return {
  postgres = {
    up = [[
      CREATE TABLE IF NOT EXISTS upstreambasicauth_credentials(
        id uuid,
        consumer_id uuid,
        username text,
        password text,
        created_at timestamp,
        PRIMARY KEY (id)
      );

      CREATE UNIQUE INDEX IF NOT EXISTS upstreambasicauth_credentials_i1 ON upstreambasicauth_credentials(consumer_id);

      ALTER TABLE upstreambasicauth_credentials
       DROP CONSTRAINT IF EXISTS upstreambasicauth_consumer_fk;

      ALTER TABLE upstreambasicauth_credentials
	   ADD CONSTRAINT upstreambasicauth_consumer_fk
	   FOREIGN KEY (consumer_id)
	   REFERENCES consumers(id) ON DELETE CASCADE;
    ]],
  },

  cassandra = {
    up =  [[
      CREATE TABLE IF NOT EXISTS upstreambasicauth_credentials(
        id uuid,
        consumer_id uuid,
        username text,
        password text,
        created_at timestamp,
        PRIMARY KEY (id)
      );

      CREATE INDEX IF NOT EXISTS upstreambasicauth_credentials_i1 ON upstreambasicauth_credentials(consumer_id);
    ]],
  },
}
