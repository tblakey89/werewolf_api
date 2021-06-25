defmodule WerewolfApiWeb.GameChannelTest do
  use WerewolfApiWeb.ChannelCase
  import WerewolfApi.Factory
  import WerewolfApi.Guardian
  alias WerewolfApi.Repo
  alias WerewolfApi.Game.Message

  setup do
    user = insert(:user)
    game = insert(:game)

    users_game =
      insert(
        :users_game,
        user: user,
        game: game,
        last_read_at: DateTime.from_naive!(~N[2018-11-15 10:00:00], "Etc/UTC")
      )

    {:ok, jwt, _} = encode_and_sign(user)
    {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
    {:ok, _, socket} = subscribe_and_join(socket, "game:#{game.id}", %{})

    {:ok, socket: socket, game: game, user: user, users_game: users_game}
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
      assert Repo.get_by(Message, body: sent_message)
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
          players: build_players(user.id)
        },
        rules: %Werewolf.Rules{state: :ready}
      }

      WerewolfApi.Game.update_state(game, state)

      {:ok, jwt, _} = encode_and_sign(user)
      {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
      {:ok, _, game_socket} = subscribe_and_join(socket, "game:#{game.id}", %{})
      {:ok, _, user_socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

      ref = push(game_socket, "launch_game", %{})

      assert_broadcast("game_update", %{
        id: ^game_id,
        state: %{players: %{^user_id => %{id: ^user_id}}}
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
          players: build_players(user.id)
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

      refute_broadcast("game_update", %{
        id: ^game_id,
        state: %{players: %{^user_id => %{id: ^user_id}}}
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
          players: build_players(user.id)
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
              role: :villager,
              team: :villager
            },
            (user.id + 1) => %Werewolf.Player{
              actions: %{},
              alive: true,
              host: false,
              id: other_id,
              role: :villager,
              team: :villager
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

  describe "claim_role event" do
    test "claim_role responds with ok on success" do
      user = insert(:user)
      game = insert(:game)
      game_id = game.id
      user_id = user.id

      state = %{
        game: %Werewolf.Game{
          end_phase_unix_time: 1000,
          id: game_id,
          phase_length: :day,
          phases: 2,
          options: %Werewolf.Options{allow_claim_role: true},
          players: %{
            user.id => %Werewolf.Player{
              actions: %{},
              alive: true,
              host: true,
              id: user.id,
              role: :villager,
              team: :villager,
              claim: :none
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

      ref = push(game_socket, "claim_role", %{claim: "gravedigger"})

      assert_broadcast("game_state_update", %{
        id: ^game_id,
        players: %{^user_id => %{claim: "gravedigger"}}
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
              role: :villager,
              team: :villager,
              claim: :none
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

      ref = push(game_socket, "claim_role", %{claim: "gravedigger"})

      refute_broadcast("game_state_update", %{
        id: ^game_id,
        players: %{^user_id => %{claim: "gravedigger"}}
      })

      assert_reply(ref, :error)
    end
  end

  describe "end_phase event" do
    test "end_phase responds with ok on success" do
      user = insert(:user)
      game = insert(:game)
      game_id = game.id
      user_id = user.id

      state = %{
        game: %Werewolf.Game{
          end_phase_unix_time: 1000,
          id: game_id,
          phase_length: :day,
          phases: 2,
          options: %Werewolf.Options{allow_host_end_phase: true},
          players: %{
            user.id => %Werewolf.Player{
              actions: %{},
              alive: true,
              host: true,
              id: user.id,
              role: :villager,
              team: :villager
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

      ref = push(game_socket, "end_phase", %{})

      assert_broadcast("game_state_update", %{
        id: ^game_id,
        state: :game_over
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
              role: :villager,
              team: :villager
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

      ref = push(game_socket, "end_phase")

      refute_broadcast("end_phase", %{
        id: ^game_id,
        state: :game_over
      })

      assert_reply(ref, :error)
    end
  end

  describe "read_game event" do
    test "users_game is updated", %{socket: socket, users_game: users_game} do
      ref = push(socket, "read_game", %{})
      original_last_read_at = users_game.last_read_at
      assert_reply(ref, :ok)
      updated_users_game = Repo.get(WerewolfApi.UsersGame, users_game.id)

      assert(
        DateTime.to_unix(original_last_read_at) <
          DateTime.to_unix(updated_users_game.last_read_at)
      )

      assert(
        DateTime.to_unix(original_last_read_at) < updated_users_game.last_read_at_map["standard"]
      )
    end

    test "users_game updates werewolf last read at", %{socket: socket, users_game: users_game} do
      ref = push(socket, "read_game", %{"destination" => "werewolf"})
      assert_reply(ref, :ok)
      updated_users_game = Repo.get(WerewolfApi.UsersGame, users_game.id)
      assert(0 < updated_users_game.last_read_at_map["werewolf"])
    end
  end

  describe "request_state_update event" do
    test "game state is sent", %{socket: socket, users_game: users_game} do
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
          players: build_players(user.id)
        },
        rules: %Werewolf.Rules{state: :ready}
      }

      {:ok, jwt, _} = encode_and_sign(user)
      {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
      {:ok, _, game_socket} = subscribe_and_join(socket, "game:#{game.id}", %{})
      {:ok, _, user_socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

      ref = push(game_socket, "request_state_update", %{})

      assert_broadcast("game_state_update", %{
        id: ^game_id
      })

      assert_reply(ref, :ok)
    end
  end

  describe "request_game_update event" do
    test "game is sent", %{socket: socket, users_game: users_game} do
      user = insert(:user)
      game = insert(:game)
      game_id = game.id
      user_id = user.id
      insert(:users_game, user: user, game: game, state: "host")

      {:ok, jwt, _} = encode_and_sign(user)
      {:ok, socket} = connect(WerewolfApiWeb.UserSocket, %{"token" => jwt})
      {:ok, _, game_socket} = subscribe_and_join(socket, "game:#{game.id}", %{})
      {:ok, _, user_socket} = subscribe_and_join(socket, "user:#{user.id}", %{})

      ref = push(game_socket, "request_game_update", %{})

      assert_broadcast("game_update", %{
        id: ^game_id
      })

      assert_reply(ref, :ok)
    end
  end

  defp build_players(user_id) do
    Enum.reduce(0..6, %{}, fn i, acc ->
      player = insert(:user)

      Map.put_new(acc, player.id, %Werewolf.Player{
        actions: %{},
        alive: true,
        host: false,
        id: player.id,
        role: :none,
        team: :none
      })
    end)
    |> Map.put(user_id, %Werewolf.Player{
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
      id: user_id,
      role: :none,
      team: :none
    })
  end
end
