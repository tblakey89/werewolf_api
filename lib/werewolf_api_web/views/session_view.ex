defmodule WerewolfApiWeb.SessionView do
  use WerewolfApiWeb, :view

  def render("create.json", %{jwt: jwt}) do
    %{
      token: jwt
    }
  end

  def render("error.json", %{message: message}) do
    %{error: message}
  end
end
