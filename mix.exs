defmodule ForgeSdk.MixProject do
  use Mix.Project

  @top File.cwd!()

  @version @top |> Path.join("version") |> File.read!() |> String.trim()
  @elixir_version @top
                  |> Path.join(".elixir_version")
                  |> File.read!()
                  |> String.trim()
  def project do
    [
      app: :forge_sdk,
      version: @version,
      elixir: @elixir_version,
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ForgeSdk.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:integration), do: elixirc_paths(:test)
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:connection, "~> 1.0"},
      {:deep_merge, "~> 0.1.1"},
      {:ex_abci_proto, "~> 0.7.6"},
      {:jason, "~> 1.1"},
      {:multibase, "~> 0.0.1"},
      {:recase, "~> 0.4"},
      {:toml, "~> 0.5"},
      {:typed_struct, "~> 0.1.4"},

      # forge family dependencies
      {:mcrypto, "~> 0.2"},
      {:abt_did, git: "git@github.com:arcblock/abt-did-elixir.git", tag: "v0.1.13"},
      {:forge_abi, git: "git@github.com:arcblock/forge_abi.git", tag: "v1.2.3"},

      # dev and test
      {:stream_data, "~> 0.4", only: [:test, :integration]}
    ]
  end
end
