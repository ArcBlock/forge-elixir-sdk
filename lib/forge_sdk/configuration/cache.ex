defmodule ForgeSdk.Configuration.Cache do
  @moduledoc "Hold cache related configuration"
  use TypedStruct

  typedstruct do
    field(:name, atom(), default: :cache)
  end
end

defimpl ForgeSdk.Configuration, for: ForgeSdk.Configuration.Cache do
  alias ForgeSdk.Configuration.{Helper, Cache}

  @spec parse(Cache.t(), map()) :: map()
  def parse(_parser, config) do
    config = Helper.parse_config(config, [])
    Helper.put_env(:cache_config, config)

    case Map.get(config, "cache_mnesia_table_timeout") do
      nil -> nil
      value -> Helper.put_env(:cache_mnesia_table_timeout, value)
    end

    config
  end

  #
end
