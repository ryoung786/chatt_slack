defmodule ChattSlack.MixProject do
  use Mix.Project

  def project do
    [
      app: :chatt_slack,
      version: "0.1.1",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      time_zone_database: Tzdata.TimeZoneDatabase,
      mod: {ChattSlack.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:goth, "~> 1.4"},
      {:req, "~> 0.5.1"},
      {:google_api_calendar, "~> 0.23.1"},
      {:tzdata, "~> 1.1"},
      {:phoenix, "~> 1.7.14"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      {:dotenv_parser, "~> 2.0", only: [:dev, :test]}
    ]
  end
end
