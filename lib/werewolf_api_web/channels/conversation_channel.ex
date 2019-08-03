defmodule WerewolfApiWeb.ConversationChannel do
  use Phoenix.Channel
  alias WerewolfApi.Repo
  alias WerewolfApi.Notification
  alias WerewolfApi.Conversation
  alias WerewolfApi.Conversation.Message

  def join("conversation:" <> conversation_id, _message, socket) do
    conversation =
      Guardian.Phoenix.Socket.current_resource(socket)
      |> Ecto.assoc(:conversations)
      |> Repo.get(String.to_integer(conversation_id))

    case conversation do
      nil -> {:error, %{reason: "unauthorized"}}
      conversation -> {:ok, assign(socket, :conversation_id, conversation.id)}
    end
  end

  def handle_in("new_message", params, socket) do
    # need to make saving message a task
    changeset =
      Guardian.Phoenix.Socket.current_resource(socket)
      |> Ecto.build_assoc(:messages, conversation_id: socket.assigns.conversation_id)
      |> Message.changeset(params)

    case Repo.insert(changeset) do
      {:ok, message} ->
        message = Repo.preload(message, :user)

        broadcast!(
          socket,
          "new_message",
          WerewolfApiWeb.MessageView.render("message.json", %{message: message})
        )

        Notification.new_conversation_message(message)

        update_last_read_at(socket)
        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  def handle_in("read_conversation", params, socket) do
    update_last_read_at(socket)
    {:reply, :ok, socket}
  end

  defp update_last_read_at(socket) do
    WerewolfApi.UsersConversation.update_last_read_at(
      Guardian.Phoenix.Socket.current_resource(socket).id,
      socket.assigns.conversation_id
    )
  end
end
