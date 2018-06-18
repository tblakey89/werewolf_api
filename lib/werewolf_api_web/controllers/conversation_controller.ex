defmodule WerewolfApiWeb.ConversationController do
  use WerewolfApiWeb, :controller
  alias WerewolfApi.Conversation
  alias WerewolfApi.Repo

  # need to load up last 100 messages for each conversation
  #  last message inserted at is last message at...
  # unread messages can be worked out by adding a last viewed
  # at to the user conversation join table, updates when user
  # views the conversation (using the channel :p)

  # need to subscribe to all direct conversations on front end
  # send conversations as part of 'me' function

  def index(conn, params) do
    conversations =
      Guardian.Plug.current_resource(conn)
      |> Ecto.assoc(:conversations)
      |> Conversation.active()
      |> Repo.all()
      |> Repo.preload(:users)

    render(conn, "index.json", conversations: conversations)
  end

  def show(conn, %{"id" => id}) do
    conversation =
      Guardian.Plug.current_resource(conn)
      |> Ecto.assoc(:conversations)
      |> Repo.get!(id)
      |> Repo.preload(:users)

    conn
    |> render("show.json", conversation: conversation)
  end

  def create(conn, %{"conversation" => conversation_params}) do
    user = Guardian.Plug.current_resource(conn)

    case Conversation.find_or_create(conversation_params, user) do
      {:ok, conversation} ->
        conversation = Repo.preload(conversation, [:users])

        WerewolfApiWeb.UserChannel.broadcast_conversation_creation_to_users(conversation)

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
