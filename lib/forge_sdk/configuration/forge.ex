defmodule ForgeSdk.Configuration.Forge do
  @moduledoc "Hold forge related configuration."
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
    consensus = config["consensus_engine"]
    chain_id = get_in(conf, [consensus, "genesis", "chain_id"])
    config = Helper.parse_config(config, ["db", "index_db", "keystore", "logfile"])
    Helper.put_env(:forge_config, config)
    Helper.put_env(:consensus, String.to_existing_atom(consensus))
    Helper.put_env(:storage, String.to_existing_atom(config["storage_engine"]))
    Helper.put_env(:chain_id, chain_id)
    config
  end
end
