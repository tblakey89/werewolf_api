defmodule WerewolfApi.ConversationTest do
  use ExUnit.Case
  import WerewolfApi.Factory
  alias WerewolfApi.Conversation
  alias WerewolfApi.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(WerewolfApi.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(WerewolfApi.Repo, {:shared, self()})
    user = insert(:user)
    user_one = insert(:user)
    user_two = insert(:user)
    {:ok, user: user, user_one: user_one, user_two: user_two}
  end

  describe "find_or_create/2" do
    test "when conversation does not exist", %{user: user, user_one: user_one, user_two: user_two} do
      attrs = %{"user_ids" => [user_one.id, user_two.id]}
      {:ok, conversation} = Conversation.find_or_create(attrs, user)
      assert conversation.id
    end

    test "when conversation exists", %{user: user, user_one: user_one, user_two: user_two} do
      conversation = insert(:conversation, users: [user, user_one, user_two])
      attrs = %{"user_ids" => [user_one.id, user_two.id]}
      {:ok, found_conversation} = Conversation.find_or_create(attrs, user)
      assert conversation.id == found_conversation.id
    end
  end

  describe "find_or_create/1" do
    test "when conversation does not exist", %{user: user, user_one: user_one, user_two: user_two} do
      attrs = %{"user_ids" => [user.id, user_one.id, user_two.id]}
      {:ok, conversation} = Conversation.find_or_create(attrs)
      assert conversation.id
    end

    test "when conversation exists", %{user: user, user_one: user_one, user_two: user_two} do
      conversation = insert(:conversation, users: [user, user_one, user_two])
      attrs = %{"user_ids" => [user.id, user_one.id, user_two.id]}
      {:ok, found_conversation} = Conversation.find_or_create(attrs)
      assert conversation.id == found_conversation.id
    end

    test "when given empty list", %{} do
      attrs = %{"user_ids" => []}
      assert :error = Conversation.find_or_create(attrs)
    end

    test "when given list of one", %{user: user} do
      attrs = %{"user_ids" => [user.id]}
      assert :error = Conversation.find_or_create(attrs)
    end
  end
end
