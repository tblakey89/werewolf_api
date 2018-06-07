defmodule WerewolfApi.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field(:body, :string)
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
end
