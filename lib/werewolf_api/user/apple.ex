defmodule WerewolfApi.User.Apple do
  alias WerewolfApi.Repo
  alias WerewolfApi.User

  def create_or_update_from_map(sub, apple_user_map) do
    case Repo.get_by(User, email: apple_user_map["email"]) do
      nil -> create_from_map(sub, apple_user_map)
      user -> update_from_map(user, sub, apple_user_map)
    end
  end

  defp create_from_map(sub, apple_user_map) do
    {:ok, user} =
      User.apple_changeset(%User{}, map_for_insertion(sub, apple_user_map))
      |> Repo.insert()

    user
  end

  defp update_from_map(user, sub, apple_user_map) do
    {:ok, user} =
      User.update_apple_changeset(user, map_for_update(user, sub, apple_user_map))
      |> Repo.update()

    user
  end

  defp map_for_insertion(sub, apple_user_map) do
    %{
      first_name: apple_user_map["given_name"],
      last_name: apple_user_map["family_name"],
      email: apple_user_map["email"],
      apple_id: sub
    }
  end

  defp map_for_update(user, sub, apple_user_map) do
    %{
      first_name: user.first_name || apple_user_map["given_name"],
      last_name: user.last_name || apple_user_map["family_name"],
      apple_id: sub
    }
  end
end
