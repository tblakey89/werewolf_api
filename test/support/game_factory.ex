defmodule WerewolfApi.GameFactory do
  defmacro __using__(_opts) do
    quote do
      def game_factory do
        %WerewolfApi.Game{
          name: "Test game",
          complete: false
        }
      end
    end
  end
end
