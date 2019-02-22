defmodule WerewolfApi.Announcement do
  require Integer

  def announce(game, _state, {:ok, :add_player, user}) do
    broadcast_message(game, "#{user.username} has joined the game.")
  end

  def announce(game, _state, {:ok, :launch_game}) do
    broadcast_message(
      game,
      "The game has launched. The first night phase has begun. Please check the role button for your roles and actions."
    )
  end

  def announce(game, _state, {:villager_win, target, phase_number}) do
    target_user = WerewolfApi.Repo.get(WerewolfApi.User, target)

    broadcast_message(
      game,
      "The people voted, and #{target_user.username} was lynched. It turns out #{
        target_user.username
      } was a werewolf. With this, all the werewolves were gone and peace was restored to the village. Villagers win."
    )
  end

  def announce(game, _state, {:werewolf_win, target, phase_number}) do
    target_user = WerewolfApi.Repo.get(WerewolfApi.User, target)

    case Integer.is_even(phase_number) do
      true ->
        broadcast_message(
          game,
          "The people voted, and #{target_user.username} was lynched. It turns out #{
            target_user.username
          } was a villager. With this, the werewolves outnumber the villagers, the remaining werewolves devoured the last survivors. Werewolves win."
        )

      false ->
        broadcast_message(
          game,
          "The sun came up on a new day. #{target_user.username} was found dead. With this the werewolves outnumber the villagers. The remaining werewolves devoured the last survivors. Werewolves win."
        )
    end
  end

  def announce(game, state, {:no_win, target, phase_number})
      when Integer.is_even(phase_number) do
    target_user = WerewolfApi.Repo.get(WerewolfApi.User, target)
    role = state.game.players[target].role
    day_phase_number = round(phase_number / 2)

    broadcast_message(
      game,
      "The sun came up on a new day, and #{target_user.username} was found dead. It turns out #{
        target_user.username
      } was a #{role}. Day phase #{day_phase_number} begins now."
    )
  end

  def announce(game, state, {:no_win, target, phase_number}) when Integer.is_odd(phase_number) do
    target_user = WerewolfApi.Repo.get(WerewolfApi.User, target)
    role = state.game.players[target].role
    night_phase_number = round(phase_number / 2)

    broadcast_message(
      game,
      "The people voted, and #{target_user.username} was lynched. It turns out #{
        target_user.username
      } was a #{role}. Night phase #{night_phase_number} begins now."
    )
  end

  def announce(_game, _state, _), do: nil

  defp broadcast_message(game, message) do
    changeset =
      Ecto.build_assoc(game, :game_messages, user_id: 0)
      |> WerewolfApi.GameMessage.changeset(%{bot: true, body: message})

    case WerewolfApi.Repo.insert(changeset) do
      {:ok, game_message} ->
        WerewolfApiWeb.Endpoint.broadcast(
          "game:#{game.id}",
          "new_message",
          WerewolfApiWeb.GameMessageView.render("game_message.json", %{
            game_message: game_message
          })
        )

      {:error, changeset} ->
        nil
    end
  end
end
