defmodule WerewolfApiWeb.GameChannel do
  use Phoenix.Channel
  alias WerewolfApi.Repo
  alias WerewolfApi.Notification
  alias WerewolfApi.Game.Message
  alias WerewolfApi.Game.Server
  alias WerewolfApi.UsersGame
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
    changeset =
      Guardian.Phoenix.Socket.current_resource(socket)
      |> Ecto.build_assoc(:game_messages, game_id: socket.assigns.game_id)
      |> Message.changeset(params)

    case Repo.insert(changeset) do
      {:ok, game_message} ->
        game_message = Repo.preload(game_message, :user)

        broadcast!(
          socket,
          "new_message",
          WerewolfApiWeb.GameMessageView.render("game_message.json", %{game_message: game_message})
        )

        Notification.new_game_message(game_message)

        update_last_read_at(socket, params["message"]["destination"] || "standard")
        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  def handle_in("launch_game", params, socket) do
    user = Guardian.Phoenix.Socket.current_resource(socket)
    game_id = socket.assigns.game_id

    Server.launch_game(game_id, user)
    |> handle_game_response(socket, game_id, user)
  end

  def handle_in("action", params, socket) do
    user = Guardian.Phoenix.Socket.current_resource(socket)
    game_id = socket.assigns.game_id

    Server.action(game_id, user, params["target"], String.to_atom(params["action_type"]))
    |> handle_game_response(socket, game_id, user)
  end

  def handle_in("claim_role", params, socket) do
    user = Guardian.Phoenix.Socket.current_resource(socket)
    game_id = socket.assigns.game_id

    Server.claim_role(game_id, user, params["claim"])
    |> handle_game_response(socket, game_id, user)
  end

  def handle_in("read_game", params, socket) do
    update_last_read_at(socket, params["destination"] || "standard")
    {:reply, :ok, socket}
  end

  def handle_in("request_state_update", params, socket) do
    user = Guardian.Phoenix.Socket.current_resource(socket)
    game_id = socket.assigns.game_id
    {:ok, state} = WerewolfApi.Game.Server.get_state(game_id)
    WerewolfApiWeb.UserChannel.broadcast_state_update_to_user(user, game_id, state)

    {:reply, :ok, socket}
  end

  def handle_in("request_game_update", params, socket) do
    user = Guardian.Phoenix.Socket.current_resource(socket)
    game_id = socket.assigns.game_id
    WerewolfApiWeb.UserChannel.broadcast_game_update_to_user(game_id, user)

    {:reply, :ok, socket}
  end

  defp handle_game_response(response, socket, game_id, user) do
    case response do
      :ok ->
        {:reply, :ok, socket}

      {:error, message} ->
        {:reply, {:error, %{errors: message}}, socket}
    end
  end

  defp update_last_read_at(socket, destination) do
    WerewolfApi.UsersGame.update_last_read_at(
      Guardian.Phoenix.Socket.current_resource(socket).id,
      socket.assigns.game_id
    )

    WerewolfApi.UsersGame.update_last_read_at_map(
      Guardian.Phoenix.Socket.current_resource(socket).id,
      socket.assigns.game_id,
      destination
    )
  end
end
