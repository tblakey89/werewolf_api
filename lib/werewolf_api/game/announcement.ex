defmodule WerewolfApi.Game.Announcement do
  alias WerewolfApi.Notification
  alias WerewolfApi.User
  alias WerewolfApi.Game
  require Integer

  def announce(game, state, {:ok, :add_player, user}) do
    broadcast_message(
      game,
      "add_player",
      "#{User.display_name(user)} has joined the game.",
      user.id
    )
  end

  def announce(game, state, {:ok, :remove_player, user}) do
    broadcast_message(
      game,
      "remove_player",
      "#{User.display_name(user)} has left the game.",
      user.id
    )
  end

  def announce(game, state, {:ok, :launch_game}) do
    broadcast_message(
      game,
      "launch_game",
      "The game has launched. The first night phase has begun. Please check the role button for your roles and actions.",
      state.game.phases
    )
  end

  def announce(game, :werewolf) do
    broadcast_message(
      game,
      "werewolf_chat",
      "This is the werewolf group chat for #{game.name}. Please place your votes on the role tab for who you want to kill.",
      0,
      :werewolf
    )
  end

  def announce(game, :mason) do
    broadcast_message(
      game,
      "mason_chat",
      "This is the mason group chat for #{game.name}. Please work together to try and find the werewolves.",
      0,
      :mason
    )
  end

  def announce(game, :dead) do
    broadcast_message(
      game,
      "dead_chat",
      "This is the dead group chat for #{game.name}. This is where all the dead players can discuss the game.",
      0,
      :dead
    )
  end

  def announce(game, state, {:ok, :action, :day_phase, :vote, user, target, vote_result}) do
    username = User.display_name(Game.user_from_game(game, target))

    broadcast_message(
      game,
      "day_vote",
      "A vote has been cast: #{User.display_name(user)} has voted for #{username}. #{show_vote_result(game, vote_result)}",
      state.game.phases
    )
  end

  def announce(game, state, {:ok, :action, :night_phase, :vote, user, target, vote_result}) do
    username = User.display_name(Game.user_from_game(game, target))

    broadcast_message(
      game,
      "werewolf_vote",
      "#{User.display_name(user)} wants to kill #{username}. #{show_vote_result(game, vote_result)}",
      state.game.phases,
      :werewolf
    )
  end

  def announce(game, state, {:village_win, targets, phase_number}) do
    village_win_message =
      "With this, all the werewolves were gone and peace was restored to the village. Villagers win."

    broadcast_message(
      game,
      "win",
      village_win_message,
      phase_number
    )

    broadcast_complete_message(game, phase_number)
  end

  def announce(game, state, {:werewolf_win, targets, phase_number}) do
    broadcast_message(
      game,
      "win",
      "With this, the werewolves outnumber the villagers, the remaining werewolves devoured the last survivors. Werewolves win.",
      phase_number
    )

    broadcast_complete_message(game, phase_number)
  end

  def announce(game, state, {:no_win, targets, phase_number})
      when Integer.is_even(phase_number) do
    day_phase_number = round(phase_number / 2)

    announce(game, state, {:death, targets})

    message =
      "Day phase #{day_phase_number} begins now. Go to the 'Role' page to vote for who you want to burn when you're ready."

    broadcast_message(game, "phase_begin", message, phase_number)
  end

  def announce(game, state, {:no_win, targets, phase_number}) when Integer.is_odd(phase_number) do
    night_phase_number = round(phase_number / 2)

    announce(game, state, {:death, targets})

    message = "Night phase #{night_phase_number} begins now."

    broadcast_message(game, "phase_begin", message, phase_number)
  end

  def announce(game, state, {:death, targets}) do
    Enum.filter(targets, fn {type, _target} -> type != :defend && type != :resurrect end)
    |> Enum.each(fn {_type, target} ->
      username = User.display_name(Game.user_from_game(game, target))

      message = "Welcome #{username} to the dead chat"

      broadcast_message(game, "death_intro", message, target, :dead)
    end)
  end

  def announce(game, state, {:fool_win, targets, phase_number}) do
    username = User.display_name(Game.user_from_game(game, targets[:vote] || targets[:overrule]))

    broadcast_message(
      game,
      "win",
      " Suddenly #{username} started laughing crazily. It turns out they wanted to be burned. Suddenly, all the villagers and werewolves dropped down dead. #{username}, the fool, wins the game.",
      phase_number
    )

    broadcast_complete_message(game, state.game.phases)
  end

  def announce(game, state, {:too_many_phases, targets, phase_number}) do
    too_many_phases_message =
      "The villagers and werewolves grew tired of fighting each other. They had been fighting for so long. They decided to make peace and move on with their lives. The game ends in a tie."

    broadcast_message(
      game,
      "win",
      too_many_phases_message,
      phase_number
    )

    broadcast_complete_message(game, state.game.phases)
  end

  def announce(game, state, {:host_end, targets, phase_number}) do
    broadcast_message(
      game,
      "win",
      "The host has decided to end the game. The game ends in a tie.",
      phase_number
    )

    broadcast_complete_message(game, state.game.phases)
  end

  def announce(game, state, :closed) do
    broadcast_message(
      game,
      "closed_game",
      "We are really sorry, not enough players were found for this game. Why don't you join our discord server and meet other players eager for a game of Werewolf: https://discord.gg/FtB8Gnj",
      state.game.phases
    )
  end

  def announce(_game, _state, _), do: nil

  defp show_vote_result(game, {votes, :none}) when length(votes) == 0, do: nil

  defp show_vote_result(game, {votes, :none}) do
    "There is currently a tie, if there is still a tie at the end of the phase, no player will be killed.\n" <>
      vote_list(game, votes)
  end

  defp show_vote_result(game, {votes, target}) do
    username = User.display_name(Game.user_from_game(game, target))

    "The player with the most votes is #{username}. Unless the votes change, #{username} will be killed at the end of the phase.\n" <>
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

  defp night_begin_death_message(_, _, targets) when map_size(targets) == 0 do
    "The people voted, but no decision could be made. Everyone went to bed hoping they would make it through the night."
  end

  defp broadcast_complete_message(game, phase_number) do
    broadcast_message(
      game,
      "complete",
      "Thank you for playing Werewolf on WolfChat. We hope you enjoyed it!",
      phase_number
    )
  end

  defp broadcast_message(game, type, message, phase_number, destination \\ :standard) do
    # why is this not in game_channel.ex?
    changeset =
      Ecto.build_assoc(game, :messages, user_id: 0)
      |> WerewolfApi.Game.Message.changeset(%{
        bot: true,
        body: message,
        type: type,
        destination: Atom.to_string(destination),
        extra: phase_number
      })

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
