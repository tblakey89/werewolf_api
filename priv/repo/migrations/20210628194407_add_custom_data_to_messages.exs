defmodule WerewolfApi.Repo.Migrations.AddCustomDataToMessages do
  use Ecto.Migration

  def change do
    alter table(:game_messages) do
      add :custom, :string
    end
  end
end
