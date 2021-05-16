defmodule WerewolfApi.Repo.Migrations.AddPhaseNumberToGameMessagesAndMessages do
  use Ecto.Migration

  def change do
    alter table(:game_messages) do
      add :phase_number, :integer, default: 0, null: false
    end
  end
end
