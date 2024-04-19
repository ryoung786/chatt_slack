defmodule ChattSlack.EventReminder do
  use GenServer

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
    get_events_and_send_to_slack()
    {:noreply, state}
  end

  @impl true
  def handle_info(:do_work, state) do
    schedule_work()
    get_events_and_send_to_slack()
    {:noreply, state}
  end

  ######################################################################
  # HELPERS

  defp get_events_and_send_to_slack() do
    events = GoogleCalendar.get_tomorrows_events()

    header_msg =
      if Enum.empty?(events),
        do: "No events planned for tomorrow.",
        else: "Tomorrow's events"

    Slack.send_message(@channel, header_msg)

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
  end

  defp event_to_message(event) do
    time =
      case event.start.dateTime do
        nil ->
          nil

        start_time ->
          start_time
          |> DateTime.shift_zone!(@tz)
          |> Calendar.strftime("%1I:%M%P")
      end

    time = time && "Time: #{time}"
    location = event.location && "Location: #{event.location}"
    [event.summary, time, location] |> Enum.filter(& &1) |> Enum.join("\n")
  end
end
