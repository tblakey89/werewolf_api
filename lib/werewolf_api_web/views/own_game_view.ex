defmodule WerewolfApiWeb.OwnGameView do
  use WerewolfApiWeb, :view
  alias WerewolfApi.Game

  def render("index.json", %{games: games, user: user}) do
    render_many(
      Enum.map(games, fn game ->
        %{game: game, user: user, state: WerewolfApi.Game.current_state(game)}
      end),
      WerewolfApiWeb.GameView,
      "game_with_state.json",
      as: :data
    )
  end
end
