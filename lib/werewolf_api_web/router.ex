defmodule WerewolfApiWeb.Router do
  use WerewolfApiWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :authenticated do
    plug(
      Guardian.Plug.Pipeline,
      module: WerewolfApi.Guardian,
      error_handler: WerewolfApi.AuthErrorHandler
    )

    plug(WerewolfApi.AuthAccessPipeline)
  end

  scope "/api", WerewolfApiWeb do
    pipe_through(:api)
    resources("/users", UserController, only: [:create])
    resources("/sessions", SessionController, only: [:create])
    resources("/forgotten_password", ForgottenPasswordController, only: [:create, :update])

    # routes below must be authenticated
    pipe_through(:authenticated)
    resources("/users", UserController, only: [:show])
  end
end
