defmodule WerewolfApi.Guardian do
  use Guardian, otp_app: :werewolf_api

  alias WerewolfApi.Repo
  alias WerewolfApi.User

  def subject_for_token(resource, _claims) do
    sub = to_string(resource.id)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    resource = Repo.get(User, id)
    {:ok, resource}
  end
end
