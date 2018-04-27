defmodule WerewolfApi.Guardian do
  use Guardian, otp_app: :werewolf_api

  alias WerewolfApi.Repo
  alias WerewolfApi.User

  # session controller for logging in and out
  # forgotten password and new password in a password controller

  def subject_for_token(resource, _claims) do
    sub = to_string(resource.id)
    {:ok, sub}
  end
  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    resource = Repo.get(User, id)
    {:ok,  resource}
  end
  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end
end
