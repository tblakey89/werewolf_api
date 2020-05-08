defmodule WerewolfApiWeb.GameNotStartedWorker do
  alias WerewolfApi.Game
  alias WerewolfApi.Conversation
  alias WerewolfApi.User
  alias WerewolfApi.Repo
  alias WerewolfApi.Notification

  def perform(game_id) do
    game =
      Repo.get(Game, game_id)
      |> Repo.preload(:users_games)

    if game != nil do
      user =
        Repo.get(User, Game.find_host_id(game))
        |> Repo.preload(:games)

      if length(user.games) == 1 && length(game.users_games) < 8 do
        {:ok, conversation} = Conversation.find_or_create(%{"user_ids" => [1, user.id]})

        broadcast_conversation(
          conversation,
          "Hello #{User.display_name(user)}, my name is Thomas, the creator of WolfChat. Thanks for downloading my application, I hope you like it. I have noticed you have created a game, but not got enough people to join. Do you need any help with how the app works, and how to invite other players? What are your thoughts on the app?"
        )
      end
    end
  end

  defp broadcast_conversation(conversation, message) do
    changeset =
      Ecto.build_assoc(conversation, :messages, user_id: 1)
      |> WerewolfApi.Conversation.Message.changeset(%{body: message})

    case WerewolfApi.Repo.insert(changeset) do
      {:ok, message} ->
        WerewolfApi.Repo.preload(conversation, [:users, :users_conversations, messages: :user])
        |> WerewolfApiWeb.UserChannel.broadcast_conversation_creation_to_users()

        Notification.new_conversation_message(message)

      {:error, changeset} ->
        nil
    end
  end
end
