defmodule WerewolfApiWeb.GameControllerTest do
  use WerewolfApiWeb.ConnCase
  use Phoenix.ChannelTest
  import WerewolfApi.Factory
  import WerewolfApi.Guardian

  describe "create/2" do
    test "when valid", %{conn: conn} do
      user = insert(:user)
      second_user = insert(:user)

      game_name = "test_name"

      game = %{
        name: "test_name",
        user_ids: [second_user.id]
      }

      WerewolfApiWeb.Endpoint.subscribe("user:#{second_user.id}")

      response = create_response(conn, user, game, 201)

      assert response["name"] == game.name
      assert Enum.at(response["users_games"], 0)["user"]["id"] == user.id
      assert Enum.at(response["users_games"], 0)["state"] == "host"
      assert Enum.at(response["users_games"], 1)["user"]["id"] == second_user.id
      assert Enum.at(response["users_games"], 1)["state"] == "pending"
      assert_broadcast("new_game", %{name: ^game_name})
    end

    test "when name is missing", %{conn: conn} do
      user = insert(:user)

      response = create_response(conn, user, %{name: nil}, 422)

      assert response["errors"]["name"] == ["can't be blank"]
    end

    test "when user not authenticated", %{conn: conn} do
      conn
      |> post(game_path(conn, :create, game: %{}))
      |> response(401)
    end
  end

  defp create_response(conn, user, game, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> post(game_path(conn, :create, game: game))
    |> json_response(expected_response)
  end
end
