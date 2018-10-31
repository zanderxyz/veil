defmodule Veil.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :veil,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "Simple passwordless authentication for your Phoenix apps.",
      package: package(),

      # Docs
      name: "Veil",
      source_url: "https://github.com/zanderxyz/veil",
      homepage_url: "https://github.com/zanderxyz/veil",
      docs: [
        source_ref: "v#{@version}",
        main: "Veil",
        canonical: "http://hexdocs.pm/veil",
        source_url: "https://github.com/zanderxyz/veil"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Veil, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev},
      {:swoosh, "~> 0.13"},
      {:phoenix_swoosh, "~> 0.2"},
      {:quantum, "~> 2.3"},
      {:plug, "~> 1.3"},
      {:cachex, "~> 3.1"}
    ]
  end

  # These are the default files included in the package
  defp package do
    [
      maintainers: ["Zander Khan"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/zanderxyz/veil"}
    ]
  end
end
