defmodule <%= web_module %>.Veil.UserController do
  use <%= web_module %>, :controller
  alias <%= main_module %>.Veil
  alias <%= main_module %>.Veil.User

  action_fallback(<%= web_module %>.Veil.FallbackController)

  <%= if html? do %>
  plug(:scrub_params, "user" when action in [:create])

  @doc """
  Shows the sign in form
  """
  def new(conn, _params) do
    render(conn, "new.html", changeset: User.changeset(%User{}))
  end
  <% end %>

  @doc """
  If needed, creates a new user, otherwise finds the existing one.
  Creates a new request and emails the unique id to the user.
  """
  <%= if html? do %>
  def create(conn, %{"user" => %{"email" => email}}) when not is_nil(email) do
  <% else %>
  def create(conn, %{"email" => email}) when not is_nil(email) do
  <% end %>
    if user = Veil.get_user_by_email(email) do
      sign_and_email(conn, user)
    else
      with {:ok, user} <- Veil.create_user(email) do
        sign_and_email(conn, user)
      else
        error ->
          error
      end
    end
  end

  defp sign_and_email(conn, %User{} = user) do
    with {:ok, request} <- Veil.create_request(conn, user),
         {:ok, email} <- Veil.send_login_email(conn, user, request) do
      <%= if html? do %>
        render(conn, "show.html", user: user, email: email)
      <% else %>
        render(conn, "ok.json")
      <% end %>
    else
      error ->
        error
    end
  end
end
