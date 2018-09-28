defmodule WerewolfApiWeb.GameController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.Game
  alias WerewolfApi.Repo

  # only send games where users_game state is not rejected

  def create(conn, %{"game" => game_params}) do
    user = Guardian.Plug.current_resource(conn)

    changeset = Game.changeset(%Game{}, game_params, user)

    case Repo.insert(changeset) do
      {:ok, game} ->
        game = Repo.preload(game, users_games: :user, game_messages: :user)

        # do we need to handle game creation failure, or just let it fail?
        {:ok, _} = WerewolfApi.GameServer.start_game(user, game.id, :day)

        update_state(game)

        conn
        |> put_status(:created)
        |> render("show.json", game: game)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json", changeset: changeset)
    end
  end

  defp update_state(game) do
    Task.async(fn ->
      {:ok, state} = WerewolfApi.GameServer.get_state(game.id)
      {:ok, game} = WerewolfApi.Game.update_state(game, state)
      WerewolfApiWeb.UserChannel.broadcast_game_creation_to_users(game)
    end)
  end
end
