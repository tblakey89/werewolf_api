defmodule WerewolfApi.Repo.Migrations.AddUuidToMessagesAndDestinationToGameMessages do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";")

    alter table(:game_messages) do
      add :uuid, :uuid, default: fragment("uuid_generate_v4()"), null: false
      add :destination, :string, default: "standard"
    end

    alter table(:messages) do
      add :uuid, :uuid, default: fragment("uuid_generate_v4()"), null: false
    end

    create unique_index(:game_messages, [:uuid])
    create unique_index(:messages, [:uuid])
  end
end
