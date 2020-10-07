defmodule WerewolfApi.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(WerewolfApi.Repo, []),
      # Start the endpoint when the application starts
      supervisor(WerewolfApiWeb.Endpoint, []),
      # start fetching google jwk verification
      GoogleAuthStrategy,
      WerewolfApi.Scheduler,
      supervisor(Exq, [])
      # Start your own worker by calling: WerewolfApi.Worker.start_link(arg1, arg2, arg3)
      # worker(WerewolfApi.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    # try one_for_all for now, normal is one_for_one
    opts = [
      strategy: :one_for_all,
      max_restarts: 10,
      max_seconds: 20,
      name: WerewolfApi.Supervisor
    ]

    {:ok, _} = Logger.add_backend(Sentry.LoggerBackend)

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    WerewolfApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
