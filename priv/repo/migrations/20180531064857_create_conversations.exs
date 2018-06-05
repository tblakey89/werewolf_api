defmodule WerewolfApi.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :name, :string
      add :last_message_at, :utc_datetime

      timestamps()
    end

  end
end
