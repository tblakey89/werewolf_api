defmodule WerewolfApi.Game.Scheduled do
  import Ecto.Changeset
  alias WerewolfApi.Game
  alias WerewolfApi.Repo

  def setup(hours, phase_length) do
    case Repo.insert(Game.scheduled_changeset(hours, phase_length)) do
      {:ok, game} ->
        game = Repo.preload(game, users_games: :user, messages: :user)

        {:ok, _} =
          Game.Server.start_game(
            nil,
            game.id,
            String.to_atom(game.time_period)
          )

        {:ok, state} = Game.Server.get_state(game.id)
        {:ok, game} = Game.update_state(game, state)

        Exq.enqueue_in(Exq, "default", 60 * 60 * hours, WerewolfApiWeb.StartScheduledGameWorker, [
          game.id
        ])

        game

      {:error, changeset} ->
        Sentry.capture_message('Failed to create scheduled game')
    end
  end
end
