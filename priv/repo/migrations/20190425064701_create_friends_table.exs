defmodule WerewolfApi.Repo.Migrations.CreateFriendsTable do
  use Ecto.Migration

  def change do
    create table(:friends) do
      add :user_id, references(:users, on_delete: :nothing)
      add :friend_id, references(:users, on_delete: :nothing)
      add :state, :string, default: "pending", null: false

      timestamps()
    end

    create index(:friends, [:user_id])
    create index(:friends, [:friend_id])
    create unique_index(:friends, [:user_id, :friend_id])
  end
end
