defmodule <%= web_module %>.Veil.UserView do
  use <%= web_module %>, :view

  <%= unless html? do %>
  def render("ok.json", _assigns) do
    %{ok: true}
  end
  <% end %>
end
