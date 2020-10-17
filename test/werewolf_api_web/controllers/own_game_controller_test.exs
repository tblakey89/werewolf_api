defmodule WerewolfApiWeb.OwnGameControllerTest do
  use WerewolfApiWeb.ConnCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  alias WerewolfApi.Repo

  describe "index/2" do
    test "responds with game if after offset", %{conn: conn} do
      user = insert(:user)
      Enum.each(0..1, fn i -> insert(:users_game, user: user) end)

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(own_game_path(conn, :index, %{"offset" => 1}))
        |> json_response(200)

      assert length(response) == 1
    end

    test "responds with no games if offset greater than number of games", %{conn: conn} do
      user = insert(:user)
      insert(:users_game, user: user)

      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      response =
        conn
        |> put_req_header("authorization", "bearer: " <> token)
        |> get(own_game_path(conn, :index, %{"offset" => 1}))
        |> json_response(200)

      assert length(response) == 0
    end

    test "responds 401 when not authenticated", %{conn: conn} do
      conn
      |> get(own_game_path(conn, :index, %{"offset" => 1}))
      |> response(401)
    end
  end
end
