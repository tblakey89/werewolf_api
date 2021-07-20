defmodule WerewolfApi.Repo.Migrations.AddQuoteIdToMessages do
  use Ecto.Migration

  def change do
    alter table(:game_messages) do
      add :quote_id, references(:game_messages)
    end

    alter table(:messages) do
      add :quote_id, references(:messages)
    end
  end
end
