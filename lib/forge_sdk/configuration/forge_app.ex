defmodule ForgeSdk.Configuration.ForgeApp do
  @moduledoc "Hold forge app related configuration."
  use TypedStruct

  typedstruct do
    field(:name, atom(), default: :forge_app)
  end
end

defimpl ForgeSdk.Configuration, for: ForgeSdk.Configuration.ForgeApp do
  alias ForgeSdk.Configuration.{ForgeApp, Helper}

  @spec parse(ForgeApp.t(), map()) :: map()
  def parse(_parser, config) do
    config = Helper.parse_config(config, ["executable", "logfile", "error_logfile"])
    Helper.put_env(:forge_app_config, config)
    config
  end
end
