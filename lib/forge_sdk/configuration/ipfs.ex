defmodule ForgeSdk.Configuration.Ipfs do
  @moduledoc "Hold ipfs related configuration."
  use TypedStruct

  typedstruct do
    field(:name, atom(), default: :ipfs)
  end
end

defimpl ForgeSdk.Configuration, for: ForgeSdk.Configuration.Ipfs do
  alias ForgeSdk.Configuration.{Helper, Ipfs}

  @spec parse(Ipfs.t(), map()) :: map()
  def parse(_parser, config) do
    config = Helper.parse_config(config, ["executable", "logpath"])

    config = Helper.add_paths(config, [{"config_file", Path.join(config["path"], "config")}])

    Helper.put_env(:ipfs_config, config)
    Application.put_env(:forge, :storage_config, config)
    config
  end
end
