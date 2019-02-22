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
        {:ok, state} = WerewolfApi.GameServer.get_state(game.id)

        conn
        |> put_status(:created)
        |> render("game_with_state.json", data: %{game: game, user: user, state: state})

      {:error, changeset} ->
        unprocessable_entity(conn, changeset)
    end
  end

  def update(conn, %{"id" => id, "game" => game_params}) do
    user = Guardian.Plug.current_resource(conn)

    game =
      Repo.get(Game, id)
      |> Repo.preload(users_games: :user, game_messages: :user)

    host_id = Game.find_host_id(game)

    with true <- user.id == host_id,
         changeset <- Game.update_changeset(game, game_params),
         {:ok, game} <- Repo.update(changeset),
         game <- Repo.preload(game, users_games: :user, game_messages: :user) do
      WerewolfApiWeb.UserChannel.broadcast_game_update(game)
      render(conn, "show.json", game: game)
    else
      false -> forbidden(conn)
      {:error, changeset} -> unprocessable_entity(conn, changeset)
    end
  end

  defp update_state(game) do
    Task.start_link(fn ->
      {:ok, state} = WerewolfApi.GameServer.get_state(game.id)
      {:ok, game} = WerewolfApi.Game.update_state(game, state)
      WerewolfApiWeb.UserChannel.broadcast_game_creation_to_users(game)
    end)
  end

  defp forbidden(conn) do
    conn
    |> put_status(:forbidden)
    |> render("error.json", message: "Not allowed.")
  end

  defp unprocessable_entity(conn, changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> render("error.json", changeset: changeset)
  end
end
