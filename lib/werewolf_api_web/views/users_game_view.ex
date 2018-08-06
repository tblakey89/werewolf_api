defmodule WerewolfApiWeb.UsersGameView do
  use WerewolfApiWeb, :view

  def render("users_game.json", %{users_game: users_game}) do
    %{
      id: users_game.id,
      state: users_game.state,
      user_id: users_game.user_id,
      user: render_one(users_game.user, WerewolfApiWeb.UserView, "simple_user.json")
    }
  end
end
