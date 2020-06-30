defmodule WerewolfApiWeb.ReportController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.User.Report
  alias WerewolfApi.Repo

  def create(conn, params) do
    changeset =
      Guardian.Plug.current_resource(conn)
      |> Ecto.build_assoc(:reports)
      |> Report.changeset(params)

    case Repo.insert(changeset) do
      {:ok, report} ->
        render(conn, "success.json", %{report: report})

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
