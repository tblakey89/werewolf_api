defmodule WerewolfApiWeb.InvitationController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.UsersGame
  alias WerewolfApi.Game
  alias WerewolfApi.UsersGame
  alias WerewolfApi.Repo

  def show(conn, %{"id" => token}) do
    user = Guardian.Plug.current_resource(conn)

    with %Game{started: false} = game <- Repo.get_by(Game, invitation_token: token),
         nil <- Repo.get_by(UsersGame, game_id: game.id, user_id: user.id) do
      game = Repo.preload(game, users_games: :user)
      game_joinable(conn, game)
    else
      nil -> invitation_not_found(conn)
      %Game{started: true} -> already_started(conn)
      %UsersGame{} -> already_joined(conn)
    end
  end

  def create(conn, %{"token" => token}) do
    user = Guardian.Plug.current_resource(conn)

    with %Game{started: false} = game <- Repo.get_by(Game, invitation_token: token),
         nil <- Repo.get_by(UsersGame, game_id: game.id, user_id: user.id),
         changeset <-
           UsersGame.changeset(%UsersGame{}, %{
             user_id: user.id,
             game_id: game.id,
             state: "accepted"
           }),
         :ok <- Game.Server.add_player(game.id, user),
         {:ok, users_game} <- Repo.insert(changeset) do
      WerewolfApiWeb.UserChannel.broadcast_game_update(game)
      render(conn, "success.json", %{users_game: users_game})
    else
      nil -> invitation_not_found(conn)
      %UsersGame{} -> already_joined(conn)
      {:error, %Ecto.Changeset{} = changeset} -> unprocessable_entity(conn, changeset)
      %Game{started: true} -> already_started(conn)
      {:error, message} -> game_error(conn, message)
    end
  end

  # pattern matching update must come before general update
  def update(conn, %{"id" => id, "users_game" => %{"state" => "rejected"} = users_game_params}) do
    user = Guardian.Plug.current_resource(conn)

    with {:ok, users_game} <- find_users_game(id, user),
         changeset <-
           UsersGame.update_state_changeset(users_game, state_change_params(users_game_params)),
         {:ok, users_game} <- Repo.update(changeset) do
      WerewolfApiWeb.UserChannel.broadcast_game_update(users_game.game)
      WerewolfApiWeb.UserChannel.broadcast_invitation_rejected(users_game)
      render(conn, "success.json", %{users_game: users_game})
    else
      {:error, :invitation_not_found} -> invitation_not_found(conn)
      {:error, %Ecto.Changeset{} = changeset} -> unprocessable_entity(conn, changeset)
    end
  end

  def update(conn, %{"id" => id, "users_game" => users_game_params}) do
    user = Guardian.Plug.current_resource(conn)

    with {:ok, users_game} <- find_users_game(id, user),
         changeset <-
           UsersGame.update_state_changeset(users_game, state_change_params(users_game_params)),
         :ok <- Game.Server.add_player(users_game.game_id, user),
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

  defp game_joinable(conn, game) do
    render(conn, "ok.json", game: game)
  end

  defp already_started(conn) do
    conn
    |> put_status(403)
    |> render("error.json", message: "Game already started")
  end

  defp already_joined(conn) do
    conn
    |> put_status(403)
    |> render("error.json", message: "Game already joined")
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

  defp state_change_params(users_game_params) do
    %{
      state: users_game_params["state"]
    }
  end
end
