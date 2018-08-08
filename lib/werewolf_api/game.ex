defmodule WerewolfApi.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field(:name, :string)
    field(:complete, :boolean)
    field(:state, :map)
    many_to_many(:users, WerewolfApi.User, join_through: "users_games")
    has_many(:users_games, WerewolfApi.UsersGame)
    has_many(:game_messages, WerewolfApi.GameMessage)

    timestamps()
  end

  @doc false
  def changeset(game, attrs, user) do
    participants =
      Enum.map(WerewolfApi.User.find_by_user_ids(attrs["user_ids"]), fn participant ->
        %{user_id: participant.id}
      end)

    attrs =
      Map.put_new(attrs, "users_games", [
        %{user_id: user.id, state: "host"} | participants
      ])

    game
    |> cast(attrs, [:name])
    |> cast_assoc(:users_games)
    |> validate_required([:name])
  end
end
