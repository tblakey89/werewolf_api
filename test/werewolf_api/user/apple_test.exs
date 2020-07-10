defmodule WerewolfApi.User.AppleTest do
  use ExUnit.Case
  import WerewolfApi.Factory
  alias WerewolfApi.User

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(WerewolfApi.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(WerewolfApi.Repo, {:shared, self()})
  end

  describe "create_or_update_from_map/2" do
    test "when user in apple map's email exists" do
      email = "test@email.com"
      user = insert(:user, email: email)

      apple_user_map = %{
        "email" => email,
        "given_name" => "apple_test",
        "family_name" => "apple_testerson"
      }

      sub = "1234"

      updated_user = User.Apple.create_or_update_from_map(sub, apple_user_map)
      assert user.id == updated_user.id
      assert updated_user.first_name == apple_user_map["given_name"]
      assert updated_user.last_name == apple_user_map["family_name"]
      assert updated_user.apple_id == sub
    end

    test "when user in apple map does not exist" do
      apple_user_map = %{
        "email" => "test@email.com",
        "given_name" => "apple_test",
        "family_name" => "apple_testerson"
      }

      sub = "1234"

      user = User.Apple.create_or_update_from_map(sub, apple_user_map)
      assert user.email == apple_user_map["email"]
      assert user.first_name == apple_user_map["given_name"]
      assert user.last_name == apple_user_map["family_name"]
      assert user.apple_id == sub
    end
  end
end
