defmodule WerewolfApi.Repo.Migrations.CreateUsersConversations do
  use Ecto.Migration

  def change do
    create table(:users_conversations) do
      add :user_id, references(:users)
      add :conversation_id, references(:conversations)
    end

    create unique_index(:users_conversations, [:user_id, :conversation_id])
    create index(:users_conversations, [:user_id])
    create index(:users_conversations, [:conversation_id])
  end
end
