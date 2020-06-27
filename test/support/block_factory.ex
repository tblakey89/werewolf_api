defmodule WerewolfApi.BlockFactory do
  defmacro __using__(_opts) do
    quote do
      def block_factory do
        %WerewolfApi.User.Block{
          user: build(:user),
          blocked_user: build(:user)
        }
      end
    end
  end
end
