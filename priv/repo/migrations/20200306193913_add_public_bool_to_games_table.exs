defmodule WerewolfApi.Repo.Migrations.AddPublicBoolToGamesTable do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :public, :boolean, default: false
    end
  end
end
