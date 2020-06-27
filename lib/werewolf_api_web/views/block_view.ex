defmodule WerewolfApiWeb.BlockView do
  use WerewolfApiWeb, :view
  alias WerewolfApi.User.Block

  def render("success.json", %{block: block}) do
    %{success: "Blocked user", blocked_user_id: block.blocked_user_id}
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end

  def render("block.json", %{block: block}) do
    %{
      id: block.id,
      blocked_user_id: block.blocked_user_id
    }
  end
end
