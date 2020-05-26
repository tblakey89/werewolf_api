defmodule WerewolfApi.Repo.Migrations.AddJoinCodeToGamesTable do
  use Ecto.Migration

  def change do
    alter table(:games) do
      remove :public, :boolean, default: false
      add :join_code, :string
    end
  end
end
