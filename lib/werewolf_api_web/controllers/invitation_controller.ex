defmodule WerewolfApiWeb.InvitationController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.UsersGame
  alias WerewolfApi.Repo

  def update(conn, %{"id" => id, "users_game" => users_game_params}) do
    user = Guardian.Plug.current_resource(conn)

    with {:ok, users_game} <- find_users_game(id, user),
         changeset <- UsersGame.update_state_changeset(users_game, users_game_params),
         :ok <- WerewolfApi.GameServer.add_player(users_game.game_id, user),
         {:ok, users_game} <- Repo.update(changeset) do
      WerewolfApiWeb.UserChannel.broadcast_game_update(users_game.game)
      render(conn, "success.json", %{users_game: users_game})
    else
      {:error, :invitation_not_found} -> invitation_not_found(conn)
      {:error, %Ecto.Changeset{} = changeset} -> unprocessable_entity(conn, changeset)
      {:error, message} -> game_error(conn, message)
    end
  end

  defp find_users_game(id, user) do
    case Repo.get_by(UsersGame, id: id, user_id: user.id) do
      nil ->
        {:error, :invitation_not_found}

      users_game ->
        users_game = Repo.preload(users_game, :game)
        {:ok, users_game}
    end
  end

  defp invitation_not_found(conn) do
    conn
    |> put_status(404)
    |> render("error.json", message: "Invitation not found")
  end

  defp unprocessable_entity(conn, changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> render("error.json", changeset: changeset)
  end

  defp game_error(conn, message) do
    conn
    |> put_status(:unprocessable_entity)
    |> render("error.json", message: message)
  end
end
