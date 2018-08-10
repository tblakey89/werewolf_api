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

  def render("error.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end
end
