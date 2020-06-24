defmodule WerewolfApiWeb.BlockController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.User.Block
  alias WerewolfApi.Repo

  def create(conn, %{"user_id" => blocked_user_id}) do
    user = Guardian.Plug.current_resource(conn)

    changeset = Block.changeset(%Block{}, %{user_id: user.id, blocked_user_id: blocked_user_id})

    case Repo.insert(changeset) do
      {:ok, block} ->
        render(conn, "success.json", %{block: block})

      {:error, %Ecto.Changeset{} = changeset} ->
        unprocessable_entity(conn, changeset)
    end
  end

  defp unprocessable_entity(conn, changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> render("error.json", changeset: changeset)
  end
end
