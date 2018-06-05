defmodule WerewolfApi.Repo.Migrations.AddConversationIdToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :conversation_id, references(:conversations)
    end

    create index(:messages, [:conversation_id])
  end
end
