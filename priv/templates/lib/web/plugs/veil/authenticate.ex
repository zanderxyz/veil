defmodule <%= web_module %>.Plugs.Veil.Authenticate do
  @moduledoc """
  A plug to restrict access to logged in users
  We simply check to see if the user has the :veil_user_id assign set
  """

  def init(default), do: default

  def call(conn, _opts) do
    unless is_nil(conn.assigns[:veil_user_id]) do
      conn
    else
      <%= if html? do %>
      Phoenix.Controller.redirect(conn, to: <%= web_module %>.Router.Helpers.user_path(conn, :new))
      <% else %>
      conn
      |> Phoenix.Controller.put_view(<%= web_module %>.Veil.ErrorView)
      |> Phoenix.Controller.render(:no_permission)
      <% end %>
    end
  end
end
