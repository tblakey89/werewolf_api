defmodule WerewolfApiWeb.InvitationControllerTest do
  use WerewolfApiWeb.ConnCase
  use Phoenix.ChannelTest
  import WerewolfApi.Factory
  import WerewolfApi.Guardian

  setup do
    user = insert(:user)
    game = insert(:game)
    WerewolfApi.GameServer.start_game(user, game.id, :day)

    {:ok, game: game, user: user}
  end

  describe "update/2" do
    test "when valid, accepting invite", %{conn: conn, game: game} do
      users_game = insert(:users_game, state: "pending", game: game)
      game_id = game.id
      WerewolfApiWeb.Endpoint.subscribe("user:#{users_game.user_id}")

      response = update_response(conn, users_game, %{state: "accepted"}, 200)

      assert_broadcast("game_update", %{id: ^game_id})
      assert response["success"] == "Joined the game"
    end

    test "when valid, rejecting invite", %{conn: conn, game: game} do
      users_game = insert(:users_game, state: "pending", game: game)

      response = update_response(conn, users_game, %{state: "rejected"}, 200)

      assert response["success"] == "Rejected the invitation"
    end

    test "when state is missing", %{conn: conn, game: game} do
      users_game = insert(:users_game, state: "pending", game: game)

      response = update_response(conn, users_game, %{state: nil}, 422)

      assert response["errors"]["state"] == ["is invalid"]
    end

    test "when user not invited", %{conn: conn, game: game} do
      user = insert(:user)
      users_game = insert(:users_game, state: "pending")

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> put(invitation_path(conn, :update, users_game.id, users_game: %{state: "accepted"}))
        |> json_response(404)

      assert response["error"] == "Invitation not found"
    end

    test "when user not authenticated", %{conn: conn} do
      conn
      |> put(invitation_path(conn, :update, 10, users_game: %{}))
      |> response(401)
    end
  end

  describe "create/2" do
    test "when game exists and is joinable", %{conn: conn, game: game} do
      new_user = insert(:user)
      game_id = game.id
      WerewolfApiWeb.Endpoint.subscribe("user:#{new_user.id}")

      response = create_response(conn, new_user, game.invitation_token, 200)

      assert_broadcast("game_update", %{id: ^game_id})
      assert response["success"] == "Joined the game"
    end

    test "when game is not joinable", %{conn: conn} do
      user = insert(:user)
      game = insert(:game, started: true)
      game_id = game.id
      WerewolfApiWeb.Endpoint.subscribe("user:#{user.id}")

      response = create_response(conn, user, game.invitation_token, 403)

      refute_broadcast("game_update", %{id: ^game_id})
      assert response["error"] == "Game already started"
    end

    test "when game already joined", %{conn: conn, user: user, game: game} do
      users_game = insert(:users_game, state: "pending", game: game, user: user)
      game_id = game.id
      WerewolfApiWeb.Endpoint.subscribe("user:#{user.id}")

      response = create_response(conn, user, game.invitation_token, 403)

      refute_broadcast("game_update", %{id: ^game_id})
      assert response["error"] == "Game already joined"
    end

    test "when game does not exist", %{conn: conn} do
      user = insert(:user)

      WerewolfApiWeb.Endpoint.subscribe("user:#{user.id}")

      response = create_response(conn, user, "fake_token", 404)

      refute_broadcast("game_update", %{})
      assert response["error"] == "Invitation not found"
    end
  end

  describe "show/2" do
    test "when game exists and is joinable", %{conn: conn, game: game} do
      new_user = insert(:user)

      response = show_response(conn, new_user, game.invitation_token, 200)
      assert response["name"] == game.name
    end

    test "when game is not joinable", %{conn: conn, user: user} do
      game = insert(:game, started: true)

      response = show_response(conn, user, game.invitation_token, 403)

      assert response["error"] == "Game already started"
    end

    test "when game already joined", %{conn: conn, user: user, game: game} do
      users_game = insert(:users_game, state: "pending", game: game, user: user)

      response = show_response(conn, user, game.invitation_token, 403)

      assert response["error"] == "Game already joined"
    end

    test "when game does not exist", %{conn: conn} do
      user = insert(:user)

      response = show_response(conn, user, "fake_token", 404)

      assert response["error"] == "Invitation not found"
    end
  end

  defp update_response(conn, users_game, users_game_attrs, expected_response) do
    {:ok, token, _} = encode_and_sign(users_game.user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> put(invitation_path(conn, :update, users_game.id, users_game: users_game_attrs))
    |> json_response(expected_response)
  end

  defp create_response(conn, user, game_token, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> post(invitation_path(conn, :create, token: game_token))
    |> json_response(expected_response)
  end

  defp show_response(conn, user, game_token, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> get(invitation_path(conn, :show, game_token))
    |> json_response(expected_response)
  end
end
