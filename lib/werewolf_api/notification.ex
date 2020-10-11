defmodule WerewolfApi.Notification do
  alias WerewolfApi.Conversation
  alias WerewolfApi.Game
  alias WerewolfApi.User
  alias WerewolfApi.Repo
  alias WerewolfApi.User.Block
  import Ecto.Query

  def new_conversation_message(message) do
    Task.start_link(fn ->
      message = WerewolfApi.Repo.preload(message, [:user, conversation: [users: :blocks]])

      WerewolfApi.User.valid_fcm_tokens(
        message.conversation.users,
        message.user_id,
        message.user_id
      )
      |> Pigeon.FCM.Notification.new(
        %{
          title: WerewolfApi.Conversation.Message.username(message),
          body: limit_message_length(message),
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          sound: "default"
        },
        %{
          type: "conversation",
          id: message.conversation_id,
          message: WerewolfApiWeb.MessageView.render("message.json", %{message: message})
        }
      )
      |> Pigeon.FCM.push()
    end)
  end

  def new_game_message(message) do
    Task.start_link(fn ->
      message = WerewolfApi.Repo.preload(message, [:user, :game])

      users_games =
        WerewolfApi.Repo.all(
          WerewolfApi.UsersGame.pending_and_accepted_only_with_user(message.game.id)
        )

      participating_users = Enum.map(users_games, fn users_game -> users_game.user end)

      WerewolfApi.User.valid_fcm_tokens(participating_users, message.user_id, message.user_id)
      |> Pigeon.FCM.Notification.new(
        %{
          title: "#{Game.Message.username(message)} @ #{message.game.name}",
          body: limit_message_length(message),
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          sound: "default"
        },
        %{
          type: "game",
          id: message.game_id,
          message:
            WerewolfApiWeb.GameMessageView.render("game_message.json", %{game_message: message})
        }
      )
      |> Pigeon.FCM.push()
    end)
  end

  def received_friend_request(%{fcm_token: nil} = friendship), do: nil

  def received_friend_request(friendship) do
    Task.start_link(fn ->
      if friendship.friend.fcm_token &&
           Block.blocked_user?(friendship.friend.blocks, friendship.user_id) do
        friendship.friend.fcm_token
        |> Pigeon.FCM.Notification.new(
          %{
            title: "New Friend Request",
            body: "#{User.display_name(friendship.user)} has sent you a friend request.",
            sound: "default"
          },
          %{
            type: "friend"
          }
        )
        |> Pigeon.FCM.push()
      end
    end)
  end

  def accepted_friend_request(%{fcm_token: nil} = friendship), do: nil
  def accepted_friend_request(%{state: "pending"} = friendship), do: nil

  def accepted_friend_request(friendship) do
    Task.start_link(fn ->
      if friendship.user.fcm_token do
        friendship.user.fcm_token
        |> Pigeon.FCM.Notification.new(
          %{
            title: "Accepted Friend Request",
            body: "#{User.display_name(friendship.friend)} has accepted your friend request.",
            sound: "default"
          },
          %{
            type: "friend"
          }
        )
        |> Pigeon.FCM.push()
      end
    end)
  end

  def received_game_invite(game, nil), do: nil

  def received_game_invite(game, user_ids) do
    Task.start_link(fn ->
      host_users_game =
        Enum.find(game.users_games, fn users_game ->
          users_game.state == "host"
        end)

      WerewolfApi.User.find_by_user_ids(user_ids)
      |> WerewolfApi.Repo.preload(:blocks)
      |> WerewolfApi.User.valid_fcm_tokens(host_users_game.user_id, nil)
      |> Pigeon.FCM.Notification.new(
        %{
          title: "New Game Invite",
          body:
            "#{User.display_name(host_users_game.user)} has invited you to join their game of Werewolf.",
          sound: "default"
        },
        %{
          type: "new_game"
        }
      )
      |> Pigeon.FCM.push()
    end)
  end

  def new_game_creation_message(%{join_code: nil} = game, user) do
    Task.start_link(fn ->
      Repo.all(
        from(u in User,
          select: u.fcm_token,
          where: u.notify_on_game_creation == true and u.id != ^user.id
        )
      )
      |> Pigeon.FCM.Notification.new(
        %{
          title: "New Game Created",
          body:
            "A new game of Werewolf has been created, ready for a game? WIll you be a villager 👩‍🌾, or a werewolf 🐺?",
          sound: "default"
        },
        %{
          type: "new_game_created"
        }
      )
      |> Pigeon.FCM.push()
    end)
  end

  def new_game_creation_message(_game, _user), do: nil

  defp limit_message_length(message) do
    if String.length(message.body) > 200 do
      String.slice(message.body, 0, 200) <> "..."
    else
      message.body
    end
  end
end
