defmodule WerewolfApi.Game.ScheduledTest do
  use ExUnit.Case
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  import Ecto.Query
  import Mox
  alias WerewolfApi.Game.Scheduled
  alias WerewolfApi.Game

  describe "setup/2" do
    test "creates game" do
      DynamicLinkBehaviourMock
      |> expect(:new_link, fn x -> x end)

      Scheduled.setup(2, "five_minute")

      scheduled_game = WerewolfApi.Repo.one(from(g in Game, order_by: [desc: g.id], limit: 1))

      assert Enum.count(scheduled_game.state["game"]["players"]) == 0
      assert scheduled_game.state["game"]["phase_length"] == "five_minute"

      assert_in_delta(
        DateTime.to_unix(scheduled_game.start_at),
        DateTime.to_unix(DateTime.from_naive!(scheduled_game.inserted_at, "Etc/UTC")) + 7200,
        2
      )
    end
  end
end
