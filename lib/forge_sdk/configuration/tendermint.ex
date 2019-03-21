defmodule ForgeSdk.Configuration.Tendermint do
  @moduledoc "Hold tendermint related configuration."
  use TypedStruct

  typedstruct do
    field(:name, atom(), default: :tendermint)
  end
end

defimpl ForgeSdk.Configuration, for: ForgeSdk.Configuration.Tendermint do
  alias ForgeSdk.Configuration.{Helper, Tendermint}

  @spec parse(Tendermint.t(), map()) :: map()
  def parse(_parser, config) do
    config = Helper.parse_config(config, ["executable", "keypath", "logpath"])

    new_paths = [
      {"genesis_file", Path.join(config["path"], "config/genesis.json")},
      {"config_file", Path.join(config["path"], "config/config.toml")},
      {"node_key_file", Path.join(config["keypath"], "node_key.json")},
      {"validator_key_file", Path.join(config["keypath"], "priv_validator_key.json")}
    ]

    config = Helper.add_paths(config, new_paths)
    Helper.put_env(:tendermint_config, config)
    Application.put_env(:forge, :consensus_config, config)
    config
  end
end
