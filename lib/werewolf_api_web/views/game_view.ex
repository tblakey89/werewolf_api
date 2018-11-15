defmodule WerewolfApiWeb.GameView do
  use WerewolfApiWeb, :view
  alias WerewolfApi.Game

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
      users_games: render_many(game.users_games, WerewolfApiWeb.UsersGameView, "users_game.json"),
      messages:
        render_many(game.game_messages, WerewolfApiWeb.GameMessageView, "game_message.json")
    }
  end

  def render("game_with_state.json", %{data: %{game: game, state: state, user: user}}) do
    %{
      id: game.id,
      name: game.name,
      users_games: render_many(game.users_games, WerewolfApiWeb.UsersGameView, "users_game.json"),
      messages:
        render_many(game.game_messages, WerewolfApiWeb.GameMessageView, "game_message.json"),
      state:
        render_one(
          %{state: state, game_id: game.id, user: user},
          WerewolfApiWeb.GameView,
          "state.json",
          as: :data
        )
    }
  end

  def render("state.json", %{data: %{state: state, game_id: game_id, user: user}}) do
    %{
      id: game_id,
      end_phase_unix_time: state.game.end_phase_unix_time,
      phase_length: state.game.phase_length,
      phases: state.game.phases,
      players:
        render_one(
          %{players: state.game.players, user: user},
          WerewolfApiWeb.GameView,
          "players.json",
          as: :data
        ),
      state: state.rules.state
    }
  end

  def render("players.json", %{data: %{players: players, user: user}}) do
    Enum.reduce(players, %{}, fn {key, player}, accumulator ->
      player_map =
        case key == user.id do
          # werewolf need to see other werewolf
          true ->
            render_one(%{player: player}, WerewolfApiWeb.GameView, "self_player.json", as: :data)

          false ->
            render_one(%{player: player}, WerewolfApiWeb.GameView, "other_player.json", as: :data)
        end

      Map.put(accumulator, key, player_map)
    end)
  end

  def render("self_player.json", %{data: %{player: player}}) do
    %{
      id: player.id,
      alive: player.alive,
      role: player.role,
      actions:
        Enum.reduce(player.actions, %{}, fn {key, action}, accumulator ->
          Map.put(accumulator, key, %{
            type: action.type,
            target: action.target
          })
        end)
    }
  end

  def render("other_player.json", %{data: %{player: player}}) do
    %{
      id: player.id,
      alive: player.alive,
      role: if(player.alive, do: 'Unknown', else: player.role)
    }
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end
end
