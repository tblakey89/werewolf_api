defmodule WerewolfApi.Conversation.Announcement do
  alias WerewolfApi.Notification
  alias WerewolfApi.User

  def announce(conversation, {:werewolf, game_name}) do
    broadcast_conversation(
      conversation,
      "werewolf_chat",
      "This is the werewolf group chat for #{game_name}. Please place your votes on the game chat for who you want to kill."
    )
  end

  def announce(conversation, {:action, user, target, vote_result}) do
    target_user = WerewolfApi.Repo.get(WerewolfApi.User, target)

    broadcast_message(
      conversation,
      "werewolf_vote",
      "#{User.display_name(user)} wants to kill #{User.display_name(target_user)}. #{
        show_vote_result(vote_result)
      }"
    )
  end

  def announce(_conversation, _), do: nil

  defp show_vote_result({0, :none}), do: nil

  defp show_vote_result({vote_count, :none}) do
    "There is currently a tie with #{Integer.to_string(vote_count)} #{
      Inflex.inflect("vote", vote_count)
    } each. If there is a tie at the end of the night phase, no player will be killed."
  end

  defp show_vote_result({vote_count, target}) do
    target_user = WerewolfApi.Repo.get(WerewolfApi.User, target)

    "The player with the most votes is #{User.display_name(target_user)} with #{
      Integer.to_string(vote_count)
    } #{Inflex.inflect("vote", vote_count)}. Unless the votes change, #{
      User.display_name(target_user)
    } will be killed at the end of the night phase."
  end

  defp broadcast_conversation(conversation, type, message) do
    changeset =
      Ecto.build_assoc(conversation, :messages, user_id: 0)
      |> WerewolfApi.Conversation.Message.changeset(%{body: message})
      |> Ecto.Changeset.change(bot: true)
      |> Ecto.Changeset.change(type: type)

    case WerewolfApi.Repo.insert(changeset) do
      {:ok, message} ->
        WerewolfApi.Repo.preload(conversation, [:users, :users_conversations, messages: :user])
        |> WerewolfApiWeb.UserChannel.broadcast_conversation_creation_to_users()

        Notification.new_conversation_message(message)

      {:error, changeset} ->
        nil
    end
  end

  defp broadcast_message(conversation, type, message) do
    changeset =
      Ecto.build_assoc(conversation, :messages, user_id: 0)
      |> WerewolfApi.Conversation.Message.changeset(%{bot: true, body: message, type: type})

    case WerewolfApi.Repo.insert(changeset) do
      {:ok, message} ->
        WerewolfApiWeb.Endpoint.broadcast(
          "conversation:#{conversation.id}",
          "new_message",
          WerewolfApiWeb.MessageView.render("message.json", %{
            message: message
          })
        )

        Notification.new_conversation_message(message)

      {:error, changeset} ->
        nil
    end
  end
end
