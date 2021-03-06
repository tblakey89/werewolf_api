defmodule WerewolfApiWeb.UserController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.User
  alias WerewolfApi.Repo
  import Ecto.Query, only: [from: 2]

  def create(conn, %{"user" => user_params}) do
    changeset = User.registration_changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = WerewolfApi.Guardian.encode_and_sign(user)

        conn
        |> put_status(:created)
        |> render(WerewolfApiWeb.SessionView, "create.json", jwt: jwt)

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
        [
          :blocks,
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
          games: WerewolfApi.Game.participating_games(user.id, nil)
        ]
      )

    conn
    |> render("me.json", user: user)
  end

  def me_v2(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    user =
      Repo.preload(
        user,
        [
          :blocks,
          friendships: [:friend, :user],
          reverse_friendships: [:friend, :user],
          conversations: [
            :users,
            :users_conversations,
            [
              messages: from(m in WerewolfApi.Conversation.Message, preload: :user)
            ]
          ],
          games: WerewolfApi.Game.limited_participating_games(user.id, 20)
        ]
      )

    conn
    |> render("me.json", user: user)
  end

  def refresh_me(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    refresh_date = DateTime.from_unix!(String.to_integer(params["timestamp"]), :millisecond)

    user =
      Repo.preload(
        user,
        [
          :blocks,
          friendships: [:friend, :user],
          reverse_friendships: [:friend, :user],
          conversations: [
            :users,
            :users_conversations,
            [
              messages:
                from(m in WerewolfApi.Conversation.Message,
                  where: m.inserted_at >= ^refresh_date,
                  order_by: [desc: m.id],
                  preload: :user
                )
            ]
          ],
          games:
            WerewolfApi.Game.participating_games(
              user.id,
              parsed_game_ids(params["game_ids"]),
              refresh_date
            )
        ]
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
         changeset <- User.update_changeset(user, update_params_as_atoms(user_params)),
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

  defp update_params_as_atoms(user_params) do
    %{
      notify_on_game_creation: user_params["notify_on_game_creation"],
      password: user_params["password"]
    }
  end

  defp parsed_game_ids(nil), do: nil
  defp parsed_game_ids(game_ids), do: Jason.decode!(game_ids)
end
