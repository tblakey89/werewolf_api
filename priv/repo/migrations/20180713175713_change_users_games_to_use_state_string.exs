defmodule WerewolfApi.Repo.Migrations.ChangeUsersGamesToUseStateString do
  use Ecto.Migration

  def up do
    alter table(:users_games) do
      remove :host
      remove :accepted_at
      remove :rejected
      add :state, :string, default: "pending", null: false
    end
  end

  def down do
    alter table(:users_games) do
      remove :state
      add :accepted_at, :utc_datetime
      add :rejected, :boolean, default: false
      add :host, :boolean, default: false
    end
  end
end
