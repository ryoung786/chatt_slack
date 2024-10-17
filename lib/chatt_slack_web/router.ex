defmodule ChattSlackWeb.Router do
  use ChattSlackWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", ChattSlackWeb do
    pipe_through(:api)

    get "/ping", SlackController, :ping
    post "/interactivity", SlackController, :interactivity
  end
end
