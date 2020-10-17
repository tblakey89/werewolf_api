defmodule WerewolfApiWeb.OwnGameController do
  use WerewolfApiWeb, :controller
  import Ecto.Query, only: [from: 2]
  alias WerewolfApi.Game
  alias WerewolfApi.Repo

  def index(conn, %{"offset" => offset}) do
    user = Guardian.Plug.current_resource(conn)
    user_id = user.id

    games =
      from(
        g in WerewolfApi.Game,
        join: ug in WerewolfApi.UsersGame,
        where: ug.user_id == ^user_id and ug.game_id == g.id and ug.state != "rejected",
        order_by: [desc: :updated_at],
        preload: [
          [
            messages:
              ^from(m in WerewolfApi.Game.Message,
                preload: :user
              )
          ],
          users_games: :user
        ],
        limit: 20,
        offset: ^offset
      )
      |> Repo.all()

    conn
    |> render("index.json", games: games, user: user)
  end
end
