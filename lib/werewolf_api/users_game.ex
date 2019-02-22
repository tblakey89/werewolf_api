defmodule WerewolfApi.UsersGame do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  schema "users_games" do
    field(:state, :string, default: "pending")
    belongs_to(:game, WerewolfApi.Game)
    belongs_to(:user, WerewolfApi.User)

    timestamps()
  end

  def changeset(users_game, attrs) do
    users_game
    |> cast(attrs, [:user_id, :state, :id])
    |> validate_required([:user_id])
  end

  def update_state_changeset(users_game, attrs) do
    users_game
    |> cast(attrs, ["state"])
    |> force_change(:state, attrs["state"])
    |> validate_inclusion(:state, ~w(accepted rejected))
  end

  def by_game_id(game_id) do
    query =
      from(
        ug in __MODULE__,
        where: ug.game_id == ^game_id and ug.state != "rejected",
        preload: [:user]
      )

    WerewolfApi.Repo.all(query)
  end
end
