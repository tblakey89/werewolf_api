defmodule WerewolfApiWeb.ReportView do
  use WerewolfApiWeb, :view
  alias WerewolfApi.User.Report

  def render("success.json", %{report: report}) do
    %{success: "Reported user", reported_user_id: report.reported_user_id}
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end
end
