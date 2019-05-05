defmodule WerewolfApiWeb.UserController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.User
  alias WerewolfApi.Repo
  import Ecto.Query, only: [from: 2]

  def create(conn, %{"user" => user_params}) do
    changeset = User.registration_changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> render("show.json", user: user)

      {:error, changeset} ->
        unprocessable_entity(conn, changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get!(User, id)

    conn
    |> render("show.json", user: user)
  end

  def me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    user =
      Repo.preload(
        user,
        friendships: [:friend, :user],
        reverse_friendships: [:friend, :user],
        conversations: [
          :users,
          :users_conversations,
          [
            messages:
              from(m in WerewolfApi.Conversation.Message, order_by: [desc: m.id], preload: :user)
          ]
        ],
        games: WerewolfApi.Game.participating_games(user.id)
      )

    conn
    |> render("me.json", user: user)
  end

  def index(conn, _params) do
    users = Repo.all(User)

    conn
    |> render("index.json", users: users)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Guardian.Plug.current_resource(conn)

    with true <- user.id == String.to_integer(id),
         changeset <- User.update_changeset(user, user_params),
         {:ok, user} <- Repo.update(changeset) do
      render(conn, "show.json", user: user)
    else
      false -> forbidden(conn)
      {:error, changeset} -> unprocessable_entity(conn, changeset)
    end
  end

  def avatar(conn, %{"user_id" => id, "user" => user_params}) do
    user = Guardian.Plug.current_resource(conn)

    with true <- user.id == String.to_integer(id),
         changeset <- User.avatar_changeset(user, user_params),
         {:ok, user} <- Repo.update(changeset) do
      WerewolfApiWeb.UserChannel.broadcast_avatar_update(user)
      render(conn, "show.json", user: user)
    else
      false -> forbidden(conn)
      {:error, changeset} -> unprocessable_entity(conn, changeset)
    end
  end

  defp unprocessable_entity(conn, changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> render("error.json", changeset: changeset)
  end

  defp forbidden(conn) do
    conn
    |> put_status(:forbidden)
    |> render("error.json", message: "Not allowed.")
  end
end
