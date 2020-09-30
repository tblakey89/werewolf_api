defmodule WerewolfApiWeb.StartScheduledGameWorkerTest do
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Guardian
  import WerewolfApi.Factory
  alias WerewolfApi.Game.Scheduled
  alias WerewolfApi.Game

  setup do
    user = insert(:user)

    game = insert(:game)

    {:ok, _} =
      Game.Server.start_game(
        nil,
        game.id,
        String.to_atom(game.time_period),
        []
      )

    {:ok, state} = Game.Server.get_state(game.id)
    {:ok, game} = Game.update_state(game, state)

    insert(:users_game, game: game, user: user, state: "accepted")
    insert(:user, id: 1)

    {:ok, jwt, _} = encode_and_sign(user)
    {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
    {:ok, _, socket} = subscribe_and_join(socket, "game:#{game.id}", %{})

    {:ok, socket: socket, user: user, game: game}
  end

  describe "perform/1" do
    test "broadcasts message to user that game is closed", %{game: game} do
      Exq.enqueue(Exq, "default", WerewolfApiWeb.StartScheduledGameWorker, [game.id])

      assert_broadcast("new_message", %{type: "closed_game"})

      scheduled_game = WerewolfApi.Repo.get(Game, game.id)

      assert scheduled_game.closed == true
    end

    test "when has enough players", %{game: game} do
      for n <- 1..8 do
        users_game = insert(:users_game, game: game, state: "accepted")
        :ok = WerewolfApi.Game.Server.add_player(game.id, users_game.user)
      end

      assert(game.closed == false)

      Exq.enqueue(Exq, "default", WerewolfApiWeb.StartScheduledGameWorker, [game.id])

      assert_broadcast("new_message", %{type: "launch_game"})

      scheduled_game = WerewolfApi.Repo.get(Game, game.id)

      assert(scheduled_game.closed == false)
    end
  end
end
