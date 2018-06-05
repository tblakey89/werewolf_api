defmodule WerewolfApiWeb.MessageController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.Conversation
  alias WerewolfApi.Repo

  def index(conn, %{"conversation_id" => conversation_id}) do
    # one day could limit this to retreive only 100 messages from
    # certain time onwards
    conversation =
      Repo.get(Conversation, conversation_id)
      |> Repo.preload([messages: :user])

    conn
    |> render("index.json", messages: conversation.messages)
  end
end
