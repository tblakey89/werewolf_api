defmodule WerewolfApiWeb.GameController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.Game
  alias WerewolfApi.Repo

  # create game controller function
  # do we want to include host as a game user
  # do the front end create game dialog
  # commit
  # do invitations for users
  # front end receiving invitation for users
  # commit

  def create(conn, %{"game" => game_params}) do
    user = Guardian.Plug.current_resource(conn)

    changeset = Game.changeset(%Game{}, game_params, user)

    case Repo.insert(changeset) do
      {:ok, game} ->
        game = Repo.preload(game, [:users])
        conn
        |> put_status(:created)
        |> render("show.json", game: game)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json", changeset: changeset)
    end
  end
end
