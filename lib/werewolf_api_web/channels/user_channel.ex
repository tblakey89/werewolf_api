defmodule WerewolfApiWeb.UserChannel do
  use Phoenix.Channel

  def join("user:" <> user_id, _message, socket) do
    case Guardian.Phoenix.Socket.current_resource(socket).id == String.to_integer(user_id) do
      true -> {:ok, socket}
      false -> {:error, %{reason: "unauthorized"}}
    end
  end
end
