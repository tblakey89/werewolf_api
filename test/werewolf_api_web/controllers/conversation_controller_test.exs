defmodule WerewolfApiWeb.ConversationControllerTest do
  use WerewolfApiWeb.ConnCase
  use Phoenix.ChannelTest
  import WerewolfApi.Factory
  import WerewolfApi.Guardian

  describe "index/2" do
    test "responds with user's conversations", %{conn: conn} do
      user = insert(:user)
      second_user = insert(:user)
      conversation = insert(:conversation, users: [user, second_user])

      response = index_response(conn, user, 200)

      assert Enum.at(response["conversations"], 0)["name"] == conversation.name
    end

    test "does not include conversations with last_message_at null", %{conn: conn} do
      user = insert(:user)
      insert(:conversation, users: [user], last_message_at: nil)

      response = index_response(conn, user, 200)

      assert length(response["conversations"]) == 0
    end

    test "responds 401 when not authenticated", %{conn: conn} do
      conn
      |> get(conversation_path(conn, :index))
      |> response(401)
    end
  end

  describe "show/2" do
    test "responds with conversation", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, users: [user])

      response = show_response(conn, user, conversation, 200)

      assert response["conversation"]["name"] == conversation.name
    end

    test "responds with 404, when not found", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation)

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      assert_error_sent(404, fn ->
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(conversation_path(conn, :show, conversation.id))
      end)
    end
  end

  describe "create/2" do
    test "when valid", %{conn: conn} do
      user = insert(:user)
      second_user = insert(:user)
      WerewolfApiWeb.Endpoint.subscribe("user:#{user.id}")

      conversation = %{
        name: "test_name",
        user_ids: [second_user.id]
      }

      response = create_response(conn, user, conversation, 201)

      assert_broadcast("new_conversation", %{name: "test_name"})
      assert Enum.at(response["conversation"]["users"], 0)["id"] == user.id
      assert Enum.at(response["conversation"]["users"], 1)["id"] == second_user.id
    end

    test "when missing second user", %{conn: conn} do
      user = insert(:user)
      conversation = %{user_ids: [], name: "test"}

      response = create_response(conn, user, conversation, 422)

      assert response["errors"]["users"] == ["need at least one other participant"]
    end

    test "when user not authenticated", %{conn: conn} do
      conn
      |> post(conversation_path(conn, :create, conversation: %{}))
      |> response(401)
    end
  end

  defp index_response(conn, user, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> get(conversation_path(conn, :index))
    |> json_response(expected_response)
  end

  defp show_response(conn, user, conversation, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> get(conversation_path(conn, :show, conversation.id))
    |> json_response(expected_response)
  end

  defp create_response(conn, user, conversation, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> post(conversation_path(conn, :create, conversation: conversation))
    |> json_response(expected_response)
  end
end
