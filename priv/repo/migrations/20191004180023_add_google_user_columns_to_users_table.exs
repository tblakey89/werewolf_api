defmodule WerewolfApi.Repo.Migrations.AddGoogleUserColumnsToUsersTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :google_id, :string
      add :google_display_name, :string
      add :first_name, :string
      add :last_name, :string
    end
  end
end
