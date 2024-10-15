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

  def send_modal(trigger_id) do
    GenServer.cast(Slack, {:send_modal, trigger_id})
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
      params: %{channel: channel_id, text: message, unfurl_links: false, unfurl_media: false}
    )

    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_modal, trigger_id}, state) do
    Req.post(
      state.req,
      url: "views.open",
      json: %{trigger_id: trigger_id, view: modal_view()}
    )

    {:noreply, state}
  end

  ######################################################################
  # HELPERS

  defp channels(req) do
    {:ok, resp} = Req.get(req, url: "conversations.list")
    Map.new(resp.body["channels"], fn channel -> {channel["name"], channel["id"]} end)
  end

  def modal_view() do
    # now = DateTime.now!("America/New_York")

    %{
      type: "modal",
      title: %{type: "plain_text", text: "Run Plans", emoji: true},
      close: %{type: "plain_text", text: "Cancel", emoji: true},
      submit: %{type: "plain_text", text: "Create", emoji: true},
      blocks: [
        %{
          type: "input",
          element: %{
            type: "plain_text_input",
            action_id: "title",
            placeholder: %{type: "plain_text", text: "Example: Big Daddy Loops"}
          },
          label: %{type: "plain_text", text: "Title", emoji: true}
        },
        %{
          type: "input",
          element: %{
            type: "plain_text_input",
            action_id: "location",
            placeholder: %{type: "plain_text", text: "Example: Ruby Falls parking lot"}
          },
          label: %{type: "plain_text", text: "Location", emoji: true}
        },
        %{
          type: "input",
          element: %{
            type: "plain_text_input",
            multiline: true,
            action_id: "description",
            placeholder: %{type: "plain_text", text: "Any details you want to add"}
          },
          label: %{type: "plain_text", text: "Description", emoji: true}
        },
        %{
          type: "input",
          element: %{
            type: "datetimepicker",
            action_id: "start-time"
            # initial_date: DateTime.to_date(now),
            # initial_time: Calendar.strftime(now, "%H:%M")
          },
          label: %{type: "plain_text", text: "Label", emoji: true}
        }
      ]
    }
  end
end
