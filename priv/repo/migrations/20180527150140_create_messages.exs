defmodule WerewolfApi.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :user_id, references(:users)
      add :body, :text

      timestamps()
    end

  end
end
