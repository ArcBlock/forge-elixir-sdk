defmodule ForgeSdk.Configuration.Forge do
  @moduledoc "Hold forge related configuration"
  use TypedStruct

  typedstruct do
    field(:name, atom(), default: :forge)
  end
end

defimpl ForgeSdk.Configuration, for: ForgeSdk.Configuration.Forge do
  alias ForgeSdk.Configuration.{Forge, Helper}

  @spec parse(Forge.t(), map()) :: map()
  def parse(_parser, conf) do
    config = conf["forge"]
    consensus_config = conf[config["consensus_engine"]]
    genesis = consensus_config["genesis"]
    config = Helper.parse_config(config, ["db", "index_db", "keystore", "logfile"])
    Helper.put_env(:forge_config, config)
    Helper.put_env(:consensus, to_atom(config, "consensus_engine"))
    Helper.put_env(:storage, to_atom(config, "storage_engine"))
    Helper.put_env(:chain_id, genesis["chain_id"])
    config
  end

  # private function
  defp to_atom(conf, name), do: String.to_existing_atom(conf[name])
end
