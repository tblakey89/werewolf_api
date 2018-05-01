defmodule WerewolfApi.Factory do
  use ExMachina.Ecto, repo: WerewolfApi.Repo
  use WerewolfApi.UserFactory
end
