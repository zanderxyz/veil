
  # Default Routes for Veil
  scope "/veil", <%= web_module %>.Veil do
    <%= if html? do %>
    pipe_through(:browser)
    <% else %>
    pipe_through(:api)
    <% end %>

    post("/users", UserController, :create)
    <%= if html? do %>
    get("/users/new", UserController, :new)
    get("/sessions/new/:request_id", SessionController, :create)
    get("/sessions/signout/:session_id", SessionController, :delete)
    <% else %>
    post("/sessions/new", SessionController, :create)
    get("/sessions/new/:request_id", SessionController, :create)
    delete("/sessions/signout", SessionController, :delete)
    <% end %>
  end

  # Add your routes that require authentication in this block.
  # Alternatively, you can use the default block and authenticate in the controllers.
  # See the Veil README for more.
  scope "/", <%= web_module %> do
    <%= if html? do %>
    pipe_through([:browser, <%= web_module %>.Plugs.Veil.Authenticate])
    <% else %>
    pipe_through([:api, <%= web_module %>.Plugs.Veil.Authenticate])
    <% end %>
  end
end