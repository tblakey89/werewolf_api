defmodule WerewolfApi.Conversation.Announcement do
  def announce(conversation, {:werewolf, game_name}) do
    broadcast_conversation(conversation, "This is the werewolf group chat for #{game_name}.")
  end

  def announce(_conversation, _), do: nil

  defp broadcast_conversation(conversation, message) do
    changeset =
      Ecto.build_assoc(conversation, :messages, user_id: 0)
      |> WerewolfApi.Conversation.Message.changeset(%{body: message})
      |> Ecto.Changeset.change(bot: true)

    case WerewolfApi.Repo.insert(changeset) do
      {:ok, _message} ->
        WerewolfApi.Repo.preload(conversation, [:users, :users_conversations, messages: :user])
        |> WerewolfApiWeb.UserChannel.broadcast_conversation_creation_to_users()

      {:error, changeset} ->
        nil
    end
  end

  defp broadcast_message(conversation, message) do
    changeset =
      Ecto.build_assoc(conversation, :messages, user_id: 0)
      |> WerewolfApi.Conversation.Message.changeset(%{bot: true, body: message})

    case WerewolfApi.Repo.insert(changeset) do
      {:ok, message} ->
        WerewolfApiWeb.Endpoint.broadcast(
          "conversation:#{conversation.id}",
          "new_message",
          WerewolfApiWeb.MessageView.render("message.json", %{
            message: message
          })
        )

      {:error, changeset} ->
        nil
    end
  end
end
