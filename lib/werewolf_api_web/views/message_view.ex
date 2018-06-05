defmodule WerewolfApiWeb.MessageView do
  use WerewolfApiWeb, :view

  def render("index.json", %{messages: messages}) do
    %{
      messages:
        render_many(
          messages,
          WerewolfApiWeb.MessageView,
          "message.json"
        )
    }
  end

  def render("message.json", %{message: message}) do
    %{
      id: message.id,
      created_at: message.inserted_at,
      body: message.body,
      sender: render_one(message.user, WerewolfApiWeb.UserView, "simple_user.json")
    }
  end
end
