defmodule WerewolfApi.User.Report do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reports" do
    belongs_to(:user, WerewolfApi.User)
    belongs_to(:reported_user, WerewolfApi.User)
    field(:body, :string)

    timestamps()
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, [:user_id, :reported_user_id, :body])
    |> validate_required([:user_id, :reported_user_id, :body])
  end
end
