defmodule WerewolfApi.Repo.Migrations.AddAppleUserColumnToUsersTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :apple_id, :string
    end
  end
end
