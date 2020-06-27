defmodule WerewolfApi.UserFactory do
  defmacro __using__(_opts) do
    quote do
      def user_factory do
        %WerewolfApi.User{
          email: sequence(:email, &"test#{&1}@test.com"),
          username: sequence(:username, &"test#{&1}"),
          password: "testtest",
          password_hash: Comeonin.Bcrypt.hashpwsalt("testtest"),
          blocks: []
        }
      end
    end
  end
end
