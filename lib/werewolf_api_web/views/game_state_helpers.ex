defmodule WerewolfApiWeb.GameStateHelpers do
  def filter_actions(:game_over, _, _, player) do
    player.actions
  end

  def filter_actions(:day_phase, phase_number, _, player) do
    Map.take(player.actions, [phase_number])
  end

  def filter_actions(
        :night_phase,
        phase_number,
        %Werewolf.Player{team: :werewolf},
        %Werewolf.Player{team: :werewolf} = player
      ) do
    Map.take(player.actions, [phase_number])
  end

  def filter_actions(_, _, _, _), do: nil

  def display_value(_, :game_over, _, player, value) do
    value
  end

  def display_value(
        _,
        _,
        %Werewolf.Player{team: :werewolf},
        %Werewolf.Player{team: :werewolf},
        value
      ) do
    value
  end

  def display_value(
        _,
        _,
        %Werewolf.Player{role: :mason},
        %Werewolf.Player{role: :mason},
        value
      ) do
    value
  end

  def display_value(%Werewolf.Options{reveal_role: false}, _, _, _, value) do
    "Unknown"
  end

  def display_value(_, _, _, %Werewolf.Player{alive: false}, value) do
    value
  end

  def display_value(_, _, _, _, _), do: "Unknown"

  def display_targets(targets, %Werewolf.Options{reveal_type_of_death: true}) do
    targets
  end

  def display_targets(targets, %Werewolf.Options{reveal_type_of_death: false}) do
    Enum.reduce(targets, %{}, fn {phase, phase_targets}, cleared_targets ->
      Map.put(
        cleared_targets,
        phase,
        Enum.map(phase_targets, fn target ->
          case target.type do
            :resurrect -> target
            :defend -> target
            _ -> Map.put(target, :type, :death)
          end
        end)
      )
    end)
  end
end
