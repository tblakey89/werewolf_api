defmodule WerewolfApiWeb.FriendView do
  use WerewolfApiWeb, :view
  alias WerewolfApi.User.Friend

  def render("success.json", %{friend: %Friend{state: "pending"} = friendship}) do
    %{success: "Friend request sent", friend_id: friendship.friend_id}
  end

  def render("success.json", %{friend: %Friend{state: "accepted"} = friendship}) do
    %{success: "Friend request accepted", friend_id: friendship.friend_id}
  end

  def render("success.json", %{friend: %Friend{state: "rejected"} = friendship}) do
    %{success: "Rejected the friend request", friend_id: friendship.friend_id}
  end

  def render("friendship.json", %{friend: friendship}) do
    %{
      id: friendship.id,
      state: friendship.state,
      created_at:
        DateTime.to_unix(DateTime.from_naive!(friendship.inserted_at, "Etc/UTC"), :millisecond),
      user: render_one(friendship.user, WerewolfApiWeb.UserView, "simple_user.json"),
      friend: render_one(friendship.friend, WerewolfApiWeb.UserView, "simple_user.json")
    }
  end

  def render("error.json", %{message: message}) do
    %{error: message}
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end
end
