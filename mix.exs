defmodule ForgeSdk.MixProject do
  use Mix.Project

  @top File.cwd!()
  @version @top |> Path.join("version") |> File.read!() |> String.trim()
  @elixir_version @top |> Path.join(".elixir_version") |> File.read!() |> String.trim()

  def project do
    [
      app: :forge_sdk,
      version: @version,
      elixir: @elixir_version,
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      dialyzer: [ignore_warnings: ".dialyzer_ignore.exs", plt_add_apps: [:eex, :typed_struct]],
      description: description(),
      package: package(),
      # Docs
      name: "ForgeSdk",
      source_url: "https://github.com/arcblock/forge-elixir-sdk",
      homepage_url: "https://github.com/arcblock/forge-elixir-sdk",
      docs: [
        main: "ForgeSdk",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ForgeSdk.Application, []}
    ]
  end

  defp elixirc_paths(env) when env in [:dev, :test, :integration], do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:connection, "~> 1.0"},
      {:deep_merge, "~> 0.1.1"},
      {:jason, "~> 1.1"},
      {:multibase, "~> 0.0.1"},
      {:recase, "~> 0.4"},
      {:toml, "~> 0.5"},
      {:typed_struct, "~> 0.1.4"},

      # forge family dependencies
      {:mcrypto, "~> 0.2"},
      {:abt_did_elixir, "~> 0.3"},
      # {:abt_did_elixir, path: "../abt-did-elixir"},
      {:forge_abi, "~> 1.7"},
      # {:forge_abi, path: "../forge-abi"},

      # dev and test
      {:credo, "~> 1.0.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: [:test]},
      {:pre_commit_hook, "~> 1.2", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 0.4", only: [:test, :integration]}
    ]
  end

  defp description do
    """
    Elixir / Erlang version of the SDK for Forge framework.
    """
  end

  defp package do
    [
      files: [
        "config",
        "lib",
        "priv",
        "mix.exs",
        "README*",
        "LICENSE",
        "version",
        ".elixir_version"
      ],
      licenses: ["Apache 2.0"],
      maintainers: [
        "christinaleizhou@gmail.com",
        "cnredink@gmail.com",
        "dingpl716@gmail.com",
        "sunboshan@gmail.com",
        "tyr.chen@gmail.com"
      ],
      links: %{
        "GitHub" => "https://github.com/arcblock/forge-elixir-sdk",
        "Docs" => "https://hexdocs.pm/forge-elixir-sdk"
      }
    ]
  end
end
