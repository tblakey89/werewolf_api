defmodule WerewolfApi.User.Block do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blocks" do
    belongs_to(:user, WerewolfApi.User)
    belongs_to(:blocked_user, WerewolfApi.User)

    timestamps()
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, [:user_id, :blocked_user_id])
    |> validate_required([:user_id, :blocked_user_id])
  end
end
