defmodule WerewolfApiWeb.GameChannel do
  use Phoenix.Channel
  alias WerewolfApi.Repo
  alias WerewolfApi.GameMessage

  def join("game:" <> game_id, _message, socket) do
    game =
      Guardian.Phoenix.Socket.current_resource(socket)
      |> Ecto.assoc(:games)
      |> Repo.get(String.to_integer(game_id))

    case game do
      nil -> {:error, %{reason: "unauthorized"}}
      game -> {:ok, assign(socket, :game_id, game.id)}
    end
  end

  def handle_in("new_message", params, socket) do
    # need to work out way to handle unread messages
    changeset =
      Guardian.Phoenix.Socket.current_resource(socket)
      |> Ecto.build_assoc(:game_messages, game_id: socket.assigns.game_id)
      |> GameMessage.changeset(params)

    case Repo.insert(changeset) do
      {:ok, game_message} ->
        game_message = Repo.preload(game_message, :user)

        broadcast!(
          socket,
          "new_message",
          WerewolfApiWeb.GameMessageView.render("game_message.json", %{game_message: game_message})
        )

        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  def broadcast_game_update(game) do
    game = Repo.preload(game, users_games: :user, game_messages: :user)

    WerewolfApiWeb.Endpoint.broadcast(
      "game:#{game.id}",
      "game_update",
      WerewolfApiWeb.GameView.render("game.json", %{
        game: game
      })
    )
  end

  def broadcast_state_update(game_id, state, user) do
    WerewolfApiWeb.Endpoint.broadcast(
      "game:#{game_id}",
      "state_update",
      WerewolfApiWeb.GameView.render("state.json", %{
        data: %{
          state: state,
          game_id: game_id,
          user: user
        }
      })
    )
  end
end
