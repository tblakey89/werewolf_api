defmodule WerewolfApiWeb.GameMessageView do
  use WerewolfApiWeb, :view

  def render("game_message.json", %{game_message: game_message}) do
    %{
      id: game_message.id,
      created_at:
        DateTime.to_unix(DateTime.from_naive!(game_message.inserted_at, "Etc/UTC"), :millisecond),
      body: game_message.body,
      bot: game_message.bot,
      sender: render_optional_user(game_message),
      game_id: game_message.game_id,
      type: game_message.type,
      uuid: game_message.uuid,
      destination: game_message.destination,
      extra: game_message.extra,
      custom: game_message.custom,
      quote_id: game_message.quote_id
    }
  end

  defp render_optional_user(%{user_id: 0}), do: nil

  defp render_optional_user(game_message) do
    render_one(game_message.user, WerewolfApiWeb.UserView, "simple_user.json")
  end
end
