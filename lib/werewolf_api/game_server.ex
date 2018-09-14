defmodule WerewolfApi.GameServer do
  def start_game(user, game_id, time_period) do
    Werewolf.GameSupervisor.start_game(user, game_id, time_period)
  end

  def get_state(game_id) do
    get_pid(game_id)
    |> Werewolf.GameServer.get_state()
  end

  def add_player(game_id, user) do
    get_pid(game_id)
    |> Werewolf.GameServer.add_player(user)
    |> handle_response(game_id, user)
  end

  def game_ready(game_id, user) do
    get_pid(game_id)
    |> Werewolf.GameServer.game_ready(user)
    |> handle_response(game_id, user)
  end

  def launch_game(game_id, user) do
    get_pid(game_id)
    |> Werewolf.GameServer.launch_game(user)
    |> handle_response(game_id, user)
  end

  def action(game_id, user, target, action_type) do
    get_pid(game_id)
    |> Werewolf.GameServer.game_ready(user, target, action_type)
    |> handle_response(game_id, user)
  end

  def end_phase(game_id) do
    response =
      get_pid(game_id)
      |> Werewolf.GameServer.end_phase()

    case response do
      {win_status, target, phases, state} ->
        WerewolfApiWeb.GameChannel.broadcast_state_update(game_id, state)
        update_game_state(game_id, state)
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_response(response, game_id, user) do
    case response do
      {:ok, state} ->
        WerewolfApiWeb.GameChannel.broadcast_state_update(game_id, state, user)
        update_game_state(game_id, state)
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_pid(game_id) do
    case Werewolf.GameSupervisor.pid_from_name(game_id) do
      nil -> restart_game(game_id)
      pid -> pid
    end
  end

  defp update_game_state(game_id, state) do
    Task.async(fn ->
      WerewolfApi.Game.update_state(game_id, state)
    end)
  end

  defp restart_game(game_id) do
    game =
      WerewolfApi.Game.find_from_id(game_id)
      |> WerewolfApi.Repo.preload(users_games: :user)

    host = Enum.find(game.users_games, fn user_game -> user_game.state == :host end)
    {:ok, pid} = Werewolf.GameSupervisor.start_game(host, game_id, game.time_period, game.state)
    pid
  end
end
