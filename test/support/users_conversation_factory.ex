defmodule WerewolfApi.UsersConversationFactory do
  defmacro __using__(_opts) do
    quote do
      def users_conversation_factory do
        %WerewolfApi.UsersConversation{
          user: build(:user),
          conversation: build(:conversation),
          last_read_at: DateTime.utc_now()
        }
      end
    end
  end
end
