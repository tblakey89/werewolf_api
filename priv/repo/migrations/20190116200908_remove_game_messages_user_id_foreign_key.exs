defmodule WerewolfApi.Repo.Migrations.RemoveGameMessagesUserIdForeignKey do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE game_messages DROP CONSTRAINT game_messages_user_id_fkey"
  end
end
