defmodule WerewolfApiWeb.GameStateHelpers do
  def filter_actions(:game_over, _, _, player) do
    player.actions
  end
  def filter_actions(:day_phase, phase_number, _, player) do
    Map.take(player.actions, [phase_number])
  end
  def filter_actions(:night_phase, phase_number, %Werewolf.Player{role: :werewolf}, %Werewolf.Player{role: :werewolf} = player) do
    Map.take(player.actions, [phase_number])
  end
  def filter_actions(_, _, _, _), do: nil

  def display_role(:game_over, _, player) do
    player.role
  end
  def display_role(_, %Werewolf.Player{role: :werewolf}, %Werewolf.Player{role: :werewolf} = player) do
    player.role
  end
  def display_role(_, _, %Werewolf.Player{alive: false} = player) do
    player.role
  end
  def display_role(_, _, _), do: "Unknown"
end
