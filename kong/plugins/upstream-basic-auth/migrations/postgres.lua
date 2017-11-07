return {
  {
    name = "2017-10-30-upstream-basic-auth",
    up =  [[
      CREATE TABLE IF NOT EXISTS upstreambasicauth_credentials(
        id uuid,
        consumer_id uuid,
        username text,
        password text,
        created_at timestamp,
        PRIMARY KEY (id)
      );

      CREATE UNIQUE INDEX IF NOT EXISTS upstreambasicauth_credentials_i1 ON upstreambasicauth_credentials(consumer_id);
      CREATE UNIQUE INDEX IF NOT EXISTS upstreambasicauth_credentials_i2 ON upstreambasicauth_credentials(username);
    ]],
    down = [[
      DROP TABLE upstreambasicauth_credentials;
    ]]
  },
  {
    name = "2017-11-07-upstream-basic-auth-non-unique-user-name",
    up =  [[
      DROP INDEX upstreambasicauth_credentials_i2;
    ]],
    down = [[
      CREATE UNIQUE INDEX IF NOT EXISTS upstreambasicauth_credentials_i2 ON upstreambasicauth_credentials(username);
    ]]
  }
}
