defmodule ChattSlack.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChattSlack.Slack,
      ChattSlack.EventReminder,
      {Goth, name: ChattSlack.Goth, source: goth_source(), http_client: &Req.request/1},
      {DNSCluster, query: Application.get_env(:chatt_slack, :dns_cluster_query) || :ignore},
      ChattSlackWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChattSlack.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def goth_source() do
    credentials = Application.fetch_env!(:chatt_slack, :service_account)

    {:service_account, credentials,
     scopes: [
       "https://www.googleapis.com/auth/cloud-platform",
       "https://www.googleapis.com/auth/calendar",
       "https://www.googleapis.com/auth/calendar.events.readonly"
     ]}
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChattSlackWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
