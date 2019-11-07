defmodule MegaParser.MixProject do
  use Mix.Project

  def project do
    [
      app: :mega_parser,
      version: "0.1.0",
      elixir: "~> 1.6",
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
      {:meeseeks, "> 0.0.0"},
      {:benchee, "~> 1.0", only: :dev},
      {:exprof, "~> 0.2.0"},
      {:saxy, "~> 0.10.0"}
    ]
  end
end
