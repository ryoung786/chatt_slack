import Config

if Config.config_env() in [:dev, :test] do
  DotenvParser.load_file(".env")
end

config :chatt_slack, :slack, bot_token: System.fetch_env!("SLACK_BOT_TOKEN")
config :chatt_slack, :google_calendar, calendar_id: System.fetch_env!("GOOGLE_CALENDAR_ID")

config :chatt_slack,
  service_account:
    System.fetch_env!("SERVICE_ACCOUNT_BASE64")
    |> Base.decode64!()
    |> Jason.decode!()
