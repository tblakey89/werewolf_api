use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :werewolf_api, WerewolfApiWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :werewolf_api, WerewolfApi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "werewolf_api_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :werewolf_api, WerewolfApi.Guardian,
  issuer: "werewolf_api",
  secret_key: "beGjn1KAEwkutwiO28Y0rFy6Hbs0sLnY6obeUmbpTP9PbV6OrHh4qjgewFw9zanL"
