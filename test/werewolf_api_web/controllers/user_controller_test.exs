defmodule WerewolfApiWeb.UserControllerTest do
  use WerewolfApiWeb.ConnCase
  use Phoenix.ChannelTest
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  alias WerewolfApi.User
  alias WerewolfApi.Repo

  @upload_folder "test/uploads"

  setup_all do
    on_exit(fn ->
      File.rm_rf!(@upload_folder)
    end)
  end

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

  describe "update/2" do
    test "updates user and changes password", %{conn: conn} do
      user = insert(:user)

      response = update_response(conn, user.id, user, %{password: "newpassword"}, 200)

      assert response["user"]["email"] == user.email
      assert Repo.get(User, user.id).password_hash != user.password_hash
    end

    test "updates user without password", %{conn: conn} do
      user = insert(:user)

      response = update_response(conn, user.id, user, %{password: ""}, 200)

      assert response["user"]["email"] == user.email
      assert Repo.get(User, user.id).password_hash == user.password_hash
    end

    test "can't update when short password", %{conn: conn} do
      user = insert(:user)

      response = update_response(conn, user.id, user, %{password: "short"}, 422)

      assert response["errors"]["password"] == ["should be at least 8 character(s)"]
    end

    test "can't update other user", %{conn: conn} do
      user = insert(:user)
      other_user = insert(:user)

      response = update_response(conn, other_user.id, user, %{password: "newpassword"}, 403)

      assert response["error"] == "Not allowed."
    end

    test "responds 401 when not authenticated", %{conn: conn} do
      conn
      |> put(user_path(conn, :update, 10, user: %{password: "new_password"}))
      |> response(401)
    end
  end

  describe "avatar/2" do
    test "updates user's avatar", %{conn: conn} do
      user = insert(:user)
      file = %Plug.Upload{path: "test/support/images/test_image.png", filename: "test_image.png"}

      WerewolfApiWeb.Endpoint.subscribe("user:#{user.id}")

      response = avatar_response(conn, user.id, user, %{avatar: file}, 200)

      assert response["user"]["avatar"] ==
               "/#{@upload_folder}/#{user.id}_#{user.username}_thumb.png"

      assert_broadcast("new_avatar", %{})
    end

    test "updates avatar without avatar", %{conn: conn} do
      user = insert(:user)

      response = avatar_response(conn, user.id, user, %{avatar: ""}, 422)

      assert response["errors"]["avatar"] == ["can't be blank"]
    end

    test "can't update when trying to update other user", %{conn: conn} do
      user = insert(:user)
      other_user = insert(:user)
      file = %Plug.Upload{path: "test/support/images/test_image.png", filename: "test_image.png"}

      response = avatar_response(conn, other_user.id, user, %{avatar: file}, 403)

      assert response["error"] == "Not allowed."
    end

    test "responds 401 when not authenticated", %{conn: conn} do
      file = %Plug.Upload{path: "test/support/images/test_image.png", filename: "test_image.png"}

      conn
      |> put(user_avatar_path(conn, :avatar, 10), %{user: %{avatar: file}})
      |> response(401)
    end
  end

  defp update_response(conn, id, user, user_attrs, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> put(user_path(conn, :update, id, user: user_attrs))
    |> json_response(expected_response)
  end

  defp avatar_response(conn, id, user, user_attrs, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> put(user_avatar_path(conn, :avatar, id), %{user: user_attrs})
    |> json_response(expected_response)
  end
end
