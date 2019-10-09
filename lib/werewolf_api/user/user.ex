defmodule WerewolfApi.User do
  use Ecto.Schema
  use Arc.Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias WerewolfApi.User
  alias WerewolfApi.Repo

  schema "users" do
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:username, :string)
    field(:google_id, :string)
    field(:google_display_name, :string)
    field(:facebook_id, :string)
    field(:facebook_display_name, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:forgotten_password_token, :string)
    field(:forgotten_token_generated_at, :utc_datetime)
    field(:avatar, WerewolfApi.Avatar.Type)
    field(:fcm_token, :string)
    many_to_many(:conversations, WerewolfApi.Conversation, join_through: "users_conversations")
    many_to_many(:games, WerewolfApi.Game, join_through: "users_games")
    has_many(:users_games, WerewolfApi.UsersGame)
    has_many(:messages, WerewolfApi.Conversation.Message)
    has_many(:game_messages, WerewolfApi.Game.Message)
    has_many(:friendships, User.Friend)
    has_many(:reverse_friendships, User.Friend, foreign_key: :friend_id)

    many_to_many(
      :friends,
      User,
      join_through: "friends",
      join_keys: [user_id: :id, friend_id: :id]
    )

    timestamps()
  end

  def display_name(user) do
    user.username || "#{user.first_name} #{user.last_name}"
  end

  def find_by_user_ids(nil), do: []

  def find_by_user_ids(user_ids) do
    Repo.all(from(u in User, where: u.id in ^user_ids))
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

  def google_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :google_id, :google_display_name])
    |> cast_attachments(attrs, [:avatar])
    |> validate_required([:first_name, :last_name, :email, :google_id, :google_display_name])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  def update_google_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :google_id, :google_display_name])
    |> validate_required([:first_name, :last_name, :google_id, :google_display_name])
  end

  def facebook_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :facebook_id, :facebook_display_name])
    |> cast_attachments(attrs, [:avatar])
    |> validate_required([:first_name, :last_name, :email, :facebook_id, :facebook_display_name])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  def update_facebook_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :facebook_id, :facebook_display_name])
    |> validate_required([:first_name, :last_name, :facebook_id, :facebook_display_name])
  end

  def registration_changeset(%User{} = user, attrs \\ %{}) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password], [])
    |> validate_length(:password, min: 8, max: 100)
    |> put_password_hash()
  end

  def update_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [], [])
    |> optional_password_update(attrs)
  end

  def forgotten_password_changeset(%User{} = user) do
    user
    |> change(%{
      forgotten_password_token: forgotten_password_token(),
      forgotten_token_generated_at: DateTime.truncate(DateTime.utc_now(), :second)
    })
  end

  def update_password_changeset(%User{} = user, attrs) do
    user
    |> change(%{forgotten_password_token: nil, forgotten_token_generated_at: nil})
    |> cast(attrs, [:password], [])
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

  def update_fcm_token_changeset(%User{} = user, fcm_token) do
    user
    |> change(%{
      fcm_token: fcm_token
    })
  end

  def avatar_changeset(%User{} = user, attrs) do
    user
    |> cast_attachments(attrs, [:avatar])
    |> validate_required([:avatar])
  end

  def check_token_valid(user) do
    token_expiry = DateTime.to_unix(user.forgotten_token_generated_at) + 60 * 60 * 24

    case DateTime.to_unix(DateTime.utc_now()) > token_expiry do
      true -> {:error, :expired_token, user}
      false -> :ok
    end
  end

  def valid_fcm_tokens(users, exclude_user_id) do
    Enum.reduce(users, [], fn user, accumulator ->
      cond do
        user.id == exclude_user_id ->
          accumulator

        user.fcm_token == nil ->
          accumulator

        true ->
          [user.fcm_token | accumulator]
      end
    end)
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(password))

      _ ->
        changeset
    end
  end

  defp optional_password_update(changeset, attrs) do
    case attrs[:password] do
      nil ->
        changeset

      "" ->
        changeset

      password ->
        cast(changeset, attrs, [:password], [])
        |> validate_length(:password, min: 8, max: 100)
        |> put_password_hash()
    end
  end

  defp forgotten_password_token do
    :crypto.strong_rand_bytes(20)
    |> Base.url_encode64()
    |> binary_part(0, 20)
  end
end
