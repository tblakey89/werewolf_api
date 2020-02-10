defmodule WerewolfApi.Repo.Migrations.ChangeConversationLastReadAtToPast do
  use Ecto.Migration

  def change do
    alter table(:users_games) do
      modify :last_read_at, :utc_datetime, default: fragment("now()::date - interval '1 hours'"), null: false
    end
    alter table(:users_conversations) do
      modify :last_read_at, :utc_datetime, default: fragment("now()::date - interval '1 hours'"), null: false
    end
  end
end
