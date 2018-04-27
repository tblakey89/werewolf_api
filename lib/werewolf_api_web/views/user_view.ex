defmodule WerewolfApiWeb.UserView do
  use WerewolfApiWeb, :view

  def render("show.json", %{user: user}) do
    %{
      user: user_json(user)
    }
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end

  defp user_json(user) do
    %{
      id: user.id,
      email: user.email,
      username: user.username
    }
  end
end
