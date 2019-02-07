defmodule WerewolfApi.AnnouncementTest do
  use ExUnit.Case
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian

  setup do
    user = insert(:user)
    game = insert(:game)
    insert(:users_game, user: user, game: game)
    {:ok, jwt, _} = encode_and_sign(user)
    {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
    {:ok, _, socket} = subscribe_and_join(socket, "game:#{game.id}", %{})

    {:ok, socket: socket, game: game, user: user}
  end

  describe "announce/3 add_player" do
    test "announces a new player joining", %{user: user, game: game} do
      WerewolfApi.Announcement.announce(game, state(user.id, game.id), {:ok, :add_player, user})

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ user.username
    end
  end

  describe "announce/3 launch_game" do
    test "announces launch of game", %{user: user, game: game} do
      WerewolfApi.Announcement.announce(game, state(user.id, game.id), {:ok, :launch_game})

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ "game has launched"
    end
  end

  describe "announce/3 villager_win" do
    test "announces villager win of game", %{user: user, game: game} do
      target = insert(:user)
      phase_number = 1

      WerewolfApi.Announcement.announce(
        game,
        state(user.id, game.id),
        {:villager_win, target.id, phase_number}
      )

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ target.username
      assert sent_message =~ "Villagers win"
    end
  end

  describe "announce/3 werewolf_win" do
    test "announces werewolf win of game in day phase", %{user: user, game: game} do
      target = insert(:user)
      phase_number = 2

      WerewolfApi.Announcement.announce(
        game,
        state(user.id, game.id),
        {:werewolf_win, target.id, phase_number}
      )

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ target.username
      assert sent_message =~ "people voted"
      assert sent_message =~ "Werewolves win"
    end

    test "announces werewolf win of game in night phase", %{user: user, game: game} do
      target = insert(:user)
      phase_number = 1

      WerewolfApi.Announcement.announce(
        game,
        state(user.id, game.id),
        {:werewolf_win, target.id, phase_number}
      )

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ target.username
      assert sent_message =~ "sun came up"
      assert sent_message =~ "Werewolves win"
    end
  end

  describe "announce/3 end of night phase" do
    test "announces villager win of game", %{user: user, game: game} do
      target = insert(:user)
      phase_number = 2

      WerewolfApi.Announcement.announce(
        game,
        state(user.id, game.id),
        {:no_win, target.id, phase_number}
      )

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ target.username
      assert sent_message =~ "sun came up"
    end
  end

  describe "announce/3 end of day phase" do
    test "announces villager win of game", %{user: user, game: game} do
      phase_number = 1

      WerewolfApi.Announcement.announce(
        game,
        state(user.id, game.id),
        {:no_win, user.id, phase_number}
      )

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ user.username
      assert sent_message =~ "villager"
      assert sent_message =~ "The people voted"
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
