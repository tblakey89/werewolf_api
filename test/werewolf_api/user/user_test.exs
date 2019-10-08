defmodule WerewolfApi.User.UserTest do
  use ExUnit.Case
  import WerewolfApi.Factory
  alias WerewolfApi.User

  describe "valid_fcm_tokens/2" do
    test "when two users, one has token, one not" do
      user = build(:user, id: 1, fcm_token: "test")
      user2 = build(:user, id: 2)

      tokens = User.valid_fcm_tokens([user, user2], nil)
      assert tokens == [user.fcm_token]
    end

    test "when two users, one has token, one not, but user excluded" do
      user = build(:user, id: 1, fcm_token: "test")
      user2 = build(:user, id: 2)

      tokens = User.valid_fcm_tokens([user, user2], user.id)
      assert tokens == []
    end

    test "when two users, none with fcm_token" do
      user = build(:user, id: 1)
      user2 = build(:user, id: 2)

      tokens = User.valid_fcm_tokens([user, user2], nil)
      assert tokens == []
    end
  end
end
