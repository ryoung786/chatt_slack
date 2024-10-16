defmodule ChattSlack.GoogleCalendar do
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
    tomorrow = DateTime.now!("America/New_York") |> DateTime.to_date() |> Date.add(1)

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

  def insert_event(type, title, %DateTime{} = start, %DateTime{} = stop, opts \\ []) do
    emoji =
      case type do
        :run -> "👟"
        :race -> "🏅"
        :bday -> "🎂"
        _fun -> "✨"
      end

    freq =
      case opts[:recurring] do
        "weekly" -> ["RRULE:FREQ=WEEKLY"]
        "monthly" -> ["RRULE:FREQ=MONTHLY;BYMONTHDAY=#{start.day}"]
        "yearly" -> ["RRULE:FREQ=YEARLY"]
        _ -> nil
      end

    Req.post!(req(),
      url: "calendars/#{calendar_id()}/events",
      json: %{
        summary: emoji <> " #{title} " <> emoji,
        description: opts[:description],
        location: opts[:location],
        start: %{dateTime: start, timeZone: "America/New_York"},
        end: %{dateTime: stop, timeZone: "America/New_York"},
        recurrence: freq
      }
    )
  end
end
