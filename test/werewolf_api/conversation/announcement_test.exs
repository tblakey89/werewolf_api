defmodule WerewolfApi.Conversation.AnnouncementTest do
  use ExUnit.Case
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  alias WerewolfApi.Conversation
  alias WerewolfApi.User

  setup do
    user = insert(:user)
    conversation = insert(:conversation, users: [user])
    {:ok, jwt, _} = encode_and_sign(user)
    {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
    {:ok, _, socket} = subscribe_and_join(socket, "user:#{user.id}", %{})
    {:ok, _, socket} = subscribe_and_join(socket, "conversation:#{conversation.id}", %{})

    {:ok, socket: socket, conversation: conversation, user: user}
  end

  describe "announce/2" do
    test "announces to conversation", %{user: user, conversation: conversation} do
      conversation_id = conversation.id
      announcement = "This is conversation"
      Conversation.Announcement.announce(conversation, {:werewolf, announcement})

      assert_broadcast("new_conversation", %{id: ^conversation_id})

      assert WerewolfApi.Repo.get_by(
               WerewolfApi.Conversation.Message,
               conversation_id: conversation.id
             ).body =~ announcement
    end
  end

  describe "announce/2 player vote" do
    test "when user votes for a target, not a tie, 1 vote", %{user: user, conversation: conversation} do
      target = insert(:user)
      Conversation.Announcement.announce(conversation, {:action, user, target.id, {1, target.id}})

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ "#{User.display_name(user)} wants to kill #{User.display_name(target)}"
      assert sent_message =~ "votes is #{User.display_name(target)} with 1 vote. Unless the votes change, #{User.display_name(target)} will be killed at the end of the night phase."
    end

    test "when user votes for a target, a tie, 3 vote", %{user: user, conversation: conversation} do
      target = insert(:user)
      Conversation.Announcement.announce(conversation, {:action, user, target.id, {3, :none}})

      assert_broadcast("new_message", %{body: sent_message})
      assert sent_message =~ "#{User.display_name(user)} wants to kill #{User.display_name(target)}"
      assert sent_message =~ "a tie with 3 votes each. If there is a tie at the end of the night phase, no player will be killed."
    end
  end
end
