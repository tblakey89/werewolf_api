defmodule WerewolfApi.Game.Announcement do
  alias WerewolfApi.Notification
  alias WerewolfApi.User
  alias WerewolfApi.Game
  require Integer

  def announce(game, _state, {:ok, :add_player, user}) do
    broadcast_message(game, "add_player", "#{User.display_name(user)} has joined the game.")
  end

  def announce(game, _state, {:ok, :remove_player, user}) do
    broadcast_message(game, "remove_player", "#{User.display_name(user)} has left the game.")
  end

  def announce(game, _state, {:ok, :launch_game}) do
    broadcast_message(
      game,
      "launch_game",
      "The game has launched. The first night phase has begun. Please check the role button for your roles and actions."
    )
  end

  def announce(game, _state, {:ok, :action, :day_phase, :vote, user, target, vote_result}) do
    username = User.display_name(Game.user_from_game(game, target))

    broadcast_message(
      game,
      "day_vote",
      "A vote has been cast: #{User.display_name(user)} has voted for #{username}. #{
        show_vote_result(game, vote_result)
      }"
    )
  end

  def announce(game, _state, {:ok, :action, :night_phase, :vote, user, target, vote_result}) do
    case game.conversation_id do
      nil ->
        :error

      conversation_id ->
        conversation = WerewolfApi.Repo.get(WerewolfApi.Conversation, game.conversation_id)

        WerewolfApi.Conversation.Announcement.announce(
          conversation,
          game,
          {:action, user, target, vote_result}
        )
    end
  end

  def announce(game, state, {:village_win, targets, phase_number}) do
    village_win_message =
      "With this, all the werewolves were gone and peace was restored to the village. Villagers win."

    case Integer.is_even(phase_number) do
      false ->
        broadcast_message(
          game,
          "village_win",
          night_begin_death_message(game, state, targets) <> " " <> village_win_message
        )

      true ->
        broadcast_message(
          game,
          "village_win",
          day_begin_death_message(game, state, targets) <> " " <> village_win_message
        )
    end

    broadcast_complete_message(game)
  end

  def announce(game, state, {:werewolf_win, targets, phase_number}) do
    werewolf_win_message =
      "With this, the werewolves outnumber the villagers, the remaining werewolves devoured the last survivors. Werewolves win."

    case Integer.is_even(phase_number) do
      false ->
        broadcast_message(
          game,
          "werewolf_win",
          night_begin_death_message(game, state, targets) <> " " <> werewolf_win_message
        )

      true ->
        broadcast_message(
          game,
          "werewolf_win",
          day_begin_death_message(game, state, targets) <> " " <> werewolf_win_message
        )
    end

    broadcast_complete_message(game)
  end

  def announce(game, state, {:no_win, targets, phase_number})
      when Integer.is_even(phase_number) do
    day_phase_number = round(phase_number / 2)

    message =
      day_begin_death_message(game, state, targets) <>
        " Day phase #{day_phase_number} begins now. Go to the 'Role' page to vote for who you want to lynch when you're ready."

    broadcast_message(game, "day_begin", message)
  end

  def announce(game, state, {:no_win, targets, phase_number}) when Integer.is_odd(phase_number) do
    night_phase_number = round(phase_number / 2)

    message =
      night_begin_death_message(game, state, targets) <>
        " Night phase #{night_phase_number} begins now."

    broadcast_message(game, "night_begin", message)
  end

  def announce(game, state, {:fool_win, targets, phase_number}) do
    username = User.display_name(Game.user_from_game(game, targets[:vote]))

    broadcast_message(
      game,
      "fool_win",
      night_begin_death_message(game, state, targets) <>
        " Suddenly #{username} started laughing crazily. It turns out they wanted to be lynched. Suddenly, all the villagers and werewolves dropped down dead. #{
          username
        }, the fool, wins the game."
    )

    broadcast_complete_message(game)
  end

  def announce(game, state, {:too_many_phases, targets, phase_number}) do
    too_many_phases_message =
      "The villagers and werewolves grew tired of fighting each other. They had been fighting for so long. They decided to make peace and move on with their lives. The game ends in a tie."

    case Integer.is_even(phase_number) do
      true ->
        broadcast_message(
          game,
          "too_many_phases",
          night_begin_death_message(game, state, targets) <> " " <> too_many_phases_message
        )

      false ->
        broadcast_message(
          game,
          "too_many_phases",
          day_begin_death_message(game, state, targets) <> " " <> too_many_phases_message
        )
    end

    broadcast_complete_message(game)
  end

  def announce(game, state, {:host_end, targets, phase_number}) do
    broadcast_message(
      game,
      "host_end",
      "The host has decided to end the game. The game ends in a tie."
    )

    broadcast_complete_message(game)
  end

  def announce(game, _state, :closed) do
    broadcast_message(
      game,
      "closed_game",
      "We are really sorry, not enough players were found for this game. Why don't you join our discord server and meet other players eager for a game of Werewolf: https://discord.gg/FtB8Gnj"
    )
  end

  def announce(_game, _state, _), do: nil

  defp show_vote_result(game, {votes, :none}) when length(votes) == 0, do: nil

  defp show_vote_result(game, {votes, :none}) do
    "There is currently a tie, if there is still a tie at the end of the phase, no player will be lynched.\n" <>
      vote_list(game, votes)
  end

  defp show_vote_result(game, {votes, target}) do
    username = User.display_name(Game.user_from_game(game, target))

    "The player with the most votes is #{username}. Unless the votes change, #{username} will be lynched at the end of the phase.\n" <>
      vote_list(game, votes)
  end

  defp vote_list(game, votes) do
    Enum.map(votes, fn {target, vote_count} ->
      username = User.display_name(Game.user_from_game(game, target))
      "#{username}: #{vote_count} #{Inflex.inflect("vote", vote_count)}"
    end)
    |> Enum.join("\n")
  end

  defp day_begin_death_message(_, _, targets) when map_size(targets) == 0 do
    "The sun came up on a new day, everyone left their homes, and everyone seemed to be ok."
  end

  defp day_begin_death_message(game, state, targets) do
    Enum.reverse(targets)
    |> Enum.map(fn {type, target} ->
      username = User.display_name(Game.user_from_game(game, target))
      role = state.game.players[target].role

      case type do
        :werewolf ->
          "The sun came up on a new day, and #{username} was found dead. It turns out #{username} was a #{
            role
          }."

        :hunter ->
          "The hunter had left a dead man switch. Suddenly, there was an explosion. The villagers rushed over, only to find #{
            username
          }. It turns out they were a #{role}."
      end
    end)
    |> Enum.join(" ")
  end

  defp night_begin_death_message(_, _, targets) when map_size(targets) == 0 do
    "The people voted, but no decision could be made. Everyone went to bed hoping they would make it through the night."
  end

  defp night_begin_death_message(game, state, targets) do
    Enum.map(targets, fn {type, target} ->
      username = User.display_name(Game.user_from_game(game, target))
      role = state.game.players[target].role

      case type do
        :vote ->
          "The people voted, and #{username} was lynched. It turns out #{username} was a #{role}."
      end
    end)
    |> Enum.join(" ")
  end

  defp broadcast_complete_message(game) do
    broadcast_message(
      game,
      "complete",
      "Thank you for playing Werewolf on WolfChat. We hope you enjoyed it!"
    )
  end

  defp broadcast_message(game, type, message) do
    # why is this not in game_channel.ex?
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
