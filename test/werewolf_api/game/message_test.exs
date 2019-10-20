defmodule WerewolfApi.Game.MessageTest do
  use ExUnit.Case
  import WerewolfApi.Factory
  alias WerewolfApi.Game.Message
  alias WerewolfApi.Repo

  describe "username/1" do
    test "when message from bot" do
      message = build(:message, bot: true)

      username = Message.username(message)

      assert username == "Narrator"
    end

    test "when message from user" do
      message = build(:message)

      username = Message.username(message)

      assert username == message.user.username
    end
  end
end
