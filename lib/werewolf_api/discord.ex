defmodule WerewolfApi.Discord do
  def new_game(game) do
    Task.start_link(fn ->
      request_body = Poison.encode!(%{
        "content" => "A new game of Werewolf has been created, join here: #{game.invitation_url}"
      })

      request_header = %{"Content-Type" => "application/json"}

      {:ok, %HTTPoison.Response{body: body}} = HTTPoison.post(game_webhook(), request_body, request_header)
    end)
  end

  defp game_webhook, do: Application.get_env(:werewolf_api, :discord)[:game_url]
end
