defmodule WerewolfApiWeb.UserChannel do
  use Phoenix.Channel

  def join("user:" <> user_id, _message, socket) do
    case Guardian.Phoenix.Socket.current_resource(socket).id == String.to_integer(user_id) do
      true -> {:ok, socket}
      false -> {:error, %{reason: "unauthorized"}}
    end
  end

  def broadcast_conversation_creation_to_users(conversation) do
    Task.start_link(fn ->
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
    broadcast_game_change_to_each_user("new_game", game)
  end

  def broadcast_game_update(game) do
    broadcast_game_change_to_each_user("game_update", game)
  end

  def broadcast_state_update(game_id, state) do
    Task.start_link(fn ->
      users_games = WerewolfApi.UsersGame.by_game_id(game_id)

      Enum.each(users_games, fn users_game ->
        WerewolfApiWeb.Endpoint.broadcast(
          "user:#{users_game.user_id}",
          "game_state_update",
          WerewolfApiWeb.GameView.render("state.json", %{
            data: %{
              state: state,
              game_id: game_id,
              user: users_game.user
            }
          })
        )
      end)
    end)
  end

  defp broadcast_game_change_to_each_user(event, game) do
    Task.start_link(fn ->
      game = WerewolfApi.Repo.preload(game, users_games: :user, game_messages: :user)
      {:ok, state} = WerewolfApi.GameServer.get_state(game.id)

      Enum.each(game.users_games, fn users_game ->
        WerewolfApiWeb.Endpoint.broadcast(
          "user:#{users_game.user_id}",
          event,
          WerewolfApiWeb.GameView.render("game_with_state.json", %{
            data: %{
              game: game,
              state: state,
              user: users_game.user
            }
          })
        )
      end)
    end)
  end
end
