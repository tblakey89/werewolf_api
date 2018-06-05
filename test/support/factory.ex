defmodule WerewolfApi.Factory do
  use ExMachina.Ecto, repo: WerewolfApi.Repo
  use WerewolfApi.UserFactory
  use WerewolfApi.ConversationFactory
  use WerewolfApi.MessageFactory
end
