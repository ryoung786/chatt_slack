import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :chatt_slack, slack_channel: "bot-test"

config :chatt_slack,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :chatt_slack, ChattSlackWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ChattSlackWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ChattSlack.PubSub,
  live_view: [signing_salt: "Je1nXpQz"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
