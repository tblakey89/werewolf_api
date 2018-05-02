defmodule WerewolfApiWeb.ForgottenPasswordView do
  use WerewolfApiWeb, :view

  def render("success.json", _) do
    %{success: "You will be emailed the new password link"}
  end

  def render("error.json", %{message: message}) do
    %{error: message}
  end
end
