defmodule WerewolfApi.UsersGame do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias WerewolfApi.Repo

  schema "users_games" do
    field(:state, :string, default: "pending")
    field(:last_read_at, :utc_datetime, default: DateTime.truncate(DateTime.utc_now(), :second))
    belongs_to(:game, WerewolfApi.Game)
    belongs_to(:user, WerewolfApi.User)

    timestamps()
  end

  def changeset(users_game, attrs) do
    users_game
    |> cast(attrs, [:user_id, :game_id, :state, :id])
    |> validate_required([:user_id])
  end

  def update_state_changeset(users_game, attrs) do
    users_game
    |> cast(attrs, [:state])
    |> force_change(:state, attrs[:state])
    |> validate_inclusion(:state, ~w(accepted rejected))
  end

  def by_game_id(game_id) do
    query =
      from(
        ug in __MODULE__,
        where: ug.game_id == ^game_id and ug.state != "rejected",
        preload: [:user]
      )

    Repo.all(query)
  end

  def pending(game_id) do
    from(ug in __MODULE__, where: ug.state == "pending" and ug.game_id == ^game_id)
  end

  def rejected(game_id) do
    from(ug in __MODULE__, where: ug.state == "rejected" and ug.game_id == ^game_id)
  end

  def pending_and_accepted_only_with_user(game_id) do
    from(
      ug in __MODULE__,
      where: ug.game_id == ^game_id and ug.state != "rejected",
      preload: [user: :blocks]
    )
  end

  def reject_pending_invitations(game_id) do
    __MODULE__.pending(game_id)
    |> Repo.update_all(set: [state: "rejected"])
  end

  def update_last_read_at(user_id, game_id) do
    Repo.get_by(__MODULE__, user_id: user_id, game_id: game_id)
    |> change(last_read_at: DateTime.truncate(DateTime.utc_now(), :second))
    |> Repo.update()
  end
end
