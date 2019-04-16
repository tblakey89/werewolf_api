defmodule WerewolfApi.Conversation.AnnouncementTest do
  use ExUnit.Case
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  alias WerewolfApi.Conversation

  setup do
    user = insert(:user)
    conversation = insert(:conversation, users: [user])
    {:ok, jwt, _} = encode_and_sign(user)
    {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
    {:ok, _, socket} = subscribe_and_join(socket, "conversation:#{conversation.id}", %{})

    {:ok, socket: socket, conversation: conversation, user: user}
  end

  describe "announce/2" do
    test "announces to conversation", %{user: user, conversation: conversation} do
      announcement = "This is conversation"
      Conversation.Announcement.announce(conversation, {:werewolf, announcement})

      assert_broadcast("new_message", %{})
    end
  end
end
