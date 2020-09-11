defmodule WerewolfApi.Game.Announcement do
  alias WerewolfApi.Notification
  alias WerewolfApi.User
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
    target_user = WerewolfApi.Repo.get(WerewolfApi.User, target)

    broadcast_message(
      game,
      "day_vote",
      "A vote has been cast: #{User.display_name(user)} has voted for #{
        User.display_name(target_user)
      }. #{show_vote_result(vote_result)}"
    )
  end

  def announce(game, _state, {:ok, :action, :night_phase, :vote, user, target, vote_result}) do
    conversation = WerewolfApi.Repo.get(WerewolfApi.Conversation, game.conversation_id)

    WerewolfApi.Conversation.Announcement.announce(
      conversation,
      {:action, user, target, vote_result}
    )
  end

  def announce(game, state, {:village_win, targets, phase_number}) do
    village_win_message =
      "With this, all the werewolves were gone and peace was restored to the village. Villagers win."

    case Integer.is_even(phase_number) do
      true ->
        broadcast_message(
          game,
          "village_win",
          night_begin_death_message(state, targets) <> " " <> village_win_message
        )

      false ->
        broadcast_message(
          game,
          "village_win",
          day_begin_death_message(state, targets) <> " " <> village_win_message
        )
    end

    broadcast_complete_message(game)
  end

  def announce(game, state, {:werewolf_win, targets, phase_number}) do
    werewolf_win_message =
      "With this, the werewolves outnumber the villagers, the remaining werewolves devoured the last survivors. Werewolves win."

    case Integer.is_even(phase_number) do
      true ->
        broadcast_message(
          game,
          "werewolf_win",
          night_begin_death_message(state, targets) <> " " <> werewolf_win_message
        )

      false ->
        broadcast_message(
          game,
          "werewolf_win",
          day_begin_death_message(state, targets) <> " " <> werewolf_win_message
        )
    end

    broadcast_complete_message(game)
  end

  def announce(game, state, {:no_win, targets, phase_number})
      when Integer.is_even(phase_number) do
    day_phase_number = round(phase_number / 2)

    message =
      day_begin_death_message(state, targets) <>
        " Day phase #{day_phase_number} begins now. Go to the 'Role' page to vote for who you want to lynch when you're ready."

    broadcast_message(game, "day_begin", message)
  end

  def announce(game, state, {:no_win, targets, phase_number}) when Integer.is_odd(phase_number) do
    night_phase_number = round(phase_number / 2)

    message =
      night_begin_death_message(state, targets) <>
        " Night phase #{night_phase_number} begins now."

    broadcast_message(game, "night_begin", message)
  end

  def announce(game, state, {:fool_win, targets, phase_number}) do
    target_user = WerewolfApi.Repo.get(WerewolfApi.User, targets[:vote])

    broadcast_message(
      game,
      "fool_win",
      night_begin_death_message(state, targets) <>
        " Suddenly #{User.display_name(target_user)} started laughing crazily. It turns out they wanted to be lynched. Suddenly, all the villagers and werewolves dropped down dead. #{
          User.display_name(target_user)
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
          night_begin_death_message(state, targets) <> " " <> too_many_phases_message
        )

      false ->
        broadcast_message(
          game,
          "too_many_phases",
          day_begin_death_message(state, targets) <> " " <> too_many_phases_message
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

  defp show_vote_result({0, :none}), do: nil

  defp show_vote_result({vote_count, :none}) do
    "There is currently a tie with #{Integer.to_string(vote_count)} #{
      Inflex.inflect("vote", vote_count)
    } each. If there is a tie at the end of the phase, no player will be lynched."
  end

  defp show_vote_result({vote_count, target}) do
    target_user = WerewolfApi.Repo.get(WerewolfApi.User, target)

    "The player with the most votes is #{User.display_name(target_user)} with #{
      Integer.to_string(vote_count)
    } #{Inflex.inflect("vote", vote_count)}. Unless the votes change, #{
      User.display_name(target_user)
    } will be lynched at the end of the phase."
  end

  defp day_begin_death_message(_, targets) when map_size(targets) == 0 do
    "The sun came up on a new day, everyone left their homes, and everyone seemed to be ok."
  end

  defp day_begin_death_message(state, targets) do
    Enum.map(targets, fn {type, target} ->
      target_user = WerewolfApi.Repo.get(WerewolfApi.User, target)
      role = state.game.players[target].role

      case type do
        :werewolf ->
          "The sun came up on a new day, and #{User.display_name(target_user)} was found dead. It turns out #{
            User.display_name(target_user)
          } was a #{role}."

        :hunter ->
          "The hunter had left a dead man switch. Suddenly, there was an explosion. The villagers rushed over, only to find #{
            User.display_name(target_user)
          }. It turns out they were a #{role}."
      end
    end)
    |> Enum.join(" ")
  end

  defp night_begin_death_message(_, targets) when map_size(targets) == 0 do
    "The people voted, but no decision could be made. Everyone went to bed hoping they would make it through the night."
  end

  defp night_begin_death_message(state, targets) do
    Enum.map(targets, fn {type, target} ->
      target_user = WerewolfApi.Repo.get(WerewolfApi.User, target)
      role = state.game.players[target].role

      case type do
        :vote ->
          "The people voted, and #{User.display_name(target_user)} was lynched. It turns out #{
            User.display_name(target_user)
          } was a #{role}."
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
