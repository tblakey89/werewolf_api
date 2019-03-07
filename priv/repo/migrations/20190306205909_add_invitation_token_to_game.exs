defmodule WerewolfApi.Repo.Migrations.AddInvitationTokenToGame do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :invitation_token, :string
    end
  end
end
