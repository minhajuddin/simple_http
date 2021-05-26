defmodule SimpleHTTP.MixProject do
  use Mix.Project

  def project do
    [
      app: :simple_http,
      name: "SimpleHTTP",
      description: description(),
      package: package(),
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    A Simple HTTP client meant to teach how to write an HTTP client.
    """
  end

  defp package do
    [
      description: description(),
      files: ~w(lib mix.exs README.md LICENSE),
      maintainers: ["Khaja Minhajuddin"],
      licenses: ["MIT"],
      links: %{
        "Github" => "http://github.com/minhajuddin/simple_http",
        "Docs" => "http://hexdocs.pm/simple_http"
      }
    ]
  end
end
