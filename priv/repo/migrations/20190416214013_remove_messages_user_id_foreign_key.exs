defmodule WerewolfApi.Repo.Migrations.RemoveMessagesUserIdForeignKey do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE messages DROP CONSTRAINT messages_user_id_fkey"
  end
end
