defimpl ForgeSdk.Display, for: AbciVendor.KVPair do
  @moduledoc """
  Implementation of `Display` protocol for `KVPair`
  """

  def display(%{key: k, value: v}, _expand? \\ false) do
    key = if String.valid?(k), do: k, else: Base.encode16(k, case: :lower)
    value = if String.valid?(v), do: v, else: Base.url_encode64(v, padding: false)

    %{
      key: key,
      value: value
    }
  end
end
