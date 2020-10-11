defmodule WerewolfApi.Game.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "game_messages" do
    field(:body, :string)
    field(:bot, :boolean, default: false)
    field(:type, :string)
    field(:destination, :string, default: "standard")
    field(:uuid, :binary_id)
    belongs_to(:user, WerewolfApi.User, foreign_key: :user_id)
    belongs_to(:game, WerewolfApi.Game, foreign_key: :game_id)

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:body, :bot, :type, :uuid, :destination])
    |> validate_required([:body])
  end

  def username(%{bot: true} = message) do
    "Narrator"
  end

  def username(message) do
    WerewolfApi.User.display_name(message.user)
  end
end
