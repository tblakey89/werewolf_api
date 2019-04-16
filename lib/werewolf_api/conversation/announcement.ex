defmodule WerewolfApi.Conversation.Announcement do
  def announce(conversation, {:werewolf, game_name}) do
    broadcast_message(conversation, "This is the werewolf group chat for #{game_name}.")
  end

  def announce(_conversation, _), do: nil

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
