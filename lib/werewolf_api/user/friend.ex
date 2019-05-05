defmodule WerewolfApi.User.Friend do
  use Ecto.Schema
  import Ecto.Changeset

  schema "friends" do
    field(:state, :string, default: "pending")
    belongs_to(:user, WerewolfApi.User)
    belongs_to(:friend, WerewolfApi.User)

    timestamps()
  end

  @doc false
  def changeset(friendship, attrs) do
    friendship
    |> cast(attrs, [:user_id, :friend_id, :state])
    |> validate_required([:user_id, :friend_id])
  end

  def update_state_changeset(friendship, attrs) do
    friendship
    |> cast(attrs, ["state"])
    |> force_change(:state, attrs["state"])
    |> validate_inclusion(:state, ~w(accepted rejected))
  end
end
