defmodule WerewolfApi.Repo.Migrations.AddColumnsForScheduledGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :start_at, :utc_datetime
      add :type, :string
      add :closed, :bool, default: false
    end
  end
end
