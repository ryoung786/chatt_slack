import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :chatt_slack, ChattSlackWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "/O2PHowyWBJCw04Ltt1TFIEQ8fb8t0cd9nl+XpWYEwaDvko3WkU5TzpdvgpmA8WF",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
