defmodule ChattSlack.EventReminder do
  use GenServer
  require Logger

  alias ChattSlack.Slack
  alias ChattSlack.GoogleCalendar

  @tz "America/New_York"
  @notification_time ~T[12:00:00]
  @channel Application.compile_env(:chatt_slack, :slack_channel)

  ######################################################################
  # CLIENT

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: EventReminder)
  end

  def run_now() do
    GenServer.cast(EventReminder, :run_now)
  end

  ######################################################################
  # SERVER

  @impl true
  def init(_) do
    schedule_work()
    {:ok, %{}}
  end

  @impl true
  def handle_cast(:run_now, state) do
    GoogleCalendar.get_tomorrows_events() |> announce_in_slack()
    Logger.info("event reminders sent to slack (via run_now)")
    {:noreply, state}
  end

  @impl true
  def handle_info(:do_work, state) do
    schedule_work()
    GoogleCalendar.get_tomorrows_events() |> announce_in_slack()
    Logger.info("event reminders sent to slack")
    {:noreply, state}
  end

  ######################################################################
  # HELPERS

  defp announce_in_slack([]) do
    Slack.send_message(@channel, "No events planned for tomorrow.")
  end

  defp announce_in_slack(events) do
    Slack.send_message(@channel, "*Tomorrow's events*")
    for event <- events, do: Slack.send_message(@channel, event_to_message(event))
  end

  defp schedule_work() do
    tomorrow = DateTime.now!(@tz) |> DateTime.to_date() |> Date.add(1)
    alarm = DateTime.new!(tomorrow, @notification_time, @tz)

    Process.send_after(
      self(),
      :do_work,
      DateTime.diff(alarm, DateTime.now!(@tz), :millisecond)
    )

    Logger.info("scheduled event reminder announcement for #{alarm}")
  end

  def event_to_message(event) do
    summary = "<#{event.htmlLink}|#{event.summary}>"

    time =
      case event.start.dateTime do
        nil ->
          nil

        start_time ->
          start_time
          |> DateTime.shift_zone!(@tz)
          |> Calendar.strftime("%1I:%M%P")
      end

    time = time && "• Time: #{time}"

    location =
      event.location && "• Location: <#{google_maps_link(event.location)}|#{event.location}>"

    [summary, time, location] |> Enum.filter(& &1) |> Enum.join("\n")
  end

  defp google_maps_link(query) do
    "http://maps.google.com/?#{URI.encode_query(%{"q" => query})}"
  end
end
