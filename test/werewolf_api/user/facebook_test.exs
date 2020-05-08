defmodule WerewolfApi.User.FacebookTest do
  use ExUnit.Case
  import WerewolfApi.Factory
  alias WerewolfApi.User

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(WerewolfApi.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(WerewolfApi.Repo, {:shared, self()})
  end

  describe "create_or_update_from_map/1" do
    test "when user in facebook map's email exists" do
      email = "test@email.com"
      user = insert(:user, email: email)

      facebook_user_map = %{
        "email" => email,
        "first_name" => "facebook_test",
        "last_name" => "facebook_testerson",
        "id" => "1234567",
        "name" => "facebook_username"
      }

      updated_user = User.Facebook.create_or_update_from_map(facebook_user_map)
      assert user.id == updated_user.id
      assert updated_user.first_name == facebook_user_map["first_name"]
      assert updated_user.last_name == facebook_user_map["last_name"]
      assert updated_user.facebook_display_name == facebook_user_map["name"]
      assert updated_user.facebook_id == facebook_user_map["id"]
    end
  end
end
