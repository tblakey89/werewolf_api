defmodule WerewolfApiWeb.ConversationView do
  use WerewolfApiWeb, :view

  def render("show.json", %{conversation: conversation}) do
    %{
      conversation:
        render_one(
          conversation,
          WerewolfApiWeb.ConversationView,
          "conversation.json"
        )
    }
  end

  def render("index.json", %{conversations: conversations}) do
    %{
      conversations:
        render_many(
          conversations,
          WerewolfApiWeb.ConversationView,
          "conversation.json"
        )
    }
  end

  def render("conversation.json", %{conversation: conversation}) do
    %{
      id: conversation.id,
      name: conversation.name,
      users: render_many(conversation.users, WerewolfApiWeb.UserView, "simple_user.json")
    }
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end
end
