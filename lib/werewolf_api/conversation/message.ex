defmodule WerewolfApi.Conversation.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field(:body, :string)
    field(:bot, :boolean, default: false)
    field(:type, :string)
    belongs_to(:user, WerewolfApi.User)
    belongs_to(:conversation, WerewolfApi.Conversation)

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body, :bot, :type])
    |> validate_required([:body])
  end

  def username(%{bot: true} = message) do
    "Narrator"
  end

  def username(message) do
    WerewolfApi.User.display_name(message.user)
  end
end
