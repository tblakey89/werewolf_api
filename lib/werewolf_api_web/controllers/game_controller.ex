defmodule WerewolfApiWeb.GameController do
  use WerewolfApiWeb, :controller
  import Ecto.Query, only: [from: 2]
  alias WerewolfApi.Game
  alias WerewolfApi.Repo
  alias WerewolfApi.Notification

  def index(conn, _param) do
    two_days_ago =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-60 * 60 * 24 * 1)

    games =
      from(g in Game,
        where: g.started == false and g.inserted_at >= ^two_days_ago and g.closed != true,
        order_by: [desc: g.inserted_at],
        limit: 20
      )
      |> Repo.all()
      |> Repo.preload(users_games: :user, messages: :user)

    conn
    |> render("index.json", games: games)
  end

  def create(conn, %{"game" => game_params}) do
    user = Guardian.Plug.current_resource(conn)

    changeset = Game.changeset(%Game{}, game_params, user)

    case Repo.insert(changeset) do
      {:ok, game} ->
        game = Repo.preload(game, users_games: :user, messages: :user)

        # do we need to handle game creation failure, or just let it fail?
        # ensure phase_length is turned to atom
        {:ok, _} =
          Game.Server.start_game(
            user,
            game.id,
            String.to_atom(game.time_period),
            Enum.map(game.allowed_roles, &String.to_atom(&1))
          )

        update_state(game)
        {:ok, state} = Game.Server.get_state(game.id)
        Notification.received_game_invite(game, game_params[:user_ids] || game_params["user_ids"])
        Notification.new_game_creation_message(game, user)

        Exq.enqueue_in(Exq, "default", 3600, WerewolfApiWeb.GameNotStartedWorker, [game.id])

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
      |> Repo.preload(users_games: :user, messages: :user)

    host_id = Game.find_host_id(game)

    with true <- user.id == host_id,
         changeset <- Game.update_changeset(game, game_params),
         {:ok, game} <- Repo.update(changeset),
         :ok =
           Game.Server.edit_game(
             game.id,
             String.to_atom(game.time_period),
             Enum.map(game.allowed_roles, &String.to_atom(&1))
           ),
         game <- Repo.preload(game, users_games: :user, messages: :user) do
      WerewolfApiWeb.UserChannel.broadcast_game_update(game)
      Notification.received_game_invite(game, game_params[:user_ids] || game_params["user_ids"])
      render(conn, "show.json", game: game)
    else
      false -> forbidden(conn)
      {:error, :invalid_action} -> forbidden(conn)
      {:error, changeset} -> unprocessable_entity(conn, changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)

    game =
      user
      |> Ecto.assoc(:games)
      |> Repo.get(id)
      |> Repo.preload(
        messages: :user,
        users_games: :user
      )

    render(conn, "show.json", game: game, user: user)
  end

  defp update_state(game) do
    Task.start_link(fn ->
      {:ok, state} = Game.Server.get_state(game.id)
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
