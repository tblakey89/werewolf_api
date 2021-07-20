defmodule WerewolfApi.Repo.Migrations.AddNotesToUsersGames do
  use Ecto.Migration

  def change do
    alter table(:users_games) do
      add :notes, :binary
    end
  end
end
