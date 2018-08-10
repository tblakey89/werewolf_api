defmodule WerewolfApiWeb.UserChannelTest do
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  alias WerewolfApi.Repo

  setup do
    user = insert(:user)
    {:ok, jwt, _} = encode_and_sign(user)
    {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
    {:ok, _, socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

    {:ok, socket: socket, user: user}
  end

  describe "join channel" do
    test "unable to join another user's channel", %{socket: socket} do
      other_user = insert(:user)

      assert {:error, %{reason: "unauthorized"}} ==
               subscribe_and_join(socket, "user:#{other_user.id}", %{})
    end
  end

  describe "broadcast_conversation_creation_to_users" do
    test "when function called game_update is broadcast", %{user: user} do
      conversation =
        insert(:conversation, users: [user])
        |> Repo.preload(:messages)

      conversation_id = conversation.id

      WerewolfApiWeb.UserChannel.broadcast_conversation_creation_to_users(conversation)
      assert_broadcast("new_conversation", %{id: ^conversation_id})
    end
  end
end
