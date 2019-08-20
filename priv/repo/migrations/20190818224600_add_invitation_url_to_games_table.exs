defmodule WerewolfApi.Repo.Migrations.AddInvitationUrlToGamesTable do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :invitation_url, :string
    end
  end
end
