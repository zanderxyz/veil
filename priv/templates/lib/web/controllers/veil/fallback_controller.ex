defmodule <%= web_module %>.Veil.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  require Logger
  use <%= web_module %>, :controller
  alias <%= main_module %>.Veil.User

  def call(conn, {:error, {:closed, ""}}) do
    Logger.error(fn -> "[Veil] Invalid Swoosh api key, update your config.exs" end)
    <%= if html? do %>
    conn
    |> put_view(<%= web_module %>.Veil.UserView)
    |> render("new.html", changeset: User.changeset(%User{}))
    <% else %>
    conn
    |> put_view(<%= web_module %>.Veil.ErrorView)
    |> render(:invalid_mail_api_key)
    <% end %>
  end

  def call(conn, {:error, :no_permission}) do
    Logger.error(fn -> "[Veil] Invalid Request or Session" end)
    <%= if html? do %>
    conn
    |> put_view(<%= web_module %>.Veil.UserView)
    |> render("new.html", changeset: User.changeset(%User{}))
    <% else %>
    conn
    |> put_view(<%= web_module %>.Veil.ErrorView)
    |> render(:no_permission)
    <% end %>
  end
end
