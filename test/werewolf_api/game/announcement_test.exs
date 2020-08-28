defmodule WerewolfApi.Game.AnnouncementTest do
  use ExUnit.Case
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  alias WerewolfApi.User

  setup do
    user = insert(:user)
    conversation = insert(:conversation, users: [user])
    game = insert(:game, conversation_id: conversation.id)
    insert(:users_game, user: user, game: game)
    {:ok, jwt, _} = encode_and_sign(user)
    {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
    {:ok, _, socket} = subscribe_and_join(socket, "game:#{game.id}", %{})
    {:ok, _, socket} = subscribe_and_join(socket, "conversation:#{conversation.id}", %{})

    {:ok, socket: socket, game: game, user: user}
  end

  describe "announce/3 add_player" do
    test "announces a new player joining", %{user: user, game: game} do
      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:ok, :add_player, user}
      )

      assert_broadcast("new_message", %{body: sent_message})
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

      assert_broadcast("new_message", %{body: sent_message})
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

  describe "announce/3 player vote" do
    test "when user votes for a target, not a tie, 1 vote", %{user: user, game: game} do
      target = insert(:user)

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:ok, :action, :day_phase, :vote, user, target.id, {1, target.id}}
      )

      assert_broadcast("new_message", %{body: sent_message})

      assert sent_message =~
               "#{User.display_name(user)} has voted for #{User.display_name(target)}"

      assert sent_message =~
               "votes is #{User.display_name(target)} with 1 vote. Unless the votes change, #{
                 User.display_name(target)
               } will be lynched at the end of the phase."

      assert WerewolfApi.Repo.get_by(
               WerewolfApi.Game.Message,
               game_id: game.id
             ).type == "day_vote"
    end

    test "when user votes for a target, a tie, 3 vote", %{user: user, game: game} do
      target = insert(:user)

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:ok, :action, :day_phase, :vote, user, target.id, {3, :none}}
      )

      assert_broadcast("new_message", %{body: sent_message})

      assert sent_message =~
               "#{User.display_name(user)} has voted for #{User.display_name(target)}"

      assert sent_message =~
               "a tie with 3 votes each. If there is a tie at the end of the phase, no player will be lynched."
    end

    test "when user votes for a target on night phase, not a tie, 1 vote", %{
      user: user,
      game: game
    } do
      target = insert(:user)

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:ok, :action, :night_phase, :vote, user, target.id, {1, target.id}}
      )

      assert_broadcast("new_message", %{body: sent_message})

      refute sent_message =~
               "#{User.display_name(user)} has voted for #{User.display_name(target)}"

      refute sent_message =~
               "votes is #{User.display_name(target)} with 1 vote. Unless the votes change, #{
                 User.display_name(target)
               } will be lynched at the end of the phase."
    end
  end

  describe "announce/3 village_win" do
    test "announces villager win of game", %{user: user, game: game} do
      target = insert(:user)
      phase_number = 1

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:village_win, target.id, phase_number}
      )

      assert_broadcast("new_message", %{body: sent_message, type: "village_win"})
      assert sent_message =~ target.username
      assert sent_message =~ "Villagers win"

       assert_broadcast("new_message", %{type: "complete"})
    end
  end

  describe "announce/3 werewolf_win" do
    test "announces werewolf win of game in day phase", %{user: user, game: game} do
      target = insert(:user)
      phase_number = 2

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:werewolf_win, target.id, phase_number}
      )

      assert_broadcast("new_message", %{body: sent_message, type: "werewolf_win_day"})
      assert sent_message =~ target.username
      assert sent_message =~ "people voted"
      assert sent_message =~ "Werewolves win"

      assert_broadcast("new_message", %{type: "complete"})
    end

    test "announces werewolf win of game in night phase", %{user: user, game: game} do
      target = insert(:user)
      phase_number = 1

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:werewolf_win, target.id, phase_number}
      )

      assert_broadcast("new_message", %{body: sent_message, type: "werewolf_win_night"})
      assert sent_message =~ target.username
      assert sent_message =~ "sun came up"
      assert sent_message =~ "Werewolves win"

      assert_broadcast("new_message", %{type: "complete"})
    end
  end

  describe "announce/3 end of night phase" do
    test "announces target of werewolves", %{user: user, game: game} do
      phase_number = 2

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:no_win, user.id, phase_number}
      )

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ user.username
      assert sent_message =~ "sun came up"

      assert WerewolfApi.Repo.get_by(
               WerewolfApi.Game.Message,
               game_id: game.id
             ).type == "day_begin_death"
    end

    test "announces no target", %{user: user, game: game} do
      phase_number = 2

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:no_win, :none, phase_number}
      )

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ "everyone seemed to be ok"

      assert WerewolfApi.Repo.get_by(
               WerewolfApi.Game.Message,
               game_id: game.id
             ).type == "day_begin_no_death"
    end
  end

  describe "announce/3 end of day phase" do
    test "announces target of vote", %{user: user, game: game} do
      phase_number = 1

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:no_win, user.id, phase_number}
      )

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ user.username
      assert sent_message =~ "villager"
      assert sent_message =~ "The people voted"

      assert WerewolfApi.Repo.get_by(
               WerewolfApi.Game.Message,
               game_id: game.id
             ).type == "night_begin_death"
    end

    test "announces no target", %{user: user, game: game} do
      phase_number = 1

      WerewolfApi.Game.Announcement.announce(
        game,
        state(user.id, game.id),
        {:no_win, :none, phase_number}
      )

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ "but no decision could be made"

      assert WerewolfApi.Repo.get_by(
               WerewolfApi.Game.Message,
               game_id: game.id
             ).type == "night_begin_no_death"
    end
  end

  describe "announce/3 closed" do
    test "announces closed", %{user: user, game: game} do
      WerewolfApi.Game.Announcement.announce(game, nil, :closed)

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
