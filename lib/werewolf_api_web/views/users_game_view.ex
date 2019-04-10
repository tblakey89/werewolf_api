defmodule WerewolfApiWeb.UsersGameView do
  use WerewolfApiWeb, :view

  def render("users_game.json", %{users_game: users_game}) do
    %{
      id: users_game.id,
      state: users_game.state,
      user_id: users_game.user_id,
      created_at:
        DateTime.to_unix(DateTime.from_naive!(users_game.inserted_at, "Etc/UTC"), :millisecond),
      last_read_at: DateTime.to_unix(users_game.last_read_at, :millisecond),
      user: render_one(users_game.user, WerewolfApiWeb.UserView, "simple_user.json")
    }
  end

  def render("simple_users_game.json", %{users_game: users_game}) do
    %{
      id: users_game.id,
      state: users_game.state,
      user_id: users_game.user_id,
      game_id: users_game.game_id,
      created_at:
        DateTime.to_unix(DateTime.from_naive!(users_game.inserted_at, "Etc/UTC"), :millisecond),
      last_read_at: DateTime.to_unix(users_game.last_read_at, :millisecond)
    }
  end
end
