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

if System.get_env("PHX_SERVER") do
  config :chatt_slack, ChattSlackWeb.Endpoint, server: true
end

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || raise "env variable PHX_HOST not set"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :chatt_slack, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :chatt_slack, ChattSlackWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base
end
