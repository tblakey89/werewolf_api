defmodule WerewolfApi.GameTest do
  use ExUnit.Case
  import WerewolfApi.Factory

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

      WerewolfApi.Game.update_state(game.id, state)

      updated_game = WerewolfApi.Repo.get(WerewolfApi.Game, game.id)

      assert updated_game.state["game"]["id"] == state.game.id
      assert updated_game.state["game"]["phase_length"] == "day"
    end
  end
end
