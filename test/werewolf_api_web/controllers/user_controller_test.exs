defmodule WerewolfApiWeb.UserControllerTest do
  use WerewolfApiWeb.ConnCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian

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

  describe "show/2" do
    test "responds with user", %{conn: conn} do
      user = insert(:user)

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(user_path(conn, :show, user.id))
        |> json_response(200)

      assert response["user"]["email"] == user.email
    end

    test "responds with 404, when not found", %{conn: conn} do
      user = insert(:user)

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      assert_error_sent(404, fn ->
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(user_path(conn, :show, 0))
      end)
    end
  end

  describe "me/2" do
    test "responds with current logged in user", %{conn: conn} do
      user = insert(:user)

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(user_path(conn, :me))
        |> json_response(200)

      assert response["user"]["email"] == user.email
    end

    test "responds 401 when not authenticated", %{conn: conn} do
      conn
      |> get(user_path(conn, :me))
      |> response(401)
    end
  end

  describe "index/2" do
    test "responds with all users", %{conn: conn} do
      user = insert(:user)
      insert(:user)

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(user_path(conn, :index))
        |> json_response(200)

      assert Enum.at(response["users"], 0)["email"] == user.email
      assert length(response["users"]) == 2
    end

    test "responds 401 when not authenticated", %{conn: conn} do
      conn
      |> get(user_path(conn, :index))
      |> response(401)
    end
  end
end
