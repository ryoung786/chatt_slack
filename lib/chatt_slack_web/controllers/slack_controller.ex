defmodule ChattSlackWeb.SlackController do
  use ChattSlackWeb, :controller

  alias ChattSlack.Slack
  alias ChattSlack.GoogleCalendar
  alias ChattSlack.EventReminder

  def ping(conn, _params) do
    json(conn, %{ping: "pong"})
  end

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
        # unpack the payload form values
        event =
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
            "Race Plans" -> :race
            _ -> :fun
          end

        event = Map.merge(event, type: type, stop: DateTime.add(event.start, 1, :hour))

        # Call Google API to create the Calendar Event
        # On success, send a slack msg to the appropriate channel to announce it
        with %{status: 200, body: event} <- GoogleCalendar.insert_event(event) do
          channel = if type in [:run, :race], do: "run-plans", else: "fun-plans"
          msg = "*A new #{type} event was created*\n\n" <> EventReminder.event_to_message(event)
          Slack.send_message(channel, msg)
        end
      end)
    end

    json(conn, %{})
  end
end
