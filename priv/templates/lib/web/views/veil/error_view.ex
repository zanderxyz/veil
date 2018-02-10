defmodule <%= web_module %>.Veil.ErrorView do
  use <%= web_module %>, :view
  <%= unless html? do %>
  def render("no_permission.json", _assigns) do
    %{errors: %{detail: "No permission"}}
  end

  def render("invalid_mail_api_key.json", _assigns) do
    %{errors: %{detail: "Invalid Mail API key in config"}}
  end
  <% end %>
end
