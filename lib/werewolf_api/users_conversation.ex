defmodule WerewolfApi.UsersConversation do
  use Ecto.Schema

  schema "users_conversations" do
    field(:user_id, :integer)
    field(:conversation_id, :integer)
    has_many(:conversations, WerewolfApi.Conversation)
    has_many(:users, WerewolfApi.User)

    timestamps()
  end
end
