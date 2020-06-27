defmodule WerewolfApiWeb.UserView do
  use WerewolfApiWeb, :view
  alias WerewolfApi.User

  def render("show.json", %{user: user}) do
    %{
      user: render_one(user, WerewolfApiWeb.UserView, "user.json")
    }
  end

  def render("index.json", %{users: users}) do
    %{
      users: render_many(users, WerewolfApiWeb.UserView, "user.json")
    }
  end

  def render("me.json", %{user: user}) do
    %{
      user: render_one(user, WerewolfApiWeb.UserView, "user_and_associations.json")
    }
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      email: user.email,
      username: User.display_name(user),
      avatar: WerewolfApi.Avatar.url({user.avatar, user}, :thumb, signed: true)
    }
  end

  def render("user_and_associations.json", %{user: user}) do
    %{
      id: user.id,
      email: user.email,
      username: User.display_name(user),
      avatar: WerewolfApi.Avatar.url({user.avatar, user}, :thumb),
      blocks:
        render_many(
          user.blocks,
          WerewolfApiWeb.BlockView,
          "block.json"
        ),
      friendships:
        render_many(
          user.friendships ++ user.reverse_friendships,
          WerewolfApiWeb.FriendView,
          "friendship.json"
        ),
      conversations:
        render_many(
          user.conversations,
          WerewolfApiWeb.ConversationView,
          "conversation_with_messages.json"
        ),
      games:
        render_many(
          Enum.map(user.games, fn game ->
            %{game: game, user: user, state: WerewolfApi.Game.current_state(game)}
          end),
          WerewolfApiWeb.GameView,
          "game_with_state.json",
          as: :data
        )
    }
  end

  def render("simple_user.json", %{user: user}) do
    %{
      id: user.id,
      username: User.display_name(user),
      avatar: WerewolfApi.Avatar.url({user.avatar, user}, :thumb)
    }
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end

  def render("error.json", %{message: message}) do
    %{error: message}
  end
end
