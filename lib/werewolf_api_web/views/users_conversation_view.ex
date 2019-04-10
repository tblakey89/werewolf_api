defmodule WerewolfApiWeb.UsersConversationView do
  use WerewolfApiWeb, :view

  def render("users_conversation.json", %{users_conversation: users_conversation}) do
    %{
      id: users_conversation.id,
      user_id: users_conversation.user_id,
      last_read_at: DateTime.to_unix(users_conversation.last_read_at, :millisecond)
    }
  end
end
