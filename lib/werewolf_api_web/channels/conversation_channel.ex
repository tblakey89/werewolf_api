defmodule WerewolfApiWeb.ConversationChannel do
  use Phoenix.Channel
  alias WerewolfApi.Repo
  alias WerewolfApi.Conversation
  alias WerewolfApi.Message

  def join("conversation:" <> conversation_id, _message, socket) do
    conversation = Repo.get(Conversation, String.to_integer(conversation_id))

    case authorized_conversation?(conversation, socket) do
      true -> {:ok, assign(socket, :conversation_id, conversation.id)}
      false -> {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("new_message", params, socket) do
    # need to work out way to handle unread messages
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

        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  defp authorized_conversation?(conversation, socket) do
    user_id = Guardian.Phoenix.Socket.current_resource(socket).id
    conversation = Repo.preload(conversation, :users)

    Enum.map(conversation.users, fn user ->
      user.id
    end)
    |> Enum.member?(user_id)
  end
end
