defmodule MavuForm.MixProject do
  use Mix.Project

  @version "1.0.0"
  def project do
    [
      app: :mavu_form,
      version: @version,
      elixir: "~> 1.0",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "MavuForm",
      source_url: "https://github.com/mavuio/mavu_form"
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
      {:mavu_utils, "~> 1.0"},
      {:phoenix_html, "~> 2.11 or ~> 3.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "HTML-Input helpers used in other upcoming packages under mavuio/\*"
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/mavuio/mavu_form"}
    ]
  end
end
