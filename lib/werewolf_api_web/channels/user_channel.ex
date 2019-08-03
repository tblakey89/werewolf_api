defmodule WerewolfApiWeb.UserChannel do
  use Phoenix.Channel
  alias WerewolfApi.Notification
  require IEx

  def join("user:" <> user_id, _message, socket) do
    case Guardian.Phoenix.Socket.current_resource(socket).id == String.to_integer(user_id) do
      true -> {:ok, socket}
      false -> {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("update_fcm_token", params, socket) do
    Guardian.Phoenix.Socket.current_resource(socket)
    |> WerewolfApi.User.update_fcm_token_changeset(params["fcm_token"])
    |> WerewolfApi.Repo.update

    {:reply, :ok, socket}
  end

  def broadcast_avatar_update(user) do
    # only do for current user
    WerewolfApiWeb.Endpoint.broadcast(
      "user:#{user.id}",
      "new_avatar",
      WerewolfApiWeb.UserView.render("user.json", %{user: user})
    )
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

  def broadcast_invitation_rejected_to_users(game_id) do
    Task.start_link(fn ->
      users_games = WerewolfApi.Repo.all(WerewolfApi.UsersGame.rejected(game_id))

      Enum.each(users_games, fn users_game ->
        broadcast_invitation_rejected(users_game)
      end)
    end)
  end

  def broadcast_invitation_rejected(users_game) do
    WerewolfApiWeb.Endpoint.broadcast(
      "user:#{users_game.user_id}",
      "invitation_rejected",
      WerewolfApiWeb.UsersGameView.render("simple_users_game.json", %{users_game: users_game})
    )
  end

  def broadcast_friend_request(friendship) do
    Task.start_link(fn ->
      friendship = WerewolfApi.Repo.preload(friendship, [:friend, :user])

      Enum.each([friendship.user, friendship.friend], fn user ->
        WerewolfApiWeb.Endpoint.broadcast(
          "user:#{user.id}",
          "new_friend_request",
          WerewolfApiWeb.FriendView.render("friendship.json", %{friend: friendship})
        )
      end)

      Notification.received_friend_request(friendship)
    end)
  end

  def broadcast_friend_request_updated(friendship) do
    Task.start_link(fn ->
      friendship = WerewolfApi.Repo.preload(friendship, [:friend, :user])

      Enum.each([friendship.user, friendship.friend], fn user ->
        WerewolfApiWeb.Endpoint.broadcast(
          "user:#{user.id}",
          "friend_request_updated",
          WerewolfApiWeb.FriendView.render("friendship.json", %{friend: friendship})
        )
      end)

      Notification.accepted_friend_request(friendship)
    end)
  end

  defp broadcast_game_change_to_each_user(event, game) do
    Task.start_link(fn ->
      game =
        WerewolfApi.Repo.preload(
          game,
          users_games: WerewolfApi.UsersGame.pending_and_accepted_only_with_user(game.id),
          messages: :user
        )

      {:ok, state} = WerewolfApi.Game.Server.get_state(game.id)

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
