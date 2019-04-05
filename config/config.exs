# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :werewolf_api, ecto_repos: [WerewolfApi.Repo]

# Configures the endpoint
config :werewolf_api, WerewolfApiWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  url: [host: "localhost"],
  secret_key_base: "felaXnGnmezcInMWq2Hczr6lVrIVkMlX1d3OUs9BcCJ6t/H0GOXdpBQ5qRqxkf79",
  render_errors: [view: WerewolfApiWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: WerewolfApi.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :werewolf_api, WerewolfApi.AuthAccessPipeline,
  module: WerewolfApi.Guardian,
  error_handler: WerewolfApi.AuthErrorHandler

config :arc,
  bucket: {:system, "S3_BUCKET"},
  virtual_host: true

config :ex_aws,
  access_key_id: {:system, "AWS_ACCESS_KEY_ID"},
  secret_access_key: {:system, "AWS_SECRET_ACCESS_KEY"},
  region: "eu-west-2",
  s3: [
    scheme: "https://",
    host: "s3.eu-west-2.amazonaws.com",
    region: "eu-west-2"
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
