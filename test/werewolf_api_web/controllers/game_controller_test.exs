defmodule WerewolfApi.Game.DynamicLink do
  def new_link(token) do
    token
  end
end

defmodule WerewolfApiWeb.GameControllerTest do
  use WerewolfApiWeb.ConnCase
  use Phoenix.ChannelTest
  import WerewolfApi.Factory
  import WerewolfApi.Guardian

  describe "index/1" do
    test "returns only games not started", %{conn: conn} do
      user = insert(:user)
      game_started = insert(:game, started: true)
      game_unstarted = insert(:game, started: false, closed: false)

      response = index_response(conn, user, 200)
      assert length(response["games"]) == 1
      assert Enum.at(response["games"], 0)["id"] == game_unstarted.id
    end

    test "returns no games started more than one day ago", %{conn: conn} do
      two_days_ago =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(-60 * 60 * 24 * 2)

      user = insert(:user)
      game = insert(:game, started: true, inserted_at: two_days_ago)

      response = index_response(conn, user, 200)
      assert length(response["games"]) == 0
    end

    test "returns no closed game", %{conn: conn} do
      user = insert(:user)
      game = insert(:game, closed: true)

      response = index_response(conn, user, 200)
      assert length(response["games"]) == 0
    end
  end

  describe "create/2" do
    test "when valid", %{conn: conn} do
      insert(:user, id: 1)
      user = insert(:user)
      second_user = insert(:user)

      game_name = "test_name"

      game = %{
        name: game_name,
        user_ids: [second_user.id],
        time_period: "day"
      }

      WerewolfApiWeb.Endpoint.subscribe("user:#{second_user.id}")

      response = create_response(conn, user, game, 201)

      assert response["name"] == game.name
      assert response["token"]
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

  describe "update/2" do
    test "updates game by adding new users", %{conn: conn} do
      user = insert(:user)
      game = insert(:game)
      WerewolfApi.Game.Server.start_game(user, game.id, :day, [], Werewolf.Options.new(%{}))
      users_game = insert(:users_game, game: game, user: user, state: "host")
      new_user = insert(:user)

      response = update_response(conn, game.id, user, %{user_ids: [new_user.id]}, 200)

      assert length(response["game"]["users_games"]) == 2
    end

    test "can't update other user's game", %{conn: conn} do
      user = insert(:user)
      game = insert(:game)
      other_user = insert(:user)
      users_game = insert(:users_game, game: game, user: other_user, state: "host")

      response = update_response(conn, game.id, user, %{user_ids: [user.id]}, 403)

      assert response["error"] == "Not allowed."
    end

    test "can't update other user's game when is player in game", %{conn: conn} do
      user = insert(:user)
      game = insert(:game)
      other_user = insert(:user)
      users_game = insert(:users_game, game: game, user: other_user, state: "host")
      this_users_game = insert(:users_game, game: game, user: user)

      response = update_response(conn, game.id, user, %{user_ids: [user.id]}, 403)

      assert response["error"] == "Not allowed."
    end

    test "responds 401 when not authenticated", %{conn: conn} do
      conn
      |> put(game_path(conn, :update, 10, game: %{user_ids: [1]}))
      |> response(401)
    end
  end

  describe "show/2" do
    test "shows user", %{conn: conn} do
      user = insert(:user)
      game = insert(:game)
      users_game = insert(:users_game, game: game, user: user, state: "host")

      response = show_response(conn, game.id, user, 200)

      assert response["game"]["id"] == game.id
    end

    test "responds 401 when not authenticated", %{conn: conn} do
      conn
      |> get(game_path(conn, :show, 10))
      |> response(401)
    end
  end

  defp index_response(conn, user, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> get(game_path(conn, :index))
    |> json_response(expected_response)
  end

  defp create_response(conn, user, game, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> post(game_path(conn, :create, game: game))
    |> json_response(expected_response)
  end

  defp update_response(conn, id, user, game_attrs, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> put(game_path(conn, :update, id, game: game_attrs))
    |> json_response(expected_response)
  end

  defp show_response(conn, id, user, expected_response) do
    {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

    conn
    |> put_req_header("authorization", "bearer: " <> token)
    |> get(game_path(conn, :show, id))
    |> json_response(expected_response)
  end
end
