defmodule <%= web_module %>.Veil.LoginEmail do
  use Phoenix.Swoosh, view: <%= web_module %>.Veil.EmailView

  @doc """
  Generates an email using the login template.
  """
  def generate(email, url) do
    new()
    |> to(email)
    |> from(from_email())
    |> subject("Welcome to #{Application.get_env(:veil, :site_name)}!")
    |> render_body("login.html", %{url: url, site_name: site_name()})
  end

  defp from_email do
    {Application.get_env(:veil, :email_from_name),
     Application.get_env(:veil, :email_from_address)}
  end

  defp site_name do
    Application.get_env(:veil, :site_name)
  end
end
