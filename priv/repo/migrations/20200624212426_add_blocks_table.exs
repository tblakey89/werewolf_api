defmodule WerewolfApi.Repo.Migrations.AddBlocksTable do
  use Ecto.Migration

  def change do
    create table(:blocks) do
      add :user_id, references(:users, on_delete: :nothing)
      add :blocked_user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:blocks, [:user_id])
    create index(:blocks, [:blocked_user_id])
    create unique_index(:blocks, [:user_id, :blocked_user_id])
  end
end
