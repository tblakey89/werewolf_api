defmodule WerewolfApi.User.GoogleTest do
  use ExUnit.Case
  import WerewolfApi.Factory
  alias WerewolfApi.User

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(WerewolfApi.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(WerewolfApi.Repo, {:shared, self()})
  end

  describe "create_or_update_from_map/1" do
    test "when user in google map's email exists" do
      email = "test@email.com"
      user = insert(:user, email: email)

      google_user_map = %{
        "email" => email,
        "given_name" => "google_test",
        "family_name" => "google_testerson",
        "sub" => "1234567",
        "name" => "google_username"
      }

      updated_user = WerewolfApi.User.Google.create_or_update_from_map(google_user_map)
      assert user.id == updated_user.id
      assert updated_user.first_name == google_user_map["given_name"]
      assert updated_user.last_name == google_user_map["family_name"]
      assert updated_user.google_display_name == google_user_map["name"]
      assert updated_user.google_id == google_user_map["sub"]
    end
  end
end
