defmodule WerewolfApiWeb.UserControllerTest do
  use WerewolfApiWeb.ConnCase

  describe "create/2" do
    test "when valid" do
      user = %{email: "test@test.com", username: "test", password: "testtest"}
      conn = build_conn()

      response =
        conn
        |> post(user_path(conn, :create, user: user))
        |> json_response(201)

      assert response["user"]["email"] == "test@test.com"
      assert response["user"]["username"] == "test"
    end

    test "when invalid" do
      user = %{email: "", username: "test", password: "testtest"}
      conn = build_conn()

      response =
        conn
        |> post(user_path(conn, :create, user: user))
        |> json_response(422)

      assert response["errors"]["email"] == ["can't be blank"]
    end
  end
end
