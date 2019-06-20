defmodule WerewolfApi.UsersConversation do
  use Ecto.Schema
  import Ecto.Changeset
  alias WerewolfApi.Repo

  schema "users_conversations" do
    field(:last_read_at, :utc_datetime, default: DateTime.utc_now())
    belongs_to(:conversation, WerewolfApi.Conversation)
    belongs_to(:user, WerewolfApi.User)

    timestamps()
  end

  def update_last_read_at(user_id, conversation_id) do
    Repo.get_by(__MODULE__, user_id: user_id, conversation_id: conversation_id)
    |> change(last_read_at: DateTime.truncate(DateTime.utc_now(), :second))
    |> Repo.update()
  end
end
