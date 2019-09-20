defmodule WerewolfApi.Game.Event do
  alias WerewolfApi.Game
  alias WerewolfApi.Conversation
  alias WerewolfApi.Repo

  def handle(game, state, {:ok, :launch_game}) do
    {:ok, conversation} = Conversation.find_or_create(%{"user_ids" => werewolf_player_ids(state)})
    Conversation.Announcement.announce(conversation, {:werewolf, game.name})

    {:ok, game} =
      game
      |> Game.state_changeset(state)
      |> Ecto.Changeset.change(conversation_id: conversation.id)
      |> Repo.update()

    WerewolfApi.UsersGame.reject_pending_invitations(game.id)
    WerewolfApiWeb.UserChannel.broadcast_invitation_rejected_to_users(game.id)
    WerewolfApiWeb.UserChannel.broadcast_game_update(game)
  end

  def handle(game, state, {game_status, _, _}) when game_status !== :ok do
    if game_status in [:village_win, :werewolf_win] do
      Ecto.Changeset.change(game, finished: DateTime.truncate(DateTime.utc_now(), :second))
      |> Repo.update()
    else
      Game.update_state(game, state)
    end

    WerewolfApiWeb.UserChannel.broadcast_state_update(game.id, state)
  end

  def handle(game, state, _game_response) do
    Game.update_state(game, state)
    WerewolfApiWeb.UserChannel.broadcast_state_update(game.id, state)
  end

  defp werewolf_player_ids(state) do
    Enum.reduce(state.game.players, [], fn {id, player}, acc ->
      case player.role do
        :werewolf -> [id | acc]
        _ -> acc
      end
    end)
  end
end
