defmodule WerewolfApiWeb.InvitationView do
  use WerewolfApiWeb, :view

  def render("success.json", %{users_game: users_game}) do
    case users_game.state do
      "accepted" -> %{success: "Joined the game"}
      "rejected" -> %{success: "Rejected the invitation"}
    end
  end

  def render("error.json", %{message: message}) do
    %{error: message}
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end
end
