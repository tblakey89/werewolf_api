defmodule WerewolfApi.Conversation.Announcement do
  alias WerewolfApi.Notification
  alias WerewolfApi.User
  alias WerewolfApi.Game

  def announce(conversation, {:werewolf, game_name}) do
    broadcast_conversation(
      conversation,
      "werewolf_chat",
      "This is the werewolf group chat for #{game_name}. Please place your votes on the game chat for who you want to kill."
    )
  end

  def announce(conversation, {:mason, game_name}) do
    broadcast_conversation(
      conversation,
      "mason_chat",
      "This is the mason group chat for #{game_name}. Please work together to try and find the werewolves."
    )
  end

  def announce(conversation, game, {:action, user, target, vote_result}) do
    username = User.display_name(Game.user_from_game(game, target))

    broadcast_message(
      conversation,
      "werewolf_vote",
      "#{User.display_name(user)} wants to kill #{username}. #{
        show_vote_result(game, vote_result)
      }"
    )
  end

  def announce(_conversation, _), do: nil

  defp show_vote_result(game, {votes, :none}) when length(votes) == 0, do: nil

  defp show_vote_result(game, {votes, :none}) do
    "There is currently a tie, if there is still a tie at the end of the night phase, no player will be killed.\n" <>
      vote_list(game, votes)
  end

  defp show_vote_result(game, {votes, target}) do
    username = User.display_name(Game.user_from_game(game, target))

    "The player with the most votes is #{username}. Unless the votes change, #{username} will be killed at the end of the night phase.\n" <>
      vote_list(game, votes)
  end

  defp vote_list(game, votes) do
    Enum.map(votes, fn {target, vote_count} ->
      username = User.display_name(Game.user_from_game(game, target))
      "#{username}: #{vote_count} #{Inflex.inflect("vote", vote_count)}"
    end)
    |> Enum.join("\n")
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
