defmodule WerewolfApiWeb.UserView do
  use WerewolfApiWeb, :view

  def render("show.json", %{user: user}) do
    %{
      user: render_one(user, WerewolfApiWeb.UserView, "user.json")
    }
  end

  def render("index.json", %{users: users}) do
    %{
      users: render_many(users, WerewolfApiWeb.UserView, "user.json")
    }
  end

  def render("me.json", %{user: user}) do
    %{
      user: render_one(user, WerewolfApiWeb.UserView, "user_and_associations.json")
    }
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      email: user.email,
      username: user.username
    }
  end

  def render("user_and_associations.json", %{user: user}) do
    %{
      id: user.id,
      email: user.email,
      username: user.username,
      conversations:
        render_many(
          user.conversations,
          WerewolfApiWeb.ConversationView,
          "conversation_with_messages.json"
        ),
      games:
        render_many(
          user.games,
          WerewolfApiWeb.GameView,
          "game.json"
        )
    }
  end

  def render("simple_user.json", %{user: user}) do
    %{
      id: user.id,
      username: user.username
    }
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end
end
