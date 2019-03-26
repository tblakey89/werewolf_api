defmodule WerewolfApiWeb.GameChannelTest do
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  alias WerewolfApi.Repo
  alias WerewolfApi.GameMessage

  setup do
    user = insert(:user)
    game = insert(:game)
    insert(:users_game, user: user, game: game)
    {:ok, jwt, _} = encode_and_sign(user)
    {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
    {:ok, _, socket} = subscribe_and_join(socket, "game:#{game.id}", %{})

    {:ok, socket: socket, game: game, user: user}
  end

  describe "join channel" do
    test "unable to join channel when user not in game", %{socket: socket} do
      other_game = insert(:game)

      assert {:error, %{reason: "unauthorized"}} ==
               subscribe_and_join(socket, "game:#{other_game.id}", %{})
    end
  end

  describe "new_message event" do
    test "new_message broadcasts new game message", %{socket: socket} do
      sent_message = "Hello there!"
      ref = push(socket, "new_message", %{"body" => sent_message})
      assert_broadcast("new_message", %{body: sent_message})
      assert_reply(ref, :ok)
      assert Repo.get_by(GameMessage, body: sent_message)
    end

    test "new_message fails to broadcast new message when invalid", %{socket: socket} do
      ref = push(socket, "new_message", %{})
      assert_reply(ref, :error)
    end
  end

  describe "launch_game event" do
    test "launch_game responds with ok on success" do
      user = insert(:user)
      game = insert(:game)
      game_id = game.id
      user_id = user.id
      insert(:users_game, user: user, game: game, state: "host")

      state = %{
        game: %Werewolf.Game{
          end_phase_unix_time: nil,
          id: game_id,
          phase_length: :day,
          phases: 0,
          players: %{
            user.id => %Werewolf.Player{
              actions: %{
                1 => %{
                  vote: %Werewolf.Action{
                    type: :vote,
                    target: 2,
                    option: :none
                  }
                }
              },
              alive: true,
              host: true,
              id: user.id,
              role: :none
            }
          }
        },
        rules: %Werewolf.Rules{state: :ready}
      }

      WerewolfApi.Game.update_state(game, state)

      {:ok, jwt, _} = encode_and_sign(user)
      {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
      {:ok, _, game_socket} = subscribe_and_join(socket, "game:#{game.id}", %{})
      {:ok, _, user_socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

      ref = push(game_socket, "launch_game", %{})

      assert_broadcast("game_state_update", %{
        id: ^game_id,
        players: %{^user_id => %{id: ^user_id}}
      })

      assert_reply(ref, :ok)
    end

    test "launch_game responds with error on failure" do
      user = insert(:user)
      game = insert(:game)
      game_id = game.id
      user_id = user.id

      state = %{
        game: %Werewolf.Game{
          end_phase_unix_time: 1000,
          id: 178,
          phase_length: :day,
          phases: 0,
          players: %{
            user.id => %Werewolf.Player{
              actions: %{
                1 => %{
                  vote: %Werewolf.Action{
                    type: :vote,
                    target: 2,
                    option: :none
                  }
                }
              },
              alive: true,
              host: true,
              id: user.id,
              role: :none
            }
          }
        },
        rules: %Werewolf.Rules{state: :initialised}
      }

      WerewolfApi.Game.update_state(game, state)

      insert(:users_game, user: user, game: game)
      {:ok, jwt, _} = encode_and_sign(user)
      {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
      {:ok, _, game_socket} = subscribe_and_join(socket, "game:#{game.id}", %{})
      {:ok, _, user_socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

      ref = push(game_socket, "launch_game", %{})

      refute_broadcast("game_state_update", %{
        id: ^game_id,
        players: %{^user_id => %{id: ^user_id}}
      })

      assert_reply(ref, :error)
    end

    test "launch_game not broadcast if invitation pending, user invite rejected" do
      user = insert(:user)
      game = insert(:game)
      game_id = game.id
      user_id = user.id
      insert(:users_game, user: user, game: game)

      state = %{
        game: %Werewolf.Game{
          end_phase_unix_time: nil,
          id: game_id,
          phase_length: :day,
          phases: 0,
          players: %{
            user.id => %Werewolf.Player{
              actions: %{
                1 => %{
                  vote: %Werewolf.Action{
                    type: :vote,
                    target: 2,
                    option: :none
                  }
                }
              },
              alive: true,
              host: true,
              id: user.id,
              role: :none
            }
          }
        },
        rules: %Werewolf.Rules{state: :ready}
      }

      WerewolfApi.Game.update_state(game, state)

      {:ok, jwt, _} = encode_and_sign(user)
      {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
      {:ok, _, game_socket} = subscribe_and_join(socket, "game:#{game.id}", %{})
      {:ok, _, user_socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

      ref = push(game_socket, "launch_game", %{})

      assert_broadcast("invitation_rejected", %{
        game_id: ^game_id
      })
    end
  end

  describe "action event" do
    test "action responds with ok on success" do
      user = insert(:user)
      other_id = user.id + 1
      game = insert(:game)
      game_id = game.id
      user_id = user.id

      state = %{
        game: %Werewolf.Game{
          end_phase_unix_time: 1000,
          id: game_id,
          phase_length: :day,
          phases: 2,
          players: %{
            user.id => %Werewolf.Player{
              actions: %{},
              alive: true,
              host: true,
              id: user.id,
              role: :villager
            },
            (user.id + 1) => %Werewolf.Player{
              actions: %{},
              alive: true,
              host: false,
              id: other_id,
              role: :villager
            }
          }
        },
        rules: %Werewolf.Rules{state: :day_phase}
      }

      WerewolfApi.Game.update_state(game, state)

      insert(:users_game, user: user, game: game)
      {:ok, jwt, _} = encode_and_sign(user)
      {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
      {:ok, _, game_socket} = subscribe_and_join(socket, "game:#{game.id}", %{})
      {:ok, _, user_socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

      ref = push(game_socket, "action", %{target: other_id, action_type: "vote"})

      assert_broadcast("game_state_update", %{
        id: ^game_id,
        players: %{^user_id => %{actions: %{2 => %{vote: %{target: ^other_id}}}}}
      })

      assert_reply(ref, :ok)
    end

    test "action responds with error on failure" do
      user = insert(:user)
      other_id = user.id + 1
      game = insert(:game)
      game_id = game.id
      user_id = user.id

      state = %{
        game: %Werewolf.Game{
          end_phase_unix_time: 1000,
          id: game_id,
          phase_length: :day,
          phases: 2,
          players: %{
            user.id => %Werewolf.Player{
              actions: %{},
              alive: true,
              host: true,
              id: user.id,
              role: :villager
            }
          }
        },
        rules: %Werewolf.Rules{state: :ready}
      }

      WerewolfApi.Game.update_state(game, state)

      insert(:users_game, user: user, game: game)
      {:ok, jwt, _} = encode_and_sign(user)
      {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
      {:ok, _, game_socket} = subscribe_and_join(socket, "game:#{game.id}", %{})
      {:ok, _, user_socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

      ref = push(game_socket, "action", %{target: other_id, action_type: "vote"})

      refute_broadcast("game_state_update", %{
        id: ^game_id,
        players: %{^user_id => %{actions: %{2 => %{vote: %{target: ^other_id}}}}}
      })

      assert_reply(ref, :error)
    end
  end
end
