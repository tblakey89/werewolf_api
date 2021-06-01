defmodule WerewolfApiWeb.GameView do
  use WerewolfApiWeb, :view
  import WerewolfApiWeb.GameStateHelpers
  alias WerewolfApi.Game

  def render("index.json", %{games: games}) do
    %{
      games:
        render_many(
          games,
          WerewolfApiWeb.GameView,
          "game.json"
        )
    }
  end

  def render("show.json", %{game: game, user: user}) do
    %{
      game:
        render_one(
          %{game: game, user: user, state: WerewolfApi.Game.current_state(game)},
          WerewolfApiWeb.GameView,
          "game_with_state.json",
          as: :data
        )
    }
  end

  def render("show.json", %{game: game}) do
    %{
      game:
        render_one(
          game,
          WerewolfApiWeb.GameView,
          "game.json"
        )
    }
  end

  def render("game.json", %{game: game}) do
    %{
      id: game.id,
      name: game.name,
      token: game.invitation_token,
      url: game.invitation_url,
      conversation_id: game.conversation_id,
      mason_conversation_id: game.mason_conversation_id,
      created_at:
        DateTime.to_unix(DateTime.from_naive!(game.inserted_at, "Etc/UTC"), :millisecond),
      users_games: render_many(game.users_games, WerewolfApiWeb.UsersGameView, "users_game.json"),
      messages: render_many(game.messages, WerewolfApiWeb.GameMessageView, "game_message.json"),
      has_join_code: game.join_code != nil,
      type: game.type,
      start_at: start_at(game),
      closed: game.closed,
      time_period: game.time_period,
      allowed_roles: game.allowed_roles || [],
      join_code: game.join_code
    }
  end

  def render("game_with_state.json", %{data: %{game: game, state: state, user: user}}) do
    %{
      id: game.id,
      name: game.name,
      created_at:
        DateTime.to_unix(DateTime.from_naive!(game.inserted_at, "Etc/UTC"), :millisecond),
      token: game.invitation_token,
      url: game.invitation_url,
      conversation_id: game.conversation_id,
      mason_conversation_id: game.mason_conversation_id,
      users_games: render_many(game.users_games, WerewolfApiWeb.UsersGameView, "users_game.json"),
      messages: render_many(game.messages, WerewolfApiWeb.GameMessageView, "game_message.json"),
      state:
        render_one(
          %{state: state, game_id: game.id, user: user},
          WerewolfApiWeb.GameView,
          "state.json",
          as: :data
        ),
      type: game.type,
      start_at: start_at(game),
      closed: game.closed,
      time_period: game.time_period,
      allowed_roles: game.allowed_roles || [],
      join_code: game.join_code
    }
  end

  def render("state.json", %{data: %{state: state, game_id: game_id, user: user}}) do
    %{
      id: game_id,
      end_phase_unix_time: state.game.end_phase_unix_time,
      phase_length: state.game.phase_length,
      phases: state.game.phases,
      win_status: state.game.win_status,
      targets: state.game.targets,
      players:
        render_one(
          %{
            game_id: game_id,
            players: state.game.players,
            user: user,
            state: state.rules.state,
            phase_number: state.game.phases
          },
          WerewolfApiWeb.GameView,
          "players.json",
          as: :data
        ),
      state: state.rules.state
    }
  end

  def render("players.json", %{
        data: %{
          game_id: game_id,
          players: players,
          user: user,
          state: state,
          phase_number: phase_number
        }
      }) do
    current_player = players[user.id]

    Enum.reduce(players, %{}, fn {key, player}, accumulator ->
      player_map =
        case key == user.id do
          # werewolf need to see other werewolf
          true ->
            render_one(%{player: player}, WerewolfApiWeb.GameView, "self_player.json", as: :data)

          false ->
            render_one(
              %{
                game_id: game_id,
                player: player,
                current_player: current_player,
                state: state,
                phase_number: phase_number
              },
              WerewolfApiWeb.GameView,
              "other_player.json",
              as: :data
            )
        end

      Map.put(accumulator, key, player_map)
    end)
  end

  def render("self_player.json", %{data: %{player: player}}) do
    %{
      id: player.id,
      alive: player.alive,
      role: player.role,
      host: player.host,
      actions: player.actions,
      items: player.items,
      team: player.team
    }
  end

  def render("other_player.json", %{
        data: %{
          game_id: game_id,
          player: player,
          current_player: current_player,
          state: state,
          phase_number: phase_number
        }
      }) do
    %{
      id: player.id,
      alive: player.alive,
      host: player.host,
      role: display_value(game_id, state, current_player, player, player.role),
      actions: filter_actions(state, phase_number, current_player, player),
      team: display_value(game_id, state, current_player, player, player.team)
    }
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end

  def render("error.json", %{message: message}) do
    %{error: message}
  end

  defp start_at(%{start_at: nil}), do: nil

  defp start_at(game) do
    DateTime.to_unix(DateTime.from_naive!(game.start_at, "Etc/UTC"), :millisecond)
  end
end
