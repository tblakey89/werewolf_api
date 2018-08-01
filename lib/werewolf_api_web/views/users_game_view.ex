defmodule WerewolfApiWeb.UsersGameView do
  use WerewolfApiWeb, :view

  def render("users_game.json", %{users_game: users_game}) do
    %{
      state: users_game.state,
      user_id: users_game.user_id,
      user: render_one(users_game.user, WerewolfApiWeb.UserView, "simple_user.json")
    }
  end
end
