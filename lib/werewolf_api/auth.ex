defmodule WerewolfApi.Auth do
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias WerewolfApi.Repo
  alias WerewolfApi.User

  def find_and_confirm_password(email, password) do
    case Repo.get_by(User, email: email) do
      nil ->
        dummy_checkpw()
        {:error, :not_found}

      user ->
        if checkpw(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :unauthorized}
        end
    end
  end
end
