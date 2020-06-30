defmodule WerewolfApi.Repo.Migrations.AddReportsTable do
  use Ecto.Migration

  def change do
    create table(:reports) do
      add :user_id, references(:users, on_delete: :nothing)
      add :reported_user_id, references(:users, on_delete: :nothing)
      add :body, :text

      timestamps()
    end
  end
end
