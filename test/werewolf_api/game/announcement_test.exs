defmodule WerewolfApi.Game.AnnouncementTest do
  use ExUnit.Case
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  alias WerewolfApi.User

  setup do
    user = insert(:user)
    target = insert(:user)
    conversation = insert(:conversation, users: [user])
    game = insert(:game, conversation_id: conversation.id)

    insert(:users_game, user: user, game: game)
    insert(:users_game, user: target, game: game)

    game =
      game
      |> WerewolfApi.Repo.preload(:users)

    {:ok, jwt, _} = encode_and_sign(user)
    {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
    {:ok, _, socket} = subscribe_and_join(socket, "game:#{game.id}", %{})
    {:ok, _, socket} = subscribe_and_join(socket, "conversation:#{conversation.id}", %{})

    {:ok, socket: socket, game: game, user: user, target: target}
  end

  describe "announce/3 add_player" do
    test "announces a new player joining", %{user: user, game: game} do
      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:ok, :add_player, user}
      )

      user_id = user.id

      assert_broadcast("new_message", %{body: sent_message, extra: ^user_id})
      assert sent_message =~ user.username

      assert WerewolfApi.Repo.get_by(
               WerewolfApi.Game.Message,
               game_id: game.id
             ).type == "add_player"
    end
  end

  describe "announce/3 remove_player" do
    test "announces a new player leaving", %{user: user, game: game} do
      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:ok, :remove_player, user}
      )

      user_id = user.id

      assert_broadcast("new_message", %{body: sent_message, extra: ^user_id})
      assert sent_message =~ user.username

      assert WerewolfApi.Repo.get_by(
               WerewolfApi.Game.Message,
               game_id: game.id
             ).type == "remove_player"
    end
  end

  describe "announce/3 launch_game" do
    test "announces launch of game", %{user: user, game: game} do
      WerewolfApi.Game.Announcement.announce(game, state(user.id, game.id), {:ok, :launch_game})

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ "game has launched"

      assert WerewolfApi.Repo.get_by(
               WerewolfApi.Game.Message,
               game_id: game.id
             ).type == "launch_game"
    end
  end

  describe "announce/3 werewolf message" do
    test "announces to werewolf conversation", %{user: user, game: game} do
      WerewolfApi.Game.Announcement.announce(game, :werewolf)

      assert_broadcast("new_message", %{
        body: sent_message,
        type: "werewolf_chat",
        destination: "werewolf"
      })

      assert sent_message =~ "This is the werewolf group chat for #{game.name}"
    end
  end

  describe "announce/3 mason message" do
    test "announces to mason conversation", %{user: user, game: game} do
      WerewolfApi.Game.Announcement.announce(game, :mason)

      assert_broadcast("new_message", %{
        body: sent_message,
        type: "mason_chat",
        destination: "mason"
      })

      assert sent_message =~ "This is the mason group chat for #{game.name}"
    end
  end

  describe "announce/3 dead message" do
    test "announces to dead conversation", %{user: user, game: game} do
      WerewolfApi.Game.Announcement.announce(game, :dead)

      assert_broadcast("new_message", %{
        body: sent_message,
        type: "dead_chat",
        destination: "dead"
      })

      assert sent_message =~ "This is the dead group chat for #{game.name}"
    end
  end

  describe "announce/3 player vote" do
    test "when user votes for a target, not a tie, 1 vote", %{
      user: user,
      game: game,
      target: target
    } do
      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:ok, :action, :day_phase, :vote, user, target.id, {[{target.id, 1}], target.id}}
      )

      assert_broadcast("new_message", %{body: sent_message})

      assert sent_message =~
               "#{User.display_name(user)} has voted for #{User.display_name(target)}"

      assert sent_message =~
               "votes is #{User.display_name(target)}. Unless the votes change, #{User.display_name(target)} will be killed at the end of the phase.\n#{User.display_name(target)}: 1 vote"

      assert WerewolfApi.Repo.get_by(
               WerewolfApi.Game.Message,
               game_id: game.id
             ).type == "day_vote"
    end

    test "when user votes for a target, a tie, 3 vote", %{user: user, game: game, target: target} do
      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:ok, :action, :day_phase, :vote, user, target.id,
         {[{user.id, 3}, {target.id, 3}], :none}}
      )

      assert_broadcast("new_message", %{body: sent_message})

      assert sent_message =~
               "#{User.display_name(user)} has voted for #{User.display_name(target)}"

      assert sent_message =~
               "There is currently a tie, if there is still a tie at the end of the phase, no player will be killed."
    end

    test "when user votes for a target on night phase, not a tie, 1 vote", %{
      user: user,
      game: game,
      target: target
    } do
      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:ok, :action, :night_phase, :vote, user, target.id,
         {[{user.id, 2}, {target.id, 3}], target.id}}
      )

      assert_broadcast("new_message", %{body: sent_message})

      assert sent_message =~
               "#{User.display_name(user)} wants to kill #{User.display_name(target)}. The player with the most votes is #{User.display_name(target)}. Unless the votes change, #{User.display_name(target)} will be killed at the end of the phase.\n#{User.display_name(user)}: 2 votes\n#{User.display_name(target)}: 3 votes"
    end

    test "when user votes for a target on night phase, but there is a tie", %{
      user: user,
      game: game,
      target: target
    } do
      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:ok, :action, :night_phase, :vote, user, target.id,
         {[{user.id, 3}, {target.id, 3}], :none}}
      )

      assert_broadcast("new_message", %{body: sent_message})

      assert sent_message =~
               "#{User.display_name(user)} wants to kill #{User.display_name(target)}. There is currently a tie, if there is still a tie at the end of the phase, no player will be killed.\n#{User.display_name(user)}: 3 votes\n#{User.display_name(target)}: 3 votes"
    end
  end

  describe "announce/3 village_win" do
    test "announces villager win of game", %{user: user, game: game} do
      phase_number = 2

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:village_win, %{werewolf: user.id}, phase_number}
      )

      assert_broadcast("new_message", %{
        body: sent_message,
        type: "win",
        extra: ^phase_number
      })

      assert sent_message =~ "Villagers win"

      assert_broadcast("new_message", %{type: "complete"})
    end
  end

  describe "announce/3 werewolf_win" do
    test "announces werewolf win of game in day phase", %{user: user, game: game} do
      phase_number = 3

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:werewolf_win, %{vote: user.id}, phase_number}
      )

      assert_broadcast("new_message", %{
        body: sent_message,
        type: "win",
        extra: ^phase_number
      })

      assert sent_message =~ "Werewolves win"

      assert_broadcast("new_message", %{type: "complete"})
    end

    test "announces werewolf win of game in night phase", %{user: user, game: game} do
      phase_number = 2

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:werewolf_win, %{werewolf: user.id}, phase_number}
      )

      assert_broadcast("new_message", %{
        body: sent_message,
        type: "win",
        extra: ^phase_number
      })

      assert sent_message =~ "Werewolves win"

      assert_broadcast("new_message", %{type: "complete"})
    end
  end

  describe "announce/3 end of night phase" do
    test "announces end of night 1", %{user: user, game: game} do
      phase_number = 2

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:no_win, %{werewolf: user.id}, phase_number}
      )

      assert_broadcast("new_message", %{
        body: sent_message,
        type: "phase_begin",
        extra: ^phase_number
      })

      assert sent_message =~ "Day phase 1 begins now."

      assert_broadcast("new_message", %{body: dead_message, type: "death_intro"})
      assert dead_message =~ "Welcome #{user.username} to the dead chat"
    end

    test "no death message for resurrect", %{user: user, game: game} do
      phase_number = 2

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:no_win, %{resurrect: user.id}, phase_number}
      )

      refute_broadcast("new_message", %{body: dead_message, type: "death_intro"})
    end

    test "no death message for defend", %{user: user, game: game} do
      phase_number = 2

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:no_win, %{defend: user.id}, phase_number}
      )

      refute_broadcast("new_message", %{body: dead_message, type: "death_intro"})
    end
  end

  describe "announce/3 end of day phase" do
    test "announces end of day 0", %{user: user, game: game} do
      phase_number = 1

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:no_win, %{vote: user.id}, phase_number}
      )

      assert_broadcast("new_message", %{
        body: sent_message,
        type: "phase_begin",
        extra: ^phase_number
      })

      assert sent_message =~ "Night phase 1 begins now."

      assert_broadcast("new_message", %{body: dead_message, type: "death_intro"})
      assert dead_message =~ "Welcome #{user.username} to the dead chat"
    end
  end

  describe "announce/3 fool_win" do
    test "announces that the fool wins the game", %{user: user, game: game} do
      phase_number = 1

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:fool_win, %{vote: user.id}, phase_number}
      )

      assert_broadcast("new_message", %{
        body: sent_message,
        type: "win",
        extra: ^phase_number
      })

      assert sent_message =~ user.username
      assert sent_message =~ "the fool, wins the game."

      assert_broadcast("new_message", %{type: "complete"})
    end
  end

  describe "announce/3 too_many_phases" do
    test "announces tie and player death", %{user: user, game: game} do
      phase_number = 1

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:too_many_phases, %{werewolf: user.id}, phase_number}
      )

      assert_broadcast("new_message", %{
        body: sent_message,
        type: "win",
        extra: ^phase_number
      })

      assert sent_message =~ "The game ends in a tie."

      assert_broadcast("new_message", %{type: "complete"})
    end

    test "announces tie", %{user: user, game: game} do
      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:too_many_phases, %{}, 1}
      )

      assert_broadcast("new_message", %{
        body: sent_message,
        type: "win",
        extra: 1
      })

      assert sent_message =~ "The game ends in a tie."

      assert_broadcast("new_message", %{type: "complete"})
    end
  end

  describe "announce/3 host_end" do
    test "announces tie", %{user: user, game: game} do
      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:host_end, %{}, 1}
      )

      assert_broadcast("new_message", %{
        body: sent_message,
        type: "win",
        extra: 1
      })

      assert sent_message =~ "The game ends in a tie."

      assert_broadcast("new_message", %{type: "complete"})
    end
  end

  describe "announce/3 closed" do
    test "announces closed", %{user: user, game: game} do
      WerewolfApi.Game.Announcement.announce(game, state(user.id, game.id), :closed)

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ "We are really sorry, not enough players"

      assert WerewolfApi.Repo.get_by(
               WerewolfApi.Game.Message,
               game_id: game.id
             ).type == "closed_game"
    end
  end

  def state(user_id, game_id) do
    %{
      game: %Werewolf.Game{
        end_phase_unix_time: nil,
        id: game_id,
        phase_length: :day,
        phases: 0,
        players: %{
          user_id => %Werewolf.Player{
            actions: %{
              user_id => %Werewolf.Action{
                type: :vote,
                target: user_id
              }
            },
            alive: true,
            host: true,
            id: user_id,
            role: :villager
          }
        }
      },
      rules: %Werewolf.Rules{state: :initialized}
    }
  end
end
