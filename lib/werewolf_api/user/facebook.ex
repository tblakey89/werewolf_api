defmodule WerewolfApi.User.Facebook do
  alias WerewolfApi.Repo
  alias WerewolfApi.User

  def create_or_update_from_map(facebook_user_map) do
    case Repo.get_by(User, email: facebook_user_map["email"]) do
      nil -> create_from_map(facebook_user_map)
      user -> update_from_map(user, facebook_user_map)
    end
  end

  defp create_from_map(facebook_user_map) do
    {:ok, user} =
      User.facebook_changeset(%User{}, map_for_insertion(facebook_user_map))
      |> Repo.insert()

    {:ok, user} =
      User.avatar_changeset(user, %{
        avatar: build_upload_struct(facebook_user_map["picture"]["data"]["url"])
      })
      |> Repo.update()

    user
  end

  defp update_from_map(user, facebook_user_map) do
    {:ok, user} =
      User.update_facebook_changeset(user, map_for_update(user, facebook_user_map))
      |> Repo.update()

    user
  end

  defp map_for_insertion(facebook_user_map) do
    %{
      first_name: facebook_user_map["first_name"],
      last_name: facebook_user_map["last_name"],
      email: facebook_user_map["email"],
      facebook_id: facebook_user_map["id"],
      facebook_display_name: facebook_user_map["name"]
    }
  end

  defp map_for_update(user, facebook_user_map) do
    %{
      first_name: user.first_name || facebook_user_map["first_name"],
      last_name: user.last_name || facebook_user_map["last_name"],
      facebook_id: facebook_user_map["id"],
      facebook_display_name: facebook_user_map["name"]
    }
  end

  defp build_upload_struct(nil), do: nil

  defp build_upload_struct(avatar_url) do
    %HTTPoison.Response{body: body, headers: headers} = HTTPoison.get!(avatar_url)
    content_type = Enum.into(headers, %{})["Content-Type"]
    file_name = Enum.random(0..10_000_000)

    case content_type do
      "image/jpeg" ->
        %{__struct__: Plug.Upload, binary: body, filename: "#{file_name}.jpg"}

      "image/png" ->
        %{__struct__: Plug.Upload, binary: body, filename: "#{file_name}.png"}
    end
  end
end
