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

    timestamps()
  end

  def active(query) do
    from c in query,
      where: not is_nil(c.last_message_at)
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
end
