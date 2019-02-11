defmodule ForgeSdk.Util.Validator do
  @moduledoc """
  Validation related functions
  """
  @doc """
  check if moniker is valid
  """
  @spec valid_moniker?(String.t()) :: boolean()
  def valid_moniker?(name), do: Regex.match?(~r/^[a-zA-Z0-9][a-zA-Z0-9_]{3,40}$/, name)

  @doc """
  check if passphrase is valid
  """
  @spec valid_passphrase?(String.t()) :: boolean()
  def valid_passphrase?(pass), do: Regex.match?(~r/^.{6,15}$/, pass)
end
