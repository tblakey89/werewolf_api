defmodule WerewolfApiWeb.Router do
  use WerewolfApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", WerewolfApiWeb do
    pipe_through :api
  end
end
