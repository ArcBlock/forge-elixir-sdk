defmodule ForgeSdk.Configuration.Tendermint do
  @moduledoc "Hold tendermint related configuration"
  use TypedStruct

  typedstruct do
    field(:name, atom(), default: :tendermint)
  end
end

defimpl ForgeSdk.Configuration, for: ForgeSdk.Configuration.Tendermint do
  require Logger

  alias ForgeSdk.Configuration.{Helper, Tendermint}

  @spec parse(Tendermint.t(), map()) :: map()
  def parse(_parser, config) do
    new_paths = [
      {"genesis_file", "config/genesis.json"},
      {"config_file", "config/config.toml"},
      {"node_key_file", "config/node_key.json"}
    ]

    config =
      config
      |> Helper.parse_config(["executable", "logfile"])
      |> Helper.add_paths(new_paths)

    Helper.put_env(:tendermint_config, config)
    Application.put_env(:forge, :consensus_config, config)
    config
  end
end
