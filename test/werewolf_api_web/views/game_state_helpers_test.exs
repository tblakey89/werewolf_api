defmodule WerewolfApiWeb.GameStateHelpersTest do
  use ExUnit.Case
  alias WerewolfApiWeb.GameStateHelpers

  describe "filter_actions/4" do
    test 'when game_over returns player actions' do
      player = player(1, :villager)

      actions = GameStateHelpers.filter_actions(:game_over, nil, nil, player)
      assert player.actions == actions
    end

    test 'when day returns player actions for that day' do
      player = player(1, :villager)

      actions = GameStateHelpers.filter_actions(:day_phase, 1, nil, player)
      assert %{1 => player.actions[1]} == actions
    end

    test 'when day returns player actions for that day if werewolf' do
      player = player(1, :werewolf)

      actions = GameStateHelpers.filter_actions(:day_phase, 1, nil, player)
      assert %{1 => player.actions[1]}  == actions
    end

    test 'when day returns player actions for different day on different phase' do
      player = player(1, :villager)

      actions = GameStateHelpers.filter_actions(:day_phase, 2, nil, player)
      assert %{2 => player.actions[2]} == actions
    end

    test 'when day returns no player actions if no actions that day' do
      player = player(1, :villager)

      actions = GameStateHelpers.filter_actions(:day_phase, 3, nil, player)
      assert %{} == actions
    end

    test 'when night returns no player actions if current player is villager' do
      player = player(1, :werewolf)
      current_player = player(2, :villager)

      actions = GameStateHelpers.filter_actions(:night_phase, 1, current_player, player)
      assert nil == actions
    end

    test 'when night returns no player actions if player is villager and current player werewolf' do
      player = player(1, :villager)
      current_player = player(2, :werewolf)

      actions = GameStateHelpers.filter_actions(:night_phase, 1, current_player, player)
      assert nil == actions
    end

    test 'when night returns player actions if player is werewolf and current player werewolf' do
      player = player(1, :werewolf)
      current_player = player(2, :werewolf)

      actions = GameStateHelpers.filter_actions(:night_phase, 1, current_player, player)
      assert %{1 => player.actions[1]} == actions
    end

    test 'when night returns player actions if player is werewolf and current player werewolf, different phase' do
      player = player(1, :werewolf)
      current_player = player(2, :werewolf)

      actions = GameStateHelpers.filter_actions(:night_phase, 2, current_player, player)
      assert %{2 => player.actions[2]} == actions
    end

    test 'when wrong state returns nil' do
      player = player(1, :werewolf)
      current_player = player(2, :werewolf)

      actions = GameStateHelpers.filter_actions(:pause, 1, current_player, player)
      assert nil == actions
    end
  end

  describe "display_role/3" do
    test 'when game_over returns player role' do
      player = player(1, :villager)

      assert player.role == GameStateHelpers.display_role(:game_over, nil, player)
    end

    test 'when day returns player actions for that day' do
      player = player(1, :villager)

      actions = GameStateHelpers.filter_actions(:day_phase, 1, nil, player)
      assert %{1 => player.actions[1]} == actions
    end

    test 'when current player is villager, other player is villager, role is unknown' do
      player = player(1, :villager)
      current_player = player(2, :villager)

      assert "Unknown" == GameStateHelpers.display_role(:day_phase, current_player, player)
    end

    test 'when current player is villager, other player is werewolf, role is unknown' do
      player = player(1, :werewolf)
      current_player = player(2, :villager)

      assert "Unknown" == GameStateHelpers.display_role(:day_phase, current_player, player)
    end

    test 'when current player is werewolf, other player is villager, role is unknown' do
      player = player(1, :villager)
      current_player = player(2, :werewolf)

      assert "Unknown" == GameStateHelpers.display_role(:day_phase, current_player, player)
    end

    test 'when current player is werewolf, other player is werewolf, role is werewolf' do
      player = player(1, :werewolf)
      current_player = player(2, :werewolf)

      assert :werewolf == GameStateHelpers.display_role(:day_phase, current_player, player)
    end

    test 'when player is werewolf and player is dead role is werewolf' do
      player = player(1, :werewolf, false)

      assert :werewolf == GameStateHelpers.display_role(:day_phase, nil, player)
    end

    test 'when player is villager and player is dead role is villager' do
      player = player(1, :villager, false)

      assert :villager == GameStateHelpers.display_role(:day_phase, nil, player)
    end
  end

  defp player(id, role, alive \\ true) do
    %Werewolf.Player{
      id: id,
      role: role,
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
