defmodule WerewolfApi.Repo.Migrations.AddLastMessagesMapToUsersGames do
  use Ecto.Migration

  def change do
    alter table(:users_games) do
      add :last_read_at_map, :jsonb, default: "{}"
    end
  end
end
