defmodule WerewolfApi.MessageFactory do
  defmacro __using__(_opts) do
    quote do
      def message_factory do
        %WerewolfApi.Conversation.Message{
          body: "Test message",
          user: build(:user),
          conversation: build(:conversation)
        }
      end
    end
  end
end
