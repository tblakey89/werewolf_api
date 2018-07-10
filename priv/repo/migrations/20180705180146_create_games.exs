defmodule WerewolfApi.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :name, :string
      add :complete, :boolean
      add :state, :jsonb

      timestamps()
    end
  end
end
