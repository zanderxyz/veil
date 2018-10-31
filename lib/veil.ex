defmodule Veil do
  @moduledoc """
  Documentation for Veil.
  """

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    import Cachex.Spec

    children = [
      worker(Veil.Scheduler, []),
      worker(Veil.Secret, []),
      %{
        id: :veil_sessions,
        start:
          {Cachex, :start_link,
           [
             :veil_sessions,
             [
               expiration:
                 expiration(
                   default: Application.get_env(:veil, :session_expiry),
                   interval: :timer.seconds(60),
                   lazy: true
                 ),
               limit: Application.get_env(:veil, :sessions_cache_limit)
             ]
           ]}
      },
      %{
        id: :veil_users,
        start:
          {Cachex, :start_link,
           [
             :veil_users,
             [
               limit: Application.get_env(:veil, :users_cache_limit)
             ]
           ]}
      }
    ]

    opts = [strategy: :one_for_one, name: Veil.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
