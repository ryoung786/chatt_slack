defmodule ChattSlack.EventReminder do
  use GenServer
  require Logger

  alias ChattSlack.Slack
  alias ChattSlack.GoogleCalendar

  @tz Application.compile_env(:chatt_slack, :timezone)
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

  def event_to_message(event, include_date? \\ false) do
    summary = "<#{event["htmlLink"]}|#{event["summary"]}>"

    time = fmt_datetime(event["start"]["dateTime"], include_date?)
    time = time && "• Time: #{time}"

    location =
      event["location"] &&
        "• Location: <#{google_maps_link(event["location"])}|#{event["location"]}>"

    [summary, time, location] |> Enum.filter(& &1) |> Enum.join("\n")
  end

  defp google_maps_link(query) do
    "http://maps.google.com/?#{URI.encode_query(%{"q" => query})}"
  end

  defp fmt_datetime(nil, _include_date?), do: nil

  defp fmt_datetime(datetime_str, include_date?) when is_binary(datetime_str) do
    {:ok, dt, _} = DateTime.from_iso8601(datetime_str)
    fmt_datetime(dt, include_date?)
  end

  defp fmt_datetime(%DateTime{} = dt, include_date?) do
    time_fmt = "%1I:%M%P"
    dt = DateTime.shift_zone!(dt, @tz)

    if include_date? do
      cur_year = DateTime.now!(@tz).year
      date_fmt = if dt.year == cur_year, do: "%A, %b %d", else: "%A, %b %d, %Y"
      Calendar.strftime(dt, time_fmt <> " " <> date_fmt)
    else
      Calendar.strftime(dt, time_fmt)
    end
  end
end
