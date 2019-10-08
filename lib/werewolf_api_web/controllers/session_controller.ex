defmodule WerewolfApiWeb.SessionController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.Auth
  alias WerewolfApi.Repo
  alias WerewolfApi.User

  def create(conn, %{"session" => %{"type" => "google", "id_token" => id_token}}) do
    case GoogleToken.verify_and_validate(id_token) do
      {:ok, google_user_map} ->
        case Repo.get_by(User, google_id: google_user_map["sub"]) do
          nil ->
            user = User.Google.create_or_update_from_map(google_user_map)
            render_jwt_response(conn, user)
          user -> render_jwt_response(conn, user)
        end
      {:error, _reason} -> render_error(conn)
    end
  end

  def create(conn, %{"session" => %{"email" => email, "password" => password}}) do
    case Auth.find_and_confirm_password(email, password) do
      {:ok, user} -> render_jwt_response(conn, user)
      {:error, _reason} -> render_error(conn)
    end
  end

  defp render_jwt_response(conn, user) do
    {:ok, jwt, _full_claims} = WerewolfApi.Guardian.encode_and_sign(user)
    # put login status
    conn
    |> render("create.json", jwt: jwt)
  end

  defp render_error(conn) do
    conn
    |> put_status(401)
    |> render("error.json", message: "Could not login")
  end
end
