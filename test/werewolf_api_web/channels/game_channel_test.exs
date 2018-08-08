defmodule WerewolfApiWeb.GameChannelTest do
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  alias WerewolfApi.Repo
  alias WerewolfApi.GameMessage

  setup do
    user = insert(:user)
    game = insert(:game)
    insert(:users_game, user: user, game: game)
    {:ok, jwt, _} = encode_and_sign(user)
    {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
    {:ok, _, socket} = subscribe_and_join(socket, "game:#{game.id}", %{})

    {:ok, socket: socket, game: game}
  end

  describe "join channel" do
    test "unable to join channel when user not in game", %{socket: socket} do
      other_game = insert(:game)

      assert {:error, %{reason: "unauthorized"}} ==
               subscribe_and_join(socket, "game:#{other_game.id}", %{})
    end
  end

  describe "new_message event" do
    test "new_message broadcasts new game message", %{socket: socket} do
      sent_message = "Hello there!"
      ref = push(socket, "new_message", %{"body" => sent_message})
      assert_broadcast("new_message", %{body: sent_message})
      assert_reply(ref, :ok)
      assert Repo.get_by(GameMessage, body: sent_message)
    end

    test "new_message fails to broadcast new message when invalid", %{socket: socket} do
      ref = push(socket, "new_message", %{})
      assert_reply(ref, :error)
    end
  end

  describe "broadcast_game_update" do
    test "when function called game_update is broadcast", %{game: game} do
      game_id = game.id

      WerewolfApiWeb.GameChannel.broadcast_game_update(game)
      assert_broadcast("game_update", %{id: ^game_id})
    end
  end
end
