defmodule WerewolfApi.Repo.Migrations.AddAvatarToUsersTable do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :avatar, :string
    end
  end

  def down do
    alter table(:users) do
      remove :avatar
    end
  end
end
