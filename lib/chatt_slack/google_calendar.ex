defmodule ChattSlack.GoogleCalendar do
  @tz Application.compile_env(:chatt_slack, :timezone)

  defp req() do
    token = Goth.fetch!(ChattSlack.Goth)

    Req.new(
      base_url: "https://www.googleapis.com/calendar/v3",
      auth: {:bearer, token.token}
    )
  end

  defp calendar_id() do
    Application.fetch_env!(:chatt_slack, :google_calendar) |> Keyword.fetch!(:calendar_id)
  end

  def get_tomorrows_events() do
    tomorrow = DateTime.now!(@tz) |> DateTime.to_date() |> Date.add(1)

    %{"items" => events} =
      Req.get!(
        req(),
        url: "calendars/#{calendar_id()}/events",
        params: [
          singleEvents: true,
          order_by: "startTime",
          timeMin: "#{tomorrow}T00:00:00-04:00",
          timeMax: "#{tomorrow}T23:59:59-04:00"
        ]
      ).body

    events
  end

  def insert_event(event) do
    emoji =
      case event.type do
        :run -> "👟"
        :race -> "🏅"
        :bday -> "🎂"
        _fun -> "✨"
      end

    freq =
      case event.recurring do
        "weekly" -> ["RRULE:FREQ=WEEKLY"]
        "monthly" -> ["RRULE:FREQ=MONTHLY;BYMONTHDAY=#{event.start.day}"]
        "yearly" -> ["RRULE:FREQ=YEARLY"]
        _ -> nil
      end

    Req.post!(req(),
      url: "calendars/#{calendar_id()}/events",
      json: %{
        summary: emoji <> " #{event.title} " <> emoji,
        description: event.description,
        location: event.location,
        start: %{dateTime: event.start, timeZone: @tz},
        end: %{dateTime: event.stop, timeZone: @tz},
        recurrence: freq
      }
    )
  end
end
