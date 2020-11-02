defmodule Mix.Tasks.UpdateLastMessageAt do
  use Mix.Task
  alias WerewolfApi.Repo
  alias WerewolfApi.UsersGame
  alias Ecto.Changeset

  @shortdoc "Updates last message at."
  def run(_) do
    Mix.Task.run("app.start")

    Repo.all(UsersGame)
    |> Enum.each(fn users_game ->
      last_read_at_map =
        users_game.last_read_at_map
        |> Map.put("standard", DateTime.to_unix(users_game.last_read_at, :millisecond))

      users_game
      |> Changeset.change(last_read_at_map: last_read_at_map)
      |> Repo.update()
    end)
  end
end
