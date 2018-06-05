defmodule WerewolfApiWeb.ConversationController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.Conversation
  alias WerewolfApi.Repo

  # direct messages controller is nested within direct conversations
  # do not need show, index on direct message controller will do

  # need to create direct_conversation channel
  # need to subscribe to all direct conversations on front end
  # don't need the direct_message recipient id, as only two users in conversation
  # add index on direct messages on conversation_id
  # send conversations as part of 'me' function
  # whenever new message is created change last message at of conversation
  # direct message index works as suggested on front end

  def index(conn, params) do
    conversations =
      Guardian.Plug.current_resource(conn)
      |> Ecto.assoc(:conversations)
      |> Conversation.active()
      |> Repo.all()
      |> Repo.preload(:users)

    render(conn, "index.json", conversations: conversations)
  end

  def create(conn, %{"conversation" => conversation_params}) do
    user = Guardian.Plug.current_resource(conn)
    changeset = Conversation.changeset(%Conversation{}, conversation_params, user)

    case Repo.insert(changeset) do
      {:ok, conversation} ->
        conversation = Repo.preload(conversation, [:users])

        conn
        |> put_status(:created)
        |> render("show.json", conversation: conversation)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json", changeset: changeset)
    end
  end
end
