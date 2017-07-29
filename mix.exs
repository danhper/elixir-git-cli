defmodule Git.Mixfile do
  use Mix.Project

  def project do
    [app: :git_cli,
     version: "0.2.4",
     elixir: "~> 1.0",
     name: "git_cli",
     source_url: "https://github.com/tuvistavie/elixir-git-cli",
     homepage_url: "https://github.com/tuvistavie/elixir-git-cli",
     package: package(),
     description: description(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     dialyzer: [ flags: [:unmatched_returns, :error_handling, :underspecs]],
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:earmark, "~> 0.2", only: :dev},
     {:ex_doc, "~> 0.11", only: :dev},
     {:dialyxir, "~> 0.5", only: [:dev, :test]},
     {:temp, "~> 0.4", only: :test}]
  end

  defp description do
    "A simple interface to Git CLI"
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE", "git-commands.txt"],
      maintainers: ["Daniel Perez"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/tuvistavie/elixir-git-cli"}
    ]
  end
end
