defmodule <%= web_module %>.Veil.LoginEmail do
  use Phoenix.Swoosh, view: <%= web_module %>.Veil.EmailView

  @doc """
  Generates an email using the login template.
  """
  def generate(email, url) do
    site = Application.get_env(:veil, :site_name)

    new()
    |> to(email)
    |> from(from_email())
    |> subject("Welcome to #{site}!")
    |> render_body("login.html", %{url: url, site_name: site})
  end

  defp from_email do
    {Application.get_env(:veil, :email_from_name),
     Application.get_env(:veil, :email_from_address)}
  end
end
