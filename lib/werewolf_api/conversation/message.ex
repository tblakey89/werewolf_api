defmodule WerewolfApi.Conversation.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field(:body, :string)
    field(:bot, :boolean, default: false)
    belongs_to(:user, WerewolfApi.User)
    belongs_to(:conversation, WerewolfApi.Conversation)

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body])
    |> validate_required([:body])
  end

  def username(%{bot: true} = message) do
    "bot"
  end

  def username(message) do
    message.user.username
  end
end
