defmodule <%= web_module %>.Plugs.Veil.User do
  @moduledoc """
  A plug to assign the Veil.User struct to the connection.
  """
  require Logger
  import Plug.Conn
  alias <%= main_module %>.Veil

  def init(default), do: default

  def call(conn, _opts) do
    if veil_user_id = conn.assigns[:veil_user_id] do
      {:ok, veil_user} = Veil.get_user(veil_user_id)
      assign(conn, :veil_user, veil_user)
    else
      conn
    end
  end
end
