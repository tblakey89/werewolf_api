  defmodule WerewolfApi.Repo.Migrations.AddExtraToGameMessagesAndMessages do
  use Ecto.Migration

  def change do
    alter table(:game_messages) do
      add :extra, :integer, default: 0, null: false
    end
  end
end
