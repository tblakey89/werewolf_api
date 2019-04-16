defmodule WerewolfApi.Repo.Migrations.AddBotToMessage do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :bot, :boolean, default: false, null: false
    end
  end
end
