defmodule WerewolfApiWeb.InvitationControllerTest do
  use WerewolfApiWeb.ConnCase
  use Phoenix.ChannelTest
  import WerewolfApi.Factory
  import WerewolfApi.Guardian

  setup do
    user = insert(:user)
    game = insert(:game)
    WerewolfApi.GameServer.start_game(user, game.id, :day)

    {:ok, game: game}
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

  defp update_response(conn, users_game, users_game_attrs, expected_response) do
    {:ok, token, _} = encode_and_sign(users_game.user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> put(invitation_path(conn, :update, users_game.id, users_game: users_game_attrs))
    |> json_response(expected_response)
  end
end
