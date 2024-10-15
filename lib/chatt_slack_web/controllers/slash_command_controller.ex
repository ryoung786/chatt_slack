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

        type =
          case payload["view"]["title"]["text"] do
            "Run Plans" -> :run
            "Fun Plans" -> :fun
            "Race Plans" -> :race
            _ -> :fun
          end

        with %{status: 200} <-
               GoogleCalendar.insert_event(
                 type,
                 values.title,
                 values.start,
                 DateTime.add(values.start, 1, :hour),
                 description: values.description,
                 location: values.location,
                 recurring: values.frequency
               ) do
          Slack.send_message("bot-test", "New run created: #{values.title}")
        end
      end)
    end

    json(conn, %{})
  end
end
