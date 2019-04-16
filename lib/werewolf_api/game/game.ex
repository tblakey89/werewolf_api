defmodule WerewolfApi.Game do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias WerewolfApi.Repo

  schema "games" do
    field(:name, :string)
    field(:time_period, :string)
    field(:started, :boolean)
    field(:finished, :utc_datetime)
    field(:state, :map)
    field(:invitation_token, :string)
    many_to_many(:users, WerewolfApi.User, join_through: "users_games")
    has_many(:users_games, WerewolfApi.UsersGame)
    has_many(:messages, WerewolfApi.Game.Message)
    belongs_to(:conversation, WerewolfApi.Conversation)

    timestamps()
  end

  def find_from_id(id) do
    Repo.get(__MODULE__, id)
  end

  def current_state(game) do
    # here, if game no longer active return from game.state
    {:ok, state} = WerewolfApi.Game.Server.get_state(game.id)
    state
  end

  def update_state(game = %__MODULE__{}, state) do
    state_changeset(game, state)
    |> Repo.update()
  end

  def update_state(id, state) do
    find_from_id(id)
    |> state_changeset(state)
    |> Repo.update()
  end

  def clean_state(state) do
    # does this belong in werewolf application?
    Map.delete(state, :broadcast_func)
    |> Map.delete(:timer)
  end

  def find_host_id(game) do
    host_users_game =
      Enum.find(game.users_games, fn users_game ->
        users_game.state == "host"
      end)

    host_users_game.user_id
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
      |> Map.put_new(
        "invitation_token",
        generate_game_token()
      )

    game
    |> cast(attrs, [:name, :invitation_token, :time_period])
    |> cast_assoc(:users_games)
    |> validate_required([:name, :time_period])
  end

  def update_changeset(game, attrs) do
    participants =
      Enum.map(WerewolfApi.User.find_by_user_ids(attrs["user_ids"]), fn participant ->
        %{user_id: participant.id}
      end)

    existing_users_games =
      Enum.map(game.users_games, fn users_game ->
        %{user_id: users_game.user_id, id: users_game.id, state: users_game.state}
      end)

    # surely there has to be a better way?
    attrs = %{users_games: Enum.concat(participants, existing_users_games)}

    game
    |> cast(attrs, [])
    |> cast_assoc(:users_games)
  end

  def state_changeset(game, state) do
    change(game, state: clean_state(state))
  end

  def generate_game_token() do
    :crypto.strong_rand_bytes(15) |> Base.url_encode64() |> binary_part(0, 15)
  end

  def participating_games(user_id) do
    from(
      g in WerewolfApi.Game,
      join: ug in WerewolfApi.UsersGame,
      where: ug.user_id == ^user_id and ug.game_id == g.id and ug.state != "rejected",
      preload: [
        [
          messages: ^from(m in WerewolfApi.Game.Message, order_by: [desc: m.id], preload: :user)
        ],
        users_games: :user
      ]
    )
  end
end
