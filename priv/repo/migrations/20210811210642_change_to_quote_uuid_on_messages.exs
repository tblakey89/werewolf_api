defmodule WerewolfApi.Repo.Migrations.ChangeToQuoteUuidOnMessages do
  use Ecto.Migration

  def change do
    alter table(:game_messages) do
      remove :quote_id
      add :quote_uuid, :string
    end

    alter table(:messages) do
      remove :quote_id
      add :quote_uuid, :string
    end
  end
end
