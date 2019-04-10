defmodule WerewolfApiWeb.ConversationChannelTest do
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  alias WerewolfApi.Repo
  alias WerewolfApi.Message

  setup do
    user = insert(:user)
    conversation = insert(:conversation)
    users_conversation = insert(:users_conversation, user: user, conversation: conversation)
    {:ok, jwt, _} = encode_and_sign(user)
    {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
    {:ok, _, socket} = subscribe_and_join(socket, "conversation:#{conversation.id}", %{})

    {:ok, socket: socket, users_conversation: users_conversation}
  end

  describe "join channel" do
    test "unable to join channel when user not in conversation", %{socket: socket} do
      other_conversation = insert(:conversation)

      assert {:error, %{reason: "unauthorized"}} ==
               subscribe_and_join(socket, "conversation:#{other_conversation.id}", %{})
    end
  end

  describe "new_message event" do
    test "new_message broadcasts new message", %{socket: socket} do
      sent_message = "Hello there!"
      ref = push(socket, "new_message", %{"body" => sent_message})
      assert_broadcast("new_message", %{body: sent_message})
      assert_reply(ref, :ok)
      assert Repo.get_by(Message, body: sent_message)
    end

    test "new_message fails to broadcast new message when invalid", %{socket: socket} do
      ref = push(socket, "new_message", %{})
      assert_reply(ref, :error)
    end
  end

  describe "read_conversation event" do
    test "users_conversation is updated", %{
      socket: socket,
      users_conversation: users_conversation
    } do
      ref = push(socket, "read_conversation", %{})
      original_last_read_at = users_conversation.last_read_at
      assert_reply(ref, :ok)

      new_last_read_at =
        Repo.get(WerewolfApi.UsersConversation, users_conversation.id).last_read_at

      assert(original_last_read_at < new_last_read_at)
    end
  end
end
