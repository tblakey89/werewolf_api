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
  def changeset(message, attrs, user) do
    # use current user to generate message
    message
    |> cast(attrs, [:user_id, :body])
    |> validate_required([:user_id, :body])
  end
end
