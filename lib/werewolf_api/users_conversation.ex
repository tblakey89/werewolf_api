defmodule WerewolfApi.UsersConversation do
  use Ecto.Schema

  schema "users_conversations" do
    belongs_to(:conversation, WerewolfApi.Conversation)
    belongs_to(:user, WerewolfApi.User)

    timestamps()
  end
end
