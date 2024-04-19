import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :chatt_slack, slack_channel: "bot-test"

if config_env() == :prod do
  config :chatt_slack, slack_channel: "run-plans"
end
