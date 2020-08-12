defmodule WerewolfApi.GameTest do
  use ExUnit.Case
  import WerewolfApi.Factory
  alias WerewolfApi.Game.Event

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(WerewolfApi.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(WerewolfApi.Repo, {:shared, self()})
  end

  describe "handle/3 launch_game" do
    test "updates game with conversation_id" do
      user_one = insert(:user)
      user_two = insert(:user)

      game_state = %{
        game: %{
          players: %{
            user_one.id => %{id: user_one.id, role: :werewolf},
            user_two.id => %{id: user_two.id, role: :werewolf}
          }
        }
      }

      game = insert(:game)
      Event.handle(game, game_state, {:ok, :launch_game})

      updated_game =
        WerewolfApi.Repo.get(WerewolfApi.Game, game.id)
        |> WerewolfApi.Repo.preload(conversation: :users)

      assert Enum.map(updated_game.conversation.users, fn user -> user.id end) == [
               user_one.id,
               user_two.id
             ]

      assert updated_game.started == true
    end
  end

  describe "handle/3 end_phase" do
    test "when villager win" do
      game = insert(:game)
      Event.handle(game, %{updated: true}, {:village_win, :ok, :ok})
      updated_game = WerewolfApi.Repo.get(WerewolfApi.Game, game.id)
      assert updated_game.finished
      assert updated_game.state == %{"updated" => true}
    end

    test "when werewolf win" do
      game = insert(:game)
      Event.handle(game, %{updated: true}, {:werewolf_win, :ok, :ok})
      updated_game = WerewolfApi.Repo.get(WerewolfApi.Game, game.id)
      assert updated_game.finished
      assert updated_game.state == %{"updated" => true}
    end

    test "when no win" do
      game = insert(:game)
      Event.handle(game, %{updated: true}, {:no_win, :ok, :ok})
      updated_game = WerewolfApi.Repo.get(WerewolfApi.Game, game.id)
      refute game.finished
      assert updated_game.state == %{"updated" => true}
    end
  end

  describe "handle/3 default" do
    test "when villager win" do
      game = insert(:game)
      user_one = insert(:user)

      game_state = %{
        game: %{
          players: %{
            user_one.id => %{id: user_one.id, role: :werewolf}
          }
        }
      }

      Event.handle(game, game_state, {:other_event, :ok})
      updated_game = WerewolfApi.Repo.get(WerewolfApi.Game, game.id)

      assert updated_game.state["game"]["players"][Integer.to_string(user_one.id)]["id"] ==
               user_one.id
    end
  end
end
