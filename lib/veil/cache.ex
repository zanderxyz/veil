defmodule Veil.Cache do
  @moduledoc """
  A cache to store sessions, to reduce database calls
  """

  @doc """
  If the changeset provided is valid, saves it in the cache under it's identifier, and executes the repo function
  """
  def put(changeset, cache, repo_function, identifier \\ & &1.id) do
    if changeset.valid? do
      with {:ok, struct} <- repo_function.(changeset),
           {:ok, true} <- Cachex.put(cache, identifier.(struct), struct) do
        {:ok, struct}
      else
        error -> error
      end
    else
      {:error, :invalid_changeset, changeset.errors}
    end
  end

  @doc """
  Fetches the value under the given key from the cache.
  If it doesn't exist, calls function on key, stores it in the cache and returns it
  """
  def get_or_update(cache, key, function) do
    Cachex.execute(cache, fn worker ->
      Cachex.touch(worker, key)

      case Cachex.fetch(worker, key, function) do
        {:commit, value} -> {:ok, value}
        {:ok, value} -> {:ok, value}
        error -> error
      end
    end)
  end

  @doc """
  Touch to reset the expiry, then get
  """
  def get_and_refresh(cache, key) do
    Cachex.execute(cache, fn worker ->
      Cachex.touch(worker, key)
      Cachex.get(worker, key)
    end)
  end
end
