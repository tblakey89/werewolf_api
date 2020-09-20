defmodule WerewolfApi.Repo.Migrations.AddMasonConversationIdToGamesTable do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :mason_conversation_id, references(:conversations)
    end

    create index(:games, [:mason_conversation_id])
  end
end
