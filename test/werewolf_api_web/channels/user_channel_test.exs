defmodule WerewolfApiWeb.UserChannelTest do
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  alias WerewolfApi.Repo

  setup do
    user = insert(:user)
    game = insert(:game)
    {:ok, jwt, _} = encode_and_sign(user)
    {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
    {:ok, _, socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

    {:ok, socket: socket, user: user, game: game}
  end

  describe "join channel" do
    test "unable to join another user's channel", %{socket: socket} do
      other_user = insert(:user)

      assert {:error, %{reason: "unauthorized"}} ==
               subscribe_and_join(socket, "user:#{other_user.id}", %{})
    end
  end

  describe "broadcast_conversation_creation_to_users" do
    test "when function called new_conversation is broadcast", %{user: user} do
      conversation =
        insert(:conversation, users: [user])
        |> Repo.preload(:messages)

      conversation_id = conversation.id

      WerewolfApiWeb.UserChannel.broadcast_conversation_creation_to_users(conversation)
      assert_broadcast("new_conversation", %{id: ^conversation_id})
    end
  end

  describe "broadcast_game_creation_to_users" do
    test "when function called, new_game is broadcast", %{user: user} do
      game = insert(:game)
      insert(:users_game, user: user, game: game)

      game_id = game.id

      Werewolf.GameSupervisor.start_game(user, game_id, :day)

      WerewolfApiWeb.UserChannel.broadcast_game_creation_to_users(game)
      assert_broadcast("new_game", %{id: ^game_id})
    end
  end

  describe "broadcast_game_update/1" do
    test "when function called game_update is broadcast", %{game: game, user: user} do
      insert(:users_game, user: user, game: game)
      game_id = game.id

      WerewolfApi.GameServer.start_game(user, game_id, :day)
      WerewolfApiWeb.UserChannel.broadcast_game_update(game)
      assert_broadcast("game_update", %{id: ^game_id})
    end
  end

  describe "broadcast_state_update/3" do
    test "when function called game_state is broadcast", %{game: game, user: user} do
      insert(:users_game, user: user, game: game)
      game_id = game.id

      state = %{
        game: %Werewolf.Game{
          end_phase_unix_time: nil,
          id: 178,
          phase_length: :day,
          phases: 0,
          players: %{
            1 => %Werewolf.Player{
              actions: %{
                1 => %Werewolf.Action{
                  type: :vote,
                  target: 2
                }
              },
              alive: true,
              host: true,
              id: 1,
              role: :none
            }
          }
        },
        rules: %Werewolf.Rules{state: :initialized}
      }

      WerewolfApi.GameServer.start_game(user, game_id, :day)
      WerewolfApiWeb.UserChannel.broadcast_state_update(game_id, state, user)
      assert_broadcast("game_state_update", %{id: ^game_id, players: %{1 => %{id: 1}}})
    end
  end
end
