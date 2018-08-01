defmodule WerewolfApiWeb.UserChannel do
  use Phoenix.Channel

  def join("user:" <> user_id, _message, socket) do
    case Guardian.Phoenix.Socket.current_resource(socket).id == String.to_integer(user_id) do
      true -> {:ok, socket}
      false -> {:error, %{reason: "unauthorized"}}
    end
  end

  def broadcast_conversation_creation_to_users(conversation) do
    # maybe move this into a task?
    Enum.each(conversation.users, fn user ->
      WerewolfApiWeb.Endpoint.broadcast(
        "user:#{user.id}",
        "new_conversation",
        WerewolfApiWeb.ConversationView.render("conversation_with_messages.json", %{
          conversation: conversation
        })
      )
    end)
  end
end
