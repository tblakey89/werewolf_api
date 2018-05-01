defmodule WerewolfApiWeb.SessionControllerTest do
  use WerewolfApiWeb.ConnCase
  import WerewolfApi.Factory

  describe "create/2" do
    test "when valid login" do
      user = insert(:user)
      conn = build_conn()

      response =
        conn
        |> post(
          session_path(conn, :create, session: %{email: user.email, password: user.password})
        )
        |> json_response(200)

      assert response["token"]
    end

    test "when invalid" do
      user = insert(:user)
      conn = build_conn()

      response =
        conn
        |> post(
          session_path(conn, :create, session: %{email: "fake@test.com", password: user.password})
        )
        |> json_response(401)

      refute response["token"]
    end
  end
end
