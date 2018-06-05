defmodule WerewolfApi.ConversationFactory do
  defmacro __using__(_opts) do
    quote do
      def conversation_factory do
        %WerewolfApi.Conversation{
          name: "Test",
          last_message_at: DateTime.utc_now(),
          users: build_list(2, :user)
        }
      end
    end
  end
end
