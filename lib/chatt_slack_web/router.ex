defmodule ChattSlackWeb.Router do
  use ChattSlackWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", ChattSlackWeb do
    pipe_through(:api)

    # get "/", SlashCommandController, :slash_command
    post "/", SlashCommandController, :slash_command
    post "/interactivity", SlashCommandController, :interactivity
  end
end
