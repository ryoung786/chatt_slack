defmodule ChattSlack.Slack do
  use GenServer
  defstruct [:channels, :req]

  ######################################################################
  # CLIENT

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: Slack)
  end

  def refresh_channels() do
    GenServer.cast(Slack, :refresh_channels)
  end

  def send_message(channel_name, message) do
    GenServer.cast(Slack, {:send_message, channel_name, message})
  end

  ######################################################################
  # SERVER

  @impl true
  def init(_) do
    bot_token = Application.fetch_env!(:chatt_slack, :slack) |> Keyword.fetch!(:bot_token)
    req = Req.new(base_url: "https://slack.com/api", auth: {:bearer, bot_token})
    {:ok, %__MODULE__{channels: channels(req), req: req}}
  end

  @impl true
  def handle_cast(:refresh_channels, state) do
    {:noreply, %{state | channels: channels(state.req)}}
  end

  @impl true
  def handle_cast({:send_message, channel_name, message}, state) do
    channel_id = state.channels[channel_name]

    Req.post(state.req,
      url: "chat.postMessage",
      params: %{channel: channel_id, text: message}
    )

    {:noreply, state}
  end

  ######################################################################
  # HELPERS

  defp channels(req) do
    {:ok, resp} = Req.get(req, url: "conversations.list")
    Map.new(resp.body["channels"], fn channel -> {channel["name"], channel["id"]} end)
  end
end
