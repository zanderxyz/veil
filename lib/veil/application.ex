defmodule Veil.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Veil.Scheduler, []),
      worker(Veil.Secret, [])
    ]

    opts = [strategy: :one_for_one, name: Veil.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
