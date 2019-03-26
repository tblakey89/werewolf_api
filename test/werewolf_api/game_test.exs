defmodule WerewolfApi.GameTest do
  use ExUnit.Case
  import WerewolfApi.Factory
  alias WerewolfApi.Game

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(WerewolfApi.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(WerewolfApi.Repo, {:shared, self()})
  end

  describe "update_state/2" do
    test "saves game state" do
      game = insert(:game)

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

      Game.update_state(game.id, state)

      updated_game = WerewolfApi.Repo.get(Game, game.id)

      assert updated_game.state["game"]["id"] == state.game.id
      assert updated_game.state["game"]["phase_length"] == "day"
    end
  end

  describe "mark_game_as_complete/2" do
    test "when villager win" do
      game = insert(:game)
      {:ok, game} = Game.mark_game_as_complete(game, {:villager_win, :ok, :ok})
      assert game.finished
    end

    test "when werewolf win" do
      game = insert(:game)
      {:ok, game} = Game.mark_game_as_complete(game, {:werewolf_win, :ok, :ok})
      assert game.finished
    end

    test "when no win" do
      game = insert(:game)
      {:ok, game} = Game.mark_game_as_complete(game, {:no_win, :ok, :ok})
      refute game.finished
    end

    test "when launching game" do
      game = insert(:game)
      {:ok, game} = Game.mark_game_as_complete(game, {:launch_game, :ok})
      refute game.finished
    end
  end
end
