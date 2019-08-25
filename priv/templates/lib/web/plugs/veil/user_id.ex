defmodule <%= web_module %>.Plugs.Veil.UserId do
  @moduledoc """
  A plug to verify if the client is logged in.
  If the client has a session id set as a cookie or api request header, we
  verify if it is valid and unexpired and assign their user_id to the conn. It
  can now be accessed using conn.assigns[:veil_user_id].
  """
  import Plug.Conn
  alias <%= main_module %>.Veil

  def init(default), do: default

  def call(conn, _opts) do
  <%= if html? do %>
    with session_unique_id <- conn.cookies["session_unique_id"],
  <% else %>
  def call(conn, _opts) do
    with [session_unique_id|_] <- get_req_header(conn, "session_unique_id"),
  <% end %>
         {:ok, session} <- Veil.get_session(session_unique_id),
         {:ok, user_id} <- Veil.verify(conn, session),
         true <- Kernel.==(user_id, session.user_id) do
      Task.start(fn -> Veil.extend_session(conn, session) end)

      conn
      |> assign(:veil_user_id, user_id)
      |> assign(:session_unique_id, session_unique_id)
    else
      _error ->
        conn
    end
  end

  <%= unless html? do %>
  def call(conn, _opts) do
    conn
  end
  <% end %>
end
