defmodule WerewolfApi.UsersGameFactory do
  defmacro __using__(_opts) do
    quote do
      def users_game_factory do
        %WerewolfApi.UsersGame{
          user: build(:user),
          game: build(:game)
        }
      end
    end
  end
end
