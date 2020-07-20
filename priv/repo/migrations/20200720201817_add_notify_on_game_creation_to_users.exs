defmodule WerewolfApi.Repo.Migrations.AddNotifyOnGameCreationToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :notify_on_game_creation, :boolean, default: false
    end

    create index(:users, [:notify_on_game_creation])
  end
end
