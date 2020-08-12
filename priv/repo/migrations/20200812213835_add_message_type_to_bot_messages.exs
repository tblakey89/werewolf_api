defmodule WerewolfApi.Repo.Migrations.AddMessageTypeToBotMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :type, :string
    end

    alter table(:game_messages) do
      add :type, :string
    end
  end
end
