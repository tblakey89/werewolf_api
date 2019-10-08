defmodule WerewolfApi.User.Google do
  alias WerewolfApi.Repo
  alias WerewolfApi.User

  def create_or_update_from_map(google_user_map) do
    case Repo.get_by(User, email: google_user_map["email"]) do
      nil -> create_from_map(google_user_map)
      user -> update_from_map(user, google_user_map)
    end
  end

  defp create_from_map(google_user_map) do
    {:ok, user} =
      User.google_changeset(%User{}, map_for_insertion(google_user_map))
      |> Repo.insert

    user
  end

  defp update_from_map(user, google_user_map) do
    {:ok, user} =
      User.update_google_changeset(user, map_for_update(user, google_user_map))
      |> Repo.update

    user
  end

  defp map_for_insertion(google_user_map) do
    %{
      first_name: google_user_map["given_name"],
      last_name: google_user_map["family_name"],
      email: google_user_map["email"],
      google_id: google_user_map["sub"],
      google_display_name: google_user_map["name"],
      avatar: build_upload_struct(google_user_map["picture"])
    }
  end

  defp map_for_update(user, google_user_map) do
    %{
      first_name: user.first_name || google_user_map["given_name"],
      last_name: user.last_name || google_user_map["family_name"],
      google_id: google_user_map["sub"],
      google_display_name: google_user_map["name"]
    }
  end

  defp build_upload_struct(nil), do: nil
  defp build_upload_struct(avatar_url) do
    %HTTPoison.Response{body: body, headers: headers} = HTTPoison.get!(avatar_url)
    content_type = Enum.into(headers, %{})["Content-Type"]
    file_name = Enum.random(0..10000000)

    case content_type do
      "image/jpeg" ->
        %{__struct__: Plug.Upload, binary: body, filename: "#{file_name}.jpg"}
      "image/png" ->
        %{__struct__: Plug.Upload, binary: body, filename: "#{file_name}.png"}
    end
  end
end
