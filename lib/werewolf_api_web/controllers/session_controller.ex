defmodule WerewolfApiWeb.SessionController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.Auth

  def create(conn, %{"session" => %{"email" => email, "password" => password}}) do
    case Auth.find_and_confirm_password(email, password) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = WerewolfApi.Guardian.encode_and_sign(user)
        # put login status
        conn
        |> render("create.json", jwt: jwt)

      {:error, _reason} ->
        conn
        |> put_status(401)
        |> render("error.json", message: "Could not login")
    end
  end
end
