defmodule MavuForm.MixProject do
  use Mix.Project

  @version "0.1.2"
  def project do
    [
      app: :mavu_form,
      version: @version,
      elixir: "~> 1.10",
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:pit, "~> 1.2.0"},
      {:dbg_inspect, "~> 0.1.0"},
      {:typed_struct, "~> 0.2.1"},
      {:blankable, "~> 1.0"},
      {:phoenix_html, "~> 2.11"}
    ]
  end
end
