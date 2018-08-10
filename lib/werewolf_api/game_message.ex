defmodule WerewolfApi.GameMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "game_messages" do
    field(:body, :string)
    field(:bot, :boolean, default: false)
    belongs_to(:user, WerewolfApi.User, foreign_key: :user_id)
    belongs_to(:game, WerewolfApi.Game, foreign_key: :game_id)

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:body])
    |> validate_required([:body])
  end
end
