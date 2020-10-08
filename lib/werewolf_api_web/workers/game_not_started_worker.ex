defmodule WerewolfApiWeb.GameNotStartedWorker do
  alias WerewolfApi.Game
  alias WerewolfApi.User
  alias WerewolfApi.Repo
  alias WerewolfApi.Notification

  def perform(game_id) do
    game =
      Repo.get(Game, game_id)
      |> Repo.preload(:users_games)

    if game != nil do
      user =
        Repo.get(User, Game.find_host_id(game))
        |> Repo.preload(:games)

      if !game.started do
        broadcast_game(
          game,
          "new_game_discord",
          "Struggling to find other players? Why not join our discord server: https://discord.gg/FtB8Gnj"
        )
      end
    end
  end

  defp broadcast_game(game, type, message) do
    changeset =
      Ecto.build_assoc(game, :messages, user_id: 0)
      |> WerewolfApi.Game.Message.changeset(%{bot: true, body: message, type: type})

    case WerewolfApi.Repo.insert(changeset) do
      {:ok, game_message} ->
        WerewolfApiWeb.Endpoint.broadcast(
          "game:#{game.id}",
          "new_message",
          WerewolfApiWeb.GameMessageView.render("game_message.json", %{
            game_message: game_message
          })
        )

        Notification.new_game_message(game_message)

      {:error, changeset} ->
        nil
    end
  end
end
