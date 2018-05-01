defmodule WerewolfApiWeb.UserController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.User
  alias WerewolfApi.Repo

  def create(conn, %{"user" => user_params}) do
    changeset = User.registration_changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> render("show.json", user: user)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get(User, id)

    conn
    |> render("show.json", user: user)
  end
end
