defmodule WerewolfApi.Repo.Migrations.AddForgottenPasswordTokenToUser do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :forgotten_password_token, :string
      add :forgotten_token_generated_at, :utc_datetime
    end
  end
end
