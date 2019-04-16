defmodule WerewolfApi.Repo.Migrations.AddTimestampsToUsersConversations do
  use Ecto.Migration

  def change do
    alter table(:users_conversations) do
      timestamps default: fragment("now()"), null: false
    end
  end
end
