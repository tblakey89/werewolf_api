defmodule WerewolfApiWeb.FriendController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.User.Friend
  alias WerewolfApi.Repo

  def create(conn, %{"user_id" => friend_id}) do
    user = Guardian.Plug.current_resource(conn)

    changeset = Friend.changeset(%Friend{}, %{user_id: user.id, friend_id: friend_id})

    case Repo.insert(changeset) do
      {:ok, friendship} ->
        WerewolfApiWeb.UserChannel.broadcast_friend_request(friendship)
        render(conn, "success.json", %{friend: friendship})

      {:error, %Ecto.Changeset{} = changeset} ->
        unprocessable_entity(conn, changeset)
    end
  end

  def update(conn, %{"id" => id, "friend" => friend_params}) do
    user = Guardian.Plug.current_resource(conn)

    with {:ok, friendship} <- find_friendship(id, user),
         changeset <- Friend.update_state_changeset(friendship, friend_params),
         {:ok, friendship} <- Repo.update(changeset) do
      WerewolfApiWeb.UserChannel.broadcast_friend_request_updated(friendship)
      render(conn, "success.json", %{friend: friendship})
    else
      {:error, :friend_request_not_found} -> friend_request_not_found(conn)
      {:error, %Ecto.Changeset{} = changeset} -> unprocessable_entity(conn, changeset)
    end
  end

  defp find_friendship(id, user) do
    case Repo.get_by(Friend, id: id, friend_id: user.id) do
      nil ->
        {:error, :friend_request_not_found}

      friendship ->
        {:ok, friendship}
    end
  end

  defp friend_request_not_found(conn) do
    conn
    |> put_status(404)
    |> render("error.json", message: "Friend request not found")
  end

  defp unprocessable_entity(conn, changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> render("error.json", changeset: changeset)
  end
end
