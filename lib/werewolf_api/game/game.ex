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
    field(:invitation_url, :string)
    field(:join_code, :string)
    field(:start_at, :utc_datetime)
    field(:type, :string)
    field(:closed, :boolean, default: false)
    field(:allowed_roles, {:array, :string}, default: [])
    many_to_many(:users, WerewolfApi.User, join_through: "users_games")
    has_many(:users_games, WerewolfApi.UsersGame)
    has_many(:messages, WerewolfApi.Game.Message)
    belongs_to(:conversation, WerewolfApi.Conversation)
    belongs_to(:mason_conversation, WerewolfApi.Conversation)

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

  def find_host_username(game) do
    host_users_game =
      Enum.find(game.users_games, fn users_game ->
        users_game.state == "host"
      end)

    case host_users_game do
      nil -> nil
      _ -> host_users_game.user.username
    end
  end

  @doc false
  def changeset(game, attrs, user) do
    participants =
      Enum.map(
        WerewolfApi.User.find_by_user_ids(attrs[:user_ids] || attrs["user_ids"]),
        fn participant ->
          %{user_id: participant.id}
        end
      )

    invitation_token = generate_game_token()

    attrs =
      Map.put_new(attrs, "users_games", [
        %{user_id: user.id, state: "host"} | participants
      ])
      |> Map.put_new(
        "invitation_token",
        invitation_token
      )
      |> Map.put_new(
        "invitation_url",
        WerewolfApi.Game.DynamicLink.new_link(invitation_token)
      )

    game
    |> cast(attrs, [
      :name,
      :invitation_token,
      :invitation_url,
      :time_period,
      :join_code,
      :allowed_roles
    ])
    |> cast_assoc(:users_games)
    |> validate_required([:name, :time_period])
  end

  def scheduled_changeset(hours, phase_length, name) do
    invitation_token = generate_game_token()

    %__MODULE__{}
    |> change(%{
      name: "Werewolf - #{name}",
      time_period: phase_length,
      start_at: start_at(hours),
      type: "scheduled",
      invitation_token: invitation_token,
      invitation_url: dynamic_url().new_link(invitation_token),
      # don't forget to re-add mason
      allowed_roles:
        Enum.take_random(["detective", "doctor", "little_girl", "hunter", "devil"], 3)
    })
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
    attrs = Map.merge(attrs, %{"users_games" => Enum.concat(participants, existing_users_games)})

    game
    |> cast(attrs, [
      :name,
      :time_period,
      :join_code,
      :allowed_roles
    ])
    |> cast_assoc(:users_games)
  end

  def state_changeset(game, state) do
    change(game, state: clean_state(state))
  end

  def closed_changeset(game) do
    change(game, closed: true)
  end

  def generate_game_token() do
    :crypto.strong_rand_bytes(15) |> Base.url_encode64() |> binary_part(0, 15)
  end

  def participating_games(user_id, game_ids, refresh_date \\ ~N[2019-08-26 00:00:00])

  def participating_games(user_id, nil, refresh_date) do
    from(
      g in WerewolfApi.Game,
      join: ug in WerewolfApi.UsersGame,
      where: ug.user_id == ^user_id and ug.game_id == g.id and ug.state != "rejected",
      preload: [
        [
          messages:
            ^from(m in WerewolfApi.Game.Message,
              where: m.inserted_at >= ^refresh_date,
              order_by: [desc: m.id],
              preload: :user
            )
        ],
        users_games: :user
      ]
    )
  end

  def participating_games(user_id, game_ids, refresh_date) do
    from(
      g in WerewolfApi.Game,
      join: ug in WerewolfApi.UsersGame,
      where:
        ug.user_id == ^user_id and ug.game_id == g.id and ug.state != "rejected" and
          g.id in ^game_ids,
      preload: [
        [
          messages:
            ^from(m in WerewolfApi.Game.Message,
              where: m.inserted_at >= ^refresh_date,
              order_by: [desc: m.id],
              preload: :user
            )
        ],
        users_games: :user
      ]
    )
  end

  def limited_participating_games(user_id, limit \\ 20, refresh_date \\ ~N[2019-08-26 00:00:00]) do
    from(
      g in WerewolfApi.Game,
      join: ug in WerewolfApi.UsersGame,
      where: ug.user_id == ^user_id and ug.game_id == g.id and ug.state != "rejected",
      order_by: [desc: :updated_at],
      preload: [
        [
          messages:
            ^from(m in WerewolfApi.Game.Message,
              where: m.inserted_at >= ^refresh_date,
              preload: :user
            )
        ],
        users_games: :user
      ],
      limit: ^limit
    )
  end

  def user_from_game(game, user_id) do
    Enum.find(game.users, fn user -> user.id == user_id end)
  end

  defp start_at(hours) do
    {:ok, start_time} = DateTime.from_unix(DateTime.to_unix(DateTime.utc_now()) + 60 * 60 * hours)
    start_time
  end

  def dynamic_url, do: Application.get_env(:werewolf_api, :dynamic_url)
end
