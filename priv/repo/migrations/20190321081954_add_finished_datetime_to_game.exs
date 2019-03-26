defmodule WerewolfApi.Repo.Migrations.AddFinishedDatetimeToGame do
  use Ecto.Migration

  def change do
    alter table(:games) do
      remove :complete
      add :finished, :utc_datetime
    end
  end
end
