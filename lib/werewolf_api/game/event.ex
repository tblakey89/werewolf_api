defmodule WerewolfApi.Game.Event do
  alias WerewolfApi.Game
  alias WerewolfApi.Conversation
  alias WerewolfApi.Repo

  def handle(game, state, {:ok, :launch_game}) do
    conversation_id = setup_conversation(:werewolf, game, state)
    mason_conversation_id = setup_conversation(:mason, game, state)

    {:ok, game} =
      game
      |> Game.state_changeset(state)
      |> Ecto.Changeset.change(
        conversation_id: conversation_id,
        mason_conversation_id: mason_conversation_id,
        started: true
      )
      |> Repo.update()

    WerewolfApi.UsersGame.reject_pending_invitations(game.id)
    WerewolfApiWeb.UserChannel.broadcast_invitation_rejected_to_users(game.id)
    WerewolfApiWeb.UserChannel.broadcast_game_update(game)
  end

  def handle(game, state, {game_status, _, _}) when game_status !== :ok do
    if game_status in [:village_win, :werewolf_win] do
      game
      |> Game.state_changeset(state)
      |> Ecto.Changeset.change(finished: DateTime.truncate(DateTime.utc_now(), :second))
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

  defp setup_conversation(role, game, state) do
    case Conversation.find_or_create(%{"user_ids" => player_ids_by_role(state, role)}) do
      {:ok, conversation} ->
        Conversation.Announcement.announce(conversation, {role, game.name})
        Game.Announcement.announce(game, role)
        conversation.id

      :error ->
        nil
    end
  end

  defp player_ids_by_role(state, role) do
    Enum.reduce(state.game.players, [], fn {id, player}, acc ->
      case player.role do
        ^role -> [id | acc]
        _ -> acc
      end
    end)
  end
end
