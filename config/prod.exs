import Config

# Do not print debug messages in production
config :logger, level: :info

config :chatt_slack, slack_channel: "run-plans"

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
