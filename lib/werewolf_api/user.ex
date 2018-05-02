defmodule WerewolfApi.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias WerewolfApi.User

  schema "users" do
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:username, :string)
    field(:forgotten_password_token, :string)
    field(:forgotten_token_generated_at, :utc_datetime)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password])
    |> validate_required([:username, :email, :password])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  def registration_changeset(%User{} = user, attrs \\ %{}) do
    user
    |> changeset(attrs)
    |> cast(attrs, ~w(password), [])
    |> validate_length(:password, min: 8, max: 100)
    |> put_password_hash()
  end

  def forgotten_password_changeset(%User{} = user) do
    user
    |> change(%{
      forgotten_password_token: forgotten_password_token(),
      forgotten_token_generated_at: NaiveDateTime.utc_now()
    })
  end

  def update_password_changeset(%User{} = user, attrs) do
    user
    |> change(%{forgotten_password_token: nil, forgotten_token_generated_at: nil})
    |> cast(attrs, ~w(password), [])
    |> validate_length(:password, min: 8, max: 100)
    |> put_password_hash()
  end

  def clear_forgotten_password_changeset(%User{} = user) do
    user
    |> change(%{
      forgotten_password_token: nil,
      forgotten_token_generated_at: nil
    })
  end

  def check_token_valid(user) do
    token_expiry = DateTime.to_unix(user.forgotten_token_generated_at) + 60 * 60 * 24

    case DateTime.to_unix(DateTime.utc_now()) > token_expiry do
      true -> {:error, :expired_token, user}
      false -> :ok
    end
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(password))

      _ ->
        changeset
    end
  end

  defp forgotten_password_token do
    :crypto.strong_rand_bytes(20)
    |> Base.url_encode64()
    |> binary_part(0, 20)
  end
end
