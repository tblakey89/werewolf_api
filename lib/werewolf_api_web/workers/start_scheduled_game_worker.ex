defmodule WerewolfApiWeb.StartScheduledGameWorker do
  alias WerewolfApi.Game
  alias WerewolfApi.Repo

  def perform(game_id) do
    case Game.Server.launch_game(game_id) do
      :ok ->
        :ok

      {:error, response} ->
        game =
          Repo.get(Game, game_id)
          |> Repo.preload(:users_games)

        Repo.update(Game.closed_changeset(game))

        Game.Announcement.announce(game, game.state, :closed)
    end
  end
end
