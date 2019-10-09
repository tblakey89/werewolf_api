defmodule WerewolfApi.Repo.Migrations.AddFacebookUserColumnsToUsersTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :facebook_id, :string
      add :facebook_display_name, :string
    end
  end
end
