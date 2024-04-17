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
      {Goth, name: ChattSlack.Goth, source: goth_source(), http_client: &Req.request/1}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChattSlack.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp goth_source() do
    service_account = Application.fetch_env!(:chatt_slack, :service_account)

    credentials = %{
      "private_key" => Keyword.fetch!(service_account, :private_key),
      "client_email" => Keyword.fetch!(service_account, :client_email)
    }

    {:service_account, credentials,
     scopes: [
       "https://www.googleapis.com/auth/cloud-platform",
       "https://www.googleapis.com/auth/calendar",
       "https://www.googleapis.com/auth/calendar.events.readonly"
     ]}
  end
end
