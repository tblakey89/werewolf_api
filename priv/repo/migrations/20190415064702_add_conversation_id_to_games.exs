defmodule WerewolfApi.Repo.Migrations.AddConversationIdToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :conversation_id, references(:conversations)
    end

    create index(:games, [:conversation_id])
  end
end
