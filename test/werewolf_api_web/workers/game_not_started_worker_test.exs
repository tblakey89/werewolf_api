defmodule WerewolfApiWeb.GameNotStartedWorkerTest do
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Guardian
  import WerewolfApi.Factory

  setup do
    user = insert(:user)
    game = insert(:game)
    insert(:users_game, game: game, user: user, state: "host")
    insert(:user, id: 1)

    {:ok, jwt, _} = encode_and_sign(user)
    {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
    {:ok, _, socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

    {:ok, socket: socket, user: user, game: game}
  end

  describe "perform/1" do
    test "broadcasts message to user if user has one game", %{game: game} do
      Exq.enqueue(Exq, "default", WerewolfApiWeb.GameNotStartedWorker, [game.id])

      assert_broadcast("new_conversation", %{})
    end

    test "does not broadcast message to user if user has more than one game", %{game: game, user: user} do
      game_two = insert(:game)
      insert(:users_game, game: game_two, user: user)

      Exq.enqueue(Exq, "default", WerewolfApiWeb.GameNotStartedWorker, [game.id])

      refute_broadcast("new_conversation", %{})
    end
  end
end
