defmodule WerewolfApi.FriendFactory do
  defmacro __using__(_opts) do
    quote do
      def friend_factory do
        %WerewolfApi.User.Friend{
          user: build(:user),
          friend: build(:user)
        }
      end
    end
  end
end
