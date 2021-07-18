defmodule WerewolfApi.Game.Server do
  alias WerewolfApi.Game

  def start_game(user, game_id, time_period, allowed_roles, options) do
    Werewolf.GameSupervisor.start_game(
      user,
      game_id,
      time_period,
      nil,
      &handle_game_callback/2,
      allowed_roles,
      options
    )
  end

  def edit_game(game_id, time_period, allowed_roles, options) do
    response =
      get_pid(game_id)
      |> Werewolf.GameServer.edit_game(time_period, allowed_roles, options)

    case response do
      {:ok, :edit_game, state} ->
        handle_success(game_id, nil, nil)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_state(game_id) do
    get_pid(game_id)
    |> Werewolf.GameServer.get_state()
  end

  def get_relevant_players(game_id, type) do
    get_pid(game_id)
    |> Werewolf.GameServer.relevant_players(type)
  end

  def add_player(game_id, user) do
    response =
      get_pid(game_id)
      |> Werewolf.GameServer.add_player(user)

    case response do
      {:ok, :add_player, _user, state} -> handle_success(game_id, user, state)
      {:error, reason} -> {:error, reason}
    end
  end

  def remove_player(game_id, user) do
    response =
      get_pid(game_id)
      |> Werewolf.GameServer.remove_player(user)

    case response do
      {:ok, :remove_player, _user, state} -> handle_success(game_id, user, state)
      {:error, reason} -> {:error, reason}
    end
  end

  def launch_game(game_id, user) do
    response =
      get_pid(game_id)
      |> Werewolf.GameServer.launch_game(user)

    case response do
      {:ok, :launch_game, state} ->
        handle_success(game_id, user, state)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def launch_game(game_id) do
    response =
      get_pid(game_id)
      |> Werewolf.GameServer.launch_game()

    case response do
      {:ok, :launch_game, state} ->
        handle_success(game_id, nil, state)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def action(game_id, user, target, action_type) do
    response =
      get_pid(game_id)
      |> Werewolf.GameServer.action(user, target, action_type)

    case response do
      {:ok, :action, _, _, _, _, _, _, state} ->
        handle_success(game_id, user, state)

      {:ok, :action, state} ->
        handle_success(game_id, user, state)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def cancel_action(game_id, user, action_type) do
    response =
      get_pid(game_id)
      |> Werewolf.GameServer.cancel_action(user, action_type)

    case response do
      {:ok, :cancel_action, _, _, _, _, _, state} ->
        handle_success(game_id, user, state)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def claim_role(game_id, user, claim) do
    response =
      get_pid(game_id)
      |> Werewolf.GameServer.claim_role(user, claim)

    case response do
      {:ok, :claim_role, user, claim, state} ->
        handle_success(game_id, user, state)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def end_phase(game_id, user) do
    response =
      get_pid(game_id)
      |> Werewolf.GameServer.end_phase(user)

    case response do
      {win_status, target, phases, state} ->
        WerewolfApiWeb.UserChannel.broadcast_state_update(game_id, Game.clean_state(state))
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_success(game_id, _user, state) do
    :ok
  end

  defp get_pid(game_id) do
    case Werewolf.GameSupervisor.pid_from_name(game_id) do
      nil -> restart_game(game_id)
      pid -> pid
    end
  end

  defp handle_game_callback(state, game_response) do
    Task.start_link(fn ->
      game =
        WerewolfApi.Repo.get(Game, state.game.id)
        |> WerewolfApi.Repo.preload(:users)

      Game.Event.handle(game, state, game_response)
      Game.Announcement.announce(game, state, game_response)
    end)
  end

  defp restart_game(game_id) do
    game =
      WerewolfApi.Game.find_from_id(game_id)
      |> WerewolfApi.Repo.preload(users_games: :user)

    host =
      Enum.find(game.users_games, fn user_game -> String.to_atom(user_game.state) == :host end)

    {:ok, pid} =
      Werewolf.GameSupervisor.start_game(
        host,
        game_id,
        String.to_atom(game.time_period),
        game.state,
        &handle_game_callback/2
      )

    pid
  end
end
