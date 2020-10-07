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
  check_origin: false,
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

config :phoenix, :json_library, Jason

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

config :exq,
  name: Exq,
  host: "127.0.0.1",
  port: 6379,
  namespace: "exq",
  # limited from infinite as we're using them with the db
  concurrency: 20,
  queues: ["default"],
  poll_timeout: 50,
  scheduler_poll_timeout: 200,
  scheduler_enable: true,
  max_retries: 25,
  shutdown_timeout: 5000,
  start_on_application: false

config :werewolf_api, WerewolfApi.Scheduler,
  jobs: [
    # Every day at 5:00 with 10 hour timer
    {"0 4 * * *", {WerewolfApi.Game.Scheduled, :setup, [10, "five_minute", "Daily Asia Game"]}},
    # Every day at 15:00 with 5 hour timer
    {"0 14 * * *", {WerewolfApi.Game.Scheduled, :setup, [5, "five_minute", "Daily Europe Game"]}},
    # Every day at 20:00 with 6 hour timer
    {"0 19 * * *",
     {WerewolfApi.Game.Scheduled, :setup, [6, "five_minute", "Daily Americas Game"]}}
    # Every 6 hours
    # {"0 */6 * * *", {WerewolfApi.Game.Scheduled, :setup, [6, "thirty_minute"]}},
    # Every 24 hours at 16:00
    # {"0 16 * * *", {WerewolfApi.Game.Scheduled, :setup, [24, "day"]}}
  ]

config :werewolf_api, dynamic_url: WerewolfApi.Game.DynamicLink

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
