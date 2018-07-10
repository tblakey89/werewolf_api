defmodule WerewolfApi.UsersGame do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users_games" do
    field(:user_id, :integer)
    field(:game_id, :integer)
    field(:accepted_at, :utc_datetime)
    field(:rejected, :boolean)
    field(:host, :boolean)
    has_many(:games, WerewolfApi.Game)
    has_many(:users, WerewolfApi.User)

    timestamps()
  end

  def changeset(users_game, attrs) do
    users_game
    |> cast(attrs, [:user_id, :host])
    |> validate_required([:user_id])
  end
end
