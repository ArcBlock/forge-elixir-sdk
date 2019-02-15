defprotocol ForgeSdk.Serializable do
  @moduledoc """
  Serializable protocol for serialize and deserialize data
  """

  @type t :: ForgeSdk.Serializable.t()

  @doc """
  Encode the data to binary data
  """
  @spec encode(t()) :: binary()
  def encode(data)
end

defimpl ForgeSdk.Serializable, for: BitString do
  @spec encode(binary()) :: binary()
  def encode(data), do: data
end

defimpl ForgeSdk.Serializable, for: Integer do
  @spec encode(integer()) :: binary()
  def encode(data), do: Integer.to_string(data)
end