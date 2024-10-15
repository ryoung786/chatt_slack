defmodule ChattSlackWeb.SlashCommandController do
  use ChattSlackWeb, :controller

  alias ChattSlack.Slack
  alias ChattSlack.GoogleCalendar

  def slash_command(conn, %{"command" => "/run"} = params) do
    Slack.send_modal(params["trigger_id"])
    Plug.Conn.send_resp(conn, 200, [])
  end

  def slash_command(conn, params) do
    Plug.Conn.send_resp(conn, 200, [])
  end

  def interactivity(conn, params) do
    payload = Jason.decode!(params["payload"])

    if payload["type"] == "view_submission" do
      values =
        payload["view"]["state"]["values"]
        |> Map.values()
        |> Map.new(fn
          %{"title" => %{"value" => v}} -> {:title, String.trim(v)}
          %{"description" => %{"value" => v}} -> {:description, String.trim(v)}
          %{"location" => %{"value" => v}} -> {:location, String.trim(v)}
          %{"start-time" => %{"selected_date_time" => v}} -> {:start, DateTime.from_unix!(v)}
        end)

      Task.start(fn ->
        with %{status: 200} <-
               GoogleCalendar.insert_event(
                 :run,
                 values.title,
                 values.start,
                 DateTime.add(values.start, 1, :hour),
                 description: values.description,
                 location: values.location
               ) do
          Slack.send_message("bot-test", "New run created: #{values.title}")
        end
      end)
    end

    json(conn, %{})
  end
end
