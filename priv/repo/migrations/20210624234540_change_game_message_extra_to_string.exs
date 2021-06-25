defmodule WerewolfApi.Repo.Migrations.ChangeGameMessageExtraToString do
  use Ecto.Migration

  def change do
    alter table(:game_messages) do
      modify :extra, :string
    end
  end
end
