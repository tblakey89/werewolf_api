defmodule WerewolfApi.Conversation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias WerewolfApi.Repo

  schema "conversations" do
    field(:name, :string)
    field(:last_message_at, :utc_datetime)
    many_to_many(:users, WerewolfApi.User, join_through: "users_conversations")
    has_many(:messages, WerewolfApi.Message)
    has_many(:users_conversations, WerewolfApi.UsersConversation)

    timestamps()
  end

  def active(query) do
    from(c in query, where: not is_nil(c.last_message_at))
  end

  def find_or_create(params, user) do
    conversations = find_by_user_ids(params, user)

    cond do
      length(conversations) > 0 ->
        {:ok, Enum.at(conversations, 0)}
      true ->
        changeset = __MODULE__.changeset(%__MODULE__{}, params, user)
        Repo.insert(changeset)
    end
  end

  def find_by_user_ids(params, user) do
    sorted_user_ids =
      Enum.sort([user.id|params["user_ids"] || []])
      |> Enum.map(&convert_user_id_to_integer/1)

    query =
      from conversation in __MODULE__,
        join: users_conversation in assoc(conversation, :users_conversations),
        group_by: conversation.id,
        having: fragment("? = array_agg(? order by ?)", ^sorted_user_ids, users_conversation.user_id, users_conversation.user_id)

    Repo.all(query)
  end

  @doc false
  def changeset(conversation, attrs, user) do
    participants = WerewolfApi.User.find_by_user_ids(attrs["user_ids"])

    conversation
    |> cast(attrs, [:name])
    |> put_assoc(:users, [user | participants])
    |> validate_user_amount(:users)
  end

  defp validate_user_amount(changeset, field) do
    validate_change(changeset, field, fn _, users ->
      case length(users) > 1 do
        true -> []
        false -> [{field, "need at least one other participant"}]
      end
    end)
  end

  defp convert_user_id_to_integer(user_id) when is_binary(user_id) do
    String.to_integer(user_id)
  end
  defp convert_user_id_to_integer(user_id), do: user_id
end
