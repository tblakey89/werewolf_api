defmodule WerewolfApi.Repo.Migrations.AddTimerPeriodToGame do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :time_period, :string, default: "day", null: false
    end
  end
end
