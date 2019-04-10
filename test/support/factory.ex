defmodule WerewolfApi.Factory do
  use ExMachina.Ecto, repo: WerewolfApi.Repo
  use WerewolfApi.UserFactory
  use WerewolfApi.ConversationFactory
  use WerewolfApi.MessageFactory
  use WerewolfApi.GameFactory
  use WerewolfApi.UsersGameFactory
  use WerewolfApi.UsersConversationFactory
end
