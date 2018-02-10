defmodule <%= main_module %>.Veil.Clean do
  @moduledoc """
  Used alongside Quantum to schedule regular pruning of the database
  """

  alias <%= main_module %>.Veil

  @doc """
  Delete all expired requests and sessions
  """
  def delete_expired do
    Task.start(fn -> Veil.delete_expired_requests() end)
    Task.start(fn -> Veil.delete_expired_sessions() end)
  end
end
