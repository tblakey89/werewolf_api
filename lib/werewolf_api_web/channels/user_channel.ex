defmodule WerewolfApiWeb.UserChannel do
  use Phoenix.Channel

  def join("user:" <> user_id, _message, socket) do
    case Guardian.Phoenix.Socket.current_resource(socket).id == String.to_integer(user_id) do
      true -> {:ok, socket}
      false -> {:error, %{reason: "unauthorized"}}
    end
  end

  def broadcast_conversation_creation_to_users(conversation) do
    Task.async(fn ->
      Enum.each(conversation.users, fn user ->
        WerewolfApiWeb.Endpoint.broadcast(
          "user:#{user.id}",
          "new_conversation",
          WerewolfApiWeb.ConversationView.render("conversation_with_messages.json", %{
            conversation: conversation
          })
        )
      end)
    end)
  end

  def broadcast_game_creation_to_users(game) do
    Task.async(fn ->
      {:ok, state} = WerewolfApi.GameServer.get_state(game.id)
      game = WerewolfApi.Repo.preload(game, users_games: :user, game_messages: :user)

      Enum.each(game.users_games, fn user_game ->
        WerewolfApiWeb.Endpoint.broadcast(
          "user:#{user_game.user_id}",
          "new_game",
          WerewolfApiWeb.GameView.render("game_with_state.json", %{
            game: game,
            state: state,
            user: user_game.user
          })
        )
      end)
    end)
  end
end
