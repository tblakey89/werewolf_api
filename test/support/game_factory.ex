defmodule WerewolfApi.GameFactory do
  defmacro __using__(_opts) do
    quote do
      def game_factory do
        %WerewolfApi.Game{
          name: "Test game",
          invitation_token: WerewolfApi.Game.generate_game_token()
        }
      end
    end
  end
end
