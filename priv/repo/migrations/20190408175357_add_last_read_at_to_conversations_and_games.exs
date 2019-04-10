defmodule WerewolfApi.Repo.Migrations.AddLastReadAtToConversationsAndGames do
  use Ecto.Migration

  def change do
    alter table(:users_games) do
      add :last_read_at, :utc_datetime, default: fragment("now()"), null: false
    end
    alter table(:users_conversations) do
      add :last_read_at, :utc_datetime, default: fragment("now()"), null: false
    end
  end
end
