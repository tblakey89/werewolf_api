defmodule WerewolfApiWeb.GameChannel do
  use Phoenix.Channel
  alias WerewolfApi.Repo

  def join("game:" <> game_id, _message, socket) do
    game =
      Guardian.Phoenix.Socket.current_resource(socket)
      |> Ecto.assoc(:games)
      |> Repo.get(String.to_integer(game_id))

    case game do
      nil -> {:error, %{reason: "unauthorized"}}
      game -> {:ok, assign(socket, :game_id, game.id)}
    end
  end

  def broadcast_game_update(game) do
    game = Repo.preload(game, users_games: :user)

    WerewolfApiWeb.Endpoint.broadcast(
      "game:#{game.id}",
      "game_update",
      WerewolfApiWeb.GameView.render("game.json", %{
        game: game
      })
    )
  end
end
