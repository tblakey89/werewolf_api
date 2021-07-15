defmodule WerewolfApiWeb.GameStateHelpersTest do
  use ExUnit.Case
  alias WerewolfApiWeb.GameStateHelpers

  describe "filter_actions/4" do
    test 'when game_over returns player actions' do
      player = player(1, :villager)

      actions = GameStateHelpers.filter_actions(%Werewolf.Options{}, :game_over, nil, nil, player)
      assert player.actions == actions
    end

    test 'when game_over returns player actions, even when display votes false' do
      player = player(1, :villager)

      actions =
        GameStateHelpers.filter_actions(
          %Werewolf.Options{display_votes: false},
          :game_over,
          nil,
          nil,
          player
        )

      assert player.actions == actions
    end

    test 'when day returns player actions for that day' do
      player = player(1, :villager)

      actions = GameStateHelpers.filter_actions(%Werewolf.Options{}, :day_phase, 1, nil, player)
      assert %{1 => player.actions[1]} == actions
    end

    test 'when day returns player actions for that day, unless display_votes off' do
      player = player(1, :villager)

      actions =
        GameStateHelpers.filter_actions(
          %Werewolf.Options{display_votes: false},
          :day_phase,
          1,
          nil,
          player
        )

      assert nil == actions
    end

    test 'when day returns player actions for that day if werewolf' do
      player = player(1, :werewolf)

      actions = GameStateHelpers.filter_actions(%Werewolf.Options{}, :day_phase, 1, nil, player)
      assert %{1 => player.actions[1]} == actions
    end

    test 'when day returns player actions for different day on different phase' do
      player = player(1, :villager)

      actions = GameStateHelpers.filter_actions(%Werewolf.Options{}, :day_phase, 2, nil, player)
      assert %{2 => player.actions[2]} == actions
    end

    test 'when day returns no player actions if no actions that day' do
      player = player(1, :villager)

      actions = GameStateHelpers.filter_actions(%Werewolf.Options{}, :day_phase, 3, nil, player)
      assert %{} == actions
    end

    test 'when night returns no player actions if current player is villager' do
      player = player(1, :werewolf)
      current_player = player(2, :villager)

      actions =
        GameStateHelpers.filter_actions(
          %Werewolf.Options{},
          :night_phase,
          1,
          current_player,
          player
        )

      assert nil == actions
    end

    test 'when night returns no player actions if player is villager and current player werewolf' do
      player = player(1, :villager)
      current_player = player(2, :werewolf)

      actions =
        GameStateHelpers.filter_actions(
          %Werewolf.Options{},
          :night_phase,
          1,
          current_player,
          player
        )

      assert nil == actions
    end

    test 'when night returns player actions if player is werewolf and current player werewolf' do
      player = player(1, :werewolf)
      current_player = player(2, :werewolf)

      actions =
        GameStateHelpers.filter_actions(
          %Werewolf.Options{},
          :night_phase,
          1,
          current_player,
          player
        )

      assert %{1 => player.actions[1]} == actions
    end

    test 'when night returns player actions if player is werewolf and current player werewolf, different phase' do
      player = player(1, :werewolf)
      current_player = player(2, :werewolf)

      actions =
        GameStateHelpers.filter_actions(
          %Werewolf.Options{},
          :night_phase,
          2,
          current_player,
          player
        )

      assert %{2 => player.actions[2]} == actions
    end

    test 'when wrong state returns nil' do
      player = player(1, :werewolf)
      current_player = player(2, :werewolf)

      actions =
        GameStateHelpers.filter_actions(%Werewolf.Options{}, :pause, 1, current_player, player)

      assert nil == actions
    end
  end

  describe "display_value/5" do
    test 'when game_over returns player role' do
      player = player(1, :villager)

      assert player.role ==
               GameStateHelpers.display_value(
                 %Werewolf.Options{},
                 :game_over,
                 nil,
                 player,
                 player.role
               )
    end

    test 'when current player is villager, other player is villager, role is unknown' do
      player = player(1, :villager)
      current_player = player(2, :villager)

      assert "Unknown" ==
               GameStateHelpers.display_value(
                 %Werewolf.Options{},
                 :day_phase,
                 current_player,
                 player,
                 player.role
               )
    end

    test 'when current player is villager, other player is werewolf, role is unknown' do
      player = player(1, :werewolf)
      current_player = player(2, :villager)

      assert "Unknown" ==
               GameStateHelpers.display_value(
                 %Werewolf.Options{},
                 :day_phase,
                 current_player,
                 player,
                 player.role
               )
    end

    test 'when current player is werewolf, other player is villager, role is unknown' do
      player = player(1, :villager)
      current_player = player(2, :werewolf)

      assert "Unknown" ==
               GameStateHelpers.display_value(
                 %Werewolf.Options{},
                 :day_phase,
                 current_player,
                 player,
                 player.role
               )
    end

    test 'when current player is werewolf, other player is werewolf, role is werewolf' do
      player = player(1, :werewolf)
      current_player = player(2, :werewolf)

      assert :werewolf ==
               GameStateHelpers.display_value(
                 %Werewolf.Options{},
                 :day_phase,
                 current_player,
                 player,
                 player.role
               )
    end

    test 'when player is werewolf and player is dead role is werewolf' do
      player = player(1, :werewolf, false)

      assert :werewolf ==
               GameStateHelpers.display_value(
                 %Werewolf.Options{},
                 :day_phase,
                 nil,
                 player,
                 player.role
               )
    end

    test 'when player is villager and player is dead role is villager' do
      player = player(1, :villager, false)

      assert :villager ==
               GameStateHelpers.display_value(
                 %Werewolf.Options{},
                 :day_phase,
                 nil,
                 player,
                 player.role
               )
    end

    test 'when reveal role is false when player is villager and player is dead role is villager' do
      player = player(1, :villager, false)

      assert "Unknown" ==
               GameStateHelpers.display_value(
                 %Werewolf.Options{reveal_role: false},
                 :day_phase,
                 nil,
                 player,
                 player.role
               )
    end
  end

  describe "display_targets/2" do
    test "when passed targets with reveal type of death true" do
      targets =
        GameStateHelpers.display_targets(
          %{
            1 => [
              %Werewolf.KillTarget{type: :werewolf, target: 1}
            ]
          },
          %Werewolf.Options{reveal_type_of_death: true}
        )

      assert Enum.at(targets[1], 0).type == :werewolf
    end

    test "when passed targets with reveal type of death false" do
      targets =
        GameStateHelpers.display_targets(
          %{
            1 => [
              %Werewolf.KillTarget{type: :werewolf, target: 1}
            ]
          },
          %Werewolf.Options{reveal_type_of_death: false}
        )

      assert Enum.at(targets[1], 0).type == :death
    end

    test "when passed resurrect and defend targets with reveal type of death false" do
      targets =
        GameStateHelpers.display_targets(
          %{
            1 => [
              %Werewolf.KillTarget{type: :werewolf, target: 1},
              %Werewolf.KillTarget{type: :defend, target: 1},
              %Werewolf.KillTarget{type: :resurrect, target: 1}
            ]
          },
          %Werewolf.Options{reveal_type_of_death: false}
        )

      assert Enum.at(targets[1], 0).type == :death
      assert Enum.at(targets[1], 1).type == :defend
      assert Enum.at(targets[1], 2).type == :resurrect
    end
  end

  defp player(id, role, alive \\ true) do
    %Werewolf.Player{
      id: id,
      role: role,
      team: role,
      host: false,
      alive: alive,
      actions: %{
        1 => %Werewolf.Action{
          type: :vote,
          target: 123
        },
        2 => %Werewolf.Action{
          type: :vote,
          target: 234
        }
      }
    }
  end
end
