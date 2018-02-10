defmodule <%= web_module %>.Veil.SessionView do
  use <%= web_module %>, :view

  <%= unless html? do %>
  def render("ok.json", _assigns) do
    %{ok: true}
  end

  def render("show.json", %{session: session}) do
    %{session_id: session.unique_id}
  end
  <% end %>
end
