defmodule WerewolfApiWeb.FriendControllerTest do
  use WerewolfApiWeb.ConnCase
  use Phoenix.ChannelTest
  import WerewolfApi.Factory
  import WerewolfApi.Guardian

  setup do
    user = insert(:user)
    friend = insert(:user)
    {:ok, user: user, friend: friend}
  end

  describe "update/2" do
    test "when valid, accepting friend request", %{conn: conn, user: user} do
      friendship = insert(:friend, state: "pending", friend: user)
      user_id = user.id
      WerewolfApiWeb.Endpoint.subscribe("user:#{user.id}")

      response = update_response(conn, friendship, %{state: "accepted"}, 200)

      assert_broadcast("friend_request_updated", %{friend: %{id: ^user_id}})
      assert response["success"] == "Friend request accepted"
    end

    test "when state is missing", %{conn: conn, user: user} do
      friendship = insert(:friend, state: "pending", friend: user)

      response = update_response(conn, friendship, %{state: nil}, 422)

      assert response["errors"]["state"] == ["is invalid"]
    end

    test "when not user's friend request to accept", %{conn: conn, user: user} do
      friendship = insert(:friend, state: "pending", user: user)
      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> put(friend_path(conn, :update, friendship.id, friend: %{state: "accepted"}))
        |> json_response(404)

      assert response["error"] == "Friend request not found"
    end

    test "when user not authenticated", %{conn: conn} do
      conn
      |> put(friend_path(conn, :update, 10, friend: %{}))
      |> response(401)
    end
  end

  describe "create/2" do
    test "when user exists and is invitable", %{conn: conn, user: user, friend: friend} do
      friend_id = friend.id
      WerewolfApiWeb.Endpoint.subscribe("user:#{friend.id}")

      response = create_response(conn, user, friend.id, 200)

      assert_broadcast("new_friend_request", %{friend: %{id: ^friend_id}})
      assert response["success"] == "Friend request sent"
    end
  end

  defp update_response(conn, friendship, friendship_attrs, expected_response) do
    {:ok, token, _} = encode_and_sign(friendship.friend, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> put(friend_path(conn, :update, friendship.id, friend: friendship_attrs))
    |> json_response(expected_response)
  end

  defp create_response(conn, user, friend_id, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> post(friend_path(conn, :create, user_id: friend_id))
    |> json_response(expected_response)
  end
end
