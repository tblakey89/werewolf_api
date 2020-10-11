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
      created_at:
        DateTime.to_unix(DateTime.from_naive!(message.inserted_at, "Etc/UTC"), :millisecond),
      body: message.body,
      bot: message.bot,
      sender: render_optional_user(message),
      conversation_id: message.conversation_id,
      type: message.type,
      uuid: message.uuid
    }
  end

  defp render_optional_user(%{user_id: 0}), do: nil

  defp render_optional_user(message) do
    render_one(message.user, WerewolfApiWeb.UserView, "simple_user.json")
  end
end
