defmodule WerewolfApiWeb.GameMessageView do
  use WerewolfApiWeb, :view

  def render("game_message.json", %{game_message: game_message}) do
    %{
      id: game_message.id,
      created_at:
        DateTime.to_unix(DateTime.from_naive!(game_message.inserted_at, "Etc/UTC"), :millisecond),
      body: game_message.body,
      bot: game_message.bot,
      sender: render_one(game_message.user, WerewolfApiWeb.UserView, "simple_user.json"),
      game_id: game_message.game_id
    }
  end
end
