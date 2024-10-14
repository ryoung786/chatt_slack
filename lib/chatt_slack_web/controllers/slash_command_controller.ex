defmodule ChattSlackWeb.SlashCommandController do
  use ChattSlackWeb, :controller

  def slash_command(conn, %{"command" => "/run"} = params) do
    json(conn, response())
  end

  def slash_command(conn, params) do
    IO.inspect(conn, label: "[xxx] full conn")
    IO.inspect(conn.body_params, label: "[xxx] body_params")
    IO.inspect(params, label: "[xxx] params")
    json(conn, response())
  end

  def response() do
    now = DateTime.now!("America/New_York")

    %{
      blocks: [
        %{
          type: "input",
          element: %{
            type: "datepicker",
            initial_date: DateTime.to_date(now),
            placeholder: %{
              type: "plain_text",
              text: "Select a date",
              emoji: true
            },
            action_id: "datepicker-action"
          },
          label: %{
            type: "plain_text",
            text: "Label",
            emoji: true
          }
        },
        %{
          type: "input",
          element: %{
            type: "timepicker",
            initial_time: Calendar.strftime(now, "%H:%M"),
            placeholder: %{
              type: "plain_text",
              text: "Select time",
              emoji: true
            },
            action_id: "timepicker-action"
          },
          label: %{
            type: "plain_text",
            text: "Label",
            emoji: true
          }
        },
        %{
          type: "actions",
          elements: [
            %{
              type: "button",
              text: %{
                type: "plain_text",
                text: "Click Me",
                emoji: true
              },
              value: "click_me_123",
              action_id: "actionId-0"
            }
          ]
        }
      ]
    }
  end
end
