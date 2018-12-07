defmodule WerewolfApiWeb.GameChannel do
  use Phoenix.Channel
  alias WerewolfApi.Repo
  alias WerewolfApi.GameMessage
  alias WerewolfApi.GameServer
  alias WerewolfApiWeb.UserChannel

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

  def handle_in("launch_game", params, socket) do
    user = Guardian.Phoenix.Socket.current_resource(socket)
    game_id = socket.assigns.game_id
    case GameServer.launch_game(game_id, user) do
      :ok ->
        state = GameServer.get_state(game_id)
        UserChannel.broadcast_state_update(game_id, state, user)
        {:reply, :ok, socket}
      {:error, message} ->
        {:reply, {:error, %{errors: message}}, socket}
    end
  end
end
