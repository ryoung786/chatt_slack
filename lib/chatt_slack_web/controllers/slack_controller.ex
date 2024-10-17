defmodule ChattSlackWeb.SlackController do
  use ChattSlackWeb, :controller

  alias ChattSlack.Slack
  alias ChattSlack.GoogleCalendar

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

        # Call Google API to create the Calendar Event
        # On success, send a slack msg to the appropriate channel to announce it
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

          channel = if type in [:run, :race], do: "run-plans", else: "fun-plans"

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
