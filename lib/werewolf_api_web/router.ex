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
    get("/me", UserController, :me)

    resources "/users", UserController, only: [:show, :index, :update] do
      put("/avatar", UserController, :avatar, as: :avatar)
    end

    resources "/conversations", ConversationController, only: [:create, :index, :show] do
      resources("/messages", MessageController, only: [:index])
    end

    resources("/games", GameController, only: [:index, :create, :update])
    resources("/invitations", InvitationController, only: [:show, :create, :update, :delete])

    resources("/friends", FriendController, only: [:create, :update])
    resources("/blocks", BlockController, only: [:create])
  end
end
