defmodule ChattSlack.MixProject do
  use Mix.Project

  def project do
    [
      app: :chatt_slack,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      time_zone_database: Tzdata.TimeZoneDatabase,
      mod: {ChattSlack.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:goth, "~> 1.4"},
      {:req, "~> 0.4.14"},
      {:google_api_calendar, "~> 0.23.1"},
      {:tzdata, "~> 1.1"},
      {:dotenv_parser, "~> 2.0", only: [:dev, :test]}
    ]
  end
end
