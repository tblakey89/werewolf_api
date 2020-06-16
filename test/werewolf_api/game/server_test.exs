defmodule WerewolfApi.Game.ServerTest do
  use Phoenix.ChannelTest
  use ExUnit.Case
  import WerewolfApi.Factory

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(WerewolfApi.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(WerewolfApi.Repo, {:shared, self()})
  end

  describe "start_game/3" do
    test "starts a Werewolf game" do
      user = insert(:user)
      game = insert(:game)

      WerewolfApi.Game.Server.start_game(user, game.id, :day)

      assert Werewolf.GameSupervisor.pid_from_name(game.id) != nil
    end
  end

  describe "get_state/1" do
    test "returns state" do
      game = insert(:game)
      start_game(game)

      WerewolfApiWeb.Endpoint.subscribe("game:#{game.id}")

      {:ok, state} = WerewolfApi.Game.Server.get_state(game.id)

      assert state.game.id == game.id
    end
  end

  describe "add_player/2" do
    test "returns state with two players" do
      game = insert(:game)
      start_game(game)
      user = insert(:user)
      insert(:users_game, user: user, game: game)

      WerewolfApiWeb.Endpoint.subscribe("user:#{user.id}")

      :ok = WerewolfApi.Game.Server.add_player(game.id, user)

      assert_broadcast("game_state_update", state)

      assert state.players[user.id].id == user.id
      assert length(Map.keys(state.players)) == 2

      :timer.sleep(10)

      updated_game = WerewolfApi.Repo.get(WerewolfApi.Game, game.id)
      assert updated_game.state["game"]["players"]["#{user.id}"]["id"] == user.id
    end
  end

  describe "remove_player/2" do
    test "returns state with two players" do
      game = insert(:game)
      start_game(game)
      user = insert(:user)
      insert(:users_game, user: user, game: game)

      WerewolfApiWeb.Endpoint.subscribe("user:#{user.id}")

      :ok = WerewolfApi.Game.Server.add_player(game.id, user)

      assert_broadcast("game_state_update", state)

      :ok = WerewolfApi.Game.Server.remove_player(game.id, user)

      assert_broadcast("game_state_update", state)

      assert state.players[user.id] == nil
      assert length(Map.keys(state.players)) == 1
    end
  end

  describe "able to restart game from state stored in database" do
    test "can add player after restart" do
      game = insert(:game)
      start_game(game)
      user = insert(:user)

      {:ok, state} = WerewolfApi.Game.Server.get_state(game.id)

      WerewolfApi.Game.update_state(game.id, state)

      Werewolf.GameSupervisor.stop_game(game.id)

      assert :ok == WerewolfApi.Game.Server.add_player(game.id, user)
    end
  end

  defp start_game(game) do
    user = insert(:user)
    WerewolfApi.Game.Server.start_game(user, game.id, :day)
  end
end
