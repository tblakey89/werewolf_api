defmodule WerewolfApiWeb.MessageControllerTest do
  use WerewolfApiWeb.ConnCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian

  describe "index/2" do
    test "responds with user's conversations", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, users: [user])
      message = insert(:message, conversation: conversation, user: user)

      response = index_response(conn, user, conversation.id, 200)

      assert Enum.at(response["messages"], 0)["body"] == message.body
    end

    test "responds 401 when not authenticated", %{conn: conn} do
      conversation = insert(:conversation)

      conn
      |> get(conversation_message_path(conn, :index, conversation.id))
      |> response(401)
    end
  end

  defp index_response(conn, user, conversation_id, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> get(conversation_message_path(conn, :index, conversation_id))
    |> json_response(expected_response)
  end
end
