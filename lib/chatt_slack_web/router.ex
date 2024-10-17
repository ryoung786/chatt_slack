defmodule ChattSlackWeb.Router do
  use ChattSlackWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", ChattSlackWeb do
    pipe_through(:api)

    get "/ping", SlashCommandController, :ping
    post "/", SlashCommandController, :slash_command
    post "/interactivity", SlashCommandController, :interactivity
  end
end
