defmodule ChattSlackWeb.SlashCommandController do
  use ChattSlackWeb, :controller

  alias ChattSlack.Slack
  alias ChattSlack.GoogleCalendar

  def slash_command(conn, %{"command" => "/run"} = params) do
    Slack.send_modal(params["trigger_id"], :run)
    Plug.Conn.send_resp(conn, 200, [])
  end

  def slash_command(conn, %{"command" => "/fun"} = params) do
    Slack.send_modal(params["trigger_id"], :fun)
    Plug.Conn.send_resp(conn, 200, [])
  end

  def slash_command(conn, %{"command" => "/race"} = params) do
    Slack.send_modal(params["trigger_id"], :race)
    Plug.Conn.send_resp(conn, 200, [])
  end

  def slash_command(conn, _params), do: Plug.Conn.send_resp(conn, 200, [])

  def interactivity(conn, %{"payload" => payload}) do
    payload = Jason.decode!(payload)

    if payload["type"] == "shortcut" do
      event_type =
        case payload["callback_id"] do
          "create_run" -> :run
          "create_fun" -> :fun
        end

      Slack.send_modal(payload["trigger_id"], event_type)
    end

    if payload["type"] == "view_submission" do
      Task.start(fn ->
        values =
          payload["view"]["state"]["values"]
          |> Map.values()
          |> Map.new(fn
            %{"title" => %{"value" => v}} -> {:title, String.trim(v)}
            %{"description" => %{"value" => v}} -> {:description, String.trim(v)}
            %{"location" => %{"value" => v}} -> {:location, String.trim(v)}
            %{"start-time" => %{"selected_date_time" => v}} -> {:start, DateTime.from_unix!(v)}
            %{"frequency" => %{"selected_option" => opt}} -> {:frequency, opt["value"]}
          end)

        {type, channel} =
          case payload["view"]["title"]["text"] do
            "Run Plans" -> {:run, "run-plans"}
            "Fun Plans" -> {:fun, "fun-plans"}
            "Race Plans" -> {:race, "run-plans"}
            _ -> {:fun, "fun-plans"}
          end

        with %{status: 200} = res <-
               GoogleCalendar.insert_event(
                 type,
                 values.title,
                 values.start,
                 DateTime.add(values.start, 1, :hour),
                 description: values.description,
                 location: values.location,
                 recurring: values.frequency
               ) do
          {:ok, start, _} = res.body["start"]["dateTime"] |> DateTime.from_iso8601()

          event = %{
            htmlLink: res.body["htmlLink"],
            summary: res.body["summary"],
            start: %{dateTime: start},
            location: res.body["location"]
          }

          Slack.send_message(
            channel,
            "*A new #{type} event was created*\n\n" <>
              ChattSlack.EventReminder.event_to_message(event)
          )
        end
      end)
    end

    json(conn, %{})
  end
end
