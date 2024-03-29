defmodule WerewolfApiWeb.UserControllerTest do
  use WerewolfApiWeb.ConnCase
  use Phoenix.ChannelTest
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  import Ecto.Query
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

      new_user = Repo.one(from(u in User, order_by: [desc: u.id], limit: 1))

      assert response["token"]
      assert new_user.notify_on_game_creation == true
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

    test "responds with no games if rejected game", %{conn: conn} do
      user = insert(:user)
      insert(:users_game, user: user, state: "rejected")

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(user_path(conn, :me))
        |> json_response(200)

      assert length(response["user"]["games"]) == 0
    end

    test "responds 401 when not authenticated", %{conn: conn} do
      conn
      |> get(user_path(conn, :me))
      |> response(401)
    end
  end

  describe "me_v2/2" do
    test "responds with current logged in user", %{conn: conn} do
      user = insert(:user)

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(user_path(conn, :me_v2))
        |> json_response(200)

      assert response["user"]["email"] == user.email
    end

    test "responds with 20 games only", %{conn: conn} do
      user = insert(:user)
      Enum.each(0..25, fn i -> insert(:users_game, user: user) end)

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(user_path(conn, :me_v2))
        |> json_response(200)

      assert response["user"]["email"] == user.email
      assert length(response["user"]["games"]) == 20
    end

    test "responds with no games if rejected game", %{conn: conn} do
      user = insert(:user)
      insert(:users_game, user: user, state: "rejected")

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(user_path(conn, :me_v2))
        |> json_response(200)

      assert length(response["user"]["games"]) == 0
    end

    test "responds 401 when not authenticated", %{conn: conn} do
      conn
      |> get(user_path(conn, :me_v2))
      |> response(401)
    end
  end

  describe "refresh_me/2" do
    test "responds with current logged in user and message", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation)
      game = insert(:game)
      insert(:users_game, user: user, game: game)
      insert(:users_conversation, user: user, conversation: conversation)
      insert(:message, conversation: conversation, inserted_at: ~U[2020-10-14 20:49:40Z])

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(user_path(conn, :refresh_me, %{"timestamp" => 1_602_708_575_000}))
        |> json_response(200)

      assert response["user"]["email"] == user.email
      assert length(Enum.at(response["user"]["conversations"], 0)["messages"]) == 1
      assert length(response["user"]["games"]) == 1
    end

    test "responds without game if not included in games_ids but game_ids provided", %{conn: conn} do
      user = insert(:user)
      game = insert(:game)
      insert(:users_game, user: user, game: game)

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(
          user_path(conn, :refresh_me, %{"timestamp" => 1_602_708_575_000, "game_ids" => "[]"})
        )
        |> json_response(200)

      assert response["user"]["email"] == user.email
      assert length(response["user"]["games"]) == 0
    end

    test "responds with game if not included in games_ids", %{conn: conn} do
      user = insert(:user)
      game = insert(:game)
      insert(:users_game, user: user, game: game)

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(
          user_path(conn, :refresh_me, %{
            "timestamp" => 1_602_708_575_000,
            "game_ids" => "[#{game.id}]"
          })
        )
        |> json_response(200)

      assert response["user"]["email"] == user.email
      assert length(response["user"]["games"]) == 1
    end

    test "responds with no messages if older than timestamp", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation)
      insert(:users_conversation, user: user, conversation: conversation)
      insert(:message, conversation: conversation, inserted_at: ~U[2020-10-14 20:49:30Z])

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(user_path(conn, :refresh_me, %{"timestamp" => 1_602_708_575_000}))
        |> json_response(200)

      assert length(Enum.at(response["user"]["conversations"], 0)["messages"]) == 0
    end

    test "responds 401 when not authenticated", %{conn: conn} do
      conn
      |> get(user_path(conn, :refresh_me, %{"timestamp" => 1_602_708_575}))
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

    test "updates notify_on_game_creation", %{conn: conn} do
      user = insert(:user, notify_on_game_creation: true)

      response = update_response(conn, user.id, user, %{notify_on_game_creation: false}, 200)

      assert response["user"]["notify_on_game_creation"] == false
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
               "/#{@upload_folder}/#{user.id}__thumb.png"

      assert_broadcast("new_avatar", %{})
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
