defmodule WerewolfApiWeb.ForgottenPasswordController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.User
  alias WerewolfApi.Repo

  # don't forget to send email

  def create(conn, %{"forgotten" => %{"email" => email}}) do
    with {:ok, user} <- find_user_by(:email, email),
         changeset <- User.forgotten_password_changeset(user),
         {:ok, _user} <- Repo.update(changeset) do
      render(conn, "success.json", %{})
    else
      {:error, :user_not_found} -> user_not_found(conn)
      {:error, changeset} -> unprocessable_entity(conn, changeset)
    end
  end

  def update(conn, %{"id" => token, "password" => attrs}) do
    with {:ok, user} <- find_user_by(:forgotten_password_token, token),
         :ok <- User.check_token_valid(user),
         changeset <- User.update_password_changeset(user, attrs),
         {:ok, _user} <- Repo.update(changeset) do
      render(conn, "success.json", %{})
    else
      {:error, :user_not_found} -> user_not_found(conn)
      {:error, :expired_token, user} -> expired_token(conn, user)
      {:error, changeset} -> unprocessable_entity(conn, changeset)
    end
  end

  defp find_user_by(key, value) do
    case Repo.get_by(User, %{key => value}) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  defp user_not_found(conn) do
    conn
    |> put_status(404)
    |> render("error.json", message: "User not found")
  end

  defp expired_token(conn, user) do
    changeset = User.clear_forgotten_password_changeset(user)
    Repo.update(changeset)
    user_not_found(conn)
  end

  defp unprocessable_entity(conn, changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(WerewolfApiWeb.UserView, "error.json", changeset: changeset)
  end
end
