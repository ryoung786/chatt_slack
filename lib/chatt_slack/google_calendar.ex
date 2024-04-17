defmodule ChattSlack.GoogleCalendar do
  def get_tomorrows_events() do
    calendar_id =
      Application.fetch_env!(:chatt_slack, :google_calendar) |> Keyword.fetch!(:calendar_id)

    token = Goth.fetch!(ChattSlack.Goth)
    conn = GoogleApi.Calendar.V3.Connection.new(token.token)
    tomorrow = DateTime.now!("America/New_York") |> DateTime.to_date() |> Date.add(1)

    {:ok, %{items: events}} =
      GoogleApi.Calendar.V3.Api.Events.calendar_events_list(
        conn,
        calendar_id,
        singleEvents: true,
        order_by: "startTime",
        timeMin: "#{tomorrow}T00:00:00-04:00",
        timeMax: "#{tomorrow}T23:59:59-04:00"
      )

    for event <- events, do: IO.inspect(event)
    events
  end
end
