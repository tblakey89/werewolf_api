defmodule WerewolfApi.Repo.Migrations.CreateGameMessage do
  use Ecto.Migration

  def change do
    create table(:game_messages) do
      add :body, :text
      add :bot, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :nothing)
      add :game_id, references(:games, on_delete: :nothing)

      timestamps()
    end

    create index(:game_messages, [:user_id])
    create index(:game_messages, [:game_id])
  end
end
