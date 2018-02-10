defmodule <%= web_module %>.Plugs.Veil.User do
  @moduledoc """
  A plug to assign the Veil.User struct to the connection.
  Not used by default, but useful if you have extended the Veil.User struct
  """
  require Logger
  import Plug.Conn
  alias <%= main_module %>.Veil

  def init(default), do: default

  def call(conn, _opts) do
    if veil_user_id = conn.assigns[:veil_user_id] do
      assign(conn, :veil_user, Veil.get_user(veil_user_id))
    else
      conn
    end
  end
end
