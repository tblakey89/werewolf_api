defmodule WerewolfApiWeb.ReportControllerTest do
  use WerewolfApiWeb.ConnCase
  use Phoenix.ChannelTest
  import WerewolfApi.Factory
  import WerewolfApi.Guardian

  setup do
    user = insert(:user)
    reported_user = insert(:user)
    {:ok, user: user, reported_user: reported_user}
  end

  describe "create/2" do
    test "when user exists", %{conn: conn, user: user, reported_user: reported_user} do
      response = create_response(conn, user, reported_user.id, "I do not like them", 200)

      assert response["success"] == "Reported user"
      assert WerewolfApi.Repo.get_by(WerewolfApi.User.Report, user_id: user.id)
    end

    test "when reported user is nil", %{conn: conn, user: user} do
      response = create_response(conn, user, nil, "I do not like them", 422)

      assert response["errors"] == %{"reported_user_id" => ["can't be blank"]}
    end

    test "when body is nil", %{conn: conn, user: user, reported_user: reported_user} do
      response = create_response(conn, user, reported_user.id, nil, 422)

      assert response["errors"] == %{"body" => ["can't be blank"]}
    end

    test "responds 401 when not authenticated", %{
      conn: conn,
      user: user,
      reported_user: reported_user
    } do
      conn
      |> post(
        report_path(conn, :create, reported_user_id: reported_user.id, body: "I don't like them")
      )
      |> response(401)
    end
  end

  defp create_response(conn, user, reported_user_id, body, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> post(report_path(conn, :create, reported_user_id: reported_user_id, body: body))
    |> json_response(expected_response)
  end
end
