defmodule WerewolfApi.Repo.Migrations.AddStartedBooleanToGame do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :started, :boolean, default: false
    end
  end
end
