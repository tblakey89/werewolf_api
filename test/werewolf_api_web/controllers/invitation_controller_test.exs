defmodule WerewolfApiWeb.InvitationControllerTest do
  use WerewolfApiWeb.ConnCase
  use Phoenix.ChannelTest
  import WerewolfApi.Factory
  import WerewolfApi.Guardian

  setup do
    user = insert(:user)
    game = insert(:game)
    insert(:users_game, state: "host", game: game, user: user)
    WerewolfApi.Game.Server.start_game(user, game.id, :day)

    on_exit(fn ->
      Werewolf.GameSupervisor.stop_game(game.id)
    end)

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
      game_id = game.id
      users_game_id = users_game.id
      WerewolfApiWeb.Endpoint.subscribe("user:#{users_game.user_id}")

      response = update_response(conn, users_game, %{state: "rejected"}, 200)

      refute_broadcast("game_update", %{id: ^game_id})
      assert_broadcast("invitation_rejected", %{id: ^users_game_id})
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
      assert response["game"]["id"] == game_id
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

    test "when game is public, and nil join_code is passed", %{conn: conn, user: user, game: game} do
      new_user = insert(:user)
      game_id = game.id
      WerewolfApiWeb.Endpoint.subscribe("user:#{new_user.id}")

      response = create_response(conn, new_user, game.id, nil, 200)

      assert_broadcast("game_update", %{id: ^game_id})
      assert response["success"] == "Joined the game"
    end

    test "when game is private, and wrong join_code is passed", %{conn: conn, user: user} do
      new_user = insert(:user)
      game = insert(:game, join_code: "correct")
      game_id = game.id
      WerewolfApiWeb.Endpoint.subscribe("user:#{new_user.id}")

      response = create_response(conn, new_user, game.id, "wrong", 403)

      refute_broadcast("game_update", %{})
      assert response["error"] == "Incorrect game password"
    end

    test "when game is private, and correct join_code is passed", %{conn: conn, user: user} do
      new_user = insert(:user)
      game = insert(:game, join_code: "correct")
      WerewolfApi.Game.Server.start_game(user, game.id, :day)
      game_id = game.id
      WerewolfApiWeb.Endpoint.subscribe("user:#{new_user.id}")

      response = create_response(conn, new_user, game.id, game.join_code, 200)

      assert_broadcast("game_update", %{id: ^game_id})
      assert response["success"] == "Joined the game"
      Werewolf.GameSupervisor.stop_game(game.id)
    end
  end

  describe "show/2" do
    test "when game exists and is joinable", %{conn: conn, game: game} do
      new_user = insert(:user)

      response = show_response(conn, new_user, game.invitation_token, 200)
      assert response["name"] == game.name
    end

    test "when game is not joinable", %{conn: conn} do
      user = insert(:user)
      game = insert(:game, started: true)

      response = show_response(conn, user, game.invitation_token, 403)

      assert response["error"] == "Game already started"
    end

    test "when game already joined", %{conn: conn, game: game} do
      user = insert(:user)
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

  describe "delete/2" do
    test "when valid, removing self", %{conn: conn, game: game} do
      user = insert(:user)
      users_game = insert(:users_game, state: "accepted", game: game, user: user)
      users_game_id = users_game.id
      game_id = game.id

      WerewolfApi.Game.Server.add_player(game.id, user)
      WerewolfApiWeb.Endpoint.subscribe("user:#{users_game.user_id}")

      response = delete_response(conn, user, users_game, 200)

      refute_broadcast("game_update", %{id: ^game_id})
      assert_broadcast("invitation_rejected", %{id: ^users_game_id})
      assert response["success"] == "Removed the user"
    end

    test "when valid, and host, removing other user", %{conn: conn, game: game, user: user} do
      other_user = insert(:user)
      users_game = insert(:users_game, state: "accepted", game: game, user: other_user)
      users_game_id = users_game.id
      game_id = game.id

      WerewolfApi.Game.Server.add_player(game.id, other_user)
      WerewolfApiWeb.Endpoint.subscribe("user:#{other_user.id}")

      response = delete_response(conn, user, users_game, 200)

      refute_broadcast("game_update", %{id: ^game_id})
      assert_broadcast("invitation_rejected", %{id: ^users_game_id})
      assert response["success"] == "Removed the user"
    end

    test "when valid, and not host, removing other user", %{conn: conn, game: game} do
      not_host = insert(:user)
      other_user = insert(:user)
      users_game = insert(:users_game, state: "accepted", game: game, user: other_user)
      users_game_id = users_game.id
      game_id = game.id

      WerewolfApi.Game.Server.add_player(game.id, other_user)
      WerewolfApiWeb.Endpoint.subscribe("user:#{other_user.id}")

      response = delete_response(conn, not_host, users_game, 401)

      assert response["error"] == "Not authorized"
    end

    test "when user not authenticated", %{conn: conn} do
      conn
      |> delete(invitation_path(conn, :delete, 10, users_game: %{}))
      |> response(401)
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

  defp create_response(conn, user, game_id, join_code, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> post(invitation_path(conn, :create, game_id: game_id, join_code: join_code))
    |> json_response(expected_response)
  end

  defp show_response(conn, user, game_token, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> get(invitation_path(conn, :show, game_token))
    |> json_response(expected_response)
  end

  defp delete_response(conn, user, users_game, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> delete(invitation_path(conn, :delete, users_game.id))
    |> json_response(expected_response)
  end
end
