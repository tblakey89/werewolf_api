defmodule WerewolfApi.Repo.Migrations.AddAllowedRolesToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :allowed_roles, {:array, :string}
    end
  end
end
