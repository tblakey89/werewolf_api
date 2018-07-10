defmodule WerewolfApi.Repo.Migrations.CreateUsersGames do
  use Ecto.Migration

  def change do
    create table(:users_games) do
      add :user_id, references(:users)
      add :game_id, references(:games)
      add :accepted_at, :utc_datetime
      add :rejected, :boolean, default: false
      add :host, :boolean, default: false

      timestamps()
    end

    create unique_index(:users_games, [:user_id, :game_id])
    create index(:users_games, [:user_id])
    create index(:users_games, [:game_id])
  end
end
