defmodule WerewolfApiWeb.GameChannel do
  use Phoenix.Channel
  alias WerewolfApi.Repo
  alias WerewolfApi.GameMessage

  # to save state of the game, save the returned state from the GameServer
  # when it replies (in a task, success is optional)
  # to restore a game which the DB says should exist, create new game, with
  # state sent on GameSupervisor.start_game
  # for new game, send no state

  # when doing action
  # check if Game exists
  # if does not exist, rebuild with state in DB
  # send game action
  # on reply, save updated state in task

  # 1) save state after game creation?
  # 2) do first action
  # ...

  # Registry.whereis_name({Registry.GameServer, game.if})
  # via = Werewolf.GameServer.via_tuple(game.id)
  # via is used to call the GameServer to do various stuff
  # Registry.whereis_name({Registry.GameServer, game.id}) is all
  # need to confirm PID exists
  # or use this: Werewolf.GameSupervisor.pid_from_name(game.id)

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

  def broadcast_state_update(game_id, state) do
    WerewolfApiWeb.Endpoint.broadcast(
      "game:#{game_id}",
      "state_update",
      WerewolfApiWeb.GameView.render("state.json", %{
        state: state,
        game_id: game_id
      })
    )
  end
end
