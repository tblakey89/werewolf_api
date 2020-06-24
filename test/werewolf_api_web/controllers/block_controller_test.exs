defmodule WerewolfApiWeb.BlockControllerTest do
  use WerewolfApiWeb.ConnCase
  use Phoenix.ChannelTest
  import WerewolfApi.Factory
  import WerewolfApi.Guardian

  setup do
    user = insert(:user)
    blocked_user = insert(:user)
    {:ok, user: user, blocked_user: blocked_user}
  end

  describe "create/2" do
    test "when user exists", %{conn: conn, user: user, blocked_user: blocked_user} do
      response = create_response(conn, user, blocked_user.id, 200)

      assert response["success"] == "Blocked user"
    end

    test "when blocked user is nil", %{conn: conn, user: user} do
      response = create_response(conn, user, nil, 422)

      assert response["errors"] == %{"blocked_user_id" => ["can't be blank"]}
    end
  end

  defp create_response(conn, user, blocked_user_id, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> post(block_path(conn, :create, user_id: blocked_user_id))
    |> json_response(expected_response)
  end
end
