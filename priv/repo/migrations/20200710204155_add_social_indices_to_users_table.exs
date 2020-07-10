defmodule WerewolfApi.Repo.Migrations.AddSocialIndicesToUsersTable do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:apple_id])
    create unique_index(:users, [:google_id])
    create unique_index(:users, [:facebook_id])
  end
end
