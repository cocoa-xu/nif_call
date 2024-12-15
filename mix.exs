defmodule NifCall.MixProject do
  use Mix.Project

  @app :nif_call
  @version "0.1.0"
  @github_url "https://github.com/cocoa-xu/nif_call"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:elixir_make] ++ Mix.compilers(),
      package: package(),
      docs: docs(),
      description: "Call Erlang/Elixir functions from NIF and use the returned value in NIF."
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @github_url,
      extras: [
        "README.md"
      ]
    ]
  end

  defp deps do
    [
      {:elixir_make, "~> 0.9", runtime: false},
      {:ex_doc, ">= 0.0.0", only: :docs, runtime: false}
    ]
  end

  defp package() do
    [
      name: to_string(@app),
      files: ~w(
        c_src
        lib
        mix.exs
        README*
        LICENSE*
      ),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @github_url}
    ]
  end
end
