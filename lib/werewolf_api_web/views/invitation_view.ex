defmodule WerewolfApiWeb.InvitationView do
  use WerewolfApiWeb, :view
  alias WerewolfApi.UsersGame

  def render("create.json", %{users_game: users_game, game: game, user: user, state: state}) do
    %{success: "Joined the game", game: render_one(
      %{
        user: user,
        state: state,
        game: game
      },
      WerewolfApiWeb.GameView,
      "game_with_state.json",
      as: :data
    ),}
  end

  def render("success.json", %{users_game: %UsersGame{state: "accepted"} = users_game}) do
    %{success: "Joined the game", game_id: users_game.game_id}
  end

  def render("success.json", %{users_game: %UsersGame{state: "rejected"} = users_game}) do
    %{success: "Rejected the invitation", game_id: users_game.game_id}
  end

  def render("removed.json", %{users_game: users_game}) do
    %{success: "Removed the user", game_id: users_game.game_id}
  end

  def render("ok.json", %{game: game}) do
    %{
      name: game.name,
      host_name: WerewolfApi.Game.find_host_username(game)
    }
  end

  def render("error.json", %{message: message}) do
    %{error: message}
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end
end
