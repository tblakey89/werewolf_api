defmodule WerewolfApiWeb.ForgottenPasswordControllerTest do
  use WerewolfApiWeb.ConnCase
  import WerewolfApi.Factory
  alias WerewolfApi.Repo
  alias WerewolfApi.User

  describe "create/2" do
    test "when valid user" do
      user = insert(:user)
      conn = build_conn()

      conn
      |> post(forgotten_password_path(conn, :create, forgotten: %{email: user.email}))
      |> json_response(200)

      updated_user = Repo.get(User, user.id)

      assert updated_user.forgotten_password_token != nil
      assert updated_user.forgotten_token_generated_at != nil
    end

    test "when bad email" do
      conn = build_conn()

      response =
        conn
        |> post(forgotten_password_path(conn, :create, forgotten: %{email: "fake@email.com"}))
        |> json_response(404)

      assert response["error"] == "User not found"
    end
  end

  describe "update/2" do
    test "when successfully changes user's password" do
      user = generate_user("test", NaiveDateTime.utc_now())

      build_conn()
      |> put_password(user.forgotten_password_token, "new_password")
      |> json_response(200)

      updated_user = Repo.get(User, user.id)

      assert updated_user.forgotten_password_token == nil
      assert updated_user.forgotten_token_generated_at == nil
      assert updated_user.password_hash != user.password_hash
    end

    test "when token does not exist" do
      build_conn()
      |> put_password("fake", "new_password")
      |> json_response(404)
    end

    test "when new password too short" do
      user = generate_user("test", NaiveDateTime.utc_now())

      build_conn()
      |> put_password(user.forgotten_password_token, "new")
      |> json_response(422)

      updated_user = Repo.get(User, user.id)

      assert updated_user.forgotten_password_token != nil
      assert updated_user.forgotten_token_generated_at != nil
      assert updated_user.password_hash == user.password_hash
    end

    test "when token too old" do
      user = generate_user("test", ~N[2000-01-01 23:00:07])

      build_conn()
      |> put_password(user.forgotten_password_token, "new_password")
      |> json_response(404)

      updated_user = Repo.get(User, user.id)

      assert updated_user.forgotten_password_token == nil
      assert updated_user.forgotten_token_generated_at == nil
      assert updated_user.password_hash == user.password_hash
    end
  end

  defp generate_user(forgotten_password_token, token_generated_at) do
    insert(
      :user,
      forgotten_password_token: forgotten_password_token,
      forgotten_token_generated_at: token_generated_at
    )
  end

  defp put_password(conn, token, password) do
    conn
    |> put(
      forgotten_password_path(
        conn,
        :update,
        token,
        password: %{password: password}
      )
    )
  end
end
