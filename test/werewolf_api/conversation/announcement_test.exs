defmodule WerewolfApi.Conversation.AnnouncementTest do
  use ExUnit.Case
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  alias WerewolfApi.Conversation
  alias WerewolfApi.User

  setup do
    user = insert(:user)
    target = insert(:user)
    conversation = insert(:conversation, users: [user])
    game = insert(:game, conversation_id: conversation.id)

    insert(:users_game, user: user, game: game)
    insert(:users_game, user: target, game: game)

    game =
      game
      |> WerewolfApi.Repo.preload(:users)

    {:ok, jwt, _} = encode_and_sign(user)
    {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
    {:ok, _, socket} = subscribe_and_join(socket, "user:#{user.id}", %{})
    {:ok, _, socket} = subscribe_and_join(socket, "conversation:#{conversation.id}", %{})

    {:ok, socket: socket, conversation: conversation, user: user, target: target, game: game}
  end

  describe "announce/2" do
    test "announces to conversation", %{user: user, conversation: conversation} do
      conversation_id = conversation.id
      announcement = "This is conversation"
      Conversation.Announcement.announce(conversation, {:werewolf, announcement})

      assert_broadcast("new_conversation", %{id: ^conversation_id})

      message =
        WerewolfApi.Repo.get_by(
          WerewolfApi.Conversation.Message,
          conversation_id: conversation.id
        )

      assert message.body =~ announcement
      assert message.type == "werewolf_chat"
    end
  end

  test "announces to mason conversation", %{user: user, conversation: conversation} do
    conversation_id = conversation.id
    announcement = "This is conversation"
    Conversation.Announcement.announce(conversation, {:mason, announcement})

    assert_broadcast("new_conversation", %{id: ^conversation_id})

    message =
      WerewolfApi.Repo.get_by(
        WerewolfApi.Conversation.Message,
        conversation_id: conversation.id
      )

    assert message.body =~ announcement
    assert message.type == "mason_chat"
  end

  describe "announce/2 player vote" do
    test "when user votes for a target, not a tie, 1 vote", %{
      user: user,
      conversation: conversation,
      game: game,
      target: target
    } do
      Conversation.Announcement.announce(
        conversation,
        game,
        {:action, user, target.id, {[{target.id, 1}], target.id}}
      )

      assert_broadcast("new_message", %{body: sent_message})

      assert sent_message =~
               "#{User.display_name(user)} wants to kill #{User.display_name(target)}"

      assert sent_message =~
               "votes is #{User.display_name(target)}. Unless the votes change, #{
                 User.display_name(target)
               } will be killed at the end of the night phase."

      assert WerewolfApi.Repo.get_by(
               WerewolfApi.Conversation.Message,
               conversation_id: conversation.id
             ).type == "werewolf_vote"
    end

    test "when user votes for a target, a tie, 3 vote", %{
      user: user,
      conversation: conversation,
      game: game,
      target: target
    } do
      Conversation.Announcement.announce(
        conversation,
        game,
        {:action, user, target.id, {[{user.id, 3}, {target.id, 3}], :none}}
      )

      assert_broadcast("new_message", %{body: sent_message})

      assert sent_message =~
               "#{User.display_name(user)} wants to kill #{User.display_name(target)}. There is currently a tie, if there is still a tie at the end of the night phase, no player will be killed.\n#{
                 User.display_name(user)
               }: 3 votes\n#{User.display_name(target)}: 3 votes"

      assert WerewolfApi.Repo.get_by(
               WerewolfApi.Conversation.Message,
               conversation_id: conversation.id
             ).type == "werewolf_vote"
    end
  end
end
