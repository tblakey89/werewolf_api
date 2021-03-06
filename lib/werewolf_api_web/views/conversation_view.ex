defmodule WerewolfApiWeb.ConversationView do
  use WerewolfApiWeb, :view
  alias WerewolfApi.Conversation

  def render("show.json", %{conversation: conversation}) do
    %{
      conversation:
        render_one(
          conversation,
          WerewolfApiWeb.ConversationView,
          "conversation_with_messages.json"
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
      created_at:
        DateTime.to_unix(DateTime.from_naive!(conversation.inserted_at, "Etc/UTC"), :millisecond),
      users: render_many(conversation.users, WerewolfApiWeb.UserView, "simple_user.json")
    }
  end

  def render("conversation_with_messages.json", %{conversation: conversation}) do
    %{
      id: conversation.id,
      name: conversation.name,
      users: render_many(conversation.users, WerewolfApiWeb.UserView, "simple_user.json"),
      messages: render_many(conversation.messages, WerewolfApiWeb.MessageView, "message.json"),
      created_at:
        DateTime.to_unix(DateTime.from_naive!(conversation.inserted_at, "Etc/UTC"), :millisecond),
      users_conversations:
        render_many(
          conversation.users_conversations,
          WerewolfApiWeb.UsersConversationView,
          "users_conversation.json"
        )
    }
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end
end
