defmodule WerewolfApi.User.BlockTest do
  use ExUnit.Case
  import WerewolfApi.Factory
  alias WerewolfApi.User.Block

  describe "blocked_user?/2" do
    test "when contains one id which matches the blocked id" do
      block = build(:block)
      block2 = build(:block)

      assert Block.blocked_user?([block, block2], block.blocked_user_id) == true
    end

    test "when contains no id which matches the blocked id" do
      block = build(:block)
      block2 = build(:block)

      assert Block.blocked_user?([block, block2], 0) == false
    end
  end
end
