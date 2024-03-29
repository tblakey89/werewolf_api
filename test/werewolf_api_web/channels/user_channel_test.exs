defmodule WerewolfApiWeb.UserChannelTest do
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  alias WerewolfApi.Repo
  require IEx

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

  describe "update_fcm_token event" do
    test "update_fcm_token updates user's fcm token" do
      user = insert(:user)
      user_id = user.id

      {:ok, jwt, _} = encode_and_sign(user)
      {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
      {:ok, _, user_socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

      fcm_token = "test token"

      ref = push(user_socket, "update_fcm_token", %{fcm_token: fcm_token})

      assert_reply(ref, :ok)

      updated_user = WerewolfApi.Repo.get(WerewolfApi.User, user_id)

      assert updated_user.fcm_token == fcm_token
    end
  end

  describe "request_conversation event" do
    test "broadcasts conversation again" do
      user = insert(:user)
      user_id = user.id
      conversation = insert(:conversation)
      conversation_id = conversation.id
      insert(:users_conversation, conversation: conversation, user: user)

      {:ok, jwt, _} = encode_and_sign(user)
      {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
      {:ok, _, user_socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

      ref = push(user_socket, "request_conversation", %{conversation_id: conversation_id})

      assert_reply(ref, :ok)

      assert_broadcast("new_conversation", %{id: ^conversation_id})
    end
  end

  describe "request_game event" do
    test "broadcasts game again" do
      user = insert(:user)
      user_id = user.id
      game = insert(:game)
      game_id = game.id
      insert(:users_game, game: game, user: user)

      {:ok, jwt, _} = encode_and_sign(user)
      {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
      {:ok, _, user_socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

      ref = push(user_socket, "request_game", %{game_id: game_id})

      assert_reply(ref, :ok)

      assert_broadcast("new_game", %{id: ^game_id})
    end

    test "does not broadcasts game if no user in game" do
      user = insert(:user)
      user_id = user.id
      game = insert(:game)
      game_id = game.id

      {:ok, jwt, _} = encode_and_sign(user)
      {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
      {:ok, _, user_socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

      ref = push(user_socket, "request_game", %{game_id: game_id})

      assert_reply(ref, :ok)

      refute_broadcast("new_game", %{id: ^game_id})
    end
  end

  describe "broadcast_conversation_creation_to_users" do
    test "when function called new_conversation is broadcast", %{user: user} do
      conversation =
        insert(:conversation, users: [user])
        |> Repo.preload([:messages, :users_conversations])

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

      WerewolfApi.Game.Server.start_game(user, game_id, :day, [], Werewolf.Options.new(%{}))
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

      WerewolfApi.Game.Server.start_game(user, game_id, :day, [], Werewolf.Options.new(%{}))
      WerewolfApiWeb.UserChannel.broadcast_state_update(game_id, state)
      assert_broadcast("game_state_update", %{id: ^game_id, players: %{1 => %{id: 1}}})
    end
  end

  describe "broadcast_invitation_rejected_to_users/1" do
    test "when function called invitation_rejected is broadcast, invite is rejected", %{
      game: game,
      user: user
    } do
      users_game = insert(:users_game, user: user, game: game, state: "rejected")
      users_game_id = users_game.id

      WerewolfApiWeb.UserChannel.broadcast_invitation_rejected_to_users(game.id)
      assert_broadcast("invitation_rejected", %{id: ^users_game_id})
    end

    test "when function called invitation_rejected is broadcast, invite is not rejected", %{
      game: game,
      user: user
    } do
      users_game = insert(:users_game, user: user, game: game)
      users_game_id = users_game.id

      WerewolfApiWeb.UserChannel.broadcast_invitation_rejected_to_users(game.id)
      refute_broadcast("invitation_rejected", %{id: ^users_game_id})
    end
  end

  describe "broadcast_invitation_rejected/1" do
    test "when function called invitation_rejected is broadcast", %{game: game, user: user} do
      users_game = insert(:users_game, user: user, game: game, state: "rejected")
      users_game_id = users_game.id

      WerewolfApiWeb.UserChannel.broadcast_invitation_rejected(users_game)
      assert_broadcast("invitation_rejected", %{id: ^users_game_id})
    end
  end

  describe "broadcast_friend_request/1" do
    test "when function called new_friend_request is broadcast", %{user: user} do
      friend = insert(:user)
      friendship = insert(:friend, user: user, friend: friend)
      friend_id = friend.id

      {:ok, jwt, _} = encode_and_sign(friend)
      {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
      {:ok, _, socket} = subscribe_and_join(socket, "user:#{friend.id}", %{})

      WerewolfApiWeb.UserChannel.broadcast_friend_request(friendship)
      assert_broadcast("new_friend_request", %{friend: %{id: ^friend_id}})
    end
  end

  describe "broadcast_friend_request_updated/1" do
    test "when function called friend_request_updated is broadcast", %{user: user} do
      friend = insert(:user)
      friendship = insert(:friend, user: user, friend: friend, state: "accepted")
      friend_id = friend.id

      WerewolfApiWeb.UserChannel.broadcast_friend_request_updated(friendship)
      assert_broadcast("friend_request_updated", %{friend: %{id: ^friend_id}})
    end
  end
end
